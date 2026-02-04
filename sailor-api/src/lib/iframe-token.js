/**
 * Iframe access token utilities.
 * Capability tokens scoped to a single ckxSessionId, short-lived, cryptographically signed.
 */
const crypto = require('crypto');
const config = require('../config');

// Use a separate secret for iframe tokens (or fallback to JWT secret)
const IFRAME_TOKEN_SECRET = process.env.IFRAME_TOKEN_SECRET || config.jwt.secret;
const IFRAME_TOKEN_EXPIRY_SECONDS = parseInt(process.env.IFRAME_TOKEN_EXPIRY_SECONDS || '600', 10); // 10 minutes default

/**
 * Sign an iframe token payload.
 * @param {Object} payload - { ckxSessionId, userId, expiresAt, issuedAt }
 * @returns {string} Base64URL-encoded token (header.payload.signature)
 */
function signIframeToken(payload) {
  const header = {
    alg: 'HS256',
    typ: 'IFRAME_TOKEN',
  };

  const encodedHeader = Buffer.from(JSON.stringify(header)).toString('base64url');
  const encodedPayload = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signature = crypto
    .createHmac('sha256', IFRAME_TOKEN_SECRET)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64url');

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

/**
 * Verify and decode an iframe token.
 * @param {string} token - Base64URL-encoded token
 * @returns {Object} { valid: boolean, payload?: Object, error?: string }
 */
function verifyIframeToken(token) {
  if (!token || typeof token !== 'string') {
    return { valid: false, error: 'Token is missing or invalid format' };
  }

  const parts = token.split('.');
  if (parts.length !== 3) {
    return { valid: false, error: 'Token format invalid' };
  }

  const [encodedHeader, encodedPayload, signature] = parts;

  // Verify signature
  const expectedSignature = crypto
    .createHmac('sha256', IFRAME_TOKEN_SECRET)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64url');

  if (signature !== expectedSignature) {
    return { valid: false, error: 'Token signature invalid' };
  }

  // Decode payload
  let payload;
  try {
    const payloadBuffer = Buffer.from(encodedPayload, 'base64url');
    payload = JSON.parse(payloadBuffer.toString('utf8'));
  } catch (err) {
    return { valid: false, error: 'Token payload invalid' };
  }

  // Verify expiry
  const now = Math.floor(Date.now() / 1000);
  if (payload.expiresAt && payload.expiresAt <= now) {
    return { valid: false, error: 'Token expired', payload };
  }

  // Verify required fields
  if (!payload.ckxSessionId || !payload.userId || !payload.expiresAt) {
    return { valid: false, error: 'Token missing required fields', payload };
  }

  return { valid: true, payload };
}

/**
 * Create a new iframe token for a session.
 * @param {string} ckxSessionId - CKX session ID
 * @param {string} userId - User ID
 * @param {number} expiresInSeconds - Optional expiry (defaults to IFRAME_TOKEN_EXPIRY_SECONDS)
 * @returns {string} Signed token
 */
function createIframeToken(ckxSessionId, userId, expiresInSeconds = IFRAME_TOKEN_EXPIRY_SECONDS) {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    ckxSessionId,
    userId,
    expiresAt: now + expiresInSeconds,
    issuedAt: now,
  };

  return signIframeToken(payload);
}

module.exports = {
  signIframeToken,
  verifyIframeToken,
  createIframeToken,
  IFRAME_TOKEN_EXPIRY_SECONDS,
};
