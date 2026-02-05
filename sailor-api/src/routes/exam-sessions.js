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
const { verifyIframeToken } = require('../lib/iframe-token');
const config = require('../config');

const router = express.Router();

/**
 * Shared auth for session-scoped, iframe-safe endpoints.
 * Accepts either JWT (Authorization header) or iframeToken (query) but always enforces:
 * - token signature/expiry
 * - token.ckxSessionId matches session.ckxSessionId
 * - ownership: token.userId === session.userId (or JWT user matches)
 * - session.status is PREPARING or ACTIVE (iframe needs PREPARING for startup)
 */
async function requireSessionAuthAllowIframe(req, res, next) {
  const session = req.examSession;
  if (!session) {
    return res.status(500).json({ error: 'Session not resolved' });
  }
  // Allow iframe/JWT auth when session is being created/prepared/ready/active.
  // This covers the initial start transition and subsequent polling.
  const allowedStatuses = ['CREATED', 'PREPARING', 'READY', 'ACTIVE'];
  const iframeToken = req.query?.iframeToken;

  // iframeToken path
  if (iframeToken) {
    const result = verifyIframeToken(iframeToken);
    if (!result.valid) {
      return res.status(401).json({ error: 'Invalid iframe token', details: result.error });
    }
    const { payload } = result;
    if (payload.ckxSessionId !== session.ckxSessionId) {
      return res.status(401).json({ error: 'Iframe token does not match session' });
    }
    if (payload.userId !== session.userId) {
      return res.status(403).json({ error: 'Not your exam session' });
    }
    if (!allowedStatuses.includes(session.status)) {
      return res.status(401).json({ error: 'Session not available for iframe', status: session.status });
    }
    req.user = { id: payload.userId };
    req.iframeTokenValid = true;
    return next();
  }

  // JWT path
  await requireAuth(req, res, async (err) => {
    if (err) return; // requireAuth already handled response
    if (!req.user || req.user.id !== session.userId) {
      return res.status(403).json({ error: 'Not your exam session' });
    }
    if (!allowedStatuses.includes(session.status)) {
      return res.status(401).json({ error: 'Session not available', status: session.status });
    }
    return next();
  });
}

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

/**
 * Iframe-safe session-scoped endpoints: allow iframeToken or JWT.
 * These must NOT fall through; respond 401/403 on auth failure.
 */
router.get(
  '/:sessionId/current-exam',
  resolveExamSession,
  requireSessionAuthAllowIframe,
  async (req, res) => {
    try {
      const resp = await fetch(`${config.facilitator.baseUrl}/api/v1/exams/current`);
      if (resp.status === 404) {
        return res.status(404).json({ message: 'No current exam is active' });
      }
      if (!resp.ok) {
        return res.status(502).json({ error: 'Upstream facilitator error', status: resp.status });
      }
      const data = await resp.json();
      return res.json(data);
    } catch (err) {
      console.error('current-exam facilitator error:', err.message);
      return res.status(502).json({ error: 'Failed to fetch current exam', message: err.message });
    }
  }
);

router.get(
  '/:sessionId/labs',
  resolveExamSession,
  requireSessionAuthAllowIframe,
  async (req, res) => {
    try {
      const resp = await fetch(`${config.facilitator.baseUrl}/api/v1/assements/`);
      if (!resp.ok) {
        return res.status(502).json({ error: 'Upstream facilitator error', status: resp.status });
      }
      const data = await resp.json();
      return res.json(data);
    } catch (err) {
      console.error('labs facilitator error:', err.message);
      return res.status(502).json({ error: 'Failed to fetch labs', message: err.message });
    }
  }
);

// Shared handler for starting an exam/lab via facilitator (iframe/JWT)
async function startExamHandler(req, res) {
  try {
    const facilitatorUrl = `${config.facilitator.baseUrl}/api/v1/exams/`;
    const resp = await fetch(facilitatorUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(req.body || {}),
    });
    if (!resp.ok) {
      return res.status(resp.status).json({
        error: 'UNAUTHORIZED',
        reason: 'Facilitator start failed',
        status: resp.status,
      });
    }
    const data = await resp.json();
    return res.json(data);
  } catch (err) {
    console.error('start exam facilitator error:', err.message);
    return res.status(502).json({ error: 'Failed to start exam', message: err.message });
  }
}

// POST /exam-sessions/:sessionId/start-exam — iframe/JWT auth via shared middleware
router.post(
  '/:sessionId/start-exam',
  resolveExamSession,
  requireSessionAuthAllowIframe,
  startExamHandler
);

// POST /exam-sessions/:sessionId/start-lab — alias for backwards-compatible CKX calls
router.post(
  '/:sessionId/start-lab',
  resolveExamSession,
  requireSessionAuthAllowIframe,
  startExamHandler
);

router.post(
  '/:sessionId/start',
  resolveExamSession,
  requireSessionAuthAllowIframe,
  startExamHandler
);

// Catch-all facilitator proxy for iframe-scoped requests.
// The fetch monkey-patch (injected by CKX proxy into HTML <head>) rewrites
// /facilitator/api/v1/* URLs to this route at runtime, so ALL facilitator
// endpoints (status, questions, evaluate, terminate, events, metrics, etc.)
// are proxied through Sailor API with iframeToken auth.
router.all(
  '/:sessionId/fproxy/*',
  resolveExamSession,
  requireSessionAuthAllowIframe,
  async (req, res) => {
    try {
      const facilitatorPath = req.params[0];
      // Forward non-auth query params to facilitator
      const query = { ...req.query };
      delete query.iframeToken;
      const qs = new URLSearchParams(query).toString();
      const url = `${config.facilitator.baseUrl}/api/v1/${facilitatorPath}${qs ? '?' + qs : ''}`;

      const fetchOpts = { method: req.method };
      if (['POST', 'PUT', 'PATCH'].includes(req.method) && req.body) {
        fetchOpts.headers = { 'Content-Type': 'application/json' };
        fetchOpts.body = JSON.stringify(req.body);
      }

      const resp = await fetch(url, fetchOpts);
      const contentType = resp.headers.get('content-type') || '';
      if (contentType.includes('json')) {
        const data = await resp.json();
        return res.status(resp.status).json(data);
      }
      const text = await resp.text();
      return res.status(resp.status).send(text);
    } catch (err) {
      console.error('fproxy facilitator error:', err.message);
      return res.status(502).json({ error: 'Facilitator proxy error', message: err.message });
    }
  }
);

module.exports = router;
