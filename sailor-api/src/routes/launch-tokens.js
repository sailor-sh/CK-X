/**
 * Launch token validation routes.
 * 
 * These endpoints are called by CKX to validate launch tokens during the new-tab handoff.
 * This is an internal API - CKX calls this when a user lands on /launch?token=...
 */
const express = require('express');
const { validateAndConsumeLaunchToken, peekLaunchToken } = require('../lib/launch-token');

const router = express.Router();

/**
 * POST /launch-tokens/validate
 * 
 * Validates and consumes a launch token. Called by CKX during lab launch.
 * The token is consumed (one-time use) to prevent replay attacks.
 * 
 * Request body: { token: string }
 * Response: { valid: true, sessionId, userId, examSessionId } or { valid: false, error }
 */
router.post('/validate', (req, res) => {
  const { token } = req.body || {};
  
  if (!token) {
    return res.status(400).json({ valid: false, error: 'Token is required' });
  }
  
  const result = validateAndConsumeLaunchToken(token);
  
  if (!result.valid) {
    return res.status(401).json({ valid: false, error: result.error });
  }
  
  return res.json({
    valid: true,
    sessionId: result.data.ckxSessionId,
    userId: result.data.userId,
    examSessionId: result.data.examSessionId,
  });
});

/**
 * POST /launch-tokens/peek
 * 
 * Validates a launch token WITHOUT consuming it. Used for verification only.
 * Useful for debugging or pre-validation.
 * 
 * Request body: { token: string }
 * Response: { valid: true, sessionId, userId, examSessionId } or { valid: false, error }
 */
router.post('/peek', (req, res) => {
  const { token } = req.body || {};
  
  if (!token) {
    return res.status(400).json({ valid: false, error: 'Token is required' });
  }
  
  const result = peekLaunchToken(token);
  
  if (!result.valid) {
    return res.status(401).json({ valid: false, error: result.error });
  }
  
  return res.json({
    valid: true,
    sessionId: result.data.ckxSessionId,
    userId: result.data.userId,
    examSessionId: result.data.examSessionId,
  });
});

module.exports = router;
