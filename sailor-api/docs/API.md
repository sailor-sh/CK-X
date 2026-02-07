# Sailor API — REST API & Session Enforcement

Sailor API is the business control plane: auth, payments, exam definitions, and ExamSession lifecycle. It creates and revokes CKX sessions; CKX never validates users directly.

---

## Base URL & Auth

- **Base:** `http://localhost:4000` (or `PORT` env).
- **Auth:** JWT in header: `Authorization: Bearer <token>`.
- **Login/register** return `{ token, user }`; use `token` for all protected routes.

---

## Endpoints

### Health

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | No | Liveness |

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | No | Body: `{ email, password, name? }`. Returns `{ user, token, expiresIn }`. |
| POST | `/auth/login` | No | Body: `{ email, password }`. Returns `{ user, token, expiresIn }`. |
| GET | `/auth/me` | Yes | Returns `{ user }`. |

### Payments & Entitlements

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/payments/products` | No | List products (for checkout). |
| GET | `/payments/entitlements` | Yes | Current user's active entitlements. |
| POST | `/payments/entitlements` | Yes | Body: `{ productId, validDays? }`. Grant entitlement (admin/webhook). |
| POST | `/payments/checkout` | Yes | Body: `{ productId }`. Create payment; returns stub (integrate Stripe etc.). |
| POST | `/payments/:id/complete` | Yes | Mark payment completed and grant 1-year entitlement. |

### Exams

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/exams` | Optional | List exams (metadata + question count). |
| GET | `/exams/:id` | Optional | One exam metadata. |
| GET | `/exams/:id/questions` | Yes | Questions for exam (options only; no answer key). |

### Exam Sessions (lifecycle + CKX orchestration)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/exam-sessions` | Yes | Body: `{ examId }`. **Enforce entitlement & max attempts**; create ExamSession and **CKX session**; return `{ examSession, examUrl, ckxSessionId }`. Client opens `examUrl` (includes `sessionId` for CKX). |
| GET | `/exam-sessions` | Yes | List current user's exam sessions. |
| GET | `/exam-sessions/:sessionId` | Yes | Get one session (by id or ckxSessionId). Ownership enforced. |
| GET | `/exam-sessions/:sessionId/access` | Yes | **Validate access**: session ACTIVE and `endsAt > now`. Returns 403 if expired/revoked. Use before loading exam UI. |
| POST | `/exam-sessions/:sessionId/end` | Yes | End session; release CKX session. |
| POST | `/exam-sessions/:sessionId/revoke` | Yes | Revoke access; release CKX session. |

---

## Session Enforcement Rules

1. **Starting an exam (POST /exam-sessions)**  
   - User must be authenticated.  
   - If exam has a product, user must have an **active entitlement** for that product (`validFrom ≤ now ≤ validUntil`, status ACTIVE).  
   - If exam has `maxAttempts`, count of user's completed/active sessions for that exam must be &lt; maxAttempts.  
   - On success: create ExamSession, call **CKX POST /api/sessions** with `ckxSessionId` and runtime config, set session ACTIVE and `endsAt = startedAt + durationMinutes`. Return `examUrl` with `sessionId=ckxSessionId` so client loads exam with that id.

2. **During exam (access)**  
   - Any route that needs “active exam” (e.g. GET `/exam-sessions/:sessionId/access`) checks:  
     - Session belongs to current user.  
     - Session status is ACTIVE.  
     - `endsAt > now`.  
   - If `endsAt` has passed: mark ExamSession EXPIRED, call **CKX DELETE /api/sessions/:ckxSessionId**, return 403.  
   - CKX never validates the user; Sailor only forwards valid sessionIds.

3. **End / revoke**  
   - **End:** User submits exam → POST `/exam-sessions/:sessionId/end` → set ExamSession ENDED, **CKX DELETE** that session.  
   - **Revoke:** Admin or payment/entitlement revoked → POST `/exam-sessions/:sessionId/revoke` → set REVOKED, **CKX DELETE**.  
   - Sailor API revokes access when time or payment expires; CKX stops serving once the session is released.

4. **Background expiry (optional)**  
   - A cron or scheduler can periodically find ExamSessions with `status = ACTIVE` and `endsAt < now`, then call the same “mark expired and release CKX” logic so access is revoked even if the client doesn’t call end.

---

## CKX Orchestration (from Sailor API)

- **Create:** When creating an exam session, Sailor calls **CKX `POST /api/sessions`** with body:  
  `{ sessionId, vnc: { host, port, password }, ssh: { host, port, username, password }, state, expiresAt? }`.  
  Sailor uses `ckxSessionId` (UUID) as `sessionId`. Runtime config comes from env (e.g. `CKX_DEFAULT_*`) or from an external orchestrator in production.

- **Release:** When ending or revoking, Sailor calls **CKX `DELETE /api/sessions/:sessionId`**.  
  CKX does not validate the caller’s identity; Sailor is the only service that creates and revokes sessions.

- **Client:** Never talks to CKX directly. Client gets `examUrl` and `ckxSessionId` from Sailor and loads the exam UI (served by Sailor or a frontend that calls only Sailor); the UI uses `sessionId` in requests that Sailor or the app server proxies to CKX.
