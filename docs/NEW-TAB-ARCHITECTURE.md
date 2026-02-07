# New-Tab Lab Launch Architecture

## Overview

This document describes the new architecture for launching labs in a dedicated browser tab instead of embedding them via iframes. This change eliminates CSP conflicts, auth token leakage, and complex proxy path rewriting issues.

## Architecture Diagram

```
┌─────────────────────────────────────┐     ┌─────────────────────────────────────┐
│ Browser Tab 1: Sailor Dashboard     │     │ Browser Tab 2: Lab Environment      │
│                                     │     │                                     │
│ ┌─────────────────────────────────┐ │     │ ┌─────────────────────────────────┐ │
│ │ ActiveExamSessionPage.tsx       │ │     │ │ CKX exam.html                   │ │
│ │                                 │ │     │ │                                 │ │
│ │ - Timer display                 │ │     │ │ - VNC desktop (full page)       │ │
│ │ - Session status                │ │     │ │ - Terminal                      │ │
│ │ - "Open Lab" button ────────────┼─┼─────┼─│ - Questions panel               │ │
│ │ - "End Session" button          │ │     │ │                                 │ │
│ │                                 │ │     │ │ Auth: Session cookie            │ │
│ │ Auth: JWT in localStorage       │ │     │ │ (set during /launch handoff)    │ │
│ └─────────────────────────────────┘ │     │ └─────────────────────────────────┘ │
│                                     │     │                                     │
│ Polls: GET /exam-sessions/:id       │     │ Direct requests to CKX (no proxy)   │
│ every 10s for status updates        │     │                                     │
└──────────────────┬──────────────────┘     └──────────────────┬──────────────────┘
                   │                                           │
                   │ HTTPS                                     │ HTTPS
                   │                                           │
                   ▼                                           ▼
          ┌────────────────┐                          ┌────────────────┐
          │ Sailor API     │◄─────── validate ────────│ CKX Server     │
          │ :4000          │        launch token      │ :3000          │
          │                │                          │                │
          │ - Auth (JWT)   │                          │ - /launch      │
          │ - Sessions     │                          │ - VNC proxy    │
          │ - Launch tokens│                          │ - SSH terminal │
          └────────────────┘                          └────────────────┘
```

## Flow: Opening a Lab

### 1. User Clicks "Open Lab"

```
Sailor Client                    Sailor API
     │                               │
     │  POST /exam-sessions/:id/     │
     │       launch-token            │
     │ ─────────────────────────────>│
     │                               │
     │  { launchUrl, launchToken,    │
     │    expiresIn: 60 }            │
     │ <─────────────────────────────│
     │                               │
     │  window.open(launchUrl)       │
     │ ─────────────────────────────────────────────>  Browser Tab 2
```

### 2. Launch Token Handoff

```
Browser Tab 2                    CKX Server                   Sailor API
     │                               │                            │
     │  GET /launch?token=xyz        │                            │
     │ ─────────────────────────────>│                            │
     │                               │                            │
     │                               │  POST /launch-tokens/      │
     │                               │       validate             │
     │                               │  { token: "xyz" }          │
     │                               │ ──────────────────────────>│
     │                               │                            │
     │                               │  { valid: true,            │
     │                               │    sessionId, userId }     │
     │                               │ <──────────────────────────│
     │                               │                            │
     │  Set-Cookie: ckx_session=abc  │                            │
     │  302 Redirect /exam.html?     │                            │
     │      sessionId=...            │                            │
     │ <─────────────────────────────│                            │
     │                               │                            │
     │  GET /exam.html?sessionId=... │                            │
     │  Cookie: ckx_session=abc      │                            │
     │ ─────────────────────────────>│                            │
```

### 3. Subsequent Requests

After the launch handoff, all requests from the lab tab use the session cookie:

```
Browser Tab 2                    CKX Server
     │                               │
     │  GET /api/sessions/:id/...    │
     │  Cookie: ckx_session=abc      │
     │ ─────────────────────────────>│
     │                               │
     │  (CKX validates cookie,       │
     │   serves VNC/terminal)        │
     │ <─────────────────────────────│
```

## Token Types

### JWT (Sailor API)
- **Purpose**: Authenticate user with Sailor platform
- **Lifetime**: 7 days (configurable)
- **Storage**: localStorage in browser
- **Used by**: Sailor Client only

### Launch Token
- **Purpose**: One-time handoff from Sailor to CKX
- **Lifetime**: 60 seconds
- **Storage**: In-memory on Sailor API (use Redis for multi-instance)
- **Consumed**: Yes, single-use
- **Contains**: sessionId, userId, examSessionId

### Session Cookie (CKX)
- **Purpose**: Authenticate requests to CKX after launch
- **Lifetime**: 24 hours (or until session ends)
- **Storage**: httpOnly cookie
- **Set by**: CKX /launch endpoint after validating launch token

## File Changes Summary

### New Files

| File | Purpose |
|------|---------|
| `sailor-api/src/lib/launch-token.js` | Create/validate launch tokens |
| `sailor-api/src/routes/launch-tokens.js` | Launch token validation API |
| `app/services/launch-service.js` | CKX launch service |

### Modified Files

| File | Changes |
|------|---------|
| `sailor-api/src/app.js` | Register launch-tokens routes |
| `sailor-api/src/routes/exam-sessions.js` | Add `/launch-token` endpoint |
| `app/server.js` | Add `/launch` route, cookie-parser |
| `app/package.json` | Add cookie-parser dependency |
| `sailor-client/src/pages/ActiveExamSessionPage.tsx` | Replace iframe with "Open Lab" button |

### Deprecated Files (to be removed later)

| File | Reason |
|------|--------|
| `sailor-api/src/routes/ckx-proxy.js` | No longer needed - no iframe proxying |
| `sailor-api/src/routes/ckx-vnc-info.js` | No longer needed |
| `sailor-api/src/middleware/iframe-token-auth.js` | Replaced by launch tokens |
| `sailor-api/src/lib/iframe-token.js` | Replaced by launch tokens |

## Security Benefits

1. **No token in URLs after handoff**: Launch token is consumed immediately; session cookie is httpOnly
2. **No token leakage via Referer**: Session cookie doesn't appear in Referer headers
3. **No CSP conflicts**: Lab runs in dedicated tab, not embedded
4. **Clear auth boundaries**: Sailor owns JWT, CKX owns session cookie
5. **One-time tokens**: Launch tokens can't be replayed

## Scaling Considerations

### Current (In-Memory)

The launch token store and session cookie store are currently in-memory:

```javascript
// In-memory stores
const launchTokenStore = new Map();
const sessionCookieStore = new Map();
```

### Production (Redis)

For multi-instance deployments, replace with Redis:

```javascript
// Use Redis for distributed stores
const redis = require('redis');
const client = redis.createClient();

async function createLaunchToken(...) {
  const tokenId = crypto.randomBytes(32).toString('hex');
  await client.setex(`launch:${tokenId}`, 60, JSON.stringify(data));
  // ...
}
```

## Session Lifecycle

| Event | Behavior |
|-------|----------|
| User clicks "Open Lab" | New tab opens, launch token consumed, session cookie set |
| User closes lab tab | Session persists; user can re-open with new launch token |
| User refreshes lab tab | Session cookie still valid; lab reloads normally |
| Timer expires | Sailor marks session EXPIRED; CKX access denied on next request |
| User clicks "End Session" | Sailor marks session ENDED; CKX access denied |
| Session cookie expires | User must get new launch token from Sailor |

## Migration Path

1. Deploy new launch token infrastructure (Sailor API + CKX)
2. Update Sailor Client to use "Open Lab" button
3. Monitor for issues during transition period
4. Remove deprecated iframe/proxy code after successful migration

## Troubleshooting

### "Pop-up blocked"
Browser blocked the new tab. User must allow pop-ups for the site.

### "Invalid or expired token"
Launch token expired (60s) or was already used. Click "Open Lab" again.

### "Session not found"
CKX doesn't have the session in its registry. Check if Sailor successfully created the CKX session.

### "Invalid session cookie"
Session cookie expired or was invalidated. Get a new launch token.
