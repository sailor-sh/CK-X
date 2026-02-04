/**
 * ExamSession lifecycle + CKX orchestration. Sailor API creates/revokes CKX sessions.
 */
const express = require('express');
const examSessionService = require('../services/exam-session-service');
const {
  resolveExamSession,
  requireActiveExamSession,
  revokeExamSession,
} = require('../middleware/session-enforcement');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// POST /exam-sessions — create session (enforce entitlement + attempts), create CKX session, return exam URL
router.post('/', requireAuth, async (req, res) => {
  const { examId, mode } = req.body || {};
  if (!examId) {
    return res.status(400).json({ error: 'examId required' });
  }
  try {
    const result = await examSessionService.createExamSession(req.user.id, examId, mode);  console.log(req.body,1)
    return res.status(201).json(result);
  } catch (err) {
    console.log(2)

    if (err.message.includes('entitlement') || err.message.includes('attempts')) {
      return res.status(403).json({ error: err.message });
    }
    if (err.message.includes('not found')) {
      return res.status(404).json({ error: err.message });
    }
    return res.status(500).json({ error: err.message });
  }
});

// GET /exam-sessions — list current user's sessions
router.get('/', requireAuth, async (req, res) => {
  const { PrismaClient } = require('@prisma/client');
  const prisma = new PrismaClient();
  const sessions = await prisma.examSession.findMany({
    where: { userId: req.user.id },
    orderBy: { createdAt: 'desc' },
    include: { exam: { select: { id: true, slug: true, name: true, durationMinutes: true } } },
  });
  return res.json({ sessions });
});

// GET /exam-sessions/:sessionId — get one (by id or ckxSessionId); enforce ownership
router.get('/:sessionId', requireAuth, resolveExamSession, (req, res) => {
  if (req.examSession.userId !== req.user.id) {
    return res.status(403).json({ error: 'Not your exam session' });
  }
  return res.json({
    session: {
      id: req.examSession.id,
      ckxSessionId: req.examSession.ckxSessionId,
      status: req.examSession.status,
      startedAt: req.examSession.startedAt,
      endsAt: req.examSession.endsAt,
      submittedAt: req.examSession.submittedAt,
      exam: req.examSession.exam,
    },
  });
});

// GET /exam-sessions/:sessionId/access — validate access (active + within time). For client to check before loading exam.
router.get('/:sessionId/access', requireAuth, resolveExamSession, requireActiveExamSession, (req, res) => {
  return res.json({
    allowed: true,
    sessionId: req.examSession.ckxSessionId,
    examSessionId: req.examSession.id,
    endsAt: req.examSession.endsAt,
  });
});

// GET /exam-sessions/:sessionId/iframe-token — mint iframe access token for VNC iframe
router.get('/:sessionId/iframe-token', requireAuth, resolveExamSession, requireActiveExamSession, (req, res) => {
  const { createIframeToken, IFRAME_TOKEN_EXPIRY_SECONDS } = require('../lib/iframe-token');
  
  if (!req.examSession.ckxSessionId) {
    return res.status(400).json({ error: 'Session has no CKX session ID' });
  }

  const iframeToken = createIframeToken(
    req.examSession.ckxSessionId,
    req.user.id,
    IFRAME_TOKEN_EXPIRY_SECONDS
  );

  return res.json({
    iframeToken,
    expiresIn: IFRAME_TOKEN_EXPIRY_SECONDS,
    ckxSessionId: req.examSession.ckxSessionId,
  });
});

// POST /exam-sessions/:sessionId/end — end session and release CKX
router.post('/:sessionId/end', requireAuth, async (req, res) => {
  const sessionId = req.params.sessionId;
  const { PrismaClient } = require('@prisma/client');
  const prisma = new PrismaClient();
  const session = await prisma.examSession.findFirst({
    where: { OR: [{ id: sessionId }, { ckxSessionId: sessionId }] },
  });
  if (!session) {
    return res.status(404).json({ error: 'Exam session not found' });
  }
  if (session.userId !== req.user.id) {
    return res.status(403).json({ error: 'Not your exam session' });
  }
  const updated = await examSessionService.endExamSession(session.id, req.user.id);
  // Disposable sessions are deleted and return null.
  return res.json({ session: updated, released: true, deleted: updated === null });
});

// POST /exam-sessions/:sessionId/revoke — admin/backend: revoke access and release CKX
router.post('/:sessionId/revoke', requireAuth, resolveExamSession, async (req, res) => {
  if (req.examSession.userId !== req.user.id) {
    return res.status(403).json({ error: 'Not your exam session' });
  }
  await revokeExamSession(req.examSession.id);
  return res.json({ revoked: true, sessionId: req.examSession.id });
});

module.exports = router;
