# Architecture Contract: CKX, Sailor API, Sailor Client

This document defines the **strict system boundary** between three systems. All future phases (CKX, Sailor API, Sailor Client) must obey this contract.

---

## 1. Hard Constraints

| # | Constraint |
|---|------------|
| 1 | **CKX must NOT** handle authentication, payments, user identity, or time/access rules. |
| 2 | **CKX** exposes a **stateless API** driven **entirely by `sessionId`**. No user tokens, no tenant context. |
| 3 | **Sailor API** owns users, payments, exam rules, and **session lifecycle** (create, extend, revoke). |
| 4 | **Sailor Client** must **never** talk directly to CKX. All CKX access is via Sailor API. |

---

## 2. Responsibility Matrix

| Responsibility | CKX | Sailor API | Sailor Client |
|----------------|-----|------------|---------------|
| **Authentication** | ❌ None | ✅ Owns (login, tokens, sessions) | ✅ Consumes (sends tokens to Sailor API only) |
| **Authorization / access rules** | ❌ None | ✅ Who can start/continue exam, time windows | ✅ Enforces UI based on API responses |
| **Payments / billing** | ❌ None | ✅ Owns (subscriptions, one-time, entitlements) | ✅ Consumes (checkout, status) |
| **User identity & profile** | ❌ None | ✅ Owns | ✅ Displays only |
| **Exam rules (duration, attempts, syllabus)** | ❌ None | ✅ Owns and enforces | ✅ Displays only |
| **Session lifecycle** | ❌ Stateless executor only | ✅ Create, extend, revoke, expire sessions | ✅ Requests start/continue via API |
| **Session → CKX binding** | ❌ Accepts `sessionId` only | ✅ Creates session, gets CKX URL/token, passes to client | ❌ Never sees CKX directly |
| **Exam execution (questions, timer, env)** | ✅ Renders UI, runs lab, timer | ❌ No execution logic | ❌ No direct execution; uses Sailor API → CKX flow |
| **Lab environment (VNC, terminal, cluster)** | ✅ Provisions & serves | ❌ No control of lab internals | ❌ No direct access |
| **Question/answer content** | ✅ Receives per session, displays & collects | ✅ Stores, selects, scores; sends to CKX per session | ✅ Renders only what API/CKX provide via Sailor API |
| **Scoring / evaluation** | ✅ Runs evaluation scripts if defined | ✅ Stores results, computes grade, policy | ✅ Displays results from Sailor API |
| **Telemetry / events** | ✅ May emit session-scoped events | ✅ Ingests, stores, analytics | ✅ Sends events to Sailor API only |
| **Static assets (exam UI shell)** | ✅ Serves (or Sailor API proxies) | ✅ Decides when to redirect to CKX | ✅ Loads from Sailor API or redirected URL |

**Legend:** ✅ = owns or performs; ❌ = must not own or perform.

---

## 3. Public CKX API Contract (Inputs/Outputs Only)

CKX is **session-scoped**. Every operation is keyed by `sessionId`. No cookies or bearer tokens for “user” auth; Sailor API is responsible for ensuring only valid sessions reach CKX (e.g. by issuing short-lived session tokens or by proxying with session binding).

### 3.1 Session context

- **Input:** `sessionId` (opaque string, provided by Sailor API when creating/continuing a session).
- **Implication:** CKX does not interpret user id, tenant id, or payment state. It trusts that the caller (Sailor API or a client carrying a Sailor-issued session token) is allowed to use that `sessionId`.

### 3.2 Get session runtime info

- **Purpose:** Return connection/runtime details for the lab (e.g. VNC URL, WebSocket path, terminal endpoint) so the client (via Sailor API) can render the exam UI.
- **Input:** `sessionId`.
- **Output:**  
  - `vncInfo`: { `url`, `path`, optional `password` or token }  
  - `terminalInfo`: { `wsPath` or equivalent }  
  - `status`: `ready` | `provisioning` | `error`  
  - Optional: `expiresAt` (if CKX manages session TTL for lab only).

### 3.3 Get exam content for session

- **Purpose:** Return questions and metadata for this session (content may be preloaded by Sailor API at session create, or CKX may fetch from Sailor API; contract is inputs/outputs only).
- **Input:** `sessionId`.
- **Output:**  
  - `questions`: array of { `id`, `body`, `type`, optional `options`, … }  
  - `durationMinutes`: number (for timer)  
  - Optional: `startedAt`, `endsAt` (if CKX stores them; otherwise Sailor API owns time).

### 3.4 Submit answers / events (telemetry)

- **Purpose:** Record answers or events for the session (storage/forwarding to Sailor API is an implementation detail).
- **Input:** `sessionId`, `answers` and/or `events` (e.g. question viewed, answer changed, tab focus).
- **Output:** `accepted`: boolean, optional `error` message.

### 3.5 Request evaluation (score run)

- **Purpose:** Trigger evaluation for the session (e.g. run scripts in lab, collect scores).
- **Input:** `sessionId`.
- **Output:**  
  - `evaluationId` or `jobId` (if async)  
  - `status`: `completed` | `running` | `failed`  
  - Optional: `score`, `details` (per-question or aggregate).

### 3.6 Get evaluation result

- **Purpose:** Poll or fetch result of a previous evaluation (if CKX evaluation is async).
- **Input:** `sessionId`, optional `evaluationId`.
- **Output:** Same shape as 3.5 (status, score, details).

### 3.7 End / release session (lab teardown)

- **Purpose:** Signal that the exam session is finished; CKX can tear down lab resources. Session validity remains Sailor API’s responsibility.
- **Input:** `sessionId`.
- **Output:** `released`: boolean, optional `error` message.

### 3.8 Health (no session)

- **Purpose:** Liveness/readiness for orchestration; no business logic.
- **Input:** None (or standard health query).
- **Output:** `status`: `ok` | `degraded` | `unhealthy`, optional details.

### 3.9 Contract summary table

| Operation | Input | Output |
|-----------|--------|--------|
| Get session runtime info | `sessionId` | `vncInfo`, `terminalInfo`, `status` [, `expiresAt`] |
| Get exam content | `sessionId` | `questions`, `durationMinutes` [, `startedAt`, `endsAt`] |
| Submit answers/events | `sessionId`, `answers`/`events` | `accepted` [, `error`] |
| Request evaluation | `sessionId` | `evaluationId`/`jobId`, `status` [, `score`, `details`] |
| Get evaluation result | `sessionId` [, `evaluationId`] | `status`, `score`, `details` |
| End/release session | `sessionId` | `released` [, `error`] |
| Health | — | `status` [, details] |

---

## 4. Sequence Diagram: Start Exam Session

Text-based (Mermaid-style) sequence for **starting an exam session**. Sailor Client never talks to CKX.

```text
participants:
  User
  Sailor Client
  Sailor API
  CKX

sequence:

  User -> Sailor Client: "Start exam" (e.g. choose exam/product)
  Sailor Client -> Sailor API: POST /exams/{examId}/sessions (or similar)
                              Authorization: Bearer <user token>
                              Body: optional preferences

  Note over Sailor API: Validate user, payment, exam rules, time window

  Sailor API -> Sailor API: Create session record; generate sessionId
  Sailor API -> CKX: Create/bind session (e.g. POST /sessions or internal)
                    Input: sessionId, exam config (questions, duration, lab type)

  CKX -> CKX: Provision lab (cluster/VNC/terminal), load content for sessionId
  CKX -> Sailor API: Session ready (or async callback / status poll)

  Sailor API -> Sailor Client: 201 Created
                              Body: { sessionId, examUrl, expiresAt, ... }
                              examUrl = Sailor API URL that proxies to CKX with sessionId
                              OR one-time URL that encodes session token for CKX

  Sailor Client -> User: Redirect or open examUrl (same origin as Sailor API or proxy)

  Note over Sailor Client, CKX: All subsequent exam traffic: Client -> Sailor API -> CKX
  Sailor Client -> Sailor API: GET /sessions/{sessionId}/runtime (or proxy to CKX)
  Sailor API -> CKX: Get session runtime info (sessionId)
  CKX -> Sailor API: vncInfo, terminalInfo, status
  Sailor API -> Sailor Client: runtime info + exam content (from API or CKX)

  Sailor Client -> User: Render exam UI (questions, timer, VNC/terminal from runtime info)
```

**Summary:** Sailor API is the only system that creates sessions and talks to CKX. The client only receives a `sessionId` and an URL that goes through Sailor API (or a Sailor-issued session token that CKX accepts as `sessionId`). All exam actions (get content, submit answers, evaluate, end session) follow the same pattern: **Sailor Client → Sailor API → CKX** by `sessionId`.

---

## 5. Out of scope for this contract

- Exact HTTP paths, status codes, or wire format (JSON schema).
- How Sailor API authenticates to CKX (API key, mTLS, internal network).
- How Sailor API proxies vs redirects (e.g. reverse proxy vs redirect with token).
- Database or deployment topology of any system.
- Sailor Client UX or technology stack.

---

## 6. Compliance

- **CKX:** Must not add endpoints or logic that accept user credentials, tenant id, or payment flags; all operations must be keyed by `sessionId` (or a Sailor-issued session token that maps 1:1 to `sessionId`).
- **Sailor API:** Must not delegate auth, payments, or session lifecycle to CKX; must be the single gateway to CKX for the Sailor Client.
- **Sailor Client:** Must not call CKX directly; all exam and session calls go to Sailor API.

This document is the **system boundary definition** that future phases must obey.
