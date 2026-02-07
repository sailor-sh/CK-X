/**
 * Auth middleware. Validates JWT and attaches req.user.
 * CKX never validates users; Sailor API does it here.
 */
const jwt = require('jsonwebtoken');
const config = require('../config');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Require valid JWT. Sets req.user (User record).
 * 401 if missing or invalid.
 * Skips validation if req.iframeTokenValid === true (set by validateIframeToken).
 */
async function requireAuth(req, res, next) {
  // If iframe token already validated, skip JWT validation
  if (req.iframeTokenValid === true) {
    return next();
  }

  const auth = req.headers.authorization;
  const token = auth && auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    const user = await prisma.user.findUnique({ where: { id: decoded.sub } });
    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/**
 * Optional auth: set req.user if valid token, else req.user = null.
 */
async function optionalAuth(req, res, next) {
  const auth = req.headers.authorization;
  const token = auth && auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) {
    req.user = null;
    return next();
  }
  try {
    const decoded = jwt.verify(token, config.jwt.secret);
    const user = await prisma.user.findUnique({ where: { id: decoded.sub } });
    req.user = user || null;
  } catch {
    req.user = null;
  }
  next();
}

module.exports = { requireAuth, optionalAuth };
