/**
 * CKX proxy routes. Sailor API proxies VNC/terminal requests to CKX after validating session access.
 * Client never calls CKX directly; all access is mediated by Sailor API.
 */
const { createProxyMiddleware, responseInterceptor } = require('http-proxy-middleware');
const config = require('../config');
const { resolveExamSession, requireActiveExamSession } = require('../middleware/session-enforcement');
const { requireAuth } = require('../middleware/auth');
const { validateIframeToken } = require('../middleware/iframe-token-auth');

/**
 * Proxy middleware factory: validates session access, then proxies to CKX.
 * @param {string} ckxPathPrefix - Path prefix to proxy (e.g., '/vnc-proxy' or '/websockify')
 */
function createCkxProxy(ckxPathPrefix) {
  return [
    // Extract ckxSessionId from URL param and set it as sessionId for resolveExamSession
    (req, res, next) => {
      // Ensure ckxSessionId is available (from route param)
      // Try both ckxSessionId (from route) and sessionId (in case it's already set)
      const ckxSessionId = req.params?.ckxSessionId || req.params?.sessionId;
      if (!ckxSessionId) {
        console.error('CKX proxy: Missing ckxSessionId in params:', Object.keys(req.params), 'URL:', req.url);
        return res.status(400).json({ error: 'ckxSessionId parameter required', debug: { params: req.params, url: req.url } });
      }
      // Set sessionId for resolveExamSession middleware (it expects sessionId or examSessionId)
      req.params.sessionId = ckxSessionId;
      // Also keep ckxSessionId for reference
      req.params.ckxSessionId = ckxSessionId;
      next();
    },
    // Validate iframe token (if present) - runs BEFORE requireAuth
    validateIframeToken,
    // Resolve ExamSession by ckxSessionId
    resolveExamSession,
    // Require authentication (JWT or iframe token already validated)
    requireAuth,
    // Validate active session access
    requireActiveExamSession,
    // Proxy to CKX
    createProxyMiddleware({
      target: config.ckx.baseUrl,
      changeOrigin: true,
      ws: true, // Enable WebSocket proxying
      secure: false, // Allow self-signed certs in dev
      selfHandleResponse: true, // needed for HTML rewriting
      pathRewrite: (path, req) => {
        // Rewrite /ckx/sessions/:ckxSessionId/vnc-proxy/* to /api/sessions/:ckxSessionId/vnc-proxy/*
        // Also handle asset requests like /ckx/sessions/:ckxSessionId/vnc-proxy/css/... -> /api/sessions/:ckxSessionId/vnc-proxy/css/...
        const ckxSessionId = req.params?.ckxSessionId;
        if (!ckxSessionId) {
          return path;
        }
        // Escape special regex chars in ckxSessionId and ckxPathPrefix
        const escapedSessionId = ckxSessionId.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const escapedPrefix = ckxPathPrefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        
        // Match pattern: /ckx/sessions/:ckxSessionId/vnc-proxy/... (including assets)
        const regex = new RegExp(`^/ckx/sessions/${escapedSessionId}${escapedPrefix}(/.*)?$`);
        const match = path.match(regex);
        if (match) {
          const rest = match[1] || '';
          // Proxy to CKX, which will then proxy to VNC server
          return `/api/sessions/${ckxSessionId}${ckxPathPrefix}${rest}`;
        }
        // Fallback: simple string replacement if regex doesn't match
        return path.replace(`/ckx/sessions/${ckxSessionId}${ckxPathPrefix}`, `/api/sessions/${ckxSessionId}${ckxPathPrefix}`);
      },
      // Strip iframeToken from query params before proxying to CKX
      onProxyReq: (proxyReq, req) => {
        // Remove iframeToken from the URL if present
        if (req.url && req.url.includes('iframeToken=')) {
          const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
          url.searchParams.delete('iframeToken');
          // Update the request URL
          const newPath = url.pathname + (url.search || '');
          proxyReq.path = newPath;
          // Also update req.url for consistency
          req.url = newPath;
        }
      },
      onError: (err, req, res) => {
        const ckxSessionId = req.params?.ckxSessionId || 'unknown';
        console.error(`CKX proxy error [${ckxSessionId}]:`, err.message);
        if (res && res.writeHead) {
          res.writeHead(502, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'CKX proxy error', message: err.message }));
        }
      },
      on: {
        proxyRes: responseInterceptor(async (responseBuffer, proxyRes, req, res) => {
          const contentType = proxyRes.headers['content-type'] || '';
          const isHtml = contentType.includes('text/html');
          const isJs =
            contentType.includes('javascript') ||
            contentType.includes('ecmascript') ||
            (req.path && req.path.endsWith('.js'));

          // Only rewrite HTML or JS; passthrough others
          if (!isHtml && !isJs) {
            return responseBuffer;
          }

          const iframeToken = req.query && req.query.iframeToken;
          const ckxSessionId = req.params?.ckxSessionId;
          const safeToken = iframeToken && typeof iframeToken === 'string' ? encodeURIComponent(iframeToken) : null;
          const appendToken = (url) =>
            safeToken
              ? url.includes('iframeToken')
                ? url
                : url + (url.includes('?') ? '&' : '?') + 'iframeToken=' + safeToken
              : url;

          if (isHtml) {
            // Rewrite HTML so assets load under the proxied path and carry iframeToken for auth
            let html = responseBuffer.toString('utf8');
            // Make asset paths relative to /ckx/sessions/:id/vnc-proxy/
            html = html.replace(/href="\/css\//g, 'href="css/');
            html = html.replace(/src="\/js\//g, 'src="js/');
            html = html.replace(/href="\/assets\//g, 'href="assets/');
            html = html.replace(/src="\/assets\//g, 'src="assets/');

            if (safeToken) {
              html = html.replace(/(href|src)="(css\/[^"]*)"/g, (_, attr, url) => `${attr}="${appendToken(url)}"`);
              html = html.replace(/(href|src)="(js\/[^"]*)"/g, (_, attr, url) => `${attr}="${appendToken(url)}"`);
              html = html.replace(/(href|src)="(assets\/[^"]*)"/g, (_, attr, url) => `${attr}="${appendToken(url)}"`);
            }

            // Inject fetch monkey-patch to rewrite facilitator API calls at runtime.
            // This handles ALL facilitator URLs including ones with dynamic exam IDs
            // in JS template literals (status, terminate, evaluate, questions, events, etc.).
            if (ckxSessionId && iframeToken) {
              const proxyPath = '/exam-sessions/' + ckxSessionId + '/fproxy/';
              const scriptContent =
                '(function(){' +
                'var t=' + JSON.stringify(iframeToken) + ';' +
                'var p=' + JSON.stringify(proxyPath) + ';' +
                'var s="/facilitator/api/v1/";' +
                'var f=window.fetch;' +
                'window.fetch=function(u,o){' +
                'if(typeof u==="string"){' +
                'if(u.indexOf(s)===0)u=p+u.substring(s.length);' +
                'u+=(u.indexOf("?")>=0?"&":"?")+"iframeToken="+encodeURIComponent(t);' +
                '}' +
                'return f.call(this,u,o);' +
                '};' +
                '})();';
              html = html.replace(/<head>/i, '<head>\n<script>' + scriptContent + '</script>');
            }

            return html;
          }

          if (isJs) {
            // Rewrite page navigation paths from absolute to relative with iframeToken.
            // Facilitator API fetch calls are handled by the monkey-patch injected in HTML <head>.
            let js = responseBuffer.toString('utf8');
            if (ckxSessionId && safeToken) {
              js = js.replace(/\/exam\.html\?/g, 'exam.html?iframeToken=' + safeToken + '&');
              js = js.replace(/\/results\?/g, 'results?iframeToken=' + safeToken + '&');
              js = js.replace(/(location\.href\s*=\s*)'\/'/g, "$1'./?iframeToken=" + safeToken + "'");
            }
            // Add cache busting so rewritten bundle is fetched fresh
            const cacheBuster = Date.now();
            js = js.replace(/(href|src)="(js\/[^"]*)"/g, (_, attr, url) => {
              const sep = url.includes('?') ? '&' : '?';
              return `${attr}="${url}${sep}v=${cacheBuster}"`;
            });
            res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
            res.setHeader('Pragma', 'no-cache');
            res.setHeader('Expires', '0');
            return js;
          }

          return responseBuffer;
        }),
      },
      logLevel: 'warn',
    }),
  ];
}

module.exports = function setupCkxProxyRoutes(app) {
  // VNC HTTP proxy: /ckx/sessions/:ckxSessionId/vnc-proxy/*
  app.use('/ckx/sessions/:ckxSessionId/vnc-proxy', ...createCkxProxy('/vnc-proxy'));

  // VNC WebSocket proxy: /ckx/sessions/:ckxSessionId/websockify/*
  app.use('/ckx/sessions/:ckxSessionId/websockify', ...createCkxProxy('/websockify'));

};
