/**
 * Terminal Service
 * Handles terminal initialization and management
 */

let terminal;
let socket;
let fitAddon;
let isTerminalInitialized = false;
let terminalCallbacks = {};

// Set up terminal callbacks
function setCallbacks(callbacks) {
    terminalCallbacks = callbacks || {};
}

// Function to initialize the terminal
function initTerminal(containerElement, isActive = false) {
    // If already initialized, just resize
    if (isTerminalInitialized) {
        console.log('Terminal already initialized, just resizing');
        resizeTerminal(containerElement);
        return { terminal, fitAddon };
    }
    
    console.log('Initializing terminal for the first time');
    
    // Create terminal container if it doesn't exist
    let terminalContainer = document.getElementById('terminal');
    if (!terminalContainer) {
        terminalContainer = document.createElement('div');
        terminalContainer.id = 'terminal';
        terminalContainer.className = 'terminal';
        containerElement.appendChild(terminalContainer);
    }
    
    // Set initial container size
    terminalContainer.style.width = '100%';
    terminalContainer.style.height = `${containerElement.clientHeight}px`;
    terminalContainer.style.maxWidth = '100%';
    terminalContainer.style.boxSizing = 'border-box';
    
    // Create a new terminal
    terminal = new Terminal({
        fontFamily: "'JetBrains Mono', 'Fira Code', 'Cascadia Code', Menlo, monospace",
        fontSize: 18,
        lineHeight: 1.2,
        theme: {
            background: '#1E1E1E',
            foreground: '#F8F8F8',
            cursor: '#A0A0A0',
            selectionBackground: '#363B4E'
        },
        cursorBlink: true,
        scrollback: 10000,
        allowTransparency: true,
        disableStdin: false
    });
    
    // Create a fit addon
    fitAddon = new FitAddon.FitAddon();
    terminal.loadAddon(fitAddon);
    
    // Open the terminal in the container
    terminal.open(terminalContainer);
    fitAddon.fit();
    
    // Connect to Socket.io server
    connectToSocketIO();
    
    // Add window resize listener to keep terminal properly sized
    window.addEventListener('resize', () => {
        if (isActive) {
            resizeTerminal(containerElement);
        }
    });
    
    isTerminalInitialized = true;
    return { terminal, fitAddon };
}

// Resize terminal to fit container
function resizeTerminal(containerElement) {
    if (!terminal || !isTerminalInitialized) return;
    
    setTimeout(() => {
        // Recalculate terminal container size
        const terminalContainer = document.getElementById('terminal');
        const containerHeight = containerElement.clientHeight;
        const containerWidth = containerElement.clientWidth;
        
        if (terminalContainer && containerHeight && containerWidth) {
            terminalContainer.style.height = `${containerHeight}px`;
            terminalContainer.style.width = `${containerWidth}px`;
            
            // Ensure the terminal div takes full available space
            terminalContainer.style.maxWidth = '100%';
            terminalContainer.style.boxSizing = 'border-box';
        }
        
        // Use the existing fitAddon instead of creating a new one
        if (fitAddon) {
            fitAddon.fit();
            console.log(`Terminal resized to ${terminal.cols} columns by ${terminal.rows} rows`);
            
            // Update server with new dimensions
            if (socket && socket.connected) {
                socket.emit('resize', {
                    cols: terminal.cols,
                    rows: terminal.rows
                });
            }
        } else {
            console.warn('fitAddon not available for resizing');
        }
    }, 100);
}

// Connect to SSH and handle reconnection
function connectToSSH() {
    if (terminalCallbacks.showConnectionStatus) {
        terminalCallbacks.showConnectionStatus('Connecting to terminal...', 'info');
    }
    
    // Clear terminal if it has content
    if (terminal) {
        terminal.clear();
    }
    
    // Connect to Socket.io server immediately without animation
    connectToSocketIO();
}

// Connect to Socket.io
function connectToSocketIO() {
    // Don't reconnect if socket already exists and is connected
    if (socket && socket.connected) {
        console.log('Socket already connected, skipping reconnection');
        return;
    }
    
    // Disconnect existing socket if it exists
    if (socket) {
        console.log('Disconnecting existing socket before creating a new one');
        socket.off('data');
        socket.off('connect');
        socket.off('disconnect');
        socket.off('error');
        socket.disconnect();
    }
    
    // Connect to Socket.io server
    socket = io('/ssh', {
        forceNew: true,
        reconnectionAttempts: 1000,
        timeout: 1000
    });
    console.log('Creating new socket connection to SSH server');
    
    // Handle connection events
    socket.on('connect', () => {
        console.log('Connected to SSH server');
        if (terminalCallbacks.showConnectionStatus) {
            terminalCallbacks.showConnectionStatus('Connected to terminal', 'success');
        }
        
        // Send terminal size to server
        const dimensions = {
            cols: terminal.cols,
            rows: terminal.rows
        };
        socket.emit('resize', dimensions);
    });
    
    // Handle disconnect
    socket.on('disconnect', () => {
        console.log('Disconnected from SSH server');
        if (terminalCallbacks.showConnectionStatus) {
            terminalCallbacks.showConnectionStatus('Disconnected from terminal. Reconnecting...', 'error');
        }
        
        // Show disconnected message in terminal with styling
        if (terminal) {
            terminal.writeln('\r\n\r\n\x1b[1;31m[CONNECTION LOST]\x1b[0m Terminal disconnected.');
            terminal.writeln('\x1b[0;33mAttempting to reconnect...\x1b[0m\r\n');
        }
        
        // Try to reconnect after a delay
        setTimeout(() => {
            if (socket && !socket.connected) {
                socket.connect();
            }
        }, 2000);
    });
    
    // Handle connection error
    socket.on('error', (err) => {
        console.error('Socket connection error:', err);
        if (terminal) {
            terminal.writeln(`\r\n\x1b[1;31m[ERROR]\x1b[0m ${err.message}\r\n`);
        }
    });
    
    // Handle SSH data with processing for ANSI codes
    socket.on('data', (data) => {
        console.log('Received data from SSH server:', data);
        // if data is a string, write it to the terminal
        if (terminal) {
            terminal.write(data);
        }
    });
    
    // Clear any existing listeners to prevent duplication
    if (terminal) {
        // Get all registered event listeners
        const existingListeners = terminal._core._events;
        
        // If we have existing data listeners, clear them
        if (existingListeners && existingListeners.data) {
            // Remove previous data listeners
            terminal._core.off('data');
            console.log('Removed existing terminal data listeners');
        }
        
        // Add our data handler
        terminal.onData((data) => {
            if (socket && socket.connected) {
                socket.emit('data', data);
            } else {
                // Visual feedback when trying to type while disconnected
                terminal.write('\r\n\x1b[1;31m[DISCONNECTED]\x1b[0m Cannot send data. Reconnecting...\r\n');
                socket.connect();
            }
        });
        console.log('Added new terminal data listener');
    }
}

// Check if terminal is initialized
function isInitialized() {
    return isTerminalInitialized;
}

// Get terminal instance
function getTerminal() {
    return terminal;
}

// Get socket instance
function getSocket() {
    return socket;
}

// Export functions
export {
    initTerminal,
    resizeTerminal,
    connectToSSH,
    isInitialized,
    getTerminal,
    getSocket,
    setCallbacks
}; 