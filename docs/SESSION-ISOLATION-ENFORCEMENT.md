# Session Isolation Enforcement — Technical Specification

## Executive Summary

This document defines the **strong, server-side enforcement** model for exam session isolation in CK-X. It consolidates the designs from `SESSION-ISOLATION-DESIGN.md` and `MULTI-SESSION-ISOLATION-DESIGN.md` into a single, actionable specification with explicit enforcement rules.

**Core Guarantee**: User A can NEVER access User B's exam session, runtime, or resources—enforced at every layer, not just the frontend.

---

## 1. Data Model & Ownership

### 1.1 Ownership Chain

```
User (id: UUID)
  └── ExamSession (userId: FK, immutable)
        └── CKX SessionRecord (ownerId: string, mirrors userId)
              ├── VNC endpoint (session-scoped credentials)
              ├── SSH endpoint (session-scoped credentials)
              └── Kubernetes namespace (session-scoped)
```

### 1.2 Ownership Rules (IMMUTABLE)

| Rule | Description | Enforcement Point |
|------|-------------|-------------------|
| **O1** | `ExamSession.userId` is set at creation and NEVER changes | Prisma schema (no update allowed) |
| **O2** | `SessionRecord.ownerId` MUST equal `ExamSession.userId` | `createExamSession()` |
| **O3** | Only the owner can: start, resume, access VNC, access SSH, call APIs | All middleware |
| **O4** | Ownership cannot be transferred, delegated, or shared | By design |

### 1.3 Credential Isolation

Each session gets **unique, randomly generated credentials** at creation:

```javascript
{
  vnc: { password: crypto.randomBytes(16).toString('hex') },
  ssh: {
    username: `user-${sessionId.slice(0,8)}`,
    password: crypto.randomBytes(16).toString('hex')
  },
  kubernetes: {
    namespace: `exam-${sessionId.slice(0,8)}`,
    serviceAccount: `sa-${sessionId.slice(0,8)}`
  }
}
```

**Why**: Even if User B guesses User A's sessionId, they don't have the credentials.

---

## 2. Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────────┐
│                         UNTRUSTED ZONE                               │
│  ┌─────────────┐                                                    │
│  │   Browser   │  ← User can manipulate anything here               │
│  └──────┬──────┘                                                    │
└─────────┼───────────────────────────────────────────────────────────┘
          │ HTTPS
┌─────────┼───────────────────────────────────────────────────────────┐
│         ▼          TRUSTED ZONE (Backend)                           │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  SAILOR API — Authentication & Authorization Authority       │   │
│  │  • Validates JWT tokens (user identity)                      │   │
│  │  • Verifies session ownership (userId === session.userId)    │   │
│  │  • Issues short-lived launch tokens                          │   │
│  │  • Controls session lifecycle (create/end/revoke)            │   │
│  │  • NEVER trusts client-provided userId                       │   │
│  └───────────────────────────┬─────────────────────────────────┘   │
│                              │ Internal calls (service-to-service)  │
│  ┌───────────────────────────▼─────────────────────────────────┐   │
│  │  CKX RUNTIME — Stateless Session Router                      │   │
│  │  • Validates session cookies (contains userId)               │   │
│  │  • Verifies ownerId matches session registry                 │   │
│  │  • Routes to session-specific VNC/SSH/K8s                    │   │
│  │  • NEVER makes authorization decisions                       │   │
│  │  • NEVER authenticates users directly                        │   │
│  └───────────────────────────┬─────────────────────────────────┘   │
│                              │ Session-scoped credentials           │
│  ┌───────────────────────────▼─────────────────────────────────┐   │
│  │  RUNTIME RESOURCES — Isolated Per Session                    │   │
│  │  • VNC server (unique password per session)                  │   │
│  │  • SSH terminal (unique user/pass per session)               │   │
│  │  • Kubernetes namespace (unique per session)                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Access Control Enforcement

### 3.1 Sailor API Middleware Stack (REQUIRED)

Every session-scoped endpoint MUST use this middleware chain:

```
Request → [JWT Auth] → [Session Resolution] → [Ownership Check] → [Status Check] → Handler
              │               │                      │                   │
              ▼               ▼                      ▼                   ▼
         401 if invalid  404 if not found     403 if not owner     410 if inactive
```

**Implementation** (`sailor-api/src/middleware/session-enforcement.js`):

```javascript
// 1. Resolve session from any ID format
async function resolveExamSession(req, res, next) {
  const sessionId = req.params.sessionId || req.params.examSessionId;
  const session = await prisma.examSession.findFirst({
    where: { OR: [{ id: sessionId }, { ckxSessionId: sessionId }] },
    include: { exam: true, user: true },
  });
  if (!session) return res.status(404).json({ error: 'Session not found' });
  req.examSession = session;
  next();
}

// 2. CRITICAL: Ownership enforcement — THE CORE SECURITY CHECK
async function requireActiveExamSession(req, res, next) {
  const session = req.examSession;
  
  // HARD RULE: User can ONLY access their own sessions
  if (session.userId !== req.user.id) {
    logSecurityEvent('SESSION_ACCESS_DENIED', {
      reason: 'ownership_mismatch',
      requesterId: req.user.id,
      sessionId: session.id,
      sessionOwnerId: session.userId,
    });
    return res.status(403).json({ error: 'Access denied' });
  }
  
  // Status check
  if (session.status !== 'ACTIVE') {
    return res.status(410).json({ error: 'Session not active', status: session.status });
  }
  
  // Expiry check
  if (session.endsAt && new Date() > session.endsAt) {
    await markSessionExpired(session);
    return res.status(410).json({ error: 'Session expired' });
  }
  
  next();
}
```

### 3.2 CKX Runtime Middleware Stack (REQUIRED)

Every request to CKX MUST pass through session ownership verification:

```
Request → [Extract Session Cookie] → [Session Registry Lookup] → [Ownership Verify] → Handler
                 │                            │                         │
                 ▼                            ▼                         ▼
            401 if missing              404 if not found          403 if mismatch
```

**ENFORCEMENT REQUIREMENT** — CKX must use `requireOwnedSession` (not basic `requireSession`):

```javascript
// app/middleware/session-resolver.js — STRICT MODE REQUIRED

function requireOwnedSession(sessionRegistry) {
  return requireSession(sessionRegistry, { 
    requireOwnership: true,   // MUST have valid session cookie
    strictOwnership: true     // MUST match session's ownerId
  });
}
```

**Apply to ALL session-scoped routes:**

```javascript
// app/services/route-service.js — HARDENED

// VNC info — REQUIRES OWNERSHIP
app.get('/api/sessions/:sessionId/runtime', 
  requireOwnedSession(this.sessionRegistry),  // NOT requireSession
  (req, res) => { /* ... */ }
);

// All session routes MUST use requireOwnedSession
app.get('/api/sessions/:sessionId/vnc-info',
  requireOwnedSession(this.sessionRegistry),
  (req, res) => { /* ... */ }
);
```

### 3.3 Token Flow Enforcement

#### Launch Token (New Tab Opening)

```
┌──────────────┐    1. POST /launch-token     ┌──────────────┐
│    Sailor    │ ─────────────────────────────▶│  Sailor API  │
│    Client    │    (JWT required)            │              │
│              │                              │ ✓ Verify JWT │
│              │    2. { token, launchUrl }   │ ✓ Check owner│
│              │ ◀─────────────────────────────│ ✓ Issue token│
└──────────────┘                              └──────────────┘
       │
       │ 3. window.open(launchUrl)
       ▼
┌──────────────┐    4. POST /validate-token   ┌──────────────┐
│     CKX      │ ─────────────────────────────▶│  Sailor API  │
│   Runtime    │                              │              │
│              │    5. { valid, data }        │ ✓ One-time   │
│              │ ◀─────────────────────────────│ ✓ 60s TTL    │
└──────────────┘    (token consumed)          │ ✓ Bound to   │
       │                                      │   userId     │
       │ 6. Set-Cookie: ckx_session=...      └──────────────┘
       │    (contains userId, signed)
       ▼
┌──────────────┐
│   Lab UI     │
│  (VNC/SSH)   │
└──────────────┘
```

**Token Properties** (enforced in `sailor-api/src/lib/launch-token.js`):
- TTL: 60 seconds
- One-time use: Consumed on first validation
- Bound to: `{ ckxSessionId, userId, examSessionId }`
- Signed: HMAC-SHA256

#### Session Cookie (Subsequent Requests)

```javascript
// Cookie contains (signed):
{
  sessionId: 'ckx-session-uuid',
  userId: 'user-uuid',         // CRITICAL: Used for ownership verification
  examSessionId: 'exam-session-uuid',
  validatedAt: timestamp
}

// On every request, CKX MUST verify:
if (cookie.userId !== sessionRegistry.get(sessionId).ownerId) {
  return 403; // Ownership mismatch
}
```

---

## 4. Session Lifecycle & State Machine

### 4.1 Valid States

```
CREATED → PROVISIONING → ACTIVE → ENDED
              │             │
              └──► REVOKED ◄┘
                     │
                     ▼
                  EXPIRED
```

### 4.2 State Transition Rules

| From | To | Trigger | Who |
|------|-----|---------|-----|
| CREATED | PROVISIONING | CKX session registered | Sailor API |
| PROVISIONING | ACTIVE | Runtime ready | Sailor API |
| ACTIVE | ENDED | User submits/ends | Sailor API |
| ACTIVE | EXPIRED | Time runs out | Cleanup job |
| * | REVOKED | Admin/payment revoke | Sailor API |

### 4.3 Access by State

| State | Can Access Runtime? | Can Resume? | Can View Results? |
|-------|---------------------|-------------|-------------------|
| CREATED | ❌ | ❌ | ❌ |
| PROVISIONING | ❌ | ❌ | ❌ |
| ACTIVE | ✅ (owner only) | ✅ (owner only) | ❌ |
| ENDED | ❌ | ❌ | ✅ (owner only) |
| EXPIRED | ❌ | ❌ | ✅ (owner only) |
| REVOKED | ❌ | ❌ | ❌ |

---

## 5. Attack Scenarios & Mitigations

### 5.1 Session ID Guessing

**Attack**: User B guesses User A's sessionId (UUID) and tries to access it.

**Mitigations**:
1. UUID v4 has 2^122 possibilities — practically unguessable
2. Even with correct sessionId, ownership check fails (403)
3. Session credentials are unique per session — no reuse possible
4. Rate limiting on session access endpoints

### 5.2 Launch Token Theft

**Attack**: User B intercepts User A's launch token (e.g., via shoulder surfing).

**Mitigations**:
1. Token expires in 60 seconds
2. Token is one-time use (consumed immediately)
3. Token is bound to `userId` — CKX validates this
4. Token creates a cookie bound to `userId`

### 5.3 Cookie Theft/Replay

**Attack**: User B steals User A's session cookie.

**Mitigations**:
1. Cookie is HttpOnly (no JavaScript access)
2. Cookie is Secure in production (HTTPS only)
3. Cookie is SameSite=Lax (CSRF protection)
4. Cookie contains `userId` — verified against session registry
5. Cookie has 24h max age and is cleaned up on session end

### 5.4 Direct CKX Access (Bypass Sailor)

**Attack**: User B crafts direct requests to CKX with a guessed sessionId.

**Mitigations**:
1. CKX requires valid session cookie (set only via launch token flow)
2. CKX verifies cookie's `userId` against session's `ownerId`
3. No cookie = 401, wrong owner = 403

### 5.5 Forged Session Registration

**Attack**: Attacker calls `POST /api/sessions` to register a fake session with their ownerId on someone else's infrastructure.

**Mitigations**:
1. Session registration only called by Sailor API (internal network)
2. Idempotency check rejects different owner for same sessionId (409)
3. CKX has no runtime to route to without real provisioning

### 5.6 URL Sharing

**Attack**: User A shares their lab URL with User B.

**Mitigations**:
1. URL alone doesn't grant access
2. Session cookie required (set during launch handoff)
3. Cookie is per-browser (User B's browser doesn't have it)
4. User B would need to steal the cookie, which requires same-machine access

---

## 6. HTTP Response Codes

| Scenario | Code | Response |
|----------|------|----------|
| No authentication (missing JWT/cookie) | **401** | `{ error: "Authentication required" }` |
| Invalid/expired token | **401** | `{ error: "Invalid or expired token" }` |
| Session not found | **404** | `{ error: "Session not found" }` |
| Not session owner | **403** | `{ error: "Access denied" }` |
| Session ended/expired/revoked | **410** | `{ error: "Session not available", status }` |
| Rate limited | **429** | `{ error: "Rate limited", retryAfter }` |
| Duplicate session (different owner) | **409** | `{ error: "Session already exists" }` |

---

## 7. Enforcement Checklist

### 7.1 Sailor API ✅

| Item | Status | File |
|------|--------|------|
| `ExamSession.userId` immutable at creation | ✅ | `exam-session-service.js` |
| Ownership check in `requireActiveExamSession` | ✅ | `session-enforcement.js` |
| Launch token bound to userId | ✅ | `launch-token.js` |
| Session ownership logged on denial | ✅ | `session-enforcement.js` |
| Concurrent session limits | ✅ | `exam-session-service.js` |
| Idempotent session creation | ✅ | `exam-session-service.js` |
| Periodic cleanup of stale sessions | ✅ | `exam-session-service.js` |

### 7.2 CKX Runtime ✅

| Item | Status | File |
|------|--------|------|
| SessionRegistry stores `ownerId` | ✅ | `session-registry.js` |
| Session cookie contains `userId` | ✅ | `launch-service.js` |
| `requireOwnedSession` middleware exists | ✅ | `session-resolver.js` |
| VNC/runtime routes use `requireOwnedSession` | ✅ | `route-service.js` |
| SSH Socket.IO verifies ownership | ✅ | `server.js` (sshIO handler) |
| VNC proxy verifies ownership | ✅ | `server.js` (websockify handlers) |
| Security event logging | ✅ | `session-resolver.js` |

### 7.3 Frontend (Informational Only)

| Item | Status | Notes |
|------|--------|-------|
| Never calls CKX directly | ✅ | All through Sailor API |
| Handles 403/410 gracefully | ✅ | Redirects to dashboard |

---

## 8. Implementation Status

All required code changes have been implemented:

### 8.1 CKX Route Service ✅

```javascript
// app/services/route-service.js — NOW USING STRICT OWNERSHIP
app.get('/api/sessions/:sessionId/runtime',
  requireOwnedSession(this.sessionRegistry),  // ✅ STRICT
  // ...
);

app.get('/api/sessions/:sessionId/vnc-info',
  requireOwnedSession(this.sessionRegistry),  // ✅ STRICT
  // ...
);
```

### 8.2 SSH Socket.IO ✅

```javascript
// app/server.js — SSH handler now verifies ownership
sshIO.on('connection', (socket) => {
  // ... session lookup ...
  
  // Extract userId from session cookie
  const cookieHeader = socket.handshake?.headers?.cookie;
  // ... parse cookie ...
  
  // SECURITY: Verify ownership
  if (session.ownerId) {
    if (!userId) {
      socket.emit('data', 'Error: Authentication required for this session.\r\n');
      socket.disconnect(true);
      return;
    }
    if (userId !== session.ownerId) {
      console.warn(`[SSH] SECURITY: Ownership mismatch...`);
      socket.emit('data', 'Error: Access denied. You do not own this session.\r\n');
      socket.disconnect(true);
      return;
    }
  }
  // ... proceed with connection ...
});
```

### 8.3 VNC/Websockify Proxy ✅

```javascript
// app/server.js — resolveVncTargetFromRequest now verifies ownership
function resolveVncTargetFromRequest(req) {
  // ... session lookup ...
  
  // SECURITY: Verify ownership before allowing VNC access
  if (session.ownerId && userId && session.ownerId !== userId) {
    return { error: 'ACCESS_DENIED', message: '...' };
  }
  if (session.ownerId && !userId) {
    return { error: 'AUTH_REQUIRED', message: '...' };
  }
  
  return { host, port, sessionId, userId };
}

// WebSocket upgrade handler rejects if error
if (target.error) {
  socket.write('HTTP/1.1 403 Forbidden\r\n\r\n');
  socket.destroy();
  return;
}
```

### 8.4 Security Logging ✅

```javascript
// app/middleware/session-resolver.js — logs all access denials
logSecurityEvent('SESSION_ACCESS_DENIED', {
  reason: 'ownership_mismatch',
  requesterId,
  sessionId,
  sessionOwnerId,
  path, method, ip, userAgent
});
```

---

## 9. Non-Goals (Explicitly Out of Scope)

| Feature | Why |
|---------|-----|
| Multi-device session sharing | Complicates ownership; single browser per session |
| Admin impersonation | Security risk; needs separate audit system |
| Collaborative labs | Requires different isolation model |
| Session transfer | Ownership is immutable by design |
| Guest access | All access requires authentication |

---

## 10. Summary

**The isolation model guarantees**:

1. **User A cannot access User B's session** — Ownership verified at every layer
2. **No shared state** — Each session has unique credentials, namespace, runtime
3. **Server-side enforcement** — Frontend is for UX, not security
4. **Defense in depth** — Multiple barriers (JWT, launch token, cookie, registry)
5. **Audit trail** — All access denials logged with full context

**The security chain**:

```
JWT (user identity)
  → Launch Token (one-time, 60s, userId-bound)
    → Session Cookie (userId, signed, HttpOnly)
      → Session Registry (ownerId match)
        → Runtime (session-scoped credentials)
```

**Breaking any link = 401/403**. No bypass possible without compromising:
- Sailor API's JWT secret (authentication)
- Launch token secret (session handoff)
- Cookie signing key (session binding)
- Runtime credentials (VNC/SSH/K8s)
