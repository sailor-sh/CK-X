const { createProxyMiddleware } = require('http-proxy-middleware');

class VNCService {
    constructor(config) {
        this.config = {
            host: config.host || 'remote-desktop-service',
            port: config.port || 6901,
            password: config.password || 'bakku-the-wizard'
        };

        this.vncProxyConfig = {
            target: `http://${this.config.host}:${this.config.port}`,
            changeOrigin: true,
            ws: true,
            secure: false,
            pathRewrite: {
                '^/vnc-proxy': ''
            },
            onProxyReq: (proxyReq, req, res) => {
                // Log HTTP requests being proxied
                console.log(`Proxying HTTP request to VNC server: ${req.url}`);
            },
            onProxyReqWs: (proxyReq, req, socket, options, head) => {
                // Log WebSocket connections
                console.log(`WebSocket connection established to VNC server: ${req.url}`);
            },
            onProxyRes: (proxyRes, req, res) => {
                // Log the responses from VNC server
                console.log(`Received response from VNC server for: ${req.url}`);
            },
            onError: (err, req, res) => {
                console.error(`Proxy error: ${err.message}`);
                if (res && res.writeHead) {
                    res.writeHead(500, {
                        'Content-Type': 'text/plain'
                    });
                    res.end(`Proxy error: ${err.message}`);
                }
            }
        };
    }

    setupVNCProxy(app) {
        // Middleware to enhance VNC URLs with authentication if needed
        app.use('/vnc-proxy', (req, res, next) => {
            // Check if the URL already has a password parameter
            if (!req.query.password) {
                // If no password provided, add default password
                console.log('Adding default VNC password to request');
                const separator = req.url.includes('?') ? '&' : '?';
                req.url = `${req.url}${separator}password=${this.config.password}`;
            }
            next();
        }, createProxyMiddleware(this.vncProxyConfig));

        // Direct WebSocket proxy to handle the websockify endpoint
        app.use('/websockify', createProxyMiddleware({
            ...this.vncProxyConfig,
            pathRewrite: {
                '^/websockify': '/websockify'
            },
            ws: true,
            onProxyReqWs: (proxyReq, req, socket, options, head) => {
                // Log WebSocket connections to websockify
                console.log(`WebSocket connection to websockify established: ${req.url}`);
                
                // Add additional headers if needed
                proxyReq.setHeader('Origin', `http://${this.config.host}:${this.config.port}`);
            },
            onError: (err, req, res) => {
                console.error(`Websockify proxy error: ${err.message}`);
                if (res && res.writeHead) {
                    res.writeHead(500, {
                        'Content-Type': 'text/plain'
                    });
                    res.end(`Websockify proxy error: ${err.message}`);
                }
            }
        }));
    }

    getVNCInfo() {
        return {
            host: this.config.host,
            port: this.config.port,
            wsUrl: `/websockify`,
            defaultPassword: this.config.password,
            status: 'connected'
        };
    }
}

module.exports = VNCService; 