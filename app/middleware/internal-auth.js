/**
 * Internal API key authentication middleware.
 * Protects admin endpoints (session create/delete) from unauthorized access.
 *
 * In production, CKX_INTERNAL_API_KEY must be set and Sailor API must send it
 * as a Bearer token. In development, the middleware is bypassed if not configured.
 */

/**
 * Middleware that requires a valid internal API key for admin operations.
 * @returns {import('express').RequestHandler}
 */
function requireInternalApiKey(req, res, next) {
    const apiKey = process.env.CKX_INTERNAL_API_KEY;

    // Dev mode: skip if not configured
    if (!apiKey) {
        if (process.env.NODE_ENV === 'production') {
            console.error('[SECURITY] CKX_INTERNAL_API_KEY not set in production!');
            return res.status(500).json({ error: 'Server misconfigured' });
        }
        // In development without API key, allow requests
        return next();
    }

    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'API key required' });
    }

    const providedKey = authHeader.slice(7); // Remove 'Bearer ' prefix
    if (providedKey !== apiKey) {
        console.warn('[SECURITY] Invalid API key attempt from:', req.ip || req.connection?.remoteAddress);
        return res.status(401).json({ error: 'Invalid API key' });
    }

    next();
}

module.exports = { requireInternalApiKey };
