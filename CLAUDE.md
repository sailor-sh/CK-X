# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CK-X is a Kubernetes certification exam simulator (CKAD, CKA, CKS) providing a realistic browser-based exam environment with VNC remote desktop, SSH terminals, and a KIND Kubernetes cluster. It uses Docker Compose to orchestrate all services on a private bridge network (`ckx-network`), with only nginx exposed on port 30080.

## Architecture

The system has three main layers with strict boundaries (see `docs/ARCHITECTURE-CONTRACT.md`):

**Sailor Client** (React/TypeScript) → **Sailor API** (Express/Prisma) → **CKX Webapp** (Express session router)

- **Sailor Client** (`sailor-client/`): React 19 + Vite + TypeScript frontend. Handles login, exam selection, active session UI. **Never talks directly to CKX** — all access goes through Sailor API.
- **Sailor API** (`sailor-api/`): Express + Prisma + PostgreSQL. Owns auth (JWT), payments, exam definitions, session lifecycle. Proxies facilitator and CKX endpoints. Port 4000.
- **CKX Webapp** (`app/`): Express server with session-scoped VNC/SSH routing. Stateless — keyed entirely by `sessionId`. No user identity, no auth, no payments. Port 3000.
- **Facilitator** (`facilitator/`): Express backend for exam operations (SSH to jumphost, assessment, question management). Uses Redis for caching. Port 3000 internally.

**Infrastructure containers** (not Node.js apps):
- `remote-desktop/` — VNC server (ConSol Ubuntu)
- `remote-terminal/` — SSH terminal
- `jumphost/` — SSH jumphost for exam environment access
- `kind-cluster/` — KIND Kubernetes cluster (privileged container)
- `nginx/` — Reverse proxy, only externally-exposed service (port 30080)
- `redis` — Cache for facilitator

### Two Operational Modes

1. **Docker Compose standalone** (CKX + infra only): Access via `http://localhost:30080`. Nginx routes `/` to webapp:3000, `/facilitator/api/` to facilitator:3000, `/vnc-proxy/` to webapp:3000. CKX serves its own exam UI directly.
2. **Full Sailor stack** (Sailor Client → Sailor API → CKX): Sailor Client talks only to Sailor API (port 4000). CKX is loaded inside an iframe via Sailor API proxy URLs. Sailor API rewrites CKX responses to route facilitator calls back through itself.

### Key Constraint

CKX must NOT handle auth, payments, or user identity. Sailor API must NOT delegate session lifecycle to CKX. Sailor Client must NOT call CKX directly.

### Session Isolation Model

**Infrastructure Isolation** (Container Orchestrator):
Each exam session gets its own isolated VNC desktop and terminal containers, provisioned dynamically via Docker API. This ensures users cannot see each other's desktops or terminal sessions.

- `sailor-api/src/services/container-orchestrator.js` — Creates/destroys per-session containers using `dockerode`
- Containers named `ckx-vnc-{sessionId12}` and `ckx-terminal-{sessionId12}` on `ckx-network`
- Env var `CKX_ISOLATION_MODE=container` (default) enables per-session containers; `=shared` uses single shared containers (dev fallback)
- Containers are cleaned up on session end, expiry, or by periodic orphan cleanup

**Routing Isolation** (CKX Webapp):
CKX enforces per-session routing via `SessionRegistry` (`app/services/session-registry.js` — in-memory map of `sessionId → {vnc, ssh, state}`). All HTTP routes require `:sessionId` parameter; Socket.IO SSH connections require `sessionId` in handshake query. The `requireSession` middleware (`app/middleware/session-resolver.js`) resolves the session and rejects invalid/missing IDs (400/404/410).

For single-session dev, setting `VNC_SERVICE_HOST`/`SSH_HOST` env vars bootstraps a `default` session automatically.

### CKX-in-Iframe Proxy Flow (Sailor API)

When the Sailor Client renders an active exam, CKX is loaded inside an `<iframe>`. Since iframes can't send Authorization headers, a capability-based **iframeToken** (custom HMAC-SHA256, not jsonwebtoken) is used:

1. Sailor Client calls `GET /exam-sessions/:id/iframe-token` (with JWT auth) to get a short-lived token (10min)
2. Iframe src is set to `/ckx/sessions/:ckxSessionId/vnc-proxy/?iframeToken=...`
3. Sailor API validates the iframeToken, then proxies to CKX with the token stripped

**Key files:**
- `sailor-api/src/lib/iframe-token.js` — Token create/verify (custom HMAC, not jwt lib)
- `sailor-api/src/middleware/iframe-token-auth.js` — iframeToken validation middleware
- `sailor-api/src/routes/ckx-proxy.js` — VNC/terminal proxy with HTML/JS response rewriting

**Response rewriting** (`ckx-proxy.js`):
- **HTML**: Asset paths made relative, iframeToken appended to asset URLs, fetch monkey-patch injected in `<head>` to rewrite `/facilitator/api/v1/*` → `/exam-sessions/:id/fproxy/*` with iframeToken
- **JS**: Page navigation paths (`/exam.html?`, `/results?`, `'/'`) rewritten to relative paths with iframeToken
- **fproxy route**: Catch-all `/:sessionId/fproxy/*` in `exam-sessions.js` proxies to facilitator

### Middleware Stack (Sailor API Proxy Routes)

```
/ckx/sessions/:ckxSessionId/vnc-proxy
├── [1] Extract ckxSessionId → set req.params.sessionId
├── [2] validateIframeToken (if present: verify sig, expiry, session match; set req.user)
├── [3] resolveExamSession (by ckxSessionId)
├── [4] requireAuth (skipped if iframeToken already validated)
├── [5] requireActiveExamSession (ownership, status, expiry)
└── [6] http-proxy-middleware → CKX (with selfHandleResponse for rewriting)
```

## Development Commands

### Full Stack (Docker Compose)
```bash
docker compose up --build              # Build and start all services
docker compose up -d                   # Start in background
docker compose down                    # Stop all services
docker compose logs -f <service>       # Follow logs for a service
docker compose exec <service> bash     # Shell into a container
docker compose up --build <service>    # Rebuild and restart single service
```

Access at `http://localhost:30080` after startup.

### Individual Services (local dev)

**Sailor API** (requires PostgreSQL running):
```bash
cd sailor-api
cp .env.example .env                   # Configure DATABASE_URL, JWT_SECRET, etc.
npm install
npm run db:generate                    # Generate Prisma client
npm run db:push                        # Push schema to database
npm run db:migrate                     # Run migrations (production)
npm run db:seed                        # Seed demo data
npm run db:studio                      # Prisma GUI
npm run dev                            # node --watch src/app.js (port 4000)
```

**Sailor Client**:
```bash
cd sailor-client
npm install
npm run dev                            # Vite dev server
npm run build                          # tsc + vite build
npm run lint                           # ESLint
```

**Facilitator**:
```bash
cd facilitator
npm install
npm run dev                            # nodemon (port 3000)
```

**CKX Webapp**:
```bash
cd app
npm install
npm run dev                            # nodemon server.js (port 3000)
```

## Database

Sailor API uses Prisma with PostgreSQL. Schema at `sailor-api/prisma/schema.prisma`.

Core models: `User`, `Product` (exam SKU), `Exam`, `ExamQuestion`, `ExamSession` (lifecycle: CREATED → PROVISIONING → ACTIVE → ENDED/EXPIRED/REVOKED), `Entitlement`, `Payment`. Exam modes: `MOCK` (free, shorter duration) and `FULL` (paid, strict timer).

## Environment Configuration

- **Sailor API**: `.env` from `.env.example` — DATABASE_URL, JWT_SECRET, CKX_BASE_URL, FACILITATOR_BASE_URL, IFRAME_TOKEN_SECRET (optional, falls back to JWT_SECRET), CKX_DEFAULT_* (dev VNC/SSH defaults), CKX_API_KEY (shared secret for CKX admin endpoints), CKX_ISOLATION_MODE (container|shared), CKX_DOCKER_NETWORK, CKX_VNC_IMAGE, CKX_TERMINAL_IMAGE
- **Facilitator**: env vars for SSH_HOST, SSH_PORT, SSH_USERNAME, REDIS_HOST, REDIS_PORT, LOG_LEVEL
- **CKX Webapp**: VNC_SERVICE_HOST, VNC_SERVICE_PORT, VNC_PASSWORD, SSH_HOST, SSH_PORT, SSH_USER, SSH_PASSWORD, CKX_INTERNAL_API_KEY (must match Sailor API's CKX_API_KEY), CKX_DEV_SKIP_OWNERSHIP (dev only: set to "true" to allow query param ownerId bypass)

## Code Patterns

- All backend services use Express.js with similar middleware patterns (cors, helmet where applicable, JSON body parsing)
- Facilitator uses Winston for logging, Joi for validation, controller/service/route separation
- Sailor API uses Prisma for DB access, JWT middleware for auth, http-proxy-middleware for CKX proxying
- Sailor Client uses React Router DOM for routing, AuthProvider context for auth state, axios-based `api.ts` utility for HTTP
- CKX Webapp uses Socket.IO for real-time SSH terminal, http-proxy for VNC proxying
- All services are plain JavaScript except sailor-client (TypeScript)

## Linting

Only `sailor-client` has ESLint configured (flat config format in `eslint.config.js`). Run with `npm run lint` from `sailor-client/`. No tests are currently implemented in any package.

## Docker Network

All containers communicate via service names on `ckx-network` bridge. Shared volumes: `kube-config` (Kubernetes config between jumphost and kind-cluster). Only nginx is exposed externally (port 30080→80).

## Known Pitfalls

- **Never append query params mid-URL**: String concat like `appendToken(url) + '/'` puts the trailing slash AFTER the query string, corrupting token values.
- **Static regex replacement breaks template literals**: Regex like `/\/exams\/(?!current)/g` matches template literal expressions like `${examId}` and corrupts dynamic URLs. Use runtime interception (fetch monkey-patch) instead.
- **Express 4 `req.query` caching**: Once accessed by middleware, `req.query` becomes a plain property that survives `req.url` modifications by proxy handlers.
- **Express 4 `strict:false`**: Router matches both `/path` and `/path/` by default.
- **iframeToken is NOT a JWT**: It uses custom HMAC-SHA256 signing in `sailor-api/src/lib/iframe-token.js`. Do not use the `jsonwebtoken` library for it.
