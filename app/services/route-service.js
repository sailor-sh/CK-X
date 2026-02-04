const path = require('path');

/**
 * Route service — session-scoped API and static routes.
 * All execution paths that touch runtime require sessionId. No global vnc-info.
 */
class RouteService {
    /**
     * @param {import('./public-service')} publicService
     * @param {import('./vnc-service')} vncService
     * @param {import('./session-registry').SessionRegistry} sessionRegistry
     * @param {import('../middleware/session-resolver').requireSession} requireSession
     */
    constructor(publicService, vncService, sessionRegistry, requireSession) {
        this.publicService = publicService;
        this.vncService = vncService;
        this.sessionRegistry = sessionRegistry;
        this.requireSession = requireSession;
    }

    setupRoutes(app) {
        // ——— Session-scoped API (sessionId required) ———
        // Get runtime info for a session (VNC + terminal endpoints)
        app.get(
            '/api/sessions/:sessionId/runtime',
            this.requireSession(this.sessionRegistry),
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
        app.get(
            '/api/sessions/:sessionId/vnc-info',
            this.requireSession(this.sessionRegistry),
            (req, res) => {
                res.json(this.vncService.getVncInfoForSession(req.sessionId, req.session));
            }
        );

        // Register session (called by Sailor API / orchestrator after provisioning)
        app.post('/api/sessions', (req, res) => {
            const { sessionId, vnc, ssh, state, expiresAt } = req.body || {};
            if (!sessionId || typeof sessionId !== 'string' || !sessionId.trim()) {
                res.status(400).json({ error: 'sessionId is required' });
                return;
            }
            try {
                const record = this.sessionRegistry.set(sessionId, {
                    state: state || 'ready',
                    vnc: vnc || {},
                    ssh: ssh || {},
                    expiresAt: expiresAt || null
                });
                res.status(201).json({ sessionId: record.sessionId, state: record.state });
            } catch (e) {
                res.status(400).json({ error: e.message });
            }
        });

        // Release session (remove from registry; teardown is external)
        app.delete('/api/sessions/:sessionId', (req, res) => {
            const { sessionId } = req.params;
            const had = this.sessionRegistry.has(sessionId);
            this.sessionRegistry.delete(sessionId);
            res.status(200).json({ released: true, sessionId, existed: had });
        });

        // ——— No session (health only) ———
        app.get('/health', (req, res) => {
            res.status(200).json({ status: 'ok', message: 'Service is healthy' });
        });

        // ——— Static and catch-all ———
        app.get('*', (req, res) => {
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
