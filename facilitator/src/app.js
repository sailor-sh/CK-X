const express = require('express');
const morgan = require('morgan');
const helmet = require('helmet');
const cors = require('cors');
const config = require('./config');
const logger = require('./utils/logger');
const redisClient = require('./utils/redisClient');

// Import routes
const sshRoutes = require('./routes/sshRoutes');
const examRoutes = require('./routes/examRoutes');
const assessmentRoutes = require('./routes/assessmentRoutes');
const remoteDesktopRoutes = require('./routes/remoteDesktopRoutes');

// Initialize Express app
const app = express();

// Apply middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS for all routes
app.use(express.json()); // Parse JSON request bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded request bodies

// HTTP request logging
app.use(morgan('combined', { 
  stream: { 
    write: message => logger.http(message.trim()) 
  } 
}));

// API routes
app.use('/api/v1', sshRoutes);
app.use('/api/v1/exams', examRoutes);
// Backward-compat: original route had a typo (assements). Keep it and add the correct alias.
app.use('/api/v1/assements', assessmentRoutes);
app.use('/api/v1/assessments', assessmentRoutes);
app.use('/api/v1/remote-desktop', remoteDesktopRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Facilitator Service API',
    version: '1.0.0'
  });
});

// 404 Handler
app.use((req, res) => {
  logger.warn(`Route not found: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    error: 'Not Found',
    message: `The requested resource ${req.originalUrl} was not found`
  });
});

// Error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({
    error: 'Internal Server Error',
    message: config.env === 'development' ? err.message : 'An unexpected error occurred'
  });
});

// Initialize Redis connection
(async () => {
  try {
    await redisClient.connect();
    logger.info('Redis connected successfully');
  } catch (error) {
    logger.error(`Redis connection failed: ${error.message}`);
  }
})();

// Start the server
const PORT = config.port;
app.listen(PORT, () => {
  logger.info(`Server running in ${config.env} mode on port ${PORT}`);
});

module.exports = app; // Export for testing 
