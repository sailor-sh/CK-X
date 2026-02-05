require('dotenv').config();

const config = {
  port: process.env.PORT || 3004,
  env: process.env.NODE_ENV || 'development',
  
  ssh: {
    host: process.env.SSH_HOST || 'jumphost',
    port: parseInt(process.env.SSH_PORT || '22', 10),
    username: process.env.SSH_USERNAME || 'candidate',
    // Password is optional as jumphost allows passwordless authentication
    password: process.env.SSH_PASSWORD,
    privateKeyPath: process.env.SSH_PRIVATE_KEY_PATH,
  },
  
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },

  remoteDesktop: {
    host: process.env.REMOTE_DESKTOP_HOST || 'remote-desktop',
    port: process.env.REMOTE_DESKTOP_PORT || 5000
  },
};

module.exports = config; 