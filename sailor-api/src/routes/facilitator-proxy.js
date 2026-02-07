/**
 * Facilitator proxy routes. Sailor API proxies facilitator API requests after validating authentication.
 * 
 * Architectural note: Facilitator uses global Redis state (not session-scoped), which violates
 * the architecture contract. This proxy layer ensures all facilitator access goes through Sailor API
 * with proper authentication, but facilitator endpoints themselves need refactoring to be session-aware.
 * 
 * For now, we proxy with authentication validation (JWT or iframeToken) to maintain security while
 * allowing CKX frontend to call facilitator endpoints. Long-term: facilitator endpoints should accept
 * sessionId and be session-scoped, or be replaced by Sailor API endpoints.
 */
const { createProxyMiddleware } = require('http-proxy-middleware');
const config = require('../config');
const { requireAuth } = require('../middleware/auth');

/**
 * Proxy middleware factory: validates authentication, then proxies to facilitator.
 * All facilitator requests must be authenticated with JWT ONLY (not iframeToken).
 * 
 * SECURITY: Facilitator is INTERNAL and should NOT be called directly by browsers.
 * Browser code must use session-scoped Sailor API endpoints instead (e.g., /exam-sessions/:id/*).
 * This proxy exists only for server-to-server calls or legacy compatibility.
 * 
 * Note: Facilitator endpoints don't accept sessionId, so we only validate authentication here.
 * The facilitator service uses global Redis state (e.g., getCurrentExamId()), which means it
 * cannot support multi-session isolation. This is an architectural violation that needs to be
 * addressed by refactoring facilitator to be session-aware or replacing it with Sailor API endpoints.
 */
function createFacilitatorProxy() {
  return [
    // Guardrail: Reject iframeToken on facilitator routes (facilitator is internal-only)
    (req, res, next) => {
      console.warn(`[FACILITATOR PROXY] Browser call detected: ${req.method} ${req.originalUrl || req.path} - Referer: ${req.headers.referer || 'none'}`);
      const origin = req.headers.origin;
      const referer = req.headers.referer || '';
      const userAgent = req.headers['user-agent'] || '';
      const isBrowser = !!origin || referer.includes('/ckx/sessions/') || /Mozilla/i.test(userAgent);
      const isInternal = req.headers['x-internal-proxy'] === '1' || (!origin && !referer);

      if (isBrowser && !isInternal) {
        console.warn(`[FACILITATOR PROXY] Blocked browser-origin call [${req.method} ${req.path}] origin=${origin || 'none'} referer=${referer || 'none'}`);
        return res.status(400).json({
          error: 'Facilitator endpoints are internal-only',
          message: 'Browser must not call facilitator; use /exam-sessions/* via Sailor API',
        });
      }

      if (req.query?.iframeToken) {
        console.warn(`[FACILITATOR PROXY] Blocked iframeToken on facilitator route [${req.method} ${req.path}]`);
        return res.status(403).json({
          error: 'Facilitator endpoints are internal-only',
          message: 'Use session-scoped Sailor API endpoints instead (e.g., /exam-sessions/:id/*)',
        });
      }
      next();
    },
    // Require JWT authentication ONLY (no iframeToken)
    requireAuth,
    // Proxy to facilitator
    createProxyMiddleware({
      target: config.facilitator.baseUrl,
      changeOrigin: true,
      secure: false, // Allow self-signed certs in dev
      pathRewrite: {
        // Rewrite /facilitator/api/v1/* to /api/v1/* (remove /facilitator prefix)
        '^/facilitator': '',
      },
      // No need to strip iframeToken - it's already rejected by middleware above
      onError: (err, req, res) => {
        console.error(`Facilitator proxy error:`, err.message);
        if (res && res.writeHead) {
          res.writeHead(502, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Facilitator proxy error', message: err.message }));
        }
      },
      logLevel: 'warn',
    }),
  ];
}

module.exports = function setupFacilitatorProxyRoutes(app) {
  // Facilitator API proxy: /facilitator/api/v1/*
  // SECURITY: Only accepts JWT authentication (NOT iframeToken).
  // Browser code must NOT call /facilitator/* directly - use session-scoped endpoints instead.
  // This proxy exists for server-to-server calls only.
  app.use('/facilitator/api', ...createFacilitatorProxy());
};
