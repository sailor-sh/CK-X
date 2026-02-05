const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const path = require('path');
const http = require('http');
const socketio = require('socket.io');
const SSHTerminal = require('./services/ssh-terminal');
const PublicService = require('./services/public-service');
const RouteService = require('./services/route-service');
const VNCService = require('./services/vnc-service');
const LaunchService = require('./services/launch-service');
const { SessionRegistry, SESSION_STATES } = require('./services/session-registry');
const { requireSession } = require('./middleware/session-resolver');

const { createProxyMiddleware } = require('http-proxy-middleware');

const PORT = process.env.PORT || 3000;
const SAILOR_API_URL = process.env.SAILOR_API_URL || 'http://localhost:4000';
const FACILITATOR_URL = process.env.FACILITATOR_URL || 'http://localhost:3004';

const app = express();
const server = http.createServer(app);
const io = socketio(server);

// ——— Session registry (no global runtime; all routing by sessionId) ———
const sessionRegistry = new SessionRegistry();

// Bootstrap default session for single-session development mode
// In production/multi-session mode, sessions are registered via POST /api/sessions by Sailor API
function bootstrapDefaultSession() {
    const sessionId = process.env.DEFAULT_SESSION_ID || 'default';
    if (sessionRegistry.has(sessionId)) return;
    
    const vncHost = process.env.VNC_SERVICE_HOST || 'remote-desktop';
    const sshHost = process.env.SSH_HOST || 'remote-terminal';
    
    sessionRegistry.set(sessionId, {
        state: SESSION_STATES.READY,
        vnc: {
            host: vncHost,
            port: parseInt(process.env.VNC_SERVICE_PORT || '6901', 10),
            password: process.env.VNC_PASSWORD || 'bakku-the-wizard'
        },
        ssh: {
            host: sshHost,
            port: parseInt(process.env.SSH_PORT || '22', 10),
            username: process.env.SSH_USER || 'candidate',
            password: process.env.SSH_PASSWORD || 'password'
        }
    });
    console.log(`Bootstrapped default session: ${sessionId}`);
    console.log(`  VNC target: ${vncHost}:${process.env.VNC_SERVICE_PORT || '6901'}`);
    console.log(`  SSH target: ${sshHost}:${process.env.SSH_PORT || '22'}`);
    
    // Warn if using Docker hostnames without Docker
    if (vncHost === 'remote-desktop' && !process.env.VNC_SERVICE_HOST) {
        console.warn('⚠️  Using default VNC host "remote-desktop" - this only works in Docker Compose');
        console.warn('   For local dev, set VNC_SERVICE_HOST=localhost or run: docker compose up remote-desktop');
    }
}
bootstrapDefaultSession();

// ——— Stateless services (no per-process connection state) ———
const publicService = new PublicService(path.join(__dirname, 'public'));
publicService.initialize();
const vncService = new VNCService();
vncService.setSessionRegistry(sessionRegistry); // Required for WebSocket session resolution
const requireSessionMiddleware = requireSession(sessionRegistry);
const routeService = new RouteService(
    publicService,
    vncService,
    sessionRegistry,
    requireSession
);

// ——— Prevent embedding full CKX UI inside iframes ———
// CKX is a runtime; Sailor (or other hosts) must own the exam UI.
// We allow embedding of the VNC runtime only (served under /api/sessions/:id/vnc-proxy
// and proxied by Sailor as /ckx/sessions/:id/vnc-proxy). Direct embedding of CKX
// UI shells like "/", "/index.html", "/exam.html", "/results" is blocked.
const UI_EMBED_BLOCKED_PATHS = new Set([
    '/',
    '/index.html',
    '/exam.html',
    '/results',
    '/results.html'
]);

function blockUiEmbedding(req, res, next) {
    if (!UI_EMBED_BLOCKED_PATHS.has(req.path)) {
        return next();
    }

    // Best-effort detection of iframe/embedded requests
    const dest = req.headers['sec-fetch-dest'];
    const isFrame = dest === 'iframe' || dest === 'frame';

    if (isFrame) {
        // Explicitly forbid framing CKX UI shells
        res.setHeader('X-Frame-Options', 'DENY');
        res.setHeader('Content-Security-Policy', "frame-ancestors 'none'");
        return res.status(403).send('Embedding CKX UI is not allowed. Use the VNC endpoint instead.');
    }

    return next();
}

// Must run before static file middleware so blocked UI paths never render in iframes
app.use(blockUiEmbedding);

// ——— Facilitator proxy ———
// MUST be before express.json() so the body stream isn't consumed before proxying
// Proxy /facilitator/* requests to the facilitator service
app.use('/facilitator', createProxyMiddleware({
    target: FACILITATOR_URL,
    changeOrigin: true,
    pathRewrite: {
        '^/facilitator': '' // Remove /facilitator prefix
    },
    onError: (err, req, res) => {
        console.error('[Facilitator Proxy] Error:', err.message);
        res.status(502).json({ error: 'Facilitator service unavailable', message: err.message });
    }
}));

console.log(`Facilitator proxy configured: /facilitator/* -> ${FACILITATOR_URL}`);

// Body parser for POST /api/sessions (after proxy routes!)
app.use(express.json());

// Cookie parser for session cookies (new-tab architecture)
app.use(cookieParser());

// ——— Launch endpoint: validates launch token and establishes session ———
// This is the entry point for the new-tab lab launch flow.
// User clicks "Open Lab" → Sailor creates launch token → browser opens this URL
app.get('/launch', async (req, res) => {
    const { token } = req.query;
    
    if (!token) {
        return res.status(400).send(`
            <!DOCTYPE html>
            <html>
            <head><title>Launch Error</title></head>
            <body>
                <h1>Missing Launch Token</h1>
                <p>No launch token was provided. Please return to the dashboard and try again.</p>
            </body>
            </html>
        `);
    }
    
    try {
        // Validate token with Sailor API
        const result = await LaunchService.validateLaunchTokenWithSailor(token, SAILOR_API_URL);
        
        if (!result.valid) {
            console.error('[Launch] Token validation failed:', result.error);
            return res.status(401).send(`
                <!DOCTYPE html>
                <html>
                <head><title>Launch Error</title></head>
                <body>
                    <h1>Invalid or Expired Token</h1>
                    <p>${result.error}</p>
                    <p>Launch tokens are single-use and expire after 60 seconds.</p>
                    <p>Please return to the dashboard and click "Open Lab" again.</p>
                </body>
                </html>
            `);
        }
        
        const { sessionId, userId, examSessionId } = result.data;
        
        // Verify the CKX session exists in registry
        if (!sessionRegistry.has(sessionId)) {
            console.error('[Launch] Session not found in registry:', sessionId);
            return res.status(404).send(`
                <!DOCTYPE html>
                <html>
                <head><title>Launch Error</title></head>
                <body>
                    <h1>Session Not Found</h1>
                    <p>The lab session could not be found. It may have expired or been terminated.</p>
                </body>
                </html>
            `);
        }
        
        // Create session cookie
        const cookieValue = LaunchService.createSessionCookie(sessionId, userId, examSessionId);
        
        res.cookie(LaunchService.SESSION_COOKIE_NAME, cookieValue, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: LaunchService.SESSION_COOKIE_MAX_AGE,
            path: '/',
        });
        
        console.log('[Launch] Session established:', { sessionId, userId, examSessionId });
        
        // Redirect to exam UI with sessionId
        res.redirect(`/exam.html?sessionId=${encodeURIComponent(sessionId)}`);
        
    } catch (err) {
        console.error('[Launch] Unexpected error:', err);
        return res.status(500).send(`
            <!DOCTYPE html>
            <html>
            <head><title>Launch Error</title></head>
            <body>
                <h1>Server Error</h1>
                <p>An unexpected error occurred. Please try again.</p>
            </body>
            </html>
        `);
    }
});

// Static files
app.use(express.static(publicService.getPublicDir()));

// ——— Session-scoped VNC proxy (must run after session resolution) ———
app.use(
    '/api/sessions/:sessionId/vnc-proxy',
    requireSessionMiddleware,
    vncService.sessionVncProxy()
);
app.use(
    '/api/sessions/:sessionId/websockify',
    requireSessionMiddleware,
    vncService.sessionWebsockifyProxy()
);

// ——— Root-level websockify for noVNC client compatibility ———
// noVNC loaded via vnc-proxy tries to connect to /websockify on the same host.
// WebSocket upgrades bypass Express, so we handle them at the HTTP server level.
const websockifyProxy = createProxyMiddleware({
    target: `http://${process.env.VNC_SERVICE_HOST || 'remote-desktop'}:${process.env.VNC_SERVICE_PORT || 6901}`,
    ws: true,
    changeOrigin: true,
    pathRewrite: { '^/websockify': '/websockify' },
    onError: (err, req, res) => {
        console.error('[Websockify Root] Proxy error:', err.message);
    }
});

// Handle WebSocket upgrade for /websockify
server.on('upgrade', (req, socket, head) => {
    if (req.url === '/websockify' || req.url.startsWith('/websockify?')) {
        console.log('[Websockify] Handling WebSocket upgrade for /websockify');
        websockifyProxy.upgrade(req, socket, head);
    }
    // Other WebSocket upgrades (like Socket.IO for SSH) are handled by their respective handlers
});

// Also handle HTTP requests to /websockify (for initial handshake)
app.use('/websockify', websockifyProxy);

// Routes (session-scoped API + health + static)
routeService.setupRoutes(app);

app.use(cors());

// ——— SSH terminal: one namespace; each connection bound to a session by sessionId in handshake ———
const sshIO = io.of('/ssh');
sshIO.on('connection', (socket) => {
    const sessionId = socket.handshake?.query?.sessionId;
    if (!sessionId || typeof sessionId !== 'string' || !sessionId.trim()) {
        socket.emit('data', 'Error: sessionId is required in connection query.\r\n');
        socket.disconnect(true);
        return;
    }
    const session = sessionRegistry.get(sessionId);
    if (!session) {
        socket.emit('data', `Error: Session not found: ${sessionId}\r\n`);
        socket.disconnect(true);
        return;
    }
    if (!sessionRegistry.isRoutable(sessionId)) {
        socket.emit('data', `Error: Session not available (state: ${session.state}).\r\n`);
        socket.disconnect(true);
        return;
    }
    const sshConfig = session.ssh || {};
    const terminal = new SSHTerminal({
        host: sshConfig.host || 'remote-terminal',
        port: sshConfig.port ?? 22,
        username: sshConfig.username || 'candidate',
        password: sshConfig.password || 'password'
    });
    terminal.handleConnection(socket);
});

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log('Session-scoped VNC and SSH; sessionId required for all runtime access.');
});
