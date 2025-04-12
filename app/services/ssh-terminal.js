const { Client } = require('ssh2');

class SSHTerminal {
    constructor(config) {
        this.config = {
            host: config.host || 'remote-terminal',
            port: config.port || 22,
            username: config.username || 'candidate',
            password: config.password || 'password',
            readyTimeout: 30000,
            keepaliveInterval: 10000
        };
    }

    handleConnection(socket) {
        console.log('New SSH terminal connection established');
        
        let ssh = new Client();
        
        ssh.on('ready', () => {
            console.log('SSH connection established');
            this.createShellSession(ssh, socket);
        });
        
        ssh.on('error', (err) => {
            console.error('SSH connection error:', err);
            socket.emit('data', `SSH connection error: ${err.message}\r\n`);
            socket.disconnect();
        });
        
        ssh.connect(this.config);
    }

    createShellSession(ssh, socket) {
        ssh.shell((err, stream) => {
            if (err) {
                console.error('SSH shell error:', err);
                socket.emit('data', `Error: ${err.message}\r\n`);
                socket.disconnect();
                return;
            }
            
            this.setupStreamHandlers(stream, socket, ssh);
        });
    }

    setupStreamHandlers(stream, socket, ssh) {
        stream.on('data', (data) => {
            socket.emit('data', data.toString('utf-8'));
        });
        
        stream.on('close', () => {
            console.log('SSH stream closed');
            ssh.end();
            socket.disconnect();
        });
        
        stream.on('error', (err) => {
            console.error('SSH stream error:', err);
            socket.emit('data', `Error: ${err.message}\r\n`);
        });
        
        socket.on('data', (data) => {
            stream.write(data);
        });
        
        socket.on('resize', (dimensions) => {
            if (dimensions && dimensions.cols && dimensions.rows) {
                stream.setWindow(dimensions.rows, dimensions.cols, 0, 0);
            }
        });
        
        socket.on('disconnect', () => {
            console.log('Client disconnected from SSH terminal');
            stream.close();
            ssh.end();
        });
    }
}

module.exports = SSHTerminal; 