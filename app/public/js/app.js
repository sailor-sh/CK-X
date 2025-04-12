document.addEventListener('DOMContentLoaded', function () {
    const vncFrame = document.getElementById('vnc-frame');
    const connectBtn = document.getElementById('connect-btn');
    const fullscreenBtn = document.getElementById('fullscreen-btn');

    connectBtn.addEventListener('click', function () {
        // Connect to the VNC server through the service
        vncFrame.src = `http://${window.location.hostname}:${window.location.port}/vnc-proxy/`;
    });

    fullscreenBtn.addEventListener('click', function () {
        if (vncFrame.requestFullscreen) {
            vncFrame.requestFullscreen();
        } else if (vncFrame.webkitRequestFullscreen) {
            vncFrame.webkitRequestFullscreen();
        } else if (vncFrame.msRequestFullscreen) {
            vncFrame.msRequestFullscreen();
        }
    });
}); 