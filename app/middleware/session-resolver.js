/**
 * Session resolver middleware.
 * Requires sessionId in path (e.g. /api/sessions/:sessionId/...) and resolves
 * session from registry. Ensures no request is processed without a valid, routable session.
 */

const { SESSION_STATES } = require('../services/session-registry');

/**
 * @param {import('../services/session-registry').SessionRegistry} sessionRegistry
 * @returns {import('express').RequestHandler}
 */
function requireSession(sessionRegistry) {
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
        req.sessionId = sessionId;
        req.session = session;
        next();
    };
}

module.exports = { requireSession, SESSION_STATES };
