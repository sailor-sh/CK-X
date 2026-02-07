/**
 * Iframe token validation middleware.
 * Validates capability tokens for iframe access to CKX proxy routes.
 * Sets req.user and req.iframeTokenValid if token is valid.
 */
const { verifyIframeToken } = require('../lib/iframe-token');

/**
 * Validate iframe access token from query parameter.
 * If token is present and valid:
 *   - Verifies signature, expiry, and ckxSessionId match
 *   - Sets req.user = { id: payload.userId } for downstream ownership checks
 *   - Sets req.iframeTokenValid = true to bypass requireAuth
 * If token is missing, continues (falls through to requireAuth).
 */
async function validateIframeToken(req, res, next) {
  const iframeToken = req.query?.iframeToken;

  // If no token, continue to normal auth flow
  if (!iframeToken) {
    return next();
  }

  // Verify token
  const result = verifyIframeToken(iframeToken);
  if (!result.valid) {
    return res.status(401).json({
      error: 'Invalid iframe token',
      details: result.error,
    });
  }

  const { payload } = result;
  // Use sessionId (set by previous middleware) or fallback to ckxSessionId
  const ckxSessionId = req.params?.sessionId || req.params?.ckxSessionId;

  if (!ckxSessionId) {
    console.error('Iframe token validation: Missing ckxSessionId:', req.params);
    return res.status(400).json({ error: 'ckxSessionId parameter required', debug: { params: req.params } });
  }

  // Verify ckxSessionId matches URL parameter (prevents token reuse for other sessions)
  if (payload.ckxSessionId !== ckxSessionId) {
    return res.status(401).json({
      error: 'Iframe token does not match session',
      expected: ckxSessionId,
      tokenSessionId: payload.ckxSessionId,
    });
  }

  // Set user for downstream ownership checks (requireActiveExamSession)
  // We only need the ID, not the full user record
  req.user = { id: payload.userId };

  // Flag to bypass requireAuth middleware
  req.iframeTokenValid = true;

  next();
}

module.exports = { validateIframeToken };
