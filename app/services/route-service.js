const path = require('path');

class RouteService {
    constructor(publicService, vncService) {
        this.publicService = publicService;
        this.vncService = vncService;
    }

    setupRoutes(app) {
        // API endpoint to get VNC server info
        app.get('/api/vnc-info', (req, res) => {
            res.json(this.vncService.getVNCInfo());
        });

        // Health check endpoint
        app.get('/health', (req, res) => {
            res.status(200).json({ status: 'ok', message: 'Service is healthy' });
        });

        // Catch-all route to serve index.html for any other requests
        app.get('*', (req, res) => {
            // Special handling for exam page
            if (req.path === '/exam') {
                res.sendFile(path.join(this.publicService.getPublicDir(), 'exam.html'));
            } 
            // Special handling for results page
            else if (req.path === '/results') {
                res.sendFile(path.join(this.publicService.getPublicDir(), 'results.html'));
            }
            else {
                res.sendFile(path.join(this.publicService.getPublicDir(), 'index.html'));
            }
        });

        // Handle errors
        app.use((err, req, res, next) => {
            console.error('Server error:', err);
            res.status(500).sendFile(path.join(this.publicService.getPublicDir(), '50x.html'));
        });
    }
}

module.exports = RouteService; 