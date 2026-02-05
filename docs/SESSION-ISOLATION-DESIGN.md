# Session Isolation Design

## Overview

This document defines the **strong isolation model** for exam sessions in the CK-X platform. The goal is to make it **impossible by design** for User A to access User B's exam session, runtime, or any associated resources.

## 1. Data Model

### 1.1 Core Entities

```
┌─────────────────────────────────────────────────────────────────┐
│                         SAILOR API                              │
├─────────────────────────────────────────────────────────────────┤
│  User                                                           │
│  ├── id: UUID (immutable)                                       │
│  ├── email: string                                              │
│  └── passwordHash: string                                       │
│                                                                 │
│  ExamSession                                                    │
│  ├── id: UUID (immutable)                                       │
│  ├── userId: UUID (immutable, FK → User) ← OWNERSHIP            │
│  ├── examId: UUID (FK → Exam)                                   │
│  ├── ckxSessionId: UUID (unique, immutable once set)            │
│  ├── status: CREATED|PROVISIONING|ACTIVE|ENDED|EXPIRED|REVOKED  │
│  ├── startedAt: timestamp                                       │
│  ├── endsAt: timestamp                                          │
│  └── mode: MOCK|FULL                                            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                           CKX RUNTIME                           │
├─────────────────────────────────────────────────────────────────┤
│  SessionRecord (in SessionRegistry)                             │
│  ├── sessionId: string (matches ExamSession.ckxSessionId)       │
│  ├── ownerId: string (matches User.id) ← OWNERSHIP MIRROR       │
│  ├── examSessionId: string (matches ExamSession.id)             │
│  ├── state: ready|ended|expired                                 │
│  ├── vnc: { host, port, password }                              │
│  ├── ssh: { host, port, username, password }                    │
│  ├── kubernetes: { namespace, serviceAccount }                  │
│  ├── expiresAt: ISO timestamp                                   │
│  └── createdAt: timestamp                                       │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Ownership Rules

| Rule | Description |
|------|-------------|
| **O1** | `ExamSession.userId` is set at creation and NEVER changes |
| **O2** | `SessionRecord.ownerId` MUST equal `ExamSession.userId` |
| **O3** | Only the owner can: start, resume, access VNC, access SSH, call APIs |
| **O4** | Ownership cannot be transferred, delegated, or shared |

### 1.3 Credential Isolation

Each session gets **unique, randomly generated credentials**:

```javascript
// Generated at session creation time
{
  vnc: {
    password: crypto.randomBytes(16).toString('hex')  // e.g., "a3f8c9d2..."
  },
  ssh: {
    username: `user-${sessionId.slice(0,8)}`,         // e.g., "user-5b09e1c7"
    password: crypto.randomBytes(16).toString('hex')
  },
  kubernetes: {
    namespace: `exam-${sessionId.slice(0,8)}`,        // e.g., "exam-5b09e1c7"
    serviceAccount: `sa-${sessionId.slice(0,8)}`
  }
}
```

**Why this matters:**
- Even if User B guesses User A's sessionId, they don't have the credentials
- Each VNC/SSH connection requires session-specific credentials
- Kubernetes namespace isolation prevents container cross-access

---

## 2. Ownership Boundaries

### 2.1 Trust Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRUST BOUNDARY DIAGRAM                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  SAILOR API (Trusted - Owns Auth & Authorization)       │   │
│  │  • Validates JWT tokens                                  │   │
│  │  • Checks session ownership                              │   │
│  │  • Issues short-lived launch tokens                      │   │
│  │  • Controls session lifecycle                            │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                           │                                     │
│                           │ Launch Token (60s TTL, one-time)    │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  CKX RUNTIME (Semi-Trusted - Stateless Router)          │   │
│  │  • Validates launch tokens with Sailor API              │   │
│  │  • Routes requests to session-specific resources        │   │
│  │  • Does NOT authenticate users directly                 │   │
│  │  • Does NOT make authorization decisions                │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                           │                                     │
│                           │ Session-specific credentials        │
│                           ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  RUNTIME RESOURCES (Untrusted - Isolated per Session)   │   │
│  │  • VNC server (per-session password)                    │   │
│  │  • SSH terminal (per-session user/pass)                 │   │
│  │  • Kubernetes namespace (per-session)                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 What Each Layer Knows

| Layer | Knows | Does NOT Know |
|-------|-------|---------------|
| **Sailor API** | User identity, all sessions, entitlements, payments | Runtime internals |
| **CKX Runtime** | Session → runtime mapping, credentials | User passwords, payment status |
| **VNC/SSH/K8s** | Connection credentials | User identity, session ownership |

---

## 3. Backend Enforcement Strategy

### 3.1 Sailor API Middleware Stack

```
Request → [JWT Auth] → [Session Resolution] → [Ownership Check] → Handler
              │               │                      │
              ▼               ▼                      ▼
         401 if invalid  404 if not found     403 if not owner
```

**Implementation:**

```javascript
// middleware/session-enforcement.js

async function resolveExamSession(req, res, next) {
  const sessionId = req.params.sessionId;
  const session = await prisma.examSession.findFirst({
    where: { OR: [{ id: sessionId }, { ckxSessionId: sessionId }] }
  });
  
  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }
  
  req.examSession = session;
  next();
}

async function requireOwnership(req, res, next) {
  // CRITICAL: This is the ownership enforcement
  if (req.examSession.userId !== req.user.id) {
    // Log security event
    console.warn(`[SECURITY] User ${req.user.id} attempted to access session ${req.examSession.id} owned by ${req.examSession.userId}`);
    return res.status(403).json({ 
      error: 'Access denied',
      message: 'You do not own this session'
    });
  }
  next();
}

async function requireActiveSession(req, res, next) {
  const validStatuses = ['ACTIVE', 'PROVISIONING'];
  if (!validStatuses.includes(req.examSession.status)) {
    return res.status(410).json({
      error: 'Session not active',
      status: req.examSession.status
    });
  }
  
  // Check expiry
  if (req.examSession.endsAt && new Date() > req.examSession.endsAt) {
    return res.status(410).json({ error: 'Session expired' });
  }
  
  next();
}
```

### 3.2 CKX Runtime Middleware Stack

```
Request → [Session Cookie Check] → [Session Registry Lookup] → [Ownership Verify] → Handler
                 │                          │                         │
                 ▼                          ▼                         ▼
            401 if missing            404 if not found          403 if mismatch
```

**Implementation:**

```javascript
// middleware/session-resolver.js

function requireOwnedSession(sessionRegistry) {
  return (req, res, next) => {
    const sessionId = req.params.sessionId;
    
    // 1. Session must exist
    const session = sessionRegistry.get(sessionId);
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }
    
    // 2. Session must be routable
    if (!sessionRegistry.isRoutable(sessionId)) {
      return res.status(410).json({ error: 'Session not available' });
    }
    
    // 3. Extract owner from session cookie
    const ownerId = extractOwnerFromCookie(req);
    
    // 4. CRITICAL: Verify ownership
    if (session.ownerId && ownerId !== session.ownerId) {
      console.warn(`[SECURITY] Owner mismatch: cookie=${ownerId}, session=${session.ownerId}`);
      return res.status(403).json({ error: 'Session access denied' });
    }
    
    req.sessionId = sessionId;
    req.session = session;
    req.ownerId = ownerId;
    next();
  };
}
```

### 3.3 Launch Token Flow (Secure Handoff)

```
┌──────────────┐    1. Request launch token    ┌──────────────┐
│              │ ─────────────────────────────▶│              │
│    Sailor    │                               │  Sailor API  │
│    Client    │    2. Launch token + URL      │              │
│              │ ◀─────────────────────────────│              │
└──────────────┘                               └──────────────┘
       │                                              │
       │ 3. Open new tab with token                   │
       ▼                                              │
┌──────────────┐    4. Validate token          ┌──────────────┐
│              │ ─────────────────────────────▶│              │
│     CKX      │                               │  Sailor API  │
│   Runtime    │    5. Token data (consumed)   │              │
│              │ ◀─────────────────────────────│              │
└──────────────┘                               └──────────────┘
       │
       │ 6. Set session cookie, redirect to /exam.html
       ▼
┌──────────────┐
│   Lab UI     │
│  (VNC/SSH)   │
└──────────────┘
```

**Token Properties:**
- **TTL:** 60 seconds (just enough for browser redirect)
- **One-time use:** Consumed on first validation
- **Bound to:** sessionId + userId + examSessionId
- **Signed:** HMAC-SHA256 prevents tampering

---

## 4. Runtime Attachment Rules

### 4.1 Start vs Resume Decision Matrix

| Current State | User Action | Allowed? | Result |
|---------------|-------------|----------|--------|
| No session exists | Start new | ✅ Yes | Create new session |
| ACTIVE session exists | Start new | ❌ No | Return existing session (idempotent) |
| ACTIVE session exists | Resume | ✅ Yes | Attach to existing runtime |
| ENDED session exists | Resume | ❌ No | 410 Gone |
| EXPIRED session exists | Resume | ❌ No | 410 Gone |
| Other user's session | Any action | ❌ No | 403 Forbidden |

### 4.2 Attach Permission Matrix

| Requester | Session Owner | Session Status | VNC Access | SSH Access | API Access |
|-----------|---------------|----------------|------------|------------|------------|
| User A | User A | ACTIVE | ✅ | ✅ | ✅ |
| User A | User A | ENDED | ❌ | ❌ | ❌ (read-only results) |
| User A | User B | Any | ❌ | ❌ | ❌ |
| Anonymous | Any | Any | ❌ | ❌ | ❌ |

### 4.3 Enforcement Points

```
┌────────────────────────────────────────────────────────────────────┐
│                     ACCESS CONTROL CHECKPOINTS                     │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  1. SESSION CREATION (Sailor API)                                  │
│     ├── Check: User authenticated (JWT)                            │
│     ├── Check: User has entitlement for exam                       │
│     ├── Check: User doesn't exceed concurrent session limit        │
│     └── Action: Set userId as owner (immutable)                    │
│                                                                    │
│  2. LAUNCH TOKEN REQUEST (Sailor API)                              │
│     ├── Check: User authenticated (JWT)                            │
│     ├── Check: User owns the session (userId match)                │
│     ├── Check: Session is ACTIVE                                   │
│     └── Action: Issue one-time launch token                        │
│                                                                    │
│  3. LAUNCH HANDOFF (CKX Runtime)                                   │
│     ├── Check: Token is valid (signature, expiry)                  │
│     ├── Check: Token not already consumed                          │
│     ├── Check: Session exists in registry                          │
│     └── Action: Set session cookie, consume token                  │
│                                                                    │
│  4. VNC/SSH ACCESS (CKX Runtime)                                   │
│     ├── Check: Session cookie valid                                │
│     ├── Check: Session exists and routable                         │
│     ├── Check: Cookie owner matches session owner                  │
│     └── Action: Proxy to session-specific VNC/SSH                  │
│                                                                    │
│  5. API CALLS (CKX → Facilitator)                                  │
│     ├── Check: Session cookie valid                                │
│     ├── Check: Session exists                                      │
│     └── Action: Proxy request with session context                 │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## 5. Failure Behavior

### 5.1 HTTP Status Codes

| Scenario | Status Code | Response Body |
|----------|-------------|---------------|
| No authentication | 401 Unauthorized | `{ error: "Authentication required" }` |
| Invalid token | 401 Unauthorized | `{ error: "Invalid or expired token" }` |
| Session not found | 404 Not Found | `{ error: "Session not found" }` |
| Not session owner | **403 Forbidden** | `{ error: "Access denied" }` |
| Session ended/expired | 410 Gone | `{ error: "Session not available", status: "ENDED" }` |
| Rate limited | 429 Too Many Requests | `{ error: "Rate limited", retryAfter: 5 }` |
| Server error | 500 Internal Server Error | `{ error: "Internal error" }` |

### 5.2 Security Event Logging

All access denials MUST be logged with:

```javascript
{
  timestamp: "2026-02-05T16:30:00Z",
  event: "SESSION_ACCESS_DENIED",
  requesterId: "user-A-id",
  sessionId: "session-123",
  sessionOwnerId: "user-B-id",
  reason: "ownership_mismatch",
  ip: "192.168.1.100",
  userAgent: "Mozilla/5.0..."
}
```

### 5.3 UI Response Guidelines

| Error | UI Action |
|-------|-----------|
| 401 | Redirect to login |
| 403 | Show "Access Denied" modal, redirect to dashboard |
| 404 | Show "Session not found", redirect to dashboard |
| 410 | Show "Session expired", offer to start new session |
| 429 | Show "Please wait", auto-retry after delay |

---

## 6. Concurrent Session Prevention

### 6.1 Per-User Limits

```javascript
const MAX_CONCURRENT_SESSIONS = 3; // Configurable

async function checkConcurrentLimit(userId) {
  const activeCount = await prisma.examSession.count({
    where: {
      userId,
      status: { in: ['ACTIVE', 'PROVISIONING'] }
    }
  });
  
  if (activeCount >= MAX_CONCURRENT_SESSIONS) {
    throw new Error(`Maximum concurrent sessions (${MAX_CONCURRENT_SESSIONS}) reached`);
  }
}
```

### 6.2 Duplicate Prevention

```javascript
// Before creating a new session
async function findExistingActiveSession(userId, examId) {
  return prisma.examSession.findFirst({
    where: {
      userId,
      examId,
      status: { in: ['ACTIVE', 'PROVISIONING'] },
      endsAt: { gt: new Date() }
    }
  });
}

// In createExamSession
const existing = await findExistingActiveSession(userId, examId);
if (existing) {
  // Return existing instead of creating duplicate
  return formatSessionResponse(existing);
}
```

---

## 7. Attack Scenarios & Mitigations

### 7.1 Session ID Guessing

**Attack:** User B guesses User A's sessionId and tries to access it.

**Mitigation:**
1. SessionId is UUID v4 (2^122 possibilities)
2. Even with correct sessionId, ownership check fails
3. Session credentials are unique per session
4. Rate limiting on session access endpoints

### 7.2 Token Theft

**Attack:** User B steals User A's launch token.

**Mitigation:**
1. Launch tokens expire in 60 seconds
2. Tokens are one-time use (consumed on first validation)
3. Token is bound to specific userId - CKX validates with Sailor API
4. Token theft window is extremely small

### 7.3 Cookie Theft

**Attack:** User B steals User A's session cookie.

**Mitigation:**
1. Cookie is HttpOnly (no JavaScript access)
2. Cookie is Secure in production (HTTPS only)
3. Cookie is SameSite=Lax (CSRF protection)
4. Cookie contains signed session reference (tamper-evident)

### 7.4 URL Sharing

**Attack:** User A shares their lab URL with User B.

**Mitigation:**
1. URL alone doesn't grant access
2. Session cookie required (set during launch handoff)
3. Cookie is bound to browser that completed launch flow
4. User B would need to complete their own launch flow

### 7.5 Browser Extension Attack

**Attack:** Malicious extension intercepts tokens/cookies.

**Mitigation:**
1. Beyond our control, but mitigated by:
   - Short token TTL
   - One-time token use
   - Session-specific credentials
   - Monitoring for anomalous access patterns

---

## 8. Implementation Checklist

### 8.1 Sailor API

- [x] `ExamSession.userId` is immutable
- [x] Ownership check in all session endpoints
- [x] Launch token includes userId binding
- [x] Concurrent session limits
- [x] Idempotent session creation
- [x] Session cleanup job for stuck states

### 8.2 CKX Runtime

- [x] SessionRegistry stores ownerId
- [x] Session cookie includes userId
- [x] Ownership verification middleware
- [x] Session-specific credentials (VNC/SSH)
- [x] Redis-backed session persistence
- [ ] Kubernetes namespace isolation (infrastructure)

### 8.3 Frontend

- [x] No direct CKX access (all through Sailor API)
- [x] Launch token flow for new tabs
- [x] Session cookie sent with all CKX requests
- [x] Graceful handling of 403/410 errors

---

## 9. Non-Goals (Explicitly Out of Scope)

| Feature | Reason |
|---------|--------|
| Multi-device session sharing | Complicates ownership model |
| Admin impersonation | Security risk, needs separate audit trail |
| Collaborative labs | Requires different isolation model |
| Session transfer | Ownership is immutable by design |
| Guest access | All access requires authentication |

---

## 10. Glossary

| Term | Definition |
|------|------------|
| **Owner** | The user who created the session (immutable) |
| **Session** | ExamSession record in Sailor API |
| **CKX Session** | SessionRecord in CKX runtime registry |
| **Launch Token** | One-time, short-lived token for secure handoff |
| **Session Cookie** | HttpOnly cookie set by CKX after launch validation |
| **Runtime** | VNC/SSH/K8s resources bound to a session |

---

## Appendix A: Sequence Diagram - Secure Session Access

```
User A                 Sailor Client         Sailor API           CKX Runtime
  │                         │                     │                    │
  │ 1. Click "Open Lab"     │                     │                    │
  │ ───────────────────────▶│                     │                    │
  │                         │ 2. POST /sessions   │                    │
  │                         │    /:id/launch-token│                    │
  │                         │ ───────────────────▶│                    │
  │                         │                     │ 3. Verify JWT      │
  │                         │                     │    Check ownership │
  │                         │                     │    Issue token     │
  │                         │ 4. { launchUrl }    │                    │
  │                         │ ◀───────────────────│                    │
  │                         │                     │                    │
  │ 5. window.open(launchUrl)                     │                    │
  │ ─────────────────────────────────────────────────────────────────▶│
  │                         │                     │                    │
  │                         │                     │ 6. POST /validate  │
  │                         │                     │ ◀───────────────────│
  │                         │                     │    (token)         │
  │                         │                     │                    │
  │                         │                     │ 7. { valid, data } │
  │                         │                     │ ───────────────────▶│
  │                         │                     │    (consumed)      │
  │                         │                     │                    │
  │ 8. Set-Cookie: ckx_session=...               │                    │
  │    Redirect: /exam.html?sessionId=...        │                    │
  │ ◀─────────────────────────────────────────────────────────────────│
  │                         │                     │                    │
  │ 9. Load VNC (with cookie)                    │                    │
  │ ─────────────────────────────────────────────────────────────────▶│
  │                         │                     │                    │
  │                         │                     │ 10. Verify cookie  │
  │                         │                     │     Check ownership│
  │                         │                     │     Proxy to VNC   │
  │ 11. VNC stream          │                     │                    │
  │ ◀─────────────────────────────────────────────────────────────────│
```

---

## Appendix B: What Happens When User B Tries to Access User A's Session

```
User B                 Sailor Client         Sailor API           CKX Runtime
  │                         │                     │                    │
  │ 1. Somehow gets User A's sessionId           │                    │
  │                         │                     │                    │
  │ ATTEMPT 1: Request launch token              │                    │
  │ ───────────────────────▶│                     │                    │
  │                         │ POST /sessions      │                    │
  │                         │ /:sessionId/launch-token                 │
  │                         │ ───────────────────▶│                    │
  │                         │                     │ Check: Is User B   │
  │                         │                     │ the owner?         │
  │                         │                     │ NO - User A owns it│
  │                         │ 403 Forbidden       │                    │
  │                         │ ◀───────────────────│                    │
  │ ◀───────────────────────│                     │                    │
  │                         │                     │                    │
  │ ATTEMPT 2: Direct CKX access (paste URL)     │                    │
  │ ─────────────────────────────────────────────────────────────────▶│
  │                         │                     │                    │
  │                         │                     │ Check: Does User B │
  │                         │                     │ have valid cookie? │
  │                         │                     │ NO - no cookie     │
  │ 401 Unauthorized        │                     │                    │
  │ ◀─────────────────────────────────────────────────────────────────│
  │                         │                     │                    │
  │ ATTEMPT 3: Steal/forge launch token          │                    │
  │ ─────────────────────────────────────────────────────────────────▶│
  │                         │                     │                    │
  │                         │                     │ 6. POST /validate  │
  │                         │                     │ ◀───────────────────│
  │                         │                     │                    │
  │                         │                     │ Token expired/used │
  │                         │                     │ OR userId mismatch │
  │                         │                     │ ───────────────────▶│
  │ 401 Invalid Token       │                     │                    │
  │ ◀─────────────────────────────────────────────────────────────────│
```

**Result:** User B cannot access User A's session through any path.
