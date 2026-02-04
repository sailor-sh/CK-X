const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http');
const socketio = require('socket.io');
const SSHTerminal = require('./services/ssh-terminal');
const PublicService = require('./services/public-service');
const RouteService = require('./services/route-service');
const VNCService = require('./services/vnc-service');
const { SessionRegistry, SESSION_STATES } = require('./services/session-registry');
const { requireSession } = require('./middleware/session-resolver');

const PORT = process.env.PORT || 3000;

const app = express();
const server = http.createServer(app);
const io = socketio(server);

// ——— Session registry (no global runtime; all routing by sessionId) ———
const sessionRegistry = new SessionRegistry();

// Optional: bootstrap one default session from env for backward compatibility (single-session dev)
function bootstrapDefaultSessionIfConfigured() {
    const host = process.env.VNC_SERVICE_HOST || process.env.SSH_HOST;
    if (!host) return;
    const sessionId = process.env.DEFAULT_SESSION_ID || 'default';
    if (sessionRegistry.has(sessionId)) return;
    sessionRegistry.set(sessionId, {
        state: SESSION_STATES.READY,
        vnc: {
            host: process.env.VNC_SERVICE_HOST || 'remote-desktop',
            port: parseInt(process.env.VNC_SERVICE_PORT || '6901', 10),
            password: process.env.VNC_PASSWORD || 'bakku-the-wizard'
        },
        ssh: {
            host: process.env.SSH_HOST || 'remote-terminal',
            port: parseInt(process.env.SSH_PORT || '22', 10),
            username: process.env.SSH_USER || 'candidate',
            password: process.env.SSH_PASSWORD || 'password'
        }
    });
    console.log(`Bootstrapped default session: ${sessionId}`);
}
bootstrapDefaultSessionIfConfigured();

// ——— Stateless services (no per-process connection state) ———
const publicService = new PublicService(path.join(__dirname, 'public'));
publicService.initialize();
const vncService = new VNCService();
const requireSessionMiddleware = requireSession(sessionRegistry);
const routeService = new RouteService(
    publicService,
    vncService,
    sessionRegistry,
    requireSession
);

// Body parser for POST /api/sessions
app.use(express.json());

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
