# Multi-Session Isolation Design

## Overview

This document defines the isolation strategy for CK-X to safely support concurrent users and sessions without cross-contamination or interference.

---

## 1. Isolation Guarantees

### 1.1 User Isolation

**Guarantee**: User A cannot observe, modify, or affect User B's data or runtime.

| Layer | Isolation Mechanism |
|-------|---------------------|
| Authentication | JWT tokens scoped to user ID |
| Session Data | Foreign key constraint to user_id in database |
| Runtime | Separate container/VNC instance per session |
| API Access | All endpoints validate user ownership |

### 1.2 Session Isolation

**Guarantee**: Session A cannot observe, modify, or affect Session B's runtime or state.

| Layer | Isolation Mechanism |
|-------|---------------------|
| Session Registry | In-memory map keyed by `sessionId` only |
| VNC Proxy | Routes based on `sessionId` → unique VNC endpoint |
| SSH Terminal | Socket.IO namespace requires `sessionId` in handshake |
| Kubernetes | Namespace-per-session or label isolation |
| Credentials | Session-scoped, never shared |

---

## 2. Session Identity Model

### 2.1 Identity Hierarchy

```
User (Sailor API)
  └── ExamSession (Sailor API)
        └── CKX Session (CKX Runtime)
              ├── VNC Endpoint
              ├── SSH Endpoint
              └── Kubernetes Context
```

### 2.2 Identity Tokens

| Token Type | Issuer | Lifetime | Purpose |
|------------|--------|----------|---------|
| JWT | Sailor API | 24h | User authentication |
| Launch Token | Sailor API | 60s | One-time session handoff |
| Session Cookie | CKX | 24h | Runtime session binding |
| Session ID | Sailor API | Session lifetime | Universal session key |

### 2.3 Session ID Properties

```typescript
interface SessionId {
  format: "UUID v4";
  uniqueness: "globally unique";
  mutability: "immutable after creation";
  visibility: "exposed to client (non-secret)";
}
```

**Session ID is NOT a secret** — it identifies the session but doesn't grant access. Access requires valid authentication (JWT or session cookie).

---

## 3. Runtime Binding Strategy

### 3.1 Session Registry (CKX)

The `SessionRegistry` is the single source of truth for runtime routing:

```typescript
// In-memory session store (Redis-backed in production)
class SessionRegistry {
  private sessions: Map<SessionId, SessionRecord>;
  
  interface SessionRecord {
    sessionId: string;           // Primary key
    state: SessionState;         // READY | ACTIVE | ENDING | etc.
    vnc: {
      host: string;              // Container hostname
      port: number;              // VNC port (6901)
      password: string;          // Session-specific password
    };
    ssh: {
      host: string;              // Container hostname
      port: number;              // SSH port (22)
      username: string;          // Session-specific user
      password: string;          // Session-specific password
    };
    kubernetes: {
      namespace: string;         // Session-specific namespace
      kubeconfig: string;        // Path to kubeconfig
    };
    createdAt: string;
    expiresAt: string | null;
  }
}
```

### 3.2 Runtime Binding Rules

1. **No Global Runtime**: CKX has NO default VNC/SSH endpoint. Every request must specify a session.

2. **Binding is Immutable**: Once a session is bound to a runtime (VNC host:port), it cannot change.

3. **Binding is Validated**: Every request validates that:
   - Session exists in registry
   - Session state allows the operation
   - Requesting user owns the session (via cookie/token)

### 3.3 Binding Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Sailor UI  │     │ Sailor API  │     │     CKX     │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       │ 1. Start Session  │                   │
       │──────────────────>│                   │
       │                   │                   │
       │                   │ 2. Provision      │
       │                   │    Runtime        │
       │                   │──────────────────>│
       │                   │                   │
       │                   │ 3. Register       │
       │                   │    Session        │
       │                   │    (POST /api/    │
       │                   │     sessions)     │
       │                   │──────────────────>│
       │                   │                   │
       │                   │ 4. Session        │
       │                   │    Registered     │
       │                   │<──────────────────│
       │                   │                   │
       │ 5. Launch Token   │                   │
       │<──────────────────│                   │
       │                   │                   │
       │ 6. Open Lab       │                   │
       │   (new tab)       │                   │
       │───────────────────────────────────────>
       │                   │                   │
       │                   │ 7. Validate Token │
       │                   │<──────────────────│
       │                   │                   │
       │ 8. Session Cookie │                   │
       │<──────────────────────────────────────│
       │                   │                   │
       │ 9. VNC/SSH via    │                   │
       │    sessionId      │                   │
       │───────────────────────────────────────>
```

---

## 4. Eliminating Shared Mutable State

### 4.1 State Classification

| State Type | Location | Scope | Mutability |
|------------|----------|-------|------------|
| User data | PostgreSQL | Per-user | Mutable (owned) |
| Session metadata | PostgreSQL | Per-session | Mutable (owned) |
| Session runtime | Redis/Memory | Per-session | Mutable (owned) |
| VNC state | Container | Per-session | Isolated |
| K8s state | Namespace | Per-session | Isolated |

### 4.2 Prohibited Shared State

**NEVER share these between sessions:**

- VNC connections
- SSH connections  
- Kubernetes namespaces
- Temporary files
- Environment variables with secrets
- In-memory caches without session key

### 4.3 Allowed Shared State (Read-Only)

- Exam definitions (immutable)
- Lab configurations (immutable)
- Static assets (immutable)

---

## 5. Session-Scoped Credentials

### 5.1 Credential Generation

Each session gets unique credentials generated at creation time:

```typescript
function generateSessionCredentials(sessionId: string): SessionCredentials {
  return {
    vnc: {
      password: crypto.randomBytes(16).toString('hex'),
    },
    ssh: {
      username: `user-${sessionId.slice(0, 8)}`,
      password: crypto.randomBytes(16).toString('hex'),
    },
    kubernetes: {
      namespace: `exam-${sessionId.slice(0, 8)}`,
      serviceAccount: `sa-${sessionId.slice(0, 8)}`,
    }
  };
}
```

### 5.2 Credential Lifecycle

```
Session Created → Credentials Generated → Stored in Registry
                                               │
Session Active ────────────────────────────────┤
                                               │
Session Ended → Credentials Revoked → Registry Entry Deleted
```

### 5.3 Credential Storage

| Credential | Storage Location | Encryption |
|------------|------------------|------------|
| VNC password | Session Registry (memory/Redis) | At-rest optional |
| SSH password | Session Registry (memory/Redis) | At-rest optional |
| Kubeconfig | Mounted volume per container | File permissions |

---

## 6. Stateless API Design

### 6.1 Stateless Principles

1. **No process-local session state**: All session data in external stores (PostgreSQL, Redis)
2. **Request contains all context**: Session ID in URL, auth in header/cookie
3. **Idempotent operations**: Same request → same result
4. **Horizontal scalability**: Any API instance can handle any request

### 6.2 Session Context Derivation

```typescript
// Middleware: derive session context from request
async function deriveSessionContext(req, res, next) {
  // 1. Extract session ID from URL
  const sessionId = req.params.sessionId;
  
  // 2. Validate authentication
  const authResult = await validateAuth(req);
  if (!authResult.valid) return res.status(401).json({ error: 'Unauthorized' });
  
  // 3. Load session from store
  const session = await sessionStore.get(sessionId);
  if (!session) return res.status(404).json({ error: 'Session not found' });
  
  // 4. Verify ownership
  if (session.userId !== authResult.userId) {
    return res.status(403).json({ error: 'Not your session' });
  }
  
  // 5. Attach to request
  req.session = session;
  req.userId = authResult.userId;
  next();
}
```

### 6.3 API Instance Recovery

If an API instance restarts:

1. No local state is lost (all in external stores)
2. Existing sessions continue working
3. WebSocket connections reconnect automatically
4. VNC connections handled by separate containers (unaffected)

---

## 7. Failure Mode Handling

### 7.1 Tab Refresh

**Scenario**: User refreshes the lab browser tab.

**Handling**:
```
1. Browser reloads /exam.html?sessionId=...
2. Session cookie still valid
3. CKX validates cookie, retrieves session
4. VNC iframe reconnects to same endpoint
5. User continues where they left off
```

**Guarantees**:
- No new session created
- No runtime restart
- Kubernetes state preserved
- Timer continues (backend-tracked)

### 7.2 Duplicate Launch Attempts

**Scenario**: User clicks "Open Lab" multiple times rapidly.

**Handling**:
```typescript
// Launch token is one-time use
function validateAndConsumeLaunchToken(token) {
  const data = tokenStore.get(tokenId);
  
  // Already consumed
  if (data.consumed) {
    return { valid: false, error: 'Token already used' };
  }
  
  // Mark as consumed
  data.consumed = true;
  
  return { valid: true, data };
}
```

**Guarantees**:
- Only first click succeeds
- Subsequent clicks get "Token already used" error
- No duplicate sessions created
- No duplicate runtimes provisioned

### 7.3 Partial Startup Failures

**Scenario**: Session creation starts but fails midway.

**State Machine**:
```
CREATED → PROVISIONING → READY → ACTIVE → ENDING → ENDED
              │                              │
              └──→ PROVISION_FAILED          └──→ FAILED
```

**Handling**:
```typescript
async function provisionSession(sessionId) {
  try {
    await updateState(sessionId, 'PROVISIONING');
    
    // Step 1: Create runtime
    const runtime = await createRuntime(sessionId);
    if (!runtime) throw new Error('Runtime creation failed');
    
    // Step 2: Register with CKX
    await registerWithCKX(sessionId, runtime);
    
    // Step 3: Mark ready
    await updateState(sessionId, 'READY');
    
  } catch (error) {
    // Cleanup any partial state
    await cleanupPartialSession(sessionId);
    await updateState(sessionId, 'PROVISION_FAILED');
    throw error;
  }
}
```

**Guarantees**:
- Failed sessions marked with clear state
- Partial resources cleaned up
- User can retry (creates new session)
- No orphaned containers/namespaces

### 7.4 Network Disconnection

**Scenario**: User loses network temporarily.

**Handling**:
- VNC: noVNC auto-reconnects (built-in)
- SSH: Socket.IO reconnects (built-in)
- API: Client retries with backoff
- Session: Remains active (server-side state)

**Guarantees**:
- Work is not lost
- Session doesn't expire during brief disconnects
- Reconnection is automatic

---

## 8. Session Ownership Rules

### 8.1 Ownership Definition

```typescript
interface SessionOwnership {
  // The user who created the session
  ownerId: UserId;
  
  // Ownership is immutable
  transferable: false;
  
  // Only owner can:
  //   - Access runtime (VNC/SSH)
  //   - End session
  //   - View results
  //   - Extend time (if allowed)
}
```

### 8.2 Ownership Verification

Every session operation verifies ownership:

```typescript
// Sailor API: verify user owns the exam session
function requireOwnedSession(req, res, next) {
  if (req.examSession.userId !== req.user.id) {
    return res.status(403).json({ 
      error: 'Forbidden',
      message: 'You do not own this session' 
    });
  }
  next();
}

// CKX: verify session cookie matches session
function requireSessionCookie(req, res, next) {
  const cookie = req.cookies['ckx_session'];
  const sessionData = cookieStore.get(cookie);
  
  if (!sessionData || sessionData.sessionId !== req.params.sessionId) {
    return res.status(401).json({ error: 'Invalid session' });
  }
  next();
}
```

### 8.3 Ownership Matrix

| Operation | Requires Auth | Requires Ownership | Endpoint |
|-----------|---------------|-------------------|----------|
| Create session | JWT | N/A (creates new) | Sailor API |
| Get session status | JWT | Yes | Sailor API |
| Generate launch token | JWT | Yes | Sailor API |
| Validate launch token | Token | Implicit | CKX |
| Access VNC | Cookie | Yes (via cookie) | CKX |
| Access SSH | Cookie | Yes (via cookie) | CKX |
| End session | JWT | Yes | Sailor API |

---

## 9. Session Conflict Prevention

### 9.1 Conflict Types

| Conflict | Prevention |
|----------|------------|
| Duplicate session ID | UUID v4 (statistically impossible) |
| Same user, multiple sessions | Allowed (each isolated) |
| Same exam, multiple users | Allowed (each gets own session) |
| Runtime port collision | Dynamic port allocation |
| K8s namespace collision | Namespace includes session ID |

### 9.2 Concurrent Session Limits

```typescript
// Optional: limit concurrent sessions per user
async function checkSessionLimit(userId: string): Promise<boolean> {
  const activeSessions = await db.examSession.count({
    where: {
      userId,
      status: { in: ['CREATED', 'PROVISIONING', 'ACTIVE'] }
    }
  });
  
  const MAX_CONCURRENT_SESSIONS = 3;
  return activeSessions < MAX_CONCURRENT_SESSIONS;
}
```

### 9.3 Idempotent Session Start

```typescript
// Idempotent: calling multiple times returns same result
async function startOrGetSession(userId, examId) {
  // Check for existing active session for this exam
  const existing = await db.examSession.findFirst({
    where: {
      userId,
      examId,
      status: { in: ['ACTIVE', 'PROVISIONING', 'READY'] }
    }
  });
  
  if (existing) {
    // Return existing session (idempotent)
    return { session: existing, created: false };
  }
  
  // Create new session
  const session = await db.examSession.create({
    data: { userId, examId, status: 'CREATED' }
  });
  
  return { session, created: true };
}
```

---

## 10. Implementation Checklist

### Phase 1: Core Isolation (Current)

- [x] Session Registry in CKX (in-memory)
- [x] Session-scoped VNC proxy
- [x] Session-scoped SSH (Socket.IO with sessionId)
- [x] Launch token handoff
- [x] Session cookies for CKX auth
- [ ] Redis-backed Session Registry (production)

### Phase 2: Enhanced Isolation

- [ ] Session-specific VNC passwords
- [ ] Session-specific SSH users
- [ ] Kubernetes namespace per session
- [ ] Automatic cleanup on session end

### Phase 3: Conflict Prevention

- [ ] Concurrent session limits
- [ ] Idempotent session start
- [ ] Duplicate launch prevention
- [ ] Partial failure cleanup

### Phase 4: Monitoring & Audit

- [ ] Session lifecycle logging
- [ ] Ownership verification audit trail
- [ ] Cross-session access attempt alerts
- [ ] Resource usage per session

---

## 11. Security Considerations

### 11.1 Attack Vectors Mitigated

| Attack | Mitigation |
|--------|------------|
| Session hijacking | Session cookie httpOnly, secure, sameSite |
| Session fixation | New cookie on every launch token validation |
| Cross-session access | All routes validate session ownership |
| Resource exhaustion | Session limits, timeouts, cleanup |
| Credential leakage | Per-session credentials, no shared secrets |

### 11.2 Trust Boundaries

```
┌─────────────────────────────────────────────────────────┐
│                    Untrusted Zone                        │
│  ┌─────────────┐                                        │
│  │   Browser   │                                        │
│  └──────┬──────┘                                        │
└─────────┼───────────────────────────────────────────────┘
          │ HTTPS + JWT/Cookies
┌─────────┼───────────────────────────────────────────────┐
│         ▼          Trusted Zone                          │
│  ┌─────────────┐     ┌─────────────┐                    │
│  │ Sailor API  │────>│     CKX     │                    │
│  └─────────────┘     └──────┬──────┘                    │
│                             │                            │
│                      ┌──────▼──────┐                    │
│                      │   Runtime   │                    │
│                      │ (VNC/SSH/K8s)│                    │
│                      └─────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

---

## Summary

This design ensures:

1. **User A cannot affect User B**: Separate credentials, namespaces, runtimes
2. **Session A cannot affect Session B**: Unique session IDs, isolated registries
3. **No shared mutable state**: All state scoped to session or user
4. **Session-scoped credentials**: Generated per session, revoked on end
5. **Stateless APIs**: All context from external stores
6. **Robust failure handling**: Clear states, automatic cleanup, idempotent operations
