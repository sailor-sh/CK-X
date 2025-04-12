/**
 * Feedback module for CK-X Simulator
 * Handles displaying feedback prompts and notifications
 */

// Wait for DOM to be loaded
document.addEventListener('DOMContentLoaded', function () {
    // Show feedback reminder after a delay
    setTimeout(function () {
        // Check if results have loaded
        const resultsContent = document.getElementById('resultsContent');
        if (resultsContent && resultsContent.style.display !== 'none') {
            showFeedbackReminder();
        } else {
            // If results haven't loaded yet, wait for them
            const observer = new MutationObserver(function (mutations) {
                mutations.forEach(function (mutation) {
                    if (mutation.target.style.display !== 'none') {
                        showFeedbackReminder();
                        observer.disconnect();
                    }
                });
            });

            if (resultsContent) {
                observer.observe(resultsContent, {
                    attributes: true,
                    attributeFilter: ['style']
                });
            }
        }
    }, 10 * 1000); // Show after 10 seconds
});

/**
 * Display a toast notification prompting for feedback
 */
function showFeedbackReminder() {
    // Create toast element
    const toast = document.createElement('div');
    toast.className = 'toast-notification';
    toast.innerHTML = `
        <div class="toast-content">
            <i class="fas fa-comment-dots toast-icon"></i>
            <div class="toast-message">
                <p><strong>Your opinion matters!</strong></p>
                <p>Please take a moment to share your feedback on CK-X</p>
            </div>
            <a href="https://forms.gle/Dac9ALQnQb2dH1mw8" target="_blank" class="toast-button">Give Feedback</a>
            <button class="toast-close">&times;</button>
        </div>
    `;

    document.body.appendChild(toast);

    // Add close functionality
    toast.querySelector('.toast-close').addEventListener('click', function () {
        toast.style.animation = 'slideOut 0.5s ease forwards';
        setTimeout(function () {
            if (document.body.contains(toast)) {
                document.body.removeChild(toast);
            }
        }, 500);
    });

    // Auto-close after 15 seconds
    setTimeout(function () {
        if (document.body.contains(toast)) {
            toast.style.animation = 'slideOut 0.5s ease forwards';
            setTimeout(function () {
                if (document.body.contains(toast)) {
                    document.body.removeChild(toast);
                }
            }, 500);
        }
    }, 15000);
} 