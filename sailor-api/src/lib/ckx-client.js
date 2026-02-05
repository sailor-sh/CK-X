/**
 * CKX API client. Sailor API creates and releases CKX sessions only.
 * CKX never validates users; Sailor enforces access before calling this.
 */
const config = require('../config');

const baseUrl = () => config.ckx.baseUrl;

function headers() {
  const h = { 'Content-Type': 'application/json' };
  if (config.ckx.apiKey) h['Authorization'] = `Bearer ${config.ckx.apiKey}`;
  return h;
}

/**
 * Register a session with CKX (after provisioning runtime elsewhere, or CKX provisions).
 * @param {string} sessionId - Opaque session id (e.g. ExamSession.ckxSessionId)
 * @param {{ vnc: { host, port, password? }, ssh: { host, port, username, password } }} body
 * @returns {Promise<{ sessionId: string, state: string }>}
 */
async function createSession(sessionId, body) {
  const res = await fetch(`${baseUrl()}/api/sessions`, {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({
      sessionId,
      vnc: body.vnc || {},
      ssh: body.ssh || {},
      kubernetes: body.kubernetes || null,
      state: body.state || 'ready',
      expiresAt: body.expiresAt || null,
      ownerId: body.ownerId || null,
      examSessionId: body.examSessionId || null,
    }),
  });

  if (!res.ok) {

    const text = await res.text();
    throw new Error(`CKX createSession failed: ${res.status} ${text}`);
  }
  return res.json();
}

/**
 * Release a CKX session (teardown). Idempotent.
 * @param {string} sessionId
 * @returns {Promise<{ released: boolean }>}
 */
async function releaseSession(sessionId) {
  const res = await fetch(`${baseUrl()}/api/sessions/${encodeURIComponent(sessionId)}`, {
    method: 'DELETE',
    headers: headers(),
  });
  if (!res.ok && res.status !== 404) {
    const text = await res.text();
    throw new Error(`CKX releaseSession failed: ${res.status} ${text}`);
  }
  return res.status === 204 ? { released: true } : res.json();
}

/**
 * Get runtime info for a session (for proxying to client or building exam URL).
 * @param {string} sessionId
 * @returns {Promise<{ status, vncInfo, terminalInfo }>}
 */
async function getRuntime(sessionId) {
  const res = await fetch(`${baseUrl()}/api/sessions/${encodeURIComponent(sessionId)}/runtime`, {
    headers: headers(),
  });
  if (!res.ok) throw new Error(`CKX getRuntime failed: ${res.status}`);
  return res.json();
}

module.exports = {
  createSession,
  releaseSession,
  getRuntime,
  baseUrl,
};
