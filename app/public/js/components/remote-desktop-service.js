/**
 * Remote Desktop Service
 * Handles remote desktop connection and management. Requires sessionId for per-session isolation.
 */
import { getVncInfo, getSessionId } from './exam-api.js';

// Track retry attempts to prevent infinite loops
let retryCount = 0;
const MAX_RETRIES = 5;
const RETRY_DELAY = 5000;

// Connect to VNC for the given session
function connectToRemoteDesktop(vncFrame, statusCallback, sessionId) {
    const sid = sessionId ?? getSessionId();
    if (statusCallback) {
        statusCallback('Connecting to Remote Desktop...', 'info');
    }
    return getVncInfo(sid)
        .then(data => {
            // Reset retry count on successful VNC info fetch
            retryCount = 0;
            
            const basePath = data.vncProxyPath || `/api/sessions/${encodeURIComponent(sid)}/vnc-proxy`;
            // Include path parameter to route websockify through session-specific endpoint
            // Also include sessionId in query for root /websockify fallback
            const websockifyPath = encodeURIComponent(`/websockify?sessionId=${encodeURIComponent(sid)}`);
            const vncUrl = `${basePath}/?autoconnect=true&resize=scale&show_dot=true&reconnect=true&password=${encodeURIComponent(data.defaultPassword || '')}&path=${websockifyPath}`;
            vncFrame.src = vncUrl;
            if (statusCallback) statusCallback('Connected to Session', 'success');
            return vncUrl;
        })
        .catch(error => {
            console.error('Error connecting to Remote Desktop:', error);
            retryCount++;
            
            // Check if it's a permanent failure (session not found)
            const isSessionError = error.message && (
                error.message.includes('404') || 
                error.message.includes('Session not found') ||
                error.message.includes('not available')
            );
            
            if (isSessionError) {
                // Session doesn't exist - this is a permanent failure, don't retry
                console.error('Session not found - cannot connect to Remote Desktop');
                if (statusCallback) {
                    statusCallback('Session not found. Please return to dashboard and start a new session.', 'error');
                }
                // Show a clear error in the VNC frame instead of loading wrong content
                vncFrame.srcdoc = `
                    <html>
                    <body style="display:flex;align-items:center;justify-content:center;height:100%;margin:0;background:#1a1a2e;color:#fff;font-family:sans-serif;">
                        <div style="text-align:center;padding:20px;">
                            <h2>Session Not Available</h2>
                            <p>The lab session could not be found or has expired.</p>
                            <p>Please return to the dashboard and start a new session.</p>
                        </div>
                    </body>
                    </html>
                `;
                return Promise.reject(new Error('Session not available'));
            }
            
            // Check if we've exceeded max retries
            if (retryCount >= MAX_RETRIES) {
                console.error(`Max retries (${MAX_RETRIES}) exceeded for Remote Desktop connection`);
                if (statusCallback) {
                    statusCallback('Failed to connect after multiple attempts. Please refresh the page.', 'error');
                }
                vncFrame.srcdoc = `
                    <html>
                    <body style="display:flex;align-items:center;justify-content:center;height:100%;margin:0;background:#1a1a2e;color:#fff;font-family:sans-serif;">
                        <div style="text-align:center;padding:20px;">
                            <h2>Connection Failed</h2>
                            <p>Could not connect to the Remote Desktop after multiple attempts.</p>
                            <p>Please refresh the page or contact support.</p>
                        </div>
                    </body>
                    </html>
                `;
                return Promise.reject(new Error('Max retries exceeded'));
            }
            
            // Transient error - retry with backoff
            if (statusCallback) {
                statusCallback(`Failed to connect. Retrying (${retryCount}/${MAX_RETRIES})...`, 'error');
            }
            return new Promise(resolve => {
                setTimeout(() => resolve(connectToRemoteDesktop(vncFrame, statusCallback, sid)), RETRY_DELAY);
            });
        });
}

// Setup Remote Desktop frame event handlers
function setupRemoteDesktopFrameHandlers(vncFrame, statusCallback) {
    vncFrame.addEventListener('load', function() {
        if (vncFrame.src !== 'about:blank') {
            console.log('Remote Desktop frame loaded successfully');
            if (statusCallback) {
                statusCallback('Connected to Session', 'success');
            }
        }
    });
    
    vncFrame.addEventListener('error', function(e) {
        console.error('Error loading Remote Desktop frame:', e);
        if (statusCallback) {
            statusCallback('Error connecting to Remote Desktop. Retrying...', 'error');
        }
        // Try to reconnect after a delay
        setTimeout(() => connectToRemoteDesktop(vncFrame, statusCallback), 5000);
    });
}

export {
    connectToRemoteDesktop,
    setupRemoteDesktopFrameHandlers
}; 