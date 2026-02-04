# Sailor API

Business control plane for the exam platform: **user auth**, **payments**, **exam definitions**, **ExamSession lifecycle**, and **CKX session orchestration**. CKX never validates users; Sailor API creates and revokes CKX sessions and enforces time/payment rules.

## Stack

- **Node.js** + **Express**
- **PostgreSQL** + **Prisma ORM**

## Setup

1. Copy env and set `DATABASE_URL` and `JWT_SECRET`:
   ```bash
   cp .env.example .env
   ```
2. Create DB and run migrations:
   ```bash
   npm install
   npx prisma generate
   npx prisma db push
   npx prisma db seed
   ```
3. Start API:
   ```bash
   npm run dev
   ```
   Default port: 4000.

## Config

- `DATABASE_URL` — PostgreSQL connection string
- `JWT_SECRET` — Signing key for JWTs (min 32 chars in production)
- `CKX_BASE_URL` — CKX app URL (for creating/releasing sessions)
- `CKX_DEFAULT_*` — Default VNC/SSH config for single-node dev (see `.env.example`)
- `SAILOR_API_PUBLIC_URL` — Public base URL (for building `examUrl` in session create)

## API Overview

| Area | Purpose |
|------|--------|
| **Auth** | Register, login, `GET /auth/me` (JWT) |
| **Payments** | Products, entitlements, checkout stub, complete payment |
| **Exams** | List/get exams, get questions |
| **Exam sessions** | Create (entitlement + attempts enforced, CKX session created), get, access check, end, revoke |

See [docs/API.md](docs/API.md) for full REST endpoints and **session enforcement rules**.

## Session enforcement

- **Start exam:** User must have valid entitlement for the exam’s product and (if set) attempt count &lt; maxAttempts. Sailor creates an ExamSession and a CKX session, returns `examUrl` with `sessionId`.
- **During exam:** Access checks require session ACTIVE and `endsAt > now`. If expired, Sailor marks session EXPIRED and releases the CKX session (403 to client).
- **End / revoke:** Sailor sets session ENDED/REVOKED and calls CKX to release the session. Sailor API revokes access when time or payment expires; CKX does not validate users.

## Demo user (after seed)

- Email: `demo@sailor.dev`
- Password: `demo1234`

Grant entitlement for the seeded product (e.g. `POST /payments/entitlements` with `productId` of "CKAD Practice Access") then `POST /exam-sessions` with that exam’s `examId` to get an `examUrl`.
