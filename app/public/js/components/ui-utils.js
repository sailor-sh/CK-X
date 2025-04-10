/**
 * UI Utilities
 * Handles common UI functions and interactions
 */

// Format time as mm:ss
function formatTime(totalSeconds) {
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

// Show connection status notification
function showConnectionStatus(element, message, type) {
    if (!element) return;
    
    element.textContent = message;
    element.className = 'connection-status show';
    
    if (type === 'success') {
        element.style.backgroundColor = 'rgba(25, 135, 84, 0.7)';

        // Hide the status after a few seconds for success messages
        setTimeout(() => {
            element.className = 'connection-status';
        }, 3000);
    } else if (type === 'error') {
        element.style.backgroundColor = 'rgba(220, 53, 69, 0.7)';
    } else {
        element.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
    }
}

// Function to request fullscreen mode
function requestFullscreen(element) {
    if (element.requestFullscreen) {
        element.requestFullscreen();
    } else if (element.mozRequestFullScreen) { // Firefox
        element.mozRequestFullScreen();
    } else if (element.webkitRequestFullscreen) { // Chrome, Safari, Opera
        element.webkitRequestFullscreen();
    } else if (element.msRequestFullscreen) { // IE/Edge
        element.msRequestFullscreen();
    }
}

// Function to exit fullscreen mode
function exitFullscreen() {
    if (document.exitFullscreen) {
        document.exitFullscreen();
    } else if (document.mozCancelFullScreen) { // Firefox
        document.mozCancelFullScreen();
    } else if (document.webkitExitFullscreen) { // Chrome, Safari, Opera
        document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) { // IE/Edge
        document.msExitFullscreen();
    }
}

// Function to toggle fullscreen mode
function toggleFullscreen() {
    if (!document.fullscreenElement &&
        !document.mozFullScreenElement &&
        !document.webkitFullscreenElement &&
        !document.msFullscreenElement) {
        requestFullscreen(document.documentElement);
    } else {
        exitFullscreen();
    }
}

// Show modal for completed exams
function showExamCompletedModal(examId, status) {
    // Create a modal to show exam completion and option to connect to session
    const completionModalHTML = `
        <div class="modal fade" id="examCompletedModal" tabindex="-1" aria-labelledby="examCompletedModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-primary text-white">
                        <h5 class="modal-title" id="examCompletedModalLabel">
                            ${status === 'EVALUATED' ? 'Exam Complete' : 'Exam Being Evaluated'}
                        </h5>
                    </div>
                    <div class="modal-body">
                        ${status === 'EVALUATED' ? 
                            '<p>This exam has been completed and your results are ready to view.</p>' : 
                            '<p>This exam has been completed and is currently being evaluated.</p><p>You can view the results once evaluation is complete.</p>'
                        }
                        <p>You can still connect to your exam environment to review your work.</p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-primary" id="connectToSessionBtn">Connect to Session</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Check if modal already exists, remove it if it does
    const existingModal = document.getElementById('examCompletedModal');
    if (existingModal) {
        existingModal.remove();
    }
    
    // Add modal to body
    document.body.insertAdjacentHTML('beforeend', completionModalHTML);
    
    // Show modal
    const completionModal = new bootstrap.Modal(document.getElementById('examCompletedModal'));
    completionModal.show();
    
    // Handle connect to session button click
    document.getElementById('connectToSessionBtn').addEventListener('click', () => {
        // Close the modal
        completionModal.hide();
        
        // Remove the modal from DOM after hiding
        setTimeout(() => {
            const modalElement = document.getElementById('examCompletedModal');
            if (modalElement) {
                const modalBackdrop = document.querySelector('.modal-backdrop');
                if (modalBackdrop) {
                    modalBackdrop.remove();
                }
                modalElement.remove();
            }
        }, 300);
        
        // Dispatch event to notify exam.js to connect to the session
        const examCompleteEvent = new CustomEvent('examCompletedSession', {
            detail: { examId }
        });
        
        document.dispatchEvent(examCompleteEvent);
    });
}

// Update UI based on fullscreen state
function updateFullscreenUI(fullscreenBtn) {
    if (fullscreenBtn) {
        if (document.fullscreenElement ||
            document.webkitFullscreenElement ||
            document.mozFullScreenElement ||
            document.msFullscreenElement) {
            fullscreenBtn.textContent = 'Exit Fullscreen';
        } else {
            fullscreenBtn.textContent = 'Enter Fullscreen';
        }
    }
}

// Show a toast notification
function showToast(message, options = {}) {
    const toastContainer = document.getElementById('toastContainer');
    if (!toastContainer) return;
    
    // Default options
    const defaults = {
        bgColor: 'bg-primary',
        textColor: 'text-white',
        autohide: true,
        delay: 5000
    };
    
    // Merge with custom options
    const settings = { ...defaults, ...options };
    
    // Create a unique ID for this toast
    const toastId = 'toast-' + Date.now();
    
    // Create toast HTML
    const toastHTML = `
        <div class="toast ${settings.bgColor} ${settings.textColor}" id="${toastId}" role="alert" aria-live="assertive" aria-atomic="true" ${settings.autohide ? 'data-bs-autohide="true"' : 'data-bs-autohide="false"'} data-bs-delay="${settings.delay}">
            <div class="toast-header">
                <strong class="me-auto">Exam Notification</strong>
                <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
            <div class="toast-body">
                ${message}
            </div>
        </div>
    `;
    
    // Add toast to container
    toastContainer.insertAdjacentHTML('beforeend', toastHTML);
    
    // Initialize and show the toast
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement);
    toast.show();
    
    // Return the toast instance for later reference
    return toast;
}

export {
    formatTime,
    showConnectionStatus,
    requestFullscreen,
    exitFullscreen,
    toggleFullscreen,
    showExamCompletedModal,
    updateFullscreenUI,
    showToast
}; 