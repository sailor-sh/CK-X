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
- `nginx/` — Reverse proxy, only externally-exposed service
- `redis` — Cache for facilitator

### Session Isolation Model

CKX enforces per-session isolation via `SessionRegistry` (in-memory map of `sessionId → {vnc, ssh, state}`). All HTTP routes require `:sessionId` parameter; Socket.IO SSH connections require `sessionId` in handshake query. The `requireSession` middleware resolves the session and rejects invalid/missing IDs (400/404/410). No global VNC or SSH connections exist — each request creates connections from the session's stored endpoints.

For single-session dev, setting `VNC_SERVICE_HOST`/`SSH_HOST` env vars bootstraps a `default` session automatically.

### Key Constraint

CKX must NOT handle auth, payments, or user identity. Sailor API must NOT delegate session lifecycle to CKX. Sailor Client must NOT call CKX directly.

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

- **Sailor API**: `.env` from `.env.example` — DATABASE_URL, JWT_SECRET, CKX_BASE_URL, FACILITATOR_BASE_URL, CKX_DEFAULT_* (dev VNC/SSH defaults)
- **Facilitator**: env vars for SSH_HOST, SSH_PORT, SSH_USERNAME, REDIS_HOST, REDIS_PORT, LOG_LEVEL
- **CKX Webapp**: VNC_SERVICE_HOST, VNC_SERVICE_PORT, VNC_PASSWORD, SSH_HOST, SSH_PORT, SSH_USER, SSH_PASSWORD

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

All containers communicate via service names on `ckx-network` bridge. Shared volumes: `kube-config` (Kubernetes config between jumphost and kind-cluster), `redis-data`.
