/**
 * ExamSession lifecycle + CKX orchestration.
 * Sailor API creates CKX sessions and revokes access when time/payment expires.
 *
 * Multi-Session Isolation:
 * - Each session gets unique credentials
 * - Each session gets isolated VNC/terminal containers
 * - Concurrent session limits enforced per user
 * - Idempotent session creation (prevents duplicates)
 * - Session ownership strictly enforced
 */
const { PrismaClient } = require('@prisma/client');
const { v4: uuid } = require('uuid');
const crypto = require('crypto');
const ckxClient = require('../lib/ckx-client');
const config = require('../config');
const containerOrchestrator = require('./container-orchestrator');

const prisma = new PrismaClient();

const EXAM_MODES = Object.freeze({
  MOCK: 'MOCK',
  FULL: 'FULL',
});

// Maximum concurrent active sessions per user (configurable)
const MAX_CONCURRENT_SESSIONS = parseInt(process.env.MAX_CONCURRENT_SESSIONS || '3', 10);

// Idempotency window (seconds) - duplicate requests within this window return existing session
const IDEMPOTENCY_WINDOW_SECONDS = 30;

// In-memory idempotency store (should be Redis in production)
const idempotencyStore = new Map();

/**
 * Generate unique, session-specific credentials
 * Each session gets its own credentials to ensure isolation
 */
function generateSessionCredentials(sessionId) {
  const shortId = sessionId.slice(0, 8);
  return {
    vnc: {
      password: crypto.randomBytes(16).toString('hex'),
    },
    ssh: {
      username: `user-${shortId}`,
      password: crypto.randomBytes(16).toString('hex'),
    },
    kubernetes: {
      namespace: `exam-${shortId}`,
      serviceAccount: `sa-${shortId}`,
    }
  };
}

// Isolation modes:
// - 'container': Per-session Docker containers (production) - full isolation
// - 'shared': Single shared containers (dev/fallback) - no isolation
const ISOLATION_MODE = process.env.CKX_ISOLATION_MODE || 'container';

// Cache Docker availability check (re-check every 60 seconds to handle Docker restarts)
let dockerAvailable = null;
let dockerAvailableCheckedAt = 0;
const DOCKER_CHECK_INTERVAL_MS = 60 * 1000;

async function isDockerAvailable() {
  const now = Date.now();
  // Re-check if never checked, or if check is stale, or if last check failed (retry on failure)
  if (dockerAvailable === null || (now - dockerAvailableCheckedAt > DOCKER_CHECK_INTERVAL_MS) || dockerAvailable === false) {
    dockerAvailable = await containerOrchestrator.checkDockerAvailable();
    dockerAvailableCheckedAt = now;
    console.log(`[ExamSession] Docker available: ${dockerAvailable}, isolation mode: ${ISOLATION_MODE}`);
  }
  return dockerAvailable;
}

// Default runtime for dev (single shared CKX stack). In production, orchestrator provides per-session endpoints.
function getDefaultRuntime(sessionCredentials = null) {
  const base = (process.env.CKX_DEFAULT_VNC_HOST || 'remote-desktop').trim();
  const vncPort = parseInt(process.env.CKX_DEFAULT_VNC_PORT || '6901', 10);
  const sshHost = (process.env.CKX_DEFAULT_SSH_HOST || 'remote-terminal').trim();
  const sshPort = parseInt(process.env.CKX_DEFAULT_SSH_PORT || '22', 10);

  // Use session-specific credentials if provided, else fall back to defaults
  return {
    vnc: {
      host: base,
      port: vncPort,
      password: sessionCredentials?.vnc?.password || process.env.CKX_DEFAULT_VNC_PASSWORD || 'bakku-the-wizard',
    },
    ssh: {
      host: sshHost,
      port: sshPort,
      username: sessionCredentials?.ssh?.username || process.env.CKX_DEFAULT_SSH_USER || 'candidate',
      password: sessionCredentials?.ssh?.password || process.env.CKX_DEFAULT_SSH_PASSWORD || 'password',
    },
    kubernetes: sessionCredentials?.kubernetes || null,
  };
}

/**
 * Get runtime configuration for a session.
 * In 'container' mode with Docker available: provisions per-session containers
 * Otherwise: falls back to shared containers
 */
async function getSessionRuntime(sessionId, sessionCredentials) {
  const useContainerIsolation = ISOLATION_MODE === 'container' && await isDockerAvailable();

  if (useContainerIsolation) {
    console.log(`[ExamSession] Provisioning isolated containers for session ${sessionId.slice(0, 8)}`);
    try {
      const runtime = await containerOrchestrator.provisionSessionContainers(sessionId, sessionCredentials);
      return {
        ...runtime,
        kubernetes: sessionCredentials?.kubernetes || null,
        isolated: true,
      };
    } catch (err) {
      console.error(`[ExamSession] Container provisioning failed, falling back to shared:`, err.message);
      // Fall through to shared runtime
    }
  }

  console.log(`[ExamSession] Using shared containers for session ${sessionId.slice(0, 8)}`);
  return {
    ...getDefaultRuntime(sessionCredentials),
    isolated: false,
  };
}

/**
 * Generate an idempotency key for session creation
 */
function generateIdempotencyKey(userId, examId, mode) {
  return `session:${userId}:${examId}:${mode}`;
}

/**
 * Check if there's a recent idempotent request
 */
function getIdempotentSession(key) {
  const entry = idempotencyStore.get(key);
  if (!entry) return null;
  
  const now = Date.now();
  if (now - entry.timestamp > IDEMPOTENCY_WINDOW_SECONDS * 1000) {
    idempotencyStore.delete(key);
    return null;
  }
  
  return entry.sessionId;
}

/**
 * Store idempotency entry
 */
function setIdempotencyEntry(key, sessionId) {
  idempotencyStore.set(key, {
    sessionId,
    timestamp: Date.now(),
  });
  
  // Cleanup old entries periodically
  if (idempotencyStore.size > 1000) {
    const now = Date.now();
    for (const [k, v] of idempotencyStore) {
      if (now - v.timestamp > IDEMPOTENCY_WINDOW_SECONDS * 1000) {
        idempotencyStore.delete(k);
      }
    }
  }
}

/**
 * Count user's active sessions
 * Valid ExamSessionStatus: CREATED, PROVISIONING, ACTIVE, ENDED, EXPIRED, REVOKED
 */
async function countActiveSessions(userId) {
  return prisma.examSession.count({
    where: {
      userId,
      status: { in: ['ACTIVE', 'PROVISIONING'] },
    },
  });
}

/**
 * Find existing active session for same exam (for idempotent reconnect)
 * Valid ExamSessionStatus: CREATED, PROVISIONING, ACTIVE, ENDED, EXPIRED, REVOKED
 */
async function findExistingActiveSession(userId, examId) {
  return prisma.examSession.findFirst({
    where: {
      userId,
      examId,
      status: { in: ['ACTIVE', 'PROVISIONING'] },
      endsAt: { gt: new Date() },
    },
    include: { exam: true },
  });
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
 * 
 * Multi-Session Isolation Features:
 * 1. Idempotent: Returns existing active session if one exists
 * 2. Concurrent limit: Enforces max active sessions per user
 * 3. Unique credentials: Each session gets its own credentials
 * 4. Ownership: Session is bound to userId at creation
 */
async function createExamSession(userId, examId, modeInput, options = {}) {
  const mode = resolveMode(modeInput);
  const idempotencyKey = generateIdempotencyKey(userId, examId, mode);

  // 1. Check idempotency - return existing session if created recently
  // Valid ExamSessionStatus: CREATED, PROVISIONING, ACTIVE, ENDED, EXPIRED, REVOKED
  const existingIdempotentSessionId = getIdempotentSession(idempotencyKey);
  if (existingIdempotentSessionId && !options.forceNew) {
    console.log(`[ExamSession] Idempotent hit for user ${userId}, returning existing session`);
    const existingSession = await prisma.examSession.findUnique({
      where: { id: existingIdempotentSessionId },
      include: { exam: true },
    });
    if (existingSession && ['ACTIVE', 'PROVISIONING'].includes(existingSession.status)) {
      return formatSessionResponse(existingSession);
    }
  }

  // 2. Check for existing active session for same exam (reconnect scenario)
  if (!options.forceNew) {
    const existingActive = await findExistingActiveSession(userId, examId);
    if (existingActive) {
      console.log(`[ExamSession] Found existing active session for user ${userId}, exam ${examId}`);
      return formatSessionResponse(existingActive);
    }
  }

  // 3. Check concurrent session limit
  const activeCount = await countActiveSessions(userId);
  if (activeCount >= MAX_CONCURRENT_SESSIONS) {
    throw new Error(`Maximum concurrent sessions (${MAX_CONCURRENT_SESSIONS}) reached. Please end an existing session first.`);
  }

  // 4. Check entitlement and attempts
  const check = await canStartExam(userId, examId, mode);
  if (!check.allowed) {
    throw new Error(check.reason || 'Cannot start exam');
  }
  const exam = check.exam;

  // 5. Generate unique session ID and credentials
  const ckxSessionId = uuid();
  const sessionCredentials = generateSessionCredentials(ckxSessionId);
  const startedAt = new Date();
  const endsAt = computeEndsAt(exam, mode, startedAt);
  
  // 6. Get runtime config — provisions per-session containers when Docker is available
  const runtime = await getSessionRuntime(ckxSessionId, sessionCredentials);
  console.log(`[ExamSession] Runtime for ${ckxSessionId.slice(0, 8)}: vnc=${runtime.vnc?.host}:${runtime.vnc?.port}, ssh=${runtime.ssh?.host}, isolated=${runtime.isolated}`);

  // 7. Create exam session in database
  // Note: Session credentials are stored in CKX registry, not in Sailor DB
  // This keeps credentials isolated per runtime and reduces DB storage
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

  // Store idempotency entry
  setIdempotencyEntry(idempotencyKey, examSession.id);

  // 8. Create CKX session with ownership binding
  try {
    console.log(`[ExamSession] Registering session ${ckxSessionId.slice(0, 8)} with CKX at ${require('../config').ckx.baseUrl}`);
    console.log(`[ExamSession] VNC: ${runtime.vnc?.host}:${runtime.vnc?.port}, SSH: ${runtime.ssh?.host}:${runtime.ssh?.port}`);

    const ckxResponse = await ckxClient.createSession(ckxSessionId, {
      vnc: runtime.vnc,
      ssh: runtime.ssh,
      kubernetes: runtime.kubernetes,
      state: 'ready',
      ownerId: userId, // Bind session to user
      examSessionId: examSession.id,
      expiresAt: endsAt.toISOString(),
    });
    console.log(`[ExamSession] CKX registration successful:`, ckxResponse);
  } catch (err) {
    console.error(`[ExamSession] CKX registration FAILED for ${ckxSessionId.slice(0, 8)}:`, err.message);
    // 9. Cleanup on CKX failure — also tear down any containers we provisioned
    await prisma.examSession.update({
      where: { id: examSession.id },
      data: { status: 'CREATED' },
    });
    try { await containerOrchestrator.cleanupSessionContainers(ckxSessionId); } catch (cleanupErr) {
      console.error('[ExamSession] Container cleanup after CKX failure:', cleanupErr.message);
    }
    throw new Error(`CKX session creation failed: ${err.message}`);
  }

  // 10. Mark session as active
  await prisma.examSession.update({
    where: { id: examSession.id },
    data: { status: 'ACTIVE' },
  });

  return formatSessionResponse({ ...examSession, status: 'ACTIVE' });
}

/**
 * Format session response consistently
 */
function formatSessionResponse(session) {
  const sailorBase = process.env.SAILOR_API_PUBLIC_URL || `http://localhost:${config.port}`;
  const examUrl = `${sailorBase}/exam?sessionId=${encodeURIComponent(session.ckxSessionId)}&examSessionId=${session.id}&examId=${session.examId}&mode=${encodeURIComponent(session.mode)}`;

  return {
    examSession: {
      id: session.id,
      ckxSessionId: session.ckxSessionId,
      status: session.status,
      mode: session.mode,
      disposable: session.disposable,
      startedAt: session.startedAt,
      endsAt: session.endsAt,
      exam: session.exam,
    },
    examUrl,
    ckxSessionId: session.ckxSessionId,
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
    // Release CKX session
    try {
      await ckxClient.releaseSession(session.ckxSessionId);
    } catch (e) {
      console.error('CKX release on end failed:', e.message);
    }
    // Cleanup per-session containers (idempotent, no-op if shared mode)
    try {
      await containerOrchestrator.cleanupSessionContainers(session.ckxSessionId);
    } catch (e) {
      console.error('Container cleanup on end failed:', e.message);
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

/**
 * Cleanup stale sessions that got stuck in transient states.
 * Called periodically to handle partial failures:
 * - PROVISIONING sessions older than 5 minutes → mark REVOKED (no FAILED status in schema)
 * - CREATED sessions older than 10 minutes → mark REVOKED
 * - ACTIVE sessions past endsAt → mark EXPIRED
 * - Try to release CKX sessions for revoked/expired sessions
 * 
 * Valid ExamSessionStatus: CREATED, PROVISIONING, ACTIVE, ENDED, EXPIRED, REVOKED
 */
async function cleanupStaleSessions() {
  const now = new Date();
  const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);
  const tenMinutesAgo = new Date(now.getTime() - 10 * 60 * 1000);
  
  let cleanedCount = 0;
  
  // 1. PROVISIONING sessions stuck too long → REVOKED
  const stuckProvisioning = await prisma.examSession.findMany({
    where: {
      status: 'PROVISIONING',
      createdAt: { lt: fiveMinutesAgo },
    },
  });
  
  for (const session of stuckProvisioning) {
    console.log(`[Cleanup] Marking stuck PROVISIONING session ${session.id} as REVOKED`);
    await prisma.examSession.update({
      where: { id: session.id },
      data: { status: 'REVOKED' },
    });
    
    if (session.ckxSessionId) {
      try { await ckxClient.releaseSession(session.ckxSessionId); } catch (e) {
        console.error(`[Cleanup] Failed to release CKX session ${session.ckxSessionId}:`, e.message);
      }
      try { await containerOrchestrator.cleanupSessionContainers(session.ckxSessionId); } catch (e) {
        console.error(`[Cleanup] Failed to cleanup containers for ${session.ckxSessionId}:`, e.message);
      }
    }
    cleanedCount++;
  }
  
  // 2. CREATED sessions stuck too long (never started) → REVOKED
  const stuckCreated = await prisma.examSession.findMany({
    where: {
      status: 'CREATED',
      createdAt: { lt: tenMinutesAgo },
    },
  });
  
  for (const session of stuckCreated) {
    console.log(`[Cleanup] Marking stuck CREATED session ${session.id} as REVOKED`);
    await prisma.examSession.update({
      where: { id: session.id },
      data: { status: 'REVOKED' },
    });
    
    if (session.ckxSessionId) {
      try { await ckxClient.releaseSession(session.ckxSessionId); } catch (e) {
        console.error(`[Cleanup] Failed to release CKX session ${session.ckxSessionId}:`, e.message);
      }
      try { await containerOrchestrator.cleanupSessionContainers(session.ckxSessionId); } catch (e) {
        console.error(`[Cleanup] Failed to cleanup containers for ${session.ckxSessionId}:`, e.message);
      }
    }
    cleanedCount++;
  }
  
  // 3. ACTIVE sessions past their end time → EXPIRED
  const expiredSessions = await prisma.examSession.findMany({
    where: {
      status: 'ACTIVE',
      endsAt: { lt: now },
    },
  });
  
  for (const session of expiredSessions) {
    console.log(`[Cleanup] Marking expired session ${session.id} as EXPIRED`);
    await prisma.examSession.update({
      where: { id: session.id },
      data: { status: 'EXPIRED' },
    });
    
    if (session.ckxSessionId) {
      try { await ckxClient.releaseSession(session.ckxSessionId); } catch (e) {
        console.error(`[Cleanup] Failed to release CKX session ${session.ckxSessionId}:`, e.message);
      }
      try { await containerOrchestrator.cleanupSessionContainers(session.ckxSessionId); } catch (e) {
        console.error(`[Cleanup] Failed to cleanup containers for ${session.ckxSessionId}:`, e.message);
      }
    }
    
    // Delete disposable expired sessions
    if (session.disposable) {
      await prisma.examSession.delete({ where: { id: session.id } });
    }
    cleanedCount++;
  }
  
  // 4. Cleanup orphaned containers (containers without active sessions)
  try {
    const activeSessions = await prisma.examSession.findMany({
      where: { status: { in: ['ACTIVE', 'PROVISIONING'] } },
      select: { ckxSessionId: true },
    });
    const activeIds = activeSessions.map(s => s.ckxSessionId).filter(Boolean);
    const orphanCount = await containerOrchestrator.cleanupOrphanedContainers(activeIds);
    if (orphanCount > 0) {
      console.log(`[Cleanup] Removed ${orphanCount} orphaned containers`);
    }
  } catch (e) {
    console.error('[Cleanup] Orphaned container cleanup failed:', e.message);
  }

  if (cleanedCount > 0) {
    console.log(`[Cleanup] Cleaned up ${cleanedCount} stale sessions`);
  }
  
  return cleanedCount;
}

/**
 * Force cleanup a specific session (admin/recovery use)
 * Valid ExamSessionStatus: CREATED, PROVISIONING, ACTIVE, ENDED, EXPIRED, REVOKED
 */
async function forceCleanupSession(sessionId) {
  const session = await prisma.examSession.findUnique({
    where: { id: sessionId },
  });
  
  if (!session) {
    return { success: false, error: 'Session not found' };
  }
  
  // Release CKX + cleanup containers
  if (session.ckxSessionId) {
    try { await ckxClient.releaseSession(session.ckxSessionId); } catch (e) {
      console.error(`[ForceCleanup] Failed to release CKX session:`, e.message);
    }
    try { await containerOrchestrator.cleanupSessionContainers(session.ckxSessionId); } catch (e) {
      console.error(`[ForceCleanup] Failed to cleanup containers:`, e.message);
    }
  }
  
  // Delete or mark as revoked based on status
  if (session.disposable) {
    await prisma.examSession.delete({ where: { id: sessionId } });
    return { success: true, action: 'deleted' };
  } else {
    await prisma.examSession.update({
      where: { id: sessionId },
      data: { status: 'REVOKED' },
    });
    return { success: true, action: 'marked_revoked' };
  }
}

// Start periodic cleanup (every 2 minutes)
let cleanupInterval = null;
function startPeriodicCleanup() {
  if (cleanupInterval) return;
  
  cleanupInterval = setInterval(() => {
    cleanupStaleSessions().catch(err => {
      console.error('[Cleanup] Periodic cleanup failed:', err.message);
    });
  }, 2 * 60 * 1000);
  
  console.log('[Cleanup] Periodic session cleanup started');
}

function stopPeriodicCleanup() {
  if (cleanupInterval) {
    clearInterval(cleanupInterval);
    cleanupInterval = null;
    console.log('[Cleanup] Periodic session cleanup stopped');
  }
}

// Auto-start cleanup when module loads
startPeriodicCleanup();

module.exports = {
  canStartExam,
  createExamSession,
  endExamSession,
  getDefaultRuntime,
  countActiveSessions,
  findExistingActiveSession,
  generateSessionCredentials,
  cleanupStaleSessions,
  forceCleanupSession,
  startPeriodicCleanup,
  stopPeriodicCleanup,
  EXAM_MODES,
  MAX_CONCURRENT_SESSIONS,
};
