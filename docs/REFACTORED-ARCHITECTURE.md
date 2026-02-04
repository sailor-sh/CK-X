# CKX Refactored Architecture — Multi-Session Isolation

This document describes the refactored CKX app layer that enforces **per-session isolation**: no global runtime, no shared terminals or VNC, and session ownership purely via `sessionId`.

---

## 1. Refactored Architecture Overview

### Before (single global runtime)

- One global VNC config and one global SSH config in `server.js`.
- All clients shared the same `remote-desktop` and `remote-terminal` containers.
- Routes: `/api/vnc-info`, `/vnc-proxy`, `/websockify` with no session identity.
- Socket.IO `/ssh`: every connection went to the same SSH host.

### After (session-scoped runtime)

```
                    +------------------+
                    |  Sailor API      |  (injects sessionId; registers session with CKX)
                    +--------+---------+
                             |
                             v
+------------------+  /api/sessions/:sessionId/*   +------------------+
|  Client (exam UI)| ---------------------------->|  CKX Webapp       |
|  sessionId from  |  Socket.IO /ssh?sessionId=   |  - SessionRegistry|
|  URL (or default)|  sessionId                   |  - requireSession |
+------------------+                              +--------+---------+
                                                          |
         +------------------------------------------------+------------------------------------------------+
         |                                                |                                                |
         v                                                v                                                v
+----------------+                              +----------------+                              +----------------+
| Session A      |                              | Session B      |                              | Session C      |
| VNC container  |                              | VNC container  |                              | VNC container  |
| SSH container  |                              | SSH container   |                              | SSH container   |
| (or namespace) |                              | (or namespace) |                              | (or namespace) |
+----------------+                              +----------------+                              +----------------+
```

- **SessionRegistry:** In-memory map `sessionId → { vnc, ssh, state }`. No user identity. Populated by Sailor API (or orchestrator) via `POST /api/sessions` after provisioning a session’s containers.
- **All runtime paths require sessionId:** `/api/sessions/:sessionId/vnc-info`, `/api/sessions/:sessionId/runtime`, `/api/sessions/:sessionId/vnc-proxy`, `/api/sessions/:sessionId/websockify`, and Socket.IO `/ssh` with `query.sessionId`.
- **No global VNC/SSH:** Each request or connection is resolved to a session, then to that session’s `vnc` and `ssh` endpoints. Terminals and VNC are per-session by construction.

---

## 2. Key Code Changes (Summary)

### 2.1 New components

| File | Purpose |
|------|--------|
| `app/services/session-registry.js` | In-memory store: `set(sessionId, record)`, `get(sessionId)`, `delete(sessionId)`, `isRoutable(sessionId)`. Record: `{ state, vnc: { host, port, password }, ssh: { host, port, username, password } }`. |
| `app/middleware/session-resolver.js` | `requireSession(sessionRegistry)`: reads `req.params.sessionId`, loads session, checks routable; sets `req.sessionId`, `req.session`; 400/404/410 on missing or non-routable. |

### 2.2 Server (`app/server.js`)

- **Removed:** Single `SSHTerminal` and single `VNCService` config; global env-based VNC/SSH.
- **Added:** `SessionRegistry`; optional bootstrap of a `default` session from env for single-session dev.
- **VNC:** No global proxy. Mounts `requireSession` + `vncService.sessionVncProxy()` at `/api/sessions/:sessionId/vnc-proxy` and `requireSession` + `sessionWebsockifyProxy()` at `/api/sessions/:sessionId/websockify`. Target is `req.session.vnc` (per request).
- **SSH:** `/ssh` namespace. On connection, reads `socket.handshake.query.sessionId`, looks up session in registry, rejects if missing or not routable; creates a **new** `SSHTerminal(session.ssh)` and calls `handleConnection(socket)`. No shared terminal instance.

### 2.3 VNC service (`app/services/vnc-service.js`)

- **Removed:** Constructor config and global target; `setupVNCProxy(app)` and `getVNCInfo()`.
- **Added:** `sessionVncProxy()` and `sessionWebsockifyProxy()` that use `req.session.vnc` (set by `requireSession`) in `router` to choose upstream. `getVncInfoForSession(sessionId, session)` for API responses with session-scoped `wsUrl` and `vncProxyPath`.

### 2.4 Route service (`app/services/route-service.js`)

- **Removed:** `GET /api/vnc-info` (global).
- **Added:** `GET /api/sessions/:sessionId/runtime` and `GET /api/sessions/:sessionId/vnc-info` (both behind `requireSession`); `POST /api/sessions` (register session); `DELETE /api/sessions/:sessionId` (release). Constructor takes `sessionRegistry` and `requireSession` factory.

### 2.5 SSH terminal (`app/services/ssh-terminal.js`)

- **Unchanged** at module level: still one config per instance, `handleConnection(socket)`. Isolation is achieved by **creating a new SSHTerminal with the session’s SSH config** for each Socket.IO connection in `server.js`, so no shared terminal process.

### 2.6 Frontend

- **exam-api.js:** `getSessionId()` (from URL param `sessionId`, fallback `'default'`); `getVncInfo(sessionId)` → `GET /api/sessions/${sessionId}/vnc-info`.
- **remote-desktop-service.js:** `connectToRemoteDesktop(vncFrame, statusCallback, sessionId)`; uses `getVncInfo(sessionId)` and `data.vncProxyPath` / `data.wsUrl` for the iframe.
- **terminal-service.js:** `initTerminal(containerElement, isActive, sessionId)`; `connectToSocketIO(sessionId)` with `query: { sessionId }`.
- **exam.js:** Reads `sessionId = ExamApi.getSessionId()` once; passes `sessionId` into every `connectToRemoteDesktop(..., sessionId)` and `initTerminal(..., sessionId)`.

### 2.7 Nginx

- **Removed:** `location /websockify` that proxied directly to `remote-desktop:6901`. All VNC traffic now goes through the webapp’s session-scoped routes (`/api/sessions/:sessionId/...`).

---

## 3. How Session Isolation Is Guaranteed

### 3.1 sessionId is mandatory

- **HTTP:** Every runtime API and proxy path includes `:sessionId`. The middleware `requireSession` runs first: it resolves `sessionId` from the path, loads the session from the registry, and checks that the session is routable. If `sessionId` is missing, invalid, or the session is not found/not routable, the request is rejected (400, 404, or 410). No request reaches VNC or terminal logic without a valid, routable session.
- **WebSocket (Socket.IO):** The client must send `sessionId` in the handshake query. The server rejects the connection if `sessionId` is missing, the session is not in the registry, or the session is not routable. Only then is a new `SSHTerminal(session.ssh)` created for that socket. So each socket is bound to exactly one session’s SSH backend.

### 3.2 No shared globals for runtime

- There is no single process-wide VNC or SSH connection. The server does not hold a global `sshTerminal` or a global proxy target. For each request or socket connection, the session is looked up by `sessionId`, and the session’s `vnc` and `ssh` config are used to create or target the backend. So one user (session A) cannot see or use another session’s (B’s) VNC or terminal, because:
  - VNC: proxy target is chosen per request from `req.session.vnc` after `requireSession`.
  - SSH: each Socket.IO connection gets a new SSH client to `session.ssh`; there is no shared terminal instance.

### 3.3 Registry is the single source of truth

- Only sessions present in the registry and in a routable state can receive traffic. Sailor API (or the orchestrator) registers a session with `POST /api/sessions` **after** it has provisioned that session’s isolated environment (containers/namespace). CKX does not provision; it only routes by `sessionId` to the endpoints stored in the registry. So isolation at the infrastructure level (one container or namespace per session) is reflected in the registry (one record per session with that session’s endpoints), and the app layer never mixes sessions.

### 3.4 Backward compatibility (single-session dev)

- If env vars `VNC_SERVICE_HOST` or `SSH_HOST` are set, a single session with `sessionId = 'default'` (or `DEFAULT_SESSION_ID`) is bootstrapped at startup. The client can omit `sessionId` in the URL and `getSessionId()` returns `'default'`, so existing single-session setups still work. In production, Sailor API injects a real `sessionId` and registers each session; there is no shared default session across users.

---

## 4. What CKX Does Not Do

- **No user identity or payment:** The registry and all APIs use only `sessionId`. No user id, tenant, or payment logic.
- **No provisioning:** CKX does not create or destroy containers or namespaces. It only stores and uses endpoints provided by Sailor API (or an external orchestrator) via `POST /api/sessions`.
- **No auth:** CKX does not validate tokens or cookies. Sailor API is responsible for only forwarding valid sessionIds (e.g. by proxying with a session binding or issuing short-lived session tokens).

This refactor establishes the **app-layer** contract for multi-session isolation; full isolation also requires that each session has its own VNC and SSH runtime (containers/namespace), which is the responsibility of the orchestrator and is documented in [MULTI-SESSION-EXECUTION-MODEL.md](MULTI-SESSION-EXECUTION-MODEL.md).
