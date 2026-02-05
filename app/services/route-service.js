const path = require('path');
const { requireOwnedSession, requireSessionReadOnly, requireSession } = require('../middleware/session-resolver');
const { requireInternalApiKey } = require('../middleware/internal-auth');

/**
 * Route service — session-scoped API and static routes.
 * All execution paths that touch runtime require sessionId. No global vnc-info.
 * 
 * Multi-Session Isolation:
 * - VNC and SSH access requires STRICT ownership verification
 * - Status/info endpoints allow read-only access
 */
class RouteService {
    /**
     * @param {import('./public-service')} publicService
     * @param {import('./vnc-service')} vncService
     * @param {import('./session-registry').SessionRegistry} sessionRegistry
     * @param {import('../middleware/session-resolver').requireSession} requireSessionFn
     */
    constructor(publicService, vncService, sessionRegistry, requireSessionFn) {
        this.publicService = publicService;
        this.vncService = vncService;
        this.sessionRegistry = sessionRegistry;
        this.requireSession = requireSessionFn;
    }

    setupRoutes(app) {
        // ——— Session-scoped API (sessionId required) ———
        // Get runtime info for a session (VNC + terminal endpoints)
        // SECURITY: Use strict ownership check since this exposes runtime endpoints
        app.get(
            '/api/sessions/:sessionId/runtime',
            requireOwnedSession(this.sessionRegistry),  // STRICT ownership
            (req, res) => {
                const session = req.session;
                const vncInfo = this.vncService.getVncInfoForSession(req.sessionId, session);
                const ssh = session.ssh || {};
                res.json({
                    status: session.state || 'ready',
                    vncInfo,
                    terminalInfo: {
                        wsPath: '/ssh',
                        query: { sessionId: req.sessionId }
                    },
                    sessionId: req.sessionId
                });
            }
        );

        // Legacy alias: vnc-info for a session (same as runtime.vncInfo)
        // SECURITY: Use strict ownership check since this exposes VNC credentials
        app.get(
            '/api/sessions/:sessionId/vnc-info',
            requireOwnedSession(this.sessionRegistry),  // STRICT ownership
            (req, res) => {
                res.json(this.vncService.getVncInfoForSession(req.sessionId, req.session));
            }
        );

        // Register session (called by Sailor API / orchestrator after provisioning)
        // SECURITY: Requires internal API key (protects against unauthorized session creation)
        app.post('/api/sessions', requireInternalApiKey, async (req, res) => {
            const { 
                sessionId, 
                vnc, 
                ssh, 
                kubernetes,
                state, 
                expiresAt,
                ownerId,      // User who owns this session
                examSessionId // Sailor API ExamSession ID for reference
            } = req.body || {};
            
            if (!sessionId || typeof sessionId !== 'string' || !sessionId.trim()) {
                return res.status(400).json({ error: 'sessionId is required' });
            }
            
            // Check for duplicate session creation (idempotency)
            if (this.sessionRegistry.has(sessionId)) {
                const existing = this.sessionRegistry.get(sessionId);
                // If same owner, return success (idempotent)
                if (existing.ownerId === ownerId) {
                    console.log(`[Sessions] Idempotent session creation for ${sessionId}`);
                    return res.status(200).json({ 
                        sessionId, 
                        state: existing.state,
                        idempotent: true 
                    });
                }
                // Different owner trying to create same session - reject
                return res.status(409).json({ 
                    error: 'Session already exists',
                    sessionId 
                });
            }
            
            try {
                const record = await this.sessionRegistry.set(sessionId, {
                    state: state || 'ready',
                    vnc: vnc || {},
                    ssh: ssh || {},
                    kubernetes: kubernetes || null,
                    expiresAt: expiresAt || null,
                    ownerId: ownerId || null,
                    examSessionId: examSessionId || null,
                });
                console.log(`[Sessions] Created session ${sessionId} for owner ${ownerId}`);
                res.status(201).json({ 
                    sessionId: record.sessionId, 
                    state: record.state,
                    ownerId: record.ownerId
                });
            } catch (e) {
                console.error(`[Sessions] Failed to create session ${sessionId}:`, e.message);
                res.status(400).json({ error: e.message });
            }
        });

        // Release session (remove from registry; teardown is external)
        // SECURITY: Requires internal API key (protects against unauthorized session deletion)
        app.delete('/api/sessions/:sessionId', requireInternalApiKey, async (req, res) => {
            const { sessionId } = req.params;
            const { ownerId } = req.query; // Optional owner verification
            
            const session = this.sessionRegistry.get(sessionId);
            
            // If ownerId provided, verify ownership
            if (ownerId && session && session.ownerId && session.ownerId !== ownerId) {
                return res.status(403).json({ 
                    error: 'Not authorized to release this session',
                    sessionId 
                });
            }
            
            const had = this.sessionRegistry.has(sessionId);
            await this.sessionRegistry.delete(sessionId);
            console.log(`[Sessions] Released session ${sessionId} (existed: ${had})`);
            res.status(200).json({ released: true, sessionId, existed: had });
        });

        // Check session existence and ownership
        app.get('/api/sessions/:sessionId/verify', (req, res) => {
            const { sessionId } = req.params;
            const { ownerId } = req.query;
            
            const session = this.sessionRegistry.get(sessionId);
            if (!session) {
                return res.status(404).json({ 
                    exists: false, 
                    sessionId,
                    message: 'Session not found'
                });
            }
            
            const isOwner = !ownerId || session.ownerId === ownerId || !session.ownerId;
            
            res.json({
                exists: true,
                sessionId,
                state: session.state,
                isOwner,
                expiresAt: session.expiresAt,
            });
        });

        // ——— No session (health only) ———
        app.get('/health', (req, res) => {
            res.status(200).json({ status: 'ok', message: 'Service is healthy' });
        });

        // ——— Static and catch-all ———
        // IMPORTANT: API routes must NOT serve HTML to prevent recursive UI embedding
        app.get('*', (req, res) => {
            // If this is an API path, return 404 JSON - NEVER serve HTML for API routes
            // This prevents the VNC iframe from loading index.html on proxy failure
            if (req.path.startsWith('/api/')) {
                return res.status(404).json({ 
                    error: 'Not Found', 
                    path: req.path,
                    message: 'API endpoint not found. This may indicate a missing session or invalid route.'
                });
            }
            
            // Static HTML routes
            if (req.path === '/exam') {
                res.sendFile(path.join(this.publicService.getPublicDir(), 'exam.html'));
            } else if (req.path === '/results') {
                res.sendFile(path.join(this.publicService.getPublicDir(), 'results.html'));
            } else {
                res.sendFile(path.join(this.publicService.getPublicDir(), 'index.html'));
            }
        });

        app.use((err, req, res, next) => {
            console.error('Server error:', err);
            res.status(500).sendFile(path.join(this.publicService.getPublicDir(), '50x.html'));
        });
    }
}

module.exports = RouteService;
