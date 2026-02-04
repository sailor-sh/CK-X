const { createProxyMiddleware } = require('http-proxy-middleware');

/**
 * VNC service — per-session proxy only.
 * No global target. req.session must be set by requireSession and contain vnc: { host, port, password }.
 */
class VNCService {
    /**
     * Middleware: proxy to this session's VNC (req.session.vnc).
     * Must be mounted after requireSession. Strips path prefix so upstream sees /.
     */
    sessionVncProxy() {
        return createProxyMiddleware({
            target: false,
            changeOrigin: true,
            ws: true,
            secure: false,
            pathRewrite: (pathIn) => {
                const match = pathIn.match(/^\/api\/sessions\/[^/]+\/vnc-proxy(\/?.*)$/);
                return match ? (match[1] || '/') : pathIn;
            },
            router: (req) => {
                const vnc = req.session?.vnc;
                if (!vnc?.host || vnc.port == null) {
                    throw new Error('Session has no VNC endpoint');
                }
                return `http://${vnc.host}:${Number(vnc.port)}`;
            },
            onProxyReq: (proxyReq, req) => {
                if (!req.query.password && req.session?.vnc?.password) {
                    const sep = req.url.includes('?') ? '&' : '?';
                    req.url = `${req.url}${sep}password=${req.session.vnc.password}`;
                }
            },
            onError: (err, req, res) => {
                console.error(`VNC proxy error [${req.sessionId}]:`, err.message);
                if (res && res.writeHead) {
                    res.writeHead(500, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'VNC proxy error' }));
                }
            }
        });
    }

    /**
     * Middleware: proxy WebSocket to this session's VNC websockify.
     * Must be mounted after requireSession.
     */
    sessionWebsockifyProxy() {
        return createProxyMiddleware({
            target: false,
            ws: true,
            changeOrigin: true,
            pathRewrite: (path) => '/websockify',
            router: (req) => {
                const vnc = req.session?.vnc;
                if (!vnc?.host || vnc.port == null) {
                    throw new Error('Session has no VNC endpoint');
                }
                return `http://${vnc.host}:${Number(vnc.port)}`;
            },
            onProxyReqWs: (proxyReq, req) => {
                if (req.session?.vnc?.host) {
                    proxyReq.setHeader('Origin', `http://${req.session.vnc.host}:${req.session.vnc.port}`);
                }
            },
            onError: (err, req, res) => {
                console.error(`Websockify proxy error [${req.sessionId}]:`, err.message);
                if (res && res.writeHead) {
                    res.writeHead(500, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Websockify proxy error' }));
                }
            }
        });
    }

    /**
     * Build VNC info for a session (for API response). Caller passes sessionId and session record.
     */
    getVncInfoForSession(sessionId, session) {
        const vnc = session?.vnc || {};
        return {
            host: vnc.host || '',
            port: vnc.port ?? 6901,
            wsUrl: `/api/sessions/${encodeURIComponent(sessionId)}/websockify`,
            vncProxyPath: `/api/sessions/${encodeURIComponent(sessionId)}/vnc-proxy`,
            defaultPassword: vnc.password || '',
            status: session ? 'connected' : 'unknown'
        };
    }
}

module.exports = VNCService;
