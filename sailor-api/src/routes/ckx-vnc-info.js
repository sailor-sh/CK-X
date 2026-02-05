/**
 * CKX VNC info route.
 * Bridges legacy CKX client call `/api/sessions/default/vnc-info`
 * to the correct CKX session using the iframeToken.
 *
 * Browser -> Sailor API (/api/sessions/default/vnc-info?iframeToken=...)
 * Sailor API -> CKX (/api/sessions/:ckxSessionId/vnc-info)
 */
const express = require('express');
const config = require('../config');
const { verifyIframeToken } = require('../lib/iframe-token');

const router = express.Router();

// Legacy path used by CKX exam UI to fetch VNC info
router.get('/sessions/default/vnc-info', async (req, res) => {
  const iframeToken = req.query && req.query.iframeToken;
  if (!iframeToken) {
    return res.status(401).json({ error: 'iframeToken required' });
  }

  const result = verifyIframeToken(iframeToken);
  if (!result.valid) {
    return res.status(401).json({ error: 'Invalid iframe token', details: result.error });
  }

  const { payload } = result;
  const ckxSessionId = payload.ckxSessionId;
  if (!ckxSessionId) {
    return res.status(400).json({ error: 'ckxSessionId missing in iframe token' });
  }

  try {
    const upstreamUrl = `${config.ckx.baseUrl}/api/sessions/${encodeURIComponent(ckxSessionId)}/vnc-info`;
    const upstreamRes = await fetch(upstreamUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!upstreamRes.ok) {
      const text = await upstreamRes.text().catch(() => '');
      return res.status(upstreamRes.status).json({
        error: 'CKX vnc-info request failed',
        status: upstreamRes.status,
        body: text || undefined,
      });
    }

    const data = await upstreamRes.json();

    // Rewrite any CKX-provided VNC URL so the browser goes back through
    // Sailor's CKX proxy with the correct ckxSessionId and iframeToken.
    if (data && typeof data === 'object' && typeof data.url === 'string') {
      try {
        const original = new URL(data.url, 'http://localhost');
        let vncPath = original.pathname || '/vnc-proxy/';
        // Normalise to just the trailing part after '/vnc-proxy'
        const idx = vncPath.indexOf('/vnc-proxy');
        const suffix = idx >= 0 ? vncPath.substring(idx + '/vnc-proxy'.length) : '';

        const proxiedUrl = new URL(
          `/ckx/sessions/${encodeURIComponent(ckxSessionId)}/vnc-proxy${suffix || '/'}`,
          'http://localhost'
        );
        // Copy over query params from original
        original.searchParams.forEach((value, key) => {
          proxiedUrl.searchParams.set(key, value);
        });
        // Ensure iframeToken is preserved on the browser-facing URL
        proxiedUrl.searchParams.set('iframeToken', iframeToken);

        data.url = proxiedUrl.pathname + proxiedUrl.search;
      } catch (e) {
        // If rewrite fails, fall back to original URL
      }
    }

    return res.json(data);
  } catch (err) {
    console.error('[CKX VNC INFO] Error fetching from CKX:', err.message);
    return res.status(502).json({ error: 'CKX vnc-info proxy error', message: err.message });
  }
});

// Alias for CKX VNC HTTP proxy.
// CKX sometimes returns URLs like `/api/sessions/:ckxSessionId/vnc-proxy/?...`
// which the browser then calls directly. We translate those into the
// Sailor CKX proxy path: `/ckx/sessions/:ckxSessionId/vnc-proxy/*` and
// ensure iframeToken is attached so iframe-token-auth can validate.
router.get('/sessions/:ckxSessionId/vnc-proxy/*', (req, res) => {
  const ckxSessionId = req.params.ckxSessionId;

  // Prefer iframeToken on this request, but fall back to Referer.
  let iframeToken = req.query && req.query.iframeToken;
  if (!iframeToken && req.headers && req.headers.referer) {
    try {
      const refererUrl = new URL(req.headers.referer);
      const fromReferer = refererUrl.searchParams.get('iframeToken');
      if (fromReferer) {
        iframeToken = fromReferer;
      }
    } catch {
      // ignore malformed Referer
    }
  }

  // Preserve the remainder of the path after /vnc-proxy/
  const rest = (req.params[0] || '').replace(/^\/+/, '');

  const url = new URL(req.originalUrl, 'http://localhost');
  // Replace path with CKX proxy equivalent under /ckx
  url.pathname = `/ckx/sessions/${encodeURIComponent(ckxSessionId)}/vnc-proxy/${rest}`;
  if (iframeToken && !url.searchParams.get('iframeToken')) {
    url.searchParams.set('iframeToken', iframeToken);
  }

  return res.redirect(url.pathname + url.search);
});

module.exports = router;

