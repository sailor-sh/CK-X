/**
 * Session enforcement: ensure ExamSession is active and within time/payment rules.
 * Sailor API revokes access when time or payment expires; CKX never validates.
 * 
 * SECURITY: All ownership checks log violations for audit trail.
 */
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const ckxClient = require('../lib/ckx-client');

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
 * Resolve session from param: sessionId (ExamSession.id) or ckxSessionId (ExamSession.ckxSessionId).
 * Sets req.examSession (ExamSession with exam, user) or 404.
 */
async function resolveExamSession(req, res, next) {
  const sessionId = req.params.sessionId || req.params.examSessionId || req.params.ckxSessionId;
  if (!sessionId) {
    console.error('resolveExamSession: Missing sessionId in params:', Object.keys(req.params), 'URL:', req.url);
    return res.status(400).json({ error: 'sessionId or examSessionId required', debug: { params: req.params, url: req.url } });
  }
  const examSession = await prisma.examSession.findFirst({
    where: {
      OR: [{ id: sessionId }, { ckxSessionId: sessionId }],
    },
    include: { exam: true, user: true },
  });
  if (!examSession) {
    return res.status(404).json({ error: 'Exam session not found' });
  }
  req.examSession = examSession;
  next();
}

/**
 * Enforce: session is ACTIVE and endsAt > now.
 * If expired/revoked: optionally release CKX session and return 403.
 * Must run after resolveExamSession and requireAuth; enforces ownership (req.user.id === session.userId).
 * 
 * SECURITY: This is the PRIMARY ownership enforcement point in Sailor API.
 */
async function requireActiveExamSession(req, res, next) {
  const session = req.examSession;
  
  // CRITICAL: Ownership check - User can ONLY access their own sessions
  if (session.userId !== req.user.id) {
    logSecurityEvent('SESSION_ACCESS_DENIED', {
      reason: 'ownership_mismatch',
      requesterId: req.user.id,
      sessionId: session.id,
      sessionOwnerId: session.userId,
      ckxSessionId: session.ckxSessionId,
      ip: req.ip || req.connection?.remoteAddress,
      userAgent: req.headers['user-agent'],
      path: req.path
    });
    return res.status(403).json({ error: 'Access denied', message: 'You do not own this session' });
  }
  
  if (session.status !== 'ACTIVE') {
    return res.status(410).json({
      error: 'Session not active',
      status: session.status,
    });
  }
  
  const now = new Date();
  if (session.endsAt && session.endsAt <= now) {
    await markSessionExpiredAndReleaseCkx(session);
    return res.status(410).json({
      error: 'Session expired',
      endedAt: session.endsAt,
    });
  }
  next();
}

/**
 * Middleware to check ownership without requiring ACTIVE status.
 * Use for read-only access to session details (e.g., viewing results).
 */
async function requireSessionOwnership(req, res, next) {
  const session = req.examSession;
  
  if (session.userId !== req.user.id) {
    logSecurityEvent('SESSION_ACCESS_DENIED', {
      reason: 'ownership_mismatch',
      requesterId: req.user.id,
      sessionId: session.id,
      sessionOwnerId: session.userId,
      ip: req.ip || req.connection?.remoteAddress,
      path: req.path
    });
    return res.status(403).json({ error: 'Access denied', message: 'You do not own this session' });
  }
  
  next();
}

/**
 * Mark ExamSession as EXPIRED and release CKX session so CKX stops serving it.
 */
async function markSessionExpiredAndReleaseCkx(examSession) {
  await prisma.examSession.update({
    where: { id: examSession.id },
    data: { status: 'EXPIRED' },
  });
  if (examSession.ckxSessionId) {
    try {
      await ckxClient.releaseSession(examSession.ckxSessionId);
    } catch (e) {
      console.error('CKX release on expiry failed:', e.message);
    }
  }

  // Disposable/mock sessions: delete after expiry to avoid persisting results.
  if (examSession.disposable) {
    try {
      await prisma.examSession.delete({ where: { id: examSession.id } });
    } catch (e) {
      console.error('Failed to delete disposable expired session:', e.message);
    }
  }
}

/**
 * Revoke access: set status to REVOKED and release CKX session.
 * Call from admin or when payment/entitlement is revoked.
 */
async function revokeExamSession(examSessionId) {
  const session = await prisma.examSession.findUnique({
    where: { id: examSessionId },
  });
  if (!session || session.status === 'ENDED' || session.status === 'EXPIRED' || session.status === 'REVOKED') {
    return;
  }
  await prisma.examSession.update({
    where: { id: examSessionId },
    data: { status: 'REVOKED' },
  });
  if (session.ckxSessionId) {
    try {
      await ckxClient.releaseSession(session.ckxSessionId);
    } catch (e) {
      console.error('CKX release on revoke failed:', e.message);
    }
  }
}

module.exports = {
  resolveExamSession,
  requireActiveExamSession,
  requireSessionOwnership,
  markSessionExpiredAndReleaseCkx,
  revokeExamSession,
  logSecurityEvent,
};
