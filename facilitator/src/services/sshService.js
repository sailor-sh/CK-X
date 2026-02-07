const { Client } = require('ssh2');
const fs = require('fs');
const logger = require('../utils/logger');
const config = require('../config');

/**
 * Execute a command on a remote SSH server
 * @param {string} command - The command to execute
 * @returns {Promise<Object>} The result of the command execution
 */
async function executeCommand(command) {
  logger.info(`Executing command: ${command}`);
  
  return new Promise((resolve, reject) => {
    const conn = new Client();
    let stdout = '';
    let stderr = '';
    
    conn.on('ready', () => {
      logger.info('SSH connection established');
      
      conn.exec(command, (err, stream) => {
        if (err) {
          logger.error('Failed to execute command', { error: err.message });
          conn.end();
          return reject(err);
        }
        
        stream.on('data', (data) => {
          stdout += data.toString();
        });
        
        stream.stderr.on('data', (data) => {
          stderr += data.toString();
        });
        
        stream.on('close', (code) => {
          logger.info(`Command execution completed with exit code: ${code}`);
          conn.end();
          resolve({
            exitCode: code,
            stdout,
            stderr
          });
        });
      });
    });
    
    conn.on('error', (err) => {
      logger.error('SSH connection error', { error: err.message });
      reject(err);
    });
    
    // Configure connection for jumphost which accepts passwordless authentication
    const connectionConfig = {
      host: config.ssh.host,
      port: config.ssh.port,
      username: config.ssh.username,
      // For passwordless authentication
      readyTimeout: 30000, // Increase timeout for slow connections
    };
    
    // Add authentication methods if available
    if (config.ssh.privateKeyPath) {
      logger.info('Using private key authentication');
      try {
        connectionConfig.privateKey = fs.readFileSync(config.ssh.privateKeyPath);
      } catch (err) {
        logger.error('Failed to read private key', { error: err.message });
        return reject(new Error(`Failed to read private key: ${err.message}`));
      }
    } else if (config.ssh.password !== undefined) {
      logger.info('Using password authentication');
      connectionConfig.password = config.ssh.password;
    } else {
      // Jumphost allows empty password authentication
      logger.info('Using empty password authentication');
      connectionConfig.password = '';
    }
    
    conn.connect(connectionConfig);
  });
}

module.exports = {
  executeCommand
}; 