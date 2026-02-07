# Iframe Access Token Design

## Problem Statement

VNC access is rendered inside an `<iframe>`, which cannot send `Authorization` headers. The current proxy routes require `requireAuth` middleware, causing iframe requests to fail with 401 Unauthorized.

**Constraints:**
- Cannot disable authentication globally
- Cannot accept JWT tokens via query params (security risk)
- Cannot add user logic to CKX
- Must preserve strict per-session isolation
- Must not leak user identity to CKX

## Solution: Capability-Based Iframe Access Tokens

### Core Concept

Introduce a **short-lived, scoped capability token** that:
- Is **not** an identity token (unlike JWT)
- Grants access **only** to a specific `ckxSessionId`
- Is cryptographically signed by Sailor API
- Expires quickly (5-15 minutes)
- Cannot be reused for other sessions or APIs

### Token Structure

```javascript
{
  // Payload
  ckxSessionId: "uuid-of-ckx-session",
  userId: "uuid-of-user",
  expiresAt: 1234567890,  // Unix timestamp
  issuedAt: 1234567800,    // Unix timestamp
  
  // Signature (HMAC-SHA256)
  signature: "base64-encoded-hmac"
}
```

**Encoding:** Base64URL-encoded JSON payload + signature, or JWT-like format (header.payload.signature) for easier parsing.

**Secret:** Uses `JWT_SECRET` or a dedicated `IFRAME_TOKEN_SECRET` (recommended for separation of concerns).

## Authentication Flow

### Phase 1: Token Issuance (Sailor API)

**Endpoint:** `GET /exam-sessions/:sessionId/iframe-token`

**Request:**
- Requires `Authorization: Bearer <jwt>` header (normal auth)
- `sessionId` can be `ExamSession.id` or `ckxSessionId`

**Sailor API Validation:**
1. ✅ Validate JWT token (`requireAuth` middleware)
2. ✅ Resolve `ExamSession` by `sessionId` (`resolveExamSession`)
3. ✅ Verify `req.user.id === session.userId` (ownership)
4. ✅ Verify `session.status === 'ACTIVE'`
5. ✅ Verify `session.endsAt > now` (not expired)
6. ✅ Verify `session.ckxSessionId` exists

**Token Generation:**
```javascript
const payload = {
  ckxSessionId: session.ckxSessionId,
  userId: session.userId,
  expiresAt: Math.floor(Date.now() / 1000) + 600, // 10 minutes
  issuedAt: Math.floor(Date.now() / 1000)
};

const token = signIframeToken(payload); // HMAC-SHA256
```

**Response:**
```json
{
  "iframeToken": "base64url-encoded-token",
  "expiresIn": 600
}
```

**Error Cases:**
- 401: Invalid/missing JWT
- 403: User doesn't own session, session not active, or expired
- 404: Session not found

### Phase 2: Iframe Request (Sailor API Proxy)

**Request:**
```
GET /ckx/sessions/:ckxSessionId/vnc-proxy/?iframeToken=...&autoconnect=true&...
```

**Sailor API Proxy Validation:**

**New Middleware:** `validateIframeToken` (runs BEFORE `requireAuth`)

1. ✅ Extract `iframeToken` from `req.query.iframeToken`
2. ✅ If missing, fall through to `requireAuth` (normal API call)
3. ✅ If present:
   - Verify signature (HMAC verification)
   - Verify `expiresAt > now`
   - Verify `payload.ckxSessionId === req.params.ckxSessionId` (URL match)
   - Verify `payload.userId` exists (for downstream checks)
   - Set `req.user = { id: payload.userId }` (for `requireActiveExamSession`)
   - Set `req.iframeTokenValid = true` (flag to bypass `requireAuth`)

4. ✅ Continue to `resolveExamSession` (by `ckxSessionId`)
5. ✅ Continue to `requireActiveExamSession` (validates ownership via `req.user.id`)

**Proxy to CKX:**
- Rewrite path: `/ckx/sessions/:ckxSessionId/vnc-proxy/*` → `/api/sessions/:ckxSessionId/vnc-proxy/*`
- **Remove** `iframeToken` from query params before proxying (CKX doesn't need it)
- Forward all other query params (`autoconnect`, `resize`, etc.)

### Phase 3: CKX Processing

**CKX receives:**
```
GET /api/sessions/:ckxSessionId/vnc-proxy/?autoconnect=true&resize=scale&...
```

**CKX behavior:** Unchanged. CKX:
- Uses `requireSession` middleware (validates `sessionId` exists in registry)
- Proxies to VNC server based on `req.session.vnc` config
- **Never sees** `iframeToken` or user identity

## Middleware Responsibility Breakdown

### Sailor API Middleware Stack (Proxy Routes)

```
/ckx/sessions/:ckxSessionId/vnc-proxy
├── [1] Extract ckxSessionId → set req.params.sessionId
├── [2] validateIframeToken (NEW)
│   ├── If iframeToken present:
│   │   ├── Verify signature
│   │   ├── Verify expiry
│   │   ├── Verify ckxSessionId match
│   │   ├── Set req.user = { id: payload.userId }
│   │   └── Set req.iframeTokenValid = true
│   └── If missing, continue (fall through to requireAuth)
├── [3] requireAuth (MODIFIED)
│   ├── If req.iframeTokenValid === true → skip (already validated)
│   └── Otherwise → normal JWT validation
├── [4] resolveExamSession
│   └── Resolves ExamSession by ckxSessionId
├── [5] requireActiveExamSession
│   ├── Verifies req.user.id === session.userId (ownership)
│   ├── Verifies session.status === 'ACTIVE'
│   └── Verifies session.endsAt > now
└── [6] Proxy middleware
    ├── Rewrite path to CKX
    ├── Remove iframeToken from query
    └── Forward to CKX
```

### Modified `requireAuth` Middleware

```javascript
async function requireAuth(req, res, next) {
  // If iframe token already validated, skip
  if (req.iframeTokenValid === true) {
    return next();
  }
  
  // Normal JWT validation
  const auth = req.headers.authorization;
  const token = auth && auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  // ... rest of JWT validation
}
```

## Validation Location Matrix

| Validation | Location | When |
|------------|----------|------|
| JWT validation | Sailor API (`requireAuth`) | Token issuance endpoint |
| Session ownership | Sailor API (`requireActiveExamSession`) | Both token issuance and proxy |
| Session active status | Sailor API (`requireActiveExamSession`) | Both token issuance and proxy |
| Iframe token signature | Sailor API (`validateIframeToken`) | Proxy request |
| Iframe token expiry | Sailor API (`validateIframeToken`) | Proxy request |
| ckxSessionId match | Sailor API (`validateIframeToken`) | Proxy request |
| Session exists in registry | CKX (`requireSession`) | CKX proxy request |
| VNC endpoint routing | CKX (`vncService`) | CKX proxy request |

**Key Point:** All user/session validation happens in Sailor API. CKX only validates that `sessionId` exists in its registry.

## Edge Cases

### 1. Expired Iframe Token

**Scenario:** User loads iframe, token expires during session.

**Behavior:**
- `validateIframeToken` returns 401
- Frontend should:
  - Call `/exam-sessions/:id/iframe-token` again (with JWT)
  - Update iframe `src` with new token
  - Or show error: "Session expired, please refresh"

**Prevention:** Set token expiry shorter than session expiry (e.g., 10 min token vs 60 min session).

### 2. Reused Token for Different Session

**Scenario:** Attacker copies `iframeToken` from one session and tries to use it for another `ckxSessionId`.

**Behavior:**
- `validateIframeToken` verifies `payload.ckxSessionId === req.params.ckxSessionId`
- Mismatch → 401 Unauthorized
- Token is cryptographically bound to one `ckxSessionId`

### 3. Revoked Session (User Ended Exam)

**Scenario:** User ends exam session, then iframe token is still valid.

**Behavior:**
- `requireActiveExamSession` checks `session.status === 'ACTIVE'`
- If status is `ENDED`/`EXPIRED`/`REVOKED` → 403 Forbidden
- Token validity doesn't matter if session is inactive

**Prevention:** Token expiry should be short (10 min), but session revocation is immediate.

### 4. Token Issued, Then Session Revoked

**Scenario:** Admin revokes session while user has valid iframe token.

**Behavior:**
- Next iframe request: `requireActiveExamSession` returns 403
- Token signature is valid, but session is inactive
- Access denied immediately (no need to wait for token expiry)

### 5. Missing Iframe Token (Direct API Call)

**Scenario:** Developer calls proxy route directly without `iframeToken`.

**Behavior:**
- `validateIframeToken` finds no token → continues
- `requireAuth` validates JWT from `Authorization` header
- Normal API flow (for programmatic access)

### 6. Token Replay Attack

**Scenario:** Attacker intercepts `iframeToken` and replays it.

**Mitigation:**
- Token is scoped to `ckxSessionId` (cannot access other sessions)
- Token is scoped to `userId` (cannot access other users' sessions)
- Token expires quickly (10 min)
- Session can be revoked independently (immediate effect)

**Note:** If token is intercepted, attacker can only access the same session the token was issued for, and only until token/session expires. This is acceptable risk for iframe access.

## Security Guarantees

### ✅ Preserved Guarantees

1. **Per-Session Isolation:** Token is cryptographically bound to one `ckxSessionId`
2. **User Ownership:** Token contains `userId`, validated against `session.userId`
3. **Time-Limited Access:** Token expires quickly (10 min), session can be revoked immediately
4. **No Direct CKX Access:** All requests go through Sailor API proxy
5. **No User Logic in CKX:** CKX never sees user identity or iframe tokens

### ✅ New Guarantees

1. **Iframe Compatibility:** Works with browser iframe limitations
2. **Capability-Based:** Token grants access to one resource only (not identity)
3. **Non-Transferable:** Token cannot be used for other sessions or APIs
4. **Server-Side Validation:** Token signature verified server-side only

### ❌ What This Does NOT Do

1. **Does NOT weaken security:** Token is more restrictive than JWT (scoped to one session)
2. **Does NOT expose CKX:** CKX still only sees `sessionId`, never tokens or user info
3. **Does NOT allow cross-session access:** Token is bound to `ckxSessionId`
4. **Does NOT persist tokens:** Frontend never stores tokens (ephemeral)

## Architecture Boundary Compliance

### Phase 1-5 Boundaries (Unchanged)

| Boundary | Status | Reason |
|----------|--------|--------|
| CKX has no auth logic | ✅ Preserved | CKX never validates iframe tokens |
| CKX identifies by sessionId only | ✅ Preserved | CKX still only sees `sessionId` |
| Sailor API owns session lifecycle | ✅ Preserved | Token issuance validates session state |
| Client never calls CKX directly | ✅ Preserved | All requests go through Sailor API proxy |
| Session isolation enforced | ✅ Preserved | Token is scoped to one `ckxSessionId` |

### Why This Design Complies

1. **CKX remains unchanged:** CKX proxy routes still use `requireSession` (sessionId validation only). Iframe tokens are stripped before proxying.

2. **Sailor API owns all validation:** User identity, session ownership, and token validation all happen in Sailor API. CKX is unaware of tokens.

3. **No direct client-CKX communication:** Client calls Sailor API (`/ckx/sessions/...`), which proxies to CKX (`/api/sessions/...`).

4. **Capability token ≠ identity token:** Iframe token is a capability (access to one resource), not an identity assertion. It cannot be used for other APIs.

5. **Strict scoping:** Token is bound to `ckxSessionId` and `userId`, preventing cross-session or cross-user access.

## Implementation Checklist

### Sailor API Changes

- [ ] Add `validateIframeToken` middleware
- [ ] Modify `requireAuth` to skip if `req.iframeTokenValid === true`
- [ ] Add `GET /exam-sessions/:sessionId/iframe-token` endpoint
- [ ] Add `signIframeToken()` and `verifyIframeToken()` utilities
- [ ] Update proxy route middleware stack
- [ ] Strip `iframeToken` from query params before proxying to CKX

### Sailor Client Changes (Future)

- [ ] Call `/exam-sessions/:id/iframe-token` before loading iframe
- [ ] Embed `iframeToken` in iframe `src` URL
- [ ] Handle token expiry (refresh token or show error)
- [ ] Never store iframe tokens in localStorage/sessionStorage

### CKX Changes

- [ ] None required (tokens are stripped before proxying)

## Token Lifetime Recommendations

- **Iframe token:** 10 minutes (short-lived, reduces replay window)
- **Session duration:** 60+ minutes (exam time)
- **JWT token:** 7 days (user session)

**Rationale:** Iframe token should be shorter than session duration, allowing for session revocation to take immediate effect even if token is still valid.
