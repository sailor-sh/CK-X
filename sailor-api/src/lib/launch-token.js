/**
 * Launch token utilities.
 * 
 * Launch tokens are short-lived, single-purpose tokens for opening a lab in a new tab.
 * They are:
 * - Bound to a specific sessionId + userId
 * - Very short TTL (60 seconds) - just enough to complete the handoff
 * - One-time use (consumed on validation)
 * 
 * Flow:
 * 1. User clicks "Open Lab" in Sailor UI
 * 2. Sailor API creates launch token (POST /exam-sessions/:id/launch-token)
 * 3. Sailor UI opens new tab: CKX_URL/launch?token=...
 * 4. CKX validates token, creates session cookie, redirects to /exam.html
 * 5. Token is consumed (cannot be reused)
 */
const crypto = require('crypto');
const config = require('../config');

// In-memory store for launch tokens (use Redis in production for multi-instance)
// Map<tokenId, { sessionId, userId, ckxSessionId, expiresAt, consumed }>
const launchTokenStore = new Map();

// Track recent token requests per session to prevent rapid-fire duplicates
// Map<ckxSessionId, { lastTokenAt: timestamp, pendingTokenId: string | null }>
const sessionLaunchTracker = new Map();

// Minimum interval between token requests for same session (ms)
const MIN_TOKEN_INTERVAL_MS = 5000;

// Cleanup expired tokens periodically
setInterval(() => {
  const now = Date.now();
  for (const [tokenId, data] of launchTokenStore) {
    if (data.expiresAt < now) {
      launchTokenStore.delete(tokenId);
    }
  }
  // Also cleanup old session trackers
  for (const [sessionId, tracker] of sessionLaunchTracker) {
    if (now - tracker.lastTokenAt > 120000) { // 2 minutes
      sessionLaunchTracker.delete(sessionId);
    }
  }
}, 60000); // Every minute

const LAUNCH_TOKEN_SECRET = process.env.LAUNCH_TOKEN_SECRET || config.jwt.secret;
const LAUNCH_TOKEN_TTL_SECONDS = parseInt(process.env.LAUNCH_TOKEN_TTL_SECONDS || '60', 10);

/**
 * Create a launch token for opening a lab session in a new tab.
 * Includes duplicate launch prevention:
 * - Returns existing token if one was recently created and not consumed
 * - Rate-limits token creation per session
 * 
 * @param {string} ckxSessionId - The CKX session ID
 * @param {string} userId - The user ID
 * @param {string} examSessionId - The Sailor exam session ID
 * @param {object} options - Optional settings
 * @param {boolean} options.allowDuplicate - Allow creating new token even if recent one exists
 * @returns {{ token: string, expiresAt: number, reused?: boolean, rateLimited?: boolean }}
 */
function createLaunchToken(ckxSessionId, userId, examSessionId, options = {}) {
  const now = Date.now();
  const tracker = sessionLaunchTracker.get(ckxSessionId);
  
  // Check for rate limiting and duplicate prevention
  if (tracker && !options.allowDuplicate) {
    const timeSinceLastToken = now - tracker.lastTokenAt;
    
    // If a token was recently created, check if it's still valid
    if (timeSinceLastToken < MIN_TOKEN_INTERVAL_MS && tracker.pendingTokenId) {
      const existingData = launchTokenStore.get(tracker.pendingTokenId);
      
      // Return existing token if still valid and not consumed
      if (existingData && !existingData.consumed && existingData.expiresAt > now) {
        const signature = crypto
          .createHmac('sha256', LAUNCH_TOKEN_SECRET)
          .update(tracker.pendingTokenId)
          .digest('hex');
        
        console.log(`[LaunchToken] Returning existing token for session ${ckxSessionId}`);
        return {
          token: `${tracker.pendingTokenId}.${signature}`,
          expiresAt: existingData.expiresAt,
          expiresIn: Math.floor((existingData.expiresAt - now) / 1000),
          reused: true,
        };
      }
    }
    
    // Rate limit - reject if too soon after last token
    if (timeSinceLastToken < MIN_TOKEN_INTERVAL_MS / 2) {
      console.log(`[LaunchToken] Rate limited for session ${ckxSessionId}`);
      return {
        token: null,
        rateLimited: true,
        retryAfter: Math.ceil((MIN_TOKEN_INTERVAL_MS / 2 - timeSinceLastToken) / 1000),
        error: 'Token request rate limited. Please wait before requesting another.'
      };
    }
  }
  
  const tokenId = crypto.randomBytes(32).toString('hex');
  const expiresAt = now + (LAUNCH_TOKEN_TTL_SECONDS * 1000);
  
  // Store token data
  launchTokenStore.set(tokenId, {
    ckxSessionId,
    userId,
    examSessionId,
    expiresAt,
    consumed: false,
  });
  
  // Track this token for the session
  sessionLaunchTracker.set(ckxSessionId, {
    lastTokenAt: now,
    pendingTokenId: tokenId,
  });
  
  // Sign the token ID to prevent tampering
  const signature = crypto
    .createHmac('sha256', LAUNCH_TOKEN_SECRET)
    .update(tokenId)
    .digest('hex');
  
  const token = `${tokenId}.${signature}`;
  
  return {
    token,
    expiresAt,
    expiresIn: LAUNCH_TOKEN_TTL_SECONDS,
  };
}

/**
 * Validate and consume a launch token.
 * @param {string} token - The launch token
 * @returns {{ valid: boolean, data?: object, error?: string }}
 */
function validateAndConsumeLaunchToken(token) {
  if (!token || typeof token !== 'string') {
    return { valid: false, error: 'Token is required' };
  }
  
  const parts = token.split('.');
  if (parts.length !== 2) {
    return { valid: false, error: 'Invalid token format' };
  }
  
  const [tokenId, signature] = parts;
  
  // Verify signature
  const expectedSignature = crypto
    .createHmac('sha256', LAUNCH_TOKEN_SECRET)
    .update(tokenId)
    .digest('hex');
  
  if (signature !== expectedSignature) {
    return { valid: false, error: 'Invalid token signature' };
  }
  
  // Look up token data
  const data = launchTokenStore.get(tokenId);
  if (!data) {
    return { valid: false, error: 'Token not found or expired' };
  }
  
  // Check expiry
  if (data.expiresAt < Date.now()) {
    launchTokenStore.delete(tokenId);
    return { valid: false, error: 'Token expired' };
  }
  
  // Check if already consumed
  if (data.consumed) {
    return { valid: false, error: 'Token already used' };
  }
  
  // Consume the token (one-time use)
  data.consumed = true;
  
  // Schedule deletion after a grace period (in case of retries)
  setTimeout(() => {
    launchTokenStore.delete(tokenId);
  }, 5000);
  
  return {
    valid: true,
    data: {
      ckxSessionId: data.ckxSessionId,
      userId: data.userId,
      examSessionId: data.examSessionId,
    },
  };
}

/**
 * Validate a launch token without consuming it (for verification only).
 * @param {string} token - The launch token
 * @returns {{ valid: boolean, data?: object, error?: string }}
 */
function peekLaunchToken(token) {
  if (!token || typeof token !== 'string') {
    return { valid: false, error: 'Token is required' };
  }
  
  const parts = token.split('.');
  if (parts.length !== 2) {
    return { valid: false, error: 'Invalid token format' };
  }
  
  const [tokenId, signature] = parts;
  
  // Verify signature
  const expectedSignature = crypto
    .createHmac('sha256', LAUNCH_TOKEN_SECRET)
    .update(tokenId)
    .digest('hex');
  
  if (signature !== expectedSignature) {
    return { valid: false, error: 'Invalid token signature' };
  }
  
  const data = launchTokenStore.get(tokenId);
  if (!data || data.expiresAt < Date.now() || data.consumed) {
    return { valid: false, error: 'Token not valid' };
  }
  
  return {
    valid: true,
    data: {
      ckxSessionId: data.ckxSessionId,
      userId: data.userId,
      examSessionId: data.examSessionId,
    },
  };
}

module.exports = {
  createLaunchToken,
  validateAndConsumeLaunchToken,
  peekLaunchToken,
  LAUNCH_TOKEN_TTL_SECONDS,
};
