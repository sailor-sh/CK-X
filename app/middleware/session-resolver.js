/**
 * Session resolver middleware.
 * Requires sessionId in path (e.g. /api/sessions/:sessionId/...) and resolves
 * session from registry. Ensures no request is processed without a valid, routable session.
 * 
 * Multi-Session Isolation:
 * - Verifies session ownership when ownerId is available
 * - Extracts ownership info from session cookie
 * - Prevents cross-session access
 * - Logs security events for audit trail
 */

const { SESSION_STATES } = require('../services/session-registry');
const LaunchService = require('../services/launch-service');

/**
 * Log security events for audit trail
 */
function logSecurityEvent(event, details) {
    console.warn(JSON.stringify({
        timestamp: new Date().toISOString(),
        event,
        ...details
    }));
}

/**
 * Extract owner ID from request.
 * Uses session cookie only - query params are NOT trusted for identity.
 * @param {import('express').Request} req
 * @returns {string|null}
 */
function extractOwnerId(req) {
    // Try session cookie (the ONLY trusted source of identity)
    const cookieValue = req.cookies?.[LaunchService.SESSION_COOKIE_NAME];
    if (cookieValue) {
        try {
            const cookieData = LaunchService.verifySessionCookie(cookieValue);
            if (cookieData) {
                return cookieData.userId;
            }
        } catch (e) {
            // Invalid cookie, continue
        }
    }

    // SECURITY: Query param ownerId was removed as it allows impersonation.
    // Dev mode escape hatch: only in development with explicit opt-in
    if (process.env.NODE_ENV !== 'production' && process.env.CKX_DEV_SKIP_OWNERSHIP === 'true') {
        if (req.query?.ownerId) {
            console.warn('[DEV] Using ownerId from query param (CKX_DEV_SKIP_OWNERSHIP=true)');
            return req.query.ownerId;
        }
    }

    return null;
}

/**
 * @param {import('../services/session-registry').SessionRegistry} sessionRegistry
 * @param {object} options
 * @param {boolean} options.requireOwnership - If true, reject requests without valid ownership
 * @param {boolean} options.strictOwnership - If true, reject if ownerId doesn't match session's ownerId
 * @returns {import('express').RequestHandler}
 */
function requireSession(sessionRegistry, options = {}) {
    const { requireOwnership = false, strictOwnership = false } = options;
    
    return (req, res, next) => {
        const sessionId = req.params.sessionId;
        if (!sessionId || typeof sessionId !== 'string' || !sessionId.trim()) {
            res.status(400).json({ error: 'sessionId is required' });
            return;
        }
        const session = sessionRegistry.get(sessionId);
        if (!session) {
            res.status(404).json({ error: 'Session not found', sessionId });
            return;
        }
        if (!sessionRegistry.isRoutable(sessionId)) {
            res.status(410).json({
                error: 'Session not available',
                sessionId,
                state: session.state
            });
            return;
        }
        
        // Ownership verification
        const requestOwnerId = extractOwnerId(req);
        const sessionOwnerId = session.ownerId;

        // If session has an owner, enforce ownership
        if (sessionOwnerId) {
            // Require authentication for owned sessions
            if (strictOwnership && !requestOwnerId) {
                res.status(401).json({
                    error: 'Authentication required',
                    sessionId,
                    message: 'Session access requires valid session cookie'
                });
                return;
            }

            // Verify ownership matches
            if (strictOwnership && requestOwnerId !== sessionOwnerId) {
                logSecurityEvent('SESSION_ACCESS_DENIED', {
                    reason: 'ownership_mismatch',
                    requesterId: requestOwnerId,
                    sessionId,
                    sessionOwnerId,
                    path: req.path,
                    method: req.method,
                    ip: req.ip || req.connection?.remoteAddress,
                    userAgent: req.headers?.['user-agent']
                });
                res.status(403).json({
                    error: 'Session access denied',
                    sessionId,
                    message: 'You do not own this session'
                });
                return;
            }
        }
        // If session has NO owner (dev/standalone mode), allow access without auth
        
        req.sessionId = sessionId;
        req.session = session;
        req.ownerId = requestOwnerId;
        req.isOwner = !sessionOwnerId || requestOwnerId === sessionOwnerId;
        next();
    };
}

/**
 * Middleware that requires strict ownership verification.
 * Use for sensitive operations like VNC access, SSH connections.
 * @param {import('../services/session-registry').SessionRegistry} sessionRegistry
 * @returns {import('express').RequestHandler}
 */
function requireOwnedSession(sessionRegistry) {
    return requireSession(sessionRegistry, { requireOwnership: true, strictOwnership: true });
}

/**
 * Middleware for read-only access that verifies ownership if available.
 * Use for status checks, info endpoints.
 * @param {import('../services/session-registry').SessionRegistry} sessionRegistry
 * @returns {import('express').RequestHandler}
 */
function requireSessionReadOnly(sessionRegistry) {
    return requireSession(sessionRegistry, { requireOwnership: false, strictOwnership: false });
}

module.exports = { 
    requireSession, 
    requireOwnedSession,
    requireSessionReadOnly,
    extractOwnerId,
    logSecurityEvent,
    SESSION_STATES 
};
