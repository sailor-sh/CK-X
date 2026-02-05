/**
 * Sailor API configuration. Prefer env vars; no secrets in code.
 */
require('dotenv').config();

module.exports = {
  port: parseInt(process.env.PORT || '4000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  ckx: {
    baseUrl: (process.env.CKX_BASE_URL || 'http://localhost:3000').replace(/\/$/, ''),
    apiKey: process.env.CKX_API_KEY || '',
  },
  facilitator: {
    baseUrl: (process.env.FACILITATOR_BASE_URL || 'http://localhost:3001').replace(/\/$/, ''),
  },
};
