# Sailor Client

React + TypeScript client that talks to **Sailor API only** (REST). It never calls CKX directly.

## Non-negotiable rules

- **Frontend NEVER calls CKX directly**
- All access is mediated by **Sailor API**
- Terminal/VNC access is loaded via **Sailor API proxy URLs**
- **Safe resume**: before reconnecting to an active session, the client always calls `GET /exam-sessions/:id/access`

## Setup

1. Configure API base URL:

```bash
cp .env.example .env
```

2. Install & run:

```bash
npm install
npm run dev
```

## Pages

- **Login / Signup**
- **Dashboard**: shows active sessions and recent attempts; resume is safe by default
- **Exam selection**: start **Mock** or **Full**
- **Active exam session**: validates access then embeds VNC via Sailor API proxy URL
- **Results per exam attempt**

## Required Sailor API endpoints

Already used:
- `POST /auth/login`, `POST /auth/register`, `GET /auth/me`
- `GET /exams`
- `POST /exam-sessions` (with `{ examId, mode: 'MOCK' | 'FULL' }`)
- `GET /exam-sessions`
- `GET /exam-sessions/:id`
- `GET /exam-sessions/:id/access`
- `POST /exam-sessions/:id/end`

For VNC/terminal (must be proxied; no direct CKX calls):
- `GET /ckx/sessions/:ckxSessionId/vnc-proxy/*` (proxy to CKX `/api/sessions/:ckxSessionId/vnc-proxy/*`)
- (optional) a WebSocket proxy for CKX `/ssh` (terminal)

