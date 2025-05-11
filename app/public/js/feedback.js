/**
 * Feedback module for CK-X Simulator
 * Handles displaying feedback prompts and notifications
 */

// Feedback state management
const feedbackState = {
    rating: null,
    comment: '',
    isTestimonial: false,
    name: '',
    socialHandle: '',
    submitted: false
};

// Wait for DOM to be loaded
document.addEventListener('DOMContentLoaded', function() {
    // DOM elements
    const feedbackModal = document.getElementById('feedbackModal');
    const submitFeedbackBtn = document.getElementById('submitFeedbackBtn');
    const testimonialConsent = document.getElementById('testimonialConsent');
    const testimonialFields = document.getElementById('testimonialFields');
    const feedbackComment = document.getElementById('feedbackComment');
    const starRatingInputs = document.querySelectorAll('input[name="rating"]');
    
    // Check if user has already submitted feedback
    const hasSubmittedFeedback = localStorage.getItem('ckx_feedback_submitted');
    
    // Check if we should show the reminder now
    if (!hasSubmittedFeedback) {
        // Check if we're skipping and when to ask again
        const skipTimestamp = localStorage.getItem('ckx_feedback_skip_until');
        const currentTime = new Date().getTime();
        
        if (!skipTimestamp || currentTime > parseInt(skipTimestamp)) {
            // Safe to show after a delay
            setTimeout(showFeedbackModal, 5000);
        }
    }
    
    // Toggle testimonial fields visibility based on checkbox
    testimonialConsent.addEventListener('change', function() {
        testimonialFields.style.display = this.checked ? 'block' : 'none';
        feedbackState.isTestimonial = this.checked;
    });
    
    // Handle rating selection
    starRatingInputs.forEach(input => {
        input.addEventListener('change', function() {
            feedbackState.rating = parseInt(this.value);
        });
    });
    
    // Handle comment input
    feedbackComment.addEventListener('input', function() {
        feedbackState.comment = this.value.trim();
    });
    
    // Handle name and social handle inputs
    document.getElementById('testimonialName').addEventListener('input', function() {
        feedbackState.name = this.value.trim();
    });
    
    document.getElementById('testimonialSocial').addEventListener('input', function() {
        feedbackState.socialHandle = this.value.trim();
    });
    
    // Submit feedback handler
    submitFeedbackBtn.addEventListener('click', function() {
        // Validate that we have at least a rating
        if (!feedbackState.rating) {
            alert('Please select a rating before submitting your feedback.');
            return;
        }
        
        // Validate name is provided if user opts for testimonial
        if (feedbackState.isTestimonial && !feedbackState.name) {
            alert('Please provide your name to be featured in testimonials.');
            return;
        }
        
        // Disable the button to prevent multiple submissions
        submitFeedbackBtn.disabled = true;
        submitFeedbackBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i> Submitting...';
        
        // Send feedback data
        sendFeedbackData();
    });
});

/**
 * Display the feedback modal
 */
function showFeedbackModal() {
    // Only show if results have loaded
    const resultsContent = document.getElementById('resultsContent');
    if (resultsContent && resultsContent.style.display !== 'none') {
        document.getElementById('feedbackModal').style.display = 'flex';
    } else {
        // If results haven't loaded yet, wait for them
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.target.style.display !== 'none') {
                    document.getElementById('feedbackModal').style.display = 'flex';
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
}

/**
 * Send feedback data to the server
 */
function sendFeedbackData() {
    // Import API functions if needed
    import('./components/exam-api.js').then(api => {
        // Get the exam ID from the URL or DOM
        const urlParams = new URLSearchParams(window.location.search);
        const examId = urlParams.get('id') || document.getElementById('examId')?.textContent.replace('Exam ID: ', '').trim();
        
        if (!examId) {
            console.error('No exam ID found for feedback submission');
            showFeedbackSubmissionResult(false);
            return;
        }
        
        // Construct feedback data
        const feedbackData = {
            type: 'feedback',
            rating: feedbackState.rating,
            comment: feedbackState.comment,
            isTestimonial: feedbackState.isTestimonial,
            name: feedbackState.name,
            socialHandle: feedbackState.socialHandle
        };
        
        // Use the API function to submit feedback
        api.submitFeedback(examId, feedbackData)
            .then(data => {
                console.log('Feedback submitted successfully:', data);
                // Set local storage to remember that feedback was submitted
                localStorage.setItem('ckx_feedback_submitted', 'true');
                // Hide the modal
                document.getElementById('feedbackModal').style.display = 'none';
                // Show success notification
                showFeedbackSubmissionResult(true);
            })
            .catch(error => {
                console.error('Error submitting feedback:', error);
                // Hide the modal despite the error
                document.getElementById('feedbackModal').style.display = 'none';
                showFeedbackSubmissionResult(false);
            });
    }).catch(error => {
        console.error('Error importing API module:', error);
        document.getElementById('feedbackModal').style.display = 'none';
        showFeedbackSubmissionResult(false);
    });
}

/**
 * Show toast notification for feedback submission result
 * @param {boolean} success - Whether the submission was successful
 */
function showFeedbackSubmissionResult(success) {
    const submitFeedbackBtn = document.getElementById('submitFeedbackBtn');
    
    // Reset button state
    submitFeedbackBtn.disabled = false;
    submitFeedbackBtn.innerHTML = '<i class="fas fa-paper-plane me-2"></i> Submit Feedback';
    
    // Create toast element
    const toast = document.createElement('div');
    toast.className = 'toast-notification';
    
    if (success) {
        toast.innerHTML = `
            <div class="toast-content">
                <i class="fas fa-check-circle toast-icon" style="color: #28a745;"></i>
                <div class="toast-message">
                    <p><strong>Thank you!</strong></p>
                    <p>Your feedback has been submitted successfully.</p>
                </div>
                <button class="toast-close">&times;</button>
            </div>
        `;
    } else {
        toast.innerHTML = `
            <div class="toast-content">
                <i class="fas fa-exclamation-circle toast-icon" style="color: #dc3545;"></i>
                <div class="toast-message">
                    <p><strong>Something went wrong</strong></p>
                    <p>We couldn't submit your feedback. Please try again.</p>
                </div>
                <button class="toast-close">&times;</button>
            </div>
        `;
    }
    
    document.body.appendChild(toast);
    
    // Add close functionality
    toast.querySelector('.toast-close').addEventListener('click', function() {
        toast.style.animation = 'slideOut 0.5s ease forwards';
        setTimeout(function() {
            if (document.body.contains(toast)) {
                document.body.removeChild(toast);
            }
        }, 500);
    });
    
    // Auto-close after 5 seconds
    setTimeout(function() {
        if (document.body.contains(toast)) {
            toast.style.animation = 'slideOut 0.5s ease forwards';
            setTimeout(function() {
                if (document.body.contains(toast)) {
                    document.body.removeChild(toast);
                }
            }, 500);
        }
    }, 5000);
} 