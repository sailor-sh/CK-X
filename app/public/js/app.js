document.addEventListener('DOMContentLoaded', function() {
    const vncFrame = document.getElementById('vnc-frame');
    const connectBtn = document.getElementById('connect-btn');
    const fullscreenBtn = document.getElementById('fullscreen-btn');
    
    connectBtn.addEventListener('click', function() {
        // Session-scoped VNC (default session for index/demo when no exam sessionId in URL)
        const sessionId = new URLSearchParams(window.location.search).get('sessionId') || 'default';
        vncFrame.src = `${window.location.origin}/api/sessions/${encodeURIComponent(sessionId)}/vnc-proxy/`;
    });
    
    fullscreenBtn.addEventListener('click', function() {
        if (vncFrame.requestFullscreen) {
            vncFrame.requestFullscreen();
        } else if (vncFrame.webkitRequestFullscreen) {
            vncFrame.webkitRequestFullscreen();
        } else if (vncFrame.msRequestFullscreen) {
            vncFrame.msRequestFullscreen();
        }
    });
}); 