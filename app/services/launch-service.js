/**
 * Launch Service - Validates launch tokens from Sailor API and establishes CKX sessions.
 * 
 * This is the entry point for the new-tab lab launch flow:
 * 1. User clicks "Open Lab" in Sailor UI
 * 2. Sailor creates a launch token and returns a URL
 * 3. Browser opens new tab to CKX /launch?token=...
 * 4. This service validates the token with Sailor API
 * 5. Creates a session cookie for subsequent requests
 * 6. Redirects to /exam.html
 * 
 * The session cookie replaces the need for iframeToken on every request.
 */

const crypto = require('crypto');

// Session cookie configuration
const SESSION_COOKIE_NAME = 'ckx_session';
const SESSION_COOKIE_MAX_AGE = 24 * 60 * 60 * 1000; // 24 hours (should match exam duration limits)

// In-memory session store (use Redis in production for multi-instance)
// Map<cookieValue, { sessionId, userId, examSessionId, validatedAt }>
const sessionCookieStore = new Map();

// Cleanup expired sessions periodically
setInterval(() => {
  const now = Date.now();
  const maxAge = SESSION_COOKIE_MAX_AGE;
  for (const [cookieValue, data] of sessionCookieStore) {
    if (now - data.validatedAt > maxAge) {
      sessionCookieStore.delete(cookieValue);
    }
  }
}, 60000); // Every minute

/**
 * Validate a launch token by calling Sailor API.
 * @param {string} token - The launch token from the URL
 * @param {string} sailorApiUrl - Base URL of Sailor API
 * @returns {Promise<{ valid: boolean, data?: object, error?: string }>}
 */
async function validateLaunchTokenWithSailor(token, sailorApiUrl) {
  try {
    const response = await fetch(`${sailorApiUrl}/launch-tokens/validate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token }),
    });
    
    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Unknown error' }));
      return { valid: false, error: error.error || `HTTP ${response.status}` };
    }
    
    const data = await response.json();
    return { valid: true, data };
  } catch (err) {
    console.error('[LaunchService] Failed to validate token with Sailor:', err.message);
    return { valid: false, error: 'Failed to connect to auth service' };
  }
}

/**
 * Create a session cookie value and store the session data.
 * @param {string} sessionId - The CKX session ID
 * @param {string} userId - The user ID
 * @param {string} examSessionId - The Sailor exam session ID
 * @returns {string} The cookie value
 */
function createSessionCookie(sessionId, userId, examSessionId) {
  const cookieValue = crypto.randomBytes(32).toString('hex');
  
  sessionCookieStore.set(cookieValue, {
    sessionId,
    userId,
    examSessionId,
    validatedAt: Date.now(),
  });
  
  return cookieValue;
}

/**
 * Validate a session cookie and return the session data.
 * @param {string} cookieValue - The cookie value
 * @returns {{ valid: boolean, data?: object }}
 */
function validateSessionCookie(cookieValue) {
  if (!cookieValue) {
    return { valid: false };
  }
  
  const data = sessionCookieStore.get(cookieValue);
  if (!data) {
    return { valid: false };
  }
  
  // Check if expired
  if (Date.now() - data.validatedAt > SESSION_COOKIE_MAX_AGE) {
    sessionCookieStore.delete(cookieValue);
    return { valid: false };
  }
  
  return { valid: true, data };
}

/**
 * Invalidate a session cookie (on logout or session end).
 * @param {string} cookieValue - The cookie value
 */
function invalidateSessionCookie(cookieValue) {
  sessionCookieStore.delete(cookieValue);
}

/**
 * Express middleware to validate session from cookie.
 * Sets req.ckxSession if valid.
 */
function requireSessionCookie(req, res, next) {
  const cookieValue = req.cookies?.[SESSION_COOKIE_NAME];
  
  if (!cookieValue) {
    return res.status(401).json({ error: 'Session cookie required' });
  }
  
  const result = validateSessionCookie(cookieValue);
  if (!result.valid) {
    return res.status(401).json({ error: 'Invalid or expired session' });
  }
  
  req.ckxSession = result.data;
  next();
}

/**
 * Optional session middleware - sets req.ckxSession if cookie is valid, but doesn't reject.
 */
function optionalSessionCookie(req, res, next) {
  const cookieValue = req.cookies?.[SESSION_COOKIE_NAME];
  
  if (cookieValue) {
    const result = validateSessionCookie(cookieValue);
    if (result.valid) {
      req.ckxSession = result.data;
    }
  }
  
  next();
}

module.exports = {
  SESSION_COOKIE_NAME,
  SESSION_COOKIE_MAX_AGE,
  validateLaunchTokenWithSailor,
  createSessionCookie,
  validateSessionCookie,
  invalidateSessionCookie,
  requireSessionCookie,
  optionalSessionCookie,
};
