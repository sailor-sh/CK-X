const { createProxyMiddleware } = require('http-proxy-middleware');

/**
 * VNC service — per-session proxy only.
 * No global target. req.session must be set by requireSession and contain vnc: { host, port, password }.
 * 
 * NOTE: WebSocket upgrades bypass Express middleware, so we need to resolve sessions
 * inside the proxy's router function using the sessionRegistry directly.
 */
class VNCService {
    constructor() {
        this._sessionRegistry = null;
    }

    /**
     * Set the session registry for WebSocket session resolution.
     * Must be called before using the proxy middleware.
     */
    setSessionRegistry(registry) {
        this._sessionRegistry = registry;
    }

    /**
     * Resolve session from request - works for both HTTP and WebSocket.
     * For HTTP, uses req.session (set by middleware).
     * For WebSocket upgrades, resolves from sessionRegistry using URL params.
     */
    _resolveSession(req) {
        // First try the session set by middleware (HTTP requests)
        if (req.session?.vnc) {
            return req.session;
        }

        // For WebSocket upgrades, resolve from registry using URL
        if (this._sessionRegistry) {
            const match = req.url?.match(/\/api\/sessions\/([^/]+)/);
            const sessionId = match?.[1] || req.params?.sessionId;
            if (sessionId) {
                const session = this._sessionRegistry.get(decodeURIComponent(sessionId));
                if (session) {
                    req.sessionId = sessionId;
                    req.session = session;
                    return session;
                }
            }
        }

        return null;
    }
    /**
     * Middleware: proxy to this session's VNC (req.session.vnc).
     * Must be mounted after requireSession. Strips path prefix so upstream sees /.
     */
    sessionVncProxy() {
        const self = this;
        return createProxyMiddleware({
            target: false,
            changeOrigin: true,
            ws: false, // WebSocket handled by server.js upgrade handler
            secure: false,
            pathRewrite: (pathIn) => {
                const match = pathIn.match(/^\/api\/sessions\/[^/]+\/vnc-proxy(\/?.*)$/);
                return match ? (match[1] || '/') : pathIn;
            },
            router: (req) => {
                // Resolve session (works for both HTTP and WebSocket)
                const session = self._resolveSession(req);
                const vnc = session?.vnc;
                if (!vnc?.host || vnc.port == null) {
                    // For dev mode, fall back to env vars instead of crashing
                    const fallbackHost = process.env.VNC_SERVICE_HOST;
                    const fallbackPort = process.env.VNC_SERVICE_PORT || '6901';
                    if (fallbackHost) {
                        console.warn(`[VNC Proxy] Session ${req.sessionId || 'unknown'} has no VNC config, using env fallback: ${fallbackHost}:${fallbackPort}`);
                        return `http://${fallbackHost}:${fallbackPort}`;
                    }
                    console.error('[VNC Proxy] Session has no VNC endpoint configured:', req.sessionId);
                    // Return a dummy target - the connection will fail but won't crash the server
                    // The onError handler will provide a helpful error page
                    return 'http://127.0.0.1:1';
                }
                const target = `http://${vnc.host}:${Number(vnc.port)}`;
                console.log(`[VNC Proxy] Routing session ${req.sessionId || 'unknown'} to ${target}`);
                return target;
            },
            onProxyReq: (proxyReq, req) => {
                const session = self._resolveSession(req);
                if (!req.query?.password && session?.vnc?.password) {
                    const sep = req.url.includes('?') ? '&' : '?';
                    req.url = `${req.url}${sep}password=${session.vnc.password}`;
                }
            },
            onError: (err, req, res) => {
                const session = self._resolveSession(req);
                const vnc = session?.vnc || {};
                const target = `${vnc.host || 'unknown'}:${vnc.port || 'unknown'}`;
                console.error(`[VNC Proxy] Connection failed to ${target}:`, err.message);
                console.error(`[VNC Proxy] Make sure the remote-desktop container is running.`);
                console.error(`[VNC Proxy] For local dev, run: docker compose up remote-desktop`);
                
                if (res && !res.headersSent) {
                    res.writeHead(502, { 'Content-Type': 'text/html' });
                    res.end(`
                        <!DOCTYPE html>
                        <html>
                        <head><title>VNC Connection Failed</title></head>
                        <body style="display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#1a1a2e;color:#fff;font-family:system-ui,sans-serif;">
                            <div style="text-align:center;max-width:500px;padding:20px;">
                                <h2 style="color:#ff6b6b;">Remote Desktop Unavailable</h2>
                                <p>Could not connect to the VNC service at <code>${target}</code></p>
                                <p style="color:#888;font-size:14px;">
                                    ${err.code === 'ECONNREFUSED' ? 'The remote-desktop container is not running.' : err.message}
                                </p>
                                <p style="color:#888;font-size:14px;">
                                    For local development, run:<br>
                                    <code style="background:#333;padding:4px 8px;border-radius:4px;">docker compose up remote-desktop</code>
                                </p>
                            </div>
                        </body>
                        </html>
                    `);
                }
            }
        });
    }

    /**
     * Middleware: proxy WebSocket to this session's VNC websockify.
     * Must be mounted after requireSession.
     */
    sessionWebsockifyProxy() {
        const self = this;
        return createProxyMiddleware({
            target: false,
            ws: false, // WebSocket handled by server.js upgrade handler
            changeOrigin: true,
            pathRewrite: (path) => '/websockify',
            router: (req) => {
                // Resolve session (works for both HTTP and WebSocket)
                const session = self._resolveSession(req);
                const vnc = session?.vnc;
                if (!vnc?.host || vnc.port == null) {
                    // For dev mode, fall back to env vars instead of crashing
                    const fallbackHost = process.env.VNC_SERVICE_HOST;
                    const fallbackPort = process.env.VNC_SERVICE_PORT || '6901';
                    if (fallbackHost) {
                        console.warn(`[Websockify Proxy] Session ${req.sessionId || 'unknown'} has no VNC config, using env fallback: ${fallbackHost}:${fallbackPort}`);
                        return `http://${fallbackHost}:${fallbackPort}`;
                    }
                    console.error('[Websockify Proxy] Session has no VNC endpoint:', req.sessionId);
                    return 'http://127.0.0.1:1';
                }
                const target = `http://${vnc.host}:${Number(vnc.port)}`;
                console.log(`[Websockify Proxy] Routing session ${req.sessionId || 'unknown'} to ${target}`);
                return target;
            },
            onProxyReqWs: (proxyReq, req) => {
                const session = self._resolveSession(req);
                if (session?.vnc?.host) {
                    proxyReq.setHeader('Origin', `http://${session.vnc.host}:${session.vnc.port}`);
                }
            },
            onError: (err, req, res) => {
                console.error(`[Websockify Proxy] Error [${req.sessionId}]:`, err.message);
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
