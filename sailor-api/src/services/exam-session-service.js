/**
 * ExamSession lifecycle + CKX orchestration.
 * Sailor API creates CKX sessions and revokes access when time/payment expires.
 */
const { PrismaClient } = require('@prisma/client');
const { v4: uuid } = require('uuid');
const ckxClient = require('../lib/ckx-client');
const config = require('../config');

const prisma = new PrismaClient();

const EXAM_MODES = Object.freeze({
  MOCK: 'MOCK',
  FULL: 'FULL',
});

// Default runtime for dev (single shared CKX stack). In production, orchestrator provides per-session endpoints.
function getDefaultRuntime() {
  const base = (process.env.CKX_DEFAULT_VNC_HOST || 'remote-desktop').trim();
  const vncPort = parseInt(process.env.CKX_DEFAULT_VNC_PORT || '6901', 10);
  const sshHost = (process.env.CKX_DEFAULT_SSH_HOST || 'remote-terminal').trim();
  const sshPort = parseInt(process.env.CKX_DEFAULT_SSH_PORT || '22', 10);
  return {
    vnc: {
      host: base,
      port: vncPort,
      password: process.env.CKX_DEFAULT_VNC_PASSWORD || 'bakku-the-wizard',
    },
    ssh: {
      host: sshHost,
      port: sshPort,
      username: process.env.CKX_DEFAULT_SSH_USER || 'candidate',
      password: process.env.CKX_DEFAULT_SSH_PASSWORD || 'password',
    },
  };
}

/**
 * Exam mode rules (server-side; clients cannot override):
 * - MOCK: free, limited time (Exam.mockDurationMinutes), disposable sessions, no persistent results.
 * - FULL: requires payment/entitlement, strict timer (Exam.durationMinutes), persistent results.
 *
 * Prevent bypass:
 * - Sailor computes duration/endsAt from mode; ignores client-provided duration.
 * - FULL requires a product+entitlement; MOCK never grants FULL behavior.
 */
async function canStartExam(userId, examId, mode) {
  const exam = await prisma.exam.findUnique({
    where: { id: examId },
    include: { product: true },
  });
  if (!exam) return { allowed: false, reason: 'Exam not found' };
  const now = new Date();

  if (mode === EXAM_MODES.FULL) {
    const productId = exam.product?.id;
    if (!productId) {
      // Contract: FULL exams require payment.
      return { allowed: false, reason: 'Full exam is not purchasable (no product configured)' };
    }
    const entitlement = await prisma.entitlement.findFirst({
      where: {
        userId,
        productId,
        status: 'ACTIVE',
        validFrom: { lte: now },
        validUntil: { gte: now },
      },
    });
    if (!entitlement) {
      return { allowed: false, reason: 'No valid entitlement for full exam' };
    }
  }

  if (exam.maxAttempts != null) {
    const attempts = await prisma.examSession.count({
      where: {
        userId,
        examId,
        status: { in: ['ACTIVE', 'ENDED', 'EXPIRED', 'REVOKED'] },
        ...(mode === EXAM_MODES.FULL ? { mode: EXAM_MODES.FULL } : {}),
      },
    });
    if (attempts >= exam.maxAttempts) {
      return { allowed: false, reason: 'Max attempts reached' };
    }
  }

  return { allowed: true, exam };
}

function resolveMode(input) {
  const m = (input || '').toString().toUpperCase();
  if (m === EXAM_MODES.MOCK) return EXAM_MODES.MOCK;
  return EXAM_MODES.FULL; // default safe: treat unknown as FULL (more restrictive)
}

function computeEndsAt(exam, mode, startedAt) {
  const minutes = mode === EXAM_MODES.MOCK ? exam.mockDurationMinutes : exam.durationMinutes;
  return new Date(startedAt.getTime() + minutes * 60 * 1000);
}

/**
 * Create ExamSession and CKX session; return exam URL for client.
 */
async function createExamSession(userId, examId, modeInput) {
  const mode = resolveMode(modeInput);
  const check = await canStartExam(userId, examId, mode);
  if (!check.allowed) {
    throw new Error(check.reason || 'Cannot start exam');
  }
  const exam = check.exam;

  const ckxSessionId = uuid();
  const startedAt = new Date();
  const endsAt = computeEndsAt(exam, mode, startedAt);
  const runtime = getDefaultRuntime();

  const examSession = await prisma.examSession.create({
    data: {
      userId,
      examId,
      ckxSessionId,
      mode,
      disposable: mode === EXAM_MODES.MOCK,
      status: 'PROVISIONING',
      startedAt,
      endsAt,
    },
    include: { exam: true },
  });

  try {
    await ckxClient.createSession(ckxSessionId, {
      vnc: runtime.vnc,
      ssh: runtime.ssh,
      state: 'ready',
      expiresAt: endsAt.toISOString(),
    });
  } catch (err) {
    await prisma.examSession.update({
      where: { id: examSession.id },
      data: { status: 'CREATED' },
    });
    throw new Error(`CKX session creation failed: ${err.message}`);
  }

  await prisma.examSession.update({
    where: { id: examSession.id },
    data: { status: 'ACTIVE' },
  });

  const sailorBase = process.env.SAILOR_API_PUBLIC_URL || `http://localhost:${config.port}`;
  const examUrl = `${sailorBase}/exam?sessionId=${encodeURIComponent(ckxSessionId)}&examSessionId=${examSession.id}&examId=${examId}&mode=${encodeURIComponent(mode)}`;

  return {
    examSession: {
      id: examSession.id,
      ckxSessionId,
      status: 'ACTIVE',
      mode,
      disposable: mode === EXAM_MODES.MOCK,
      startedAt,
      endsAt,
      exam: examSession.exam,
    },
    examUrl,
    ckxSessionId,
  };
}

/**
 * End session: mark ENDED and release CKX.
 */
async function endExamSession(examSessionId, userId) {
  const session = await prisma.examSession.findFirst({
    where: { id: examSessionId, userId },
  });
  if (!session) return null;
  if (session.status !== 'ACTIVE') return session;

  await prisma.examSession.update({
    where: { id: examSessionId },
    data: { status: 'ENDED', submittedAt: new Date() },
  });
  if (session.ckxSessionId) {
    try {
      await ckxClient.releaseSession(session.ckxSessionId);
    } catch (e) {
      console.error('CKX release on end failed:', e.message);
    }
  }

  // Disposable sessions: remove record after release (keeps lifecycle clean; results are not persisted).
  if (session.disposable) {
    await prisma.examSession.delete({ where: { id: examSessionId } });
    return null;
  }

  return prisma.examSession.findUnique({
    where: { id: examSessionId },
    include: { exam: true },
  });
}

module.exports = {
  canStartExam,
  createExamSession,
  endExamSession,
  getDefaultRuntime,
  EXAM_MODES,
};
