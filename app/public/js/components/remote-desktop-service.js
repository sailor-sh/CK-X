/**
 * Remote Desktop Service
 * Handles remote desktop connection and management. Requires sessionId for per-session isolation.
 */
import { getVncInfo, getSessionId } from './exam-api.js';

// Connect to VNC for the given session
function connectToRemoteDesktop(vncFrame, statusCallback, sessionId) {
    const sid = sessionId ?? getSessionId();
    if (statusCallback) {
        statusCallback('Connecting to Remote Desktop...', 'info');
    }
    return getVncInfo(sid)
        .then(data => {
            const basePath = data.vncProxyPath || `/api/sessions/${encodeURIComponent(sid)}/vnc-proxy`;
            const vncUrl = `${basePath}/?autoconnect=true&resize=scale&show_dot=true&reconnect=true&password=${encodeURIComponent(data.defaultPassword || '')}`;
            vncFrame.src = vncUrl;
            if (statusCallback) statusCallback('Connected to Session', 'success');
            return vncUrl;
        })
        .catch(error => {
            console.error('Error connecting to Remote Desktop:', error);
            if (statusCallback) statusCallback('Failed to connect to Remote Desktop. Retrying...', 'error');
            return new Promise(resolve => {
                setTimeout(() => resolve(connectToRemoteDesktop(vncFrame, statusCallback, sid)), 5000);
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