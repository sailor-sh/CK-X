const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http');
const socketio = require('socket.io');
const SSHTerminal = require('./services/ssh-terminal');
const PublicService = require('./services/public-service');
const RouteService = require('./services/route-service');
const VNCService = require('./services/vnc-service');

// Server configuration
const PORT = process.env.PORT || 3000;

// VNC service configuration from environment variables
const VNC_SERVICE_HOST = process.env.VNC_SERVICE_HOST || 'remote-desktop-service';
const VNC_SERVICE_PORT = process.env.VNC_SERVICE_PORT || 6901;
const VNC_PASSWORD = process.env.VNC_PASSWORD || 'bakku-the-wizard'; // Default password

// SSH service configuration
const SSH_HOST = process.env.SSH_HOST || 'remote-terminal'; // Use remote-terminal service
const SSH_PORT = process.env.SSH_PORT || 22;
const SSH_USER = process.env.SSH_USER || 'candidate';
const SSH_PASSWORD = process.env.SSH_PASSWORD || 'password';

const app = express();
const server = http.createServer(app);
const io = socketio(server);

// Initialize SSH Terminal
const sshTerminal = new SSHTerminal({
    host: SSH_HOST,
    port: SSH_PORT,
    username: SSH_USER,
    password: SSH_PASSWORD
});

// Initialize Public Service
const publicService = new PublicService(path.join(__dirname, 'public'));
publicService.initialize();


// Initialize VNC Service
const vncService = new VNCService({
    host: VNC_SERVICE_HOST,
    port: VNC_SERVICE_PORT,
    password: VNC_PASSWORD
});

// SSH terminal namespace
const sshIO = io.of('/ssh');
sshIO.on('connection', (socket) => {
    sshTerminal.handleConnection(socket);
});

// Initialize Route Service
const routeService = new RouteService(publicService, vncService);

// Serve static files from the public directory
app.use(express.static(publicService.getPublicDir()));

// Setup VNC proxy
vncService.setupVNCProxy(app);

// Setup routes
routeService.setupRoutes(app);

// Enable CORS
app.use(cors());

// Start the server
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`VNC proxy configured to ${VNC_SERVICE_HOST}:${VNC_SERVICE_PORT}`);
    console.log(`SSH service configured to ${SSH_HOST}:${SSH_PORT}`);
}); 