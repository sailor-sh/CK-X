# Fix: Session Status Endpoint Returning HTML Instead of JSON

## Problem
The `/api/sessions/:sessionId/status` endpoint was returning HTML (`<!DOCTYPE html>`) instead of JSON, causing `JSON.parse` to fail and exam sessions to show "UNKNOWN" status with infinite loading.

## Root Cause
The catch-all route `app.get('*', ...)` in `route-service.js` was matching API routes and serving `index.html` before the specific API route handler could process the request.

## Fixes Applied

### 1. Fixed Catch-All Route (`app/services/route-service.js`)
- Added explicit check to skip `/api/*` paths
- Returns JSON 404 instead of HTML for unmatched API routes
- Added logging to detect when catch-all catches API routes (should not happen)

### 2. Added Explicit Content-Type Headers
- All API endpoints now explicitly set `Content-Type: application/json`
- Prevents browsers/servers from inferring wrong content type

### 3. Improved Error Handling
- All API routes wrapped in try-catch blocks
- Global error handler returns JSON for API routes, HTML for frontend routes
- Standardized error response format

### 4. Enhanced Session Status Handler
- Added logging to track route hits
- Normalized state values (ready → READY, provisioning → PROVISIONING, etc.)
- Better error messages

### 5. Fixed Static Middleware (`app/server.js`)
- Added guard to skip API routes in static file middleware
- Prevents static files from being served for API paths

### 6. Enhanced Frontend JSON Validation (`sailor-client/src/utils/api.ts`)
- Detects HTML responses (checks for `<!DOCTYPE` or `text/html`)
- Throws descriptive errors when HTML is received instead of JSON
- Includes path and Content-Type in error messages

## Testing

After restarting the CKX server, verify:

```bash
# Test CKX status endpoint directly
curl -v http://localhost:3000/api/sessions/test-session-id/status

# Should return:
# Content-Type: application/json
# {"status":"NOT_FOUND","error":"Session not found",...}

# Test via Sailor API proxy
curl -v http://localhost:4000/ckx/sessions/test-session-id/status

# Should return JSON, not HTML
```

## Deployment

**IMPORTANT**: The CKX server (webapp container) must be rebuilt/restarted for changes to take effect:

```bash
cd /Users/danilo/repos/CK-X
docker compose build webapp
docker compose up -d webapp
```

Or rebuild the entire stack:
```bash
docker compose up -d --build
```

## Verification Checklist

- [ ] CKX server restarted with new code
- [ ] `/api/sessions/:id/status` returns JSON (not HTML)
- [ ] Content-Type header is `application/json`
- [ ] Frontend no longer receives HTML responses
- [ ] Exam sessions no longer stuck at 90% loading
- [ ] Error messages are clear and helpful
