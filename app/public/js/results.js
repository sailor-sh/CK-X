document.addEventListener('DOMContentLoaded', function() {
    // DOM elements
    const pageLoader = document.getElementById('pageLoader');
    const errorMessage = document.getElementById('errorMessage');
    const errorText = document.getElementById('errorText');
    const retryButton = document.getElementById('retryButton');
    const resultsContent = document.getElementById('resultsContent');
    const examIdElement = document.getElementById('examId');
    const completedAtElement = document.getElementById('completedAt');
    const totalScoreElement = document.getElementById('totalScore');
    const totalPossibleScoreElement = document.getElementById('totalPossibleScore');
    const rankTextElement = document.getElementById('rankText');
    const rankBadgeElement = document.getElementById('rankBadge');
    const questionsContainer = document.getElementById('questionsContainer');
    const dashboardBtn = document.getElementById('dashboardBtn');
    const reEvaluateBtn = document.getElementById('reEvaluateBtn');
    const currentExamBtn = document.getElementById('currentExamBtn');
    const terminateBtn = document.getElementById('terminateBtn');
    const viewAnswersBtn = document.getElementById('viewAnswersBtn');
    
    // Configuration for polling
    const POLLING_INTERVAL = 2000; // 5 seconds
    const MAX_POLLING_TIME = 100000; // 10 minutes (600 seconds)
    let pollingStartTime = 0;
    let pollingTimer = null;
    let currentExamId = null; // Store the current exam ID
    
    // Add DOM elements for modal
    const terminateModal = document.getElementById('terminateModal');
    const closeModalBtn = document.getElementById('closeModalBtn');
    const cancelTerminateBtn = document.getElementById('cancelTerminateBtn');
    const confirmTerminateBtn = document.getElementById('confirmTerminateBtn');
    
    // Add event listeners for action buttons
    dashboardBtn.addEventListener('click', function() {
        window.location.href = '/';
    });
    
    currentExamBtn.addEventListener('click', () => {
        if (currentExamId) {
            window.open(`/exam.html?id=${currentExamId}`, '_blank');
        } else {
            showError('No exam ID available for redirection.');
        }
    });
    
    viewAnswersBtn.addEventListener('click', () => {
        if (currentExamId) {
            window.open(`/answers.html?id=${currentExamId}`, '_blank');
        } else {
            showError('No exam ID available for viewing answers.');
        }
    });
    
    reEvaluateBtn.addEventListener('click', function() {
        if (currentExamId) {
            // Disable the button while re-evaluating
            reEvaluateBtn.disabled = true;
            reEvaluateBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Evaluating...';
            
            // Call the API to re-evaluate the exam
            initiateReEvaluation(currentExamId);
        } else {
            showError('No exam ID available for re-evaluation.');
        }
    });
    
    terminateBtn.addEventListener('click', function() {
        if (!currentExamId) {
            showError('No exam ID available for termination.');
            return;
        }
        
        // Show modal instead of confirm dialog
        terminateModal.style.display = 'flex';
    });
    
    // Close modal when clicking the close button
    closeModalBtn.addEventListener('click', function() {
        terminateModal.style.display = 'none';
    });
    
    // Close modal when clicking the cancel button
    cancelTerminateBtn.addEventListener('click', function() {
        terminateModal.style.display = 'none';
    });
    
    // Handle confirm termination
    confirmTerminateBtn.addEventListener('click', function() {
        // Disable the button while terminating
        confirmTerminateBtn.disabled = true;
        confirmTerminateBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i> Terminating...';
        
        // Call the API to terminate the session
        fetch(`/facilitator/api/v1/exams/${currentExamId}/terminate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            console.log('Session terminated:', data);
            // Redirect to dashboard after successful termination
            window.location.href = '/';
        })
        .catch(error => {
            console.error('Error terminating session:', error);
            confirmTerminateBtn.disabled = false;
            confirmTerminateBtn.innerHTML = '<i class="fas fa-power-off me-2"></i>Terminate Session';
            terminateModal.style.display = 'none';
            showError('Failed to terminate session: ' + error.message);
        });
    });
    
    // Close modal when clicking outside of it
    window.addEventListener('click', function(event) {
        if (event.target === terminateModal) {
            terminateModal.style.display = 'none';
        }
    });
    
    // Function to initiate re-evaluation
    function initiateReEvaluation(examId) {
        // Hide results and show loading
        resultsContent.style.display = 'none';
        pageLoader.style.display = 'flex';
        
        // Update loader message
        updateLoaderMessage('Re-evaluation in progress...');
        
        fetch(`/facilitator/api/v1/exams/${examId}/evaluate`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            console.log('Re-evaluation started:', data);
            
            // Start polling for results
            startPolling(examId);
        })
        .catch(error => {
            console.error('Error starting re-evaluation:', error);
            reEvaluateBtn.disabled = false;
            reEvaluateBtn.innerHTML = '<i class="fas fa-sync-alt me-2"></i>Re-evaluate Exam';
            showError('Failed to start re-evaluation: ' + error.message);
        });
    }
    
    // Get exam ID from URL
    function getExamId() {
        const urlParams = new URLSearchParams(window.location.search);
        const examId = urlParams.get('id');
        
        if (!examId) {
            showError('No exam ID provided. Please return to the dashboard.');
            return null;
        }
        
        currentExamId = examId; // Store the exam ID for later use
        return examId;
    }
    
    // Format date for display
    function formatDate(dateString) {
        const options = { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric', 
            hour: '2-digit', 
            minute: '2-digit' 
        };
        return new Date(dateString).toLocaleDateString(undefined, options);
    }
    
    // Show error message
    function showError(message) {
        pageLoader.style.display = 'none';
        errorText.textContent = message;
        errorMessage.style.display = 'block';
        resultsContent.style.display = 'none';
    }
    
    // Update loader message
    function updateLoaderMessage(message) {
        const loaderMessage = document.getElementById('loaderMessage');
        if (loaderMessage) {
            loaderMessage.textContent = message;
        }
    }
    
    // Start polling for exam results
    function startPolling(examId) {
        // Save the start time for tracking elapsed time
        pollingStartTime = Date.now();
        
        // Update UI to show evaluation in progress
        updateLoaderMessage('Evaluation in progress... (typically takes 2-3 minutes)');
        
        // Start polling for status changes
        pollingTimer = setInterval(() => {
            checkExamStatus(examId);
        }, POLLING_INTERVAL);
    }
    
    // Stop polling
    function stopPolling() {
        if (pollingTimer) {
            clearInterval(pollingTimer);
            pollingTimer = null;
        }
    }
    
    // Update progress indicator
    function updateProgressIndicator(elapsedSeconds) {
        // Simplified - just show static message
        updateLoaderMessage('Evaluation in progress... (typically takes 2-3 minutes)');
    }
    
    // Check exam status (for polling)
    function checkExamStatus(examId) {
        // Check if we've exceeded maximum polling time
        if (Date.now() - pollingStartTime > MAX_POLLING_TIME) {
            stopPolling();
            showError('Exam evaluation is taking longer than expected. Please try again later.');
            return;
        }
        
        // Calculate elapsed time for tracking only (not displayed)
        const elapsedSeconds = Math.floor((Date.now() - pollingStartTime) / 1000);
        
        // Check if exam status and results are available
        fetch(`/facilitator/api/v1/exams/${examId}/status`)
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP error! Status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                // If evaluation is complete, fetch and display results
                if (data.status === 'EVALUATED') {
                    stopPolling();
                    fetchExamResults(examId);
                } else if (data.status === 'EVALUATING') {
                    // Keep showing static message without progress updates
                    updateLoaderMessage('Evaluation in progress... (typically takes 2-3 minutes)');
                } else if (data.status === 'EVALUATION_FAILED') {
                    stopPolling();
                    showError('Exam evaluation failed. Please contact support.');
                } else {
                    // For any other status, show appropriate message
                    updateLoaderMessage(`Waiting for evaluation to start... Current status: ${data.status}`);
                }
            })
            .catch(error => {
                console.error('Error checking exam status:', error);
                // Don't stop polling on network errors - will retry on next interval
            });
    }
    
    // Fetch exam results from API
    function fetchExamResults(examId = null) {
        // If no exam ID provided, get it from the URL
        if (!examId) {
            examId = getExamId();
            if (!examId) {
                showError('No exam ID provided. Please return to the dashboard and try again.');
                return;
            }
        }
        
        // Store current exam ID for later use
        currentExamId = examId;
        
        // Show loader
        pageLoader.style.display = 'flex';
        updateLoaderMessage('Loading exam results...');
        
        errorMessage.style.display = 'none';
        resultsContent.style.display = 'none';
        
        const apiUrl = `/facilitator/api/v1/exams/${examId}/result`;
        
        fetch(apiUrl)
            .then(response => {
                if (!response.ok) {
                    if (response.status === 404) {
                        // If results not found, check status to see if we need to start polling
                        return checkResultsStatus(examId);
                    }
                    throw new Error(`HTTP error! Status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                if (data && data.data) {
                    renderExamResults(data.data);
                    
                    // Reset the Re-evaluate button state if it was disabled
                    if (reEvaluateBtn.disabled) {
                        reEvaluateBtn.disabled = false;
                        reEvaluateBtn.innerHTML = '<i class="fas fa-sync-alt me-2"></i>Re-evaluate Exam';
                    }
                } else if (data && data.status === 'polling_started') {
                    // This is a special status returned by checkResultsStatus
                    // Polling has been started, so we just wait
                } else {
                    throw new Error('Invalid response format');
                }
            })
            .catch(error => {
                console.error('Error loading exam results:', error);
                showError(error.message || 'Failed to load exam results');
                
                // Reset the Re-evaluate button state if it was disabled
                if (reEvaluateBtn.disabled) {
                    reEvaluateBtn.disabled = false;
                    reEvaluateBtn.innerHTML = '<i class="fas fa-sync-alt me-2"></i>Re-evaluate Exam';
                }
            });
    }
    
    // Check if we need to poll for results
    function checkResultsStatus(examId) {
        return fetch(`/facilitator/api/v1/exams/${examId}/status`)
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP error! Status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                if (data.status === 'EVALUATING') {
                    // Start polling if exam is being evaluated
                    startPolling(examId);
                    return { status: 'polling_started' };
                } else if (data.status === 'EVALUATION_FAILED') {
                    throw new Error('Exam evaluation failed');
                } else if (data.status !== 'EVALUATED') {
                    throw new Error(`Exam results not available. Current status: ${data.status}`);
                } else {
                    // If status is EVALUATED but no results found, there might be a delay
                    // Start polling anyway in case results are being finalized
                    startPolling(examId);
                    return { status: 'polling_started' };
                }
            });
    }
    
    // Render exam results
    function renderExamResults(results) {
        // Update basic info
        examIdElement.textContent = `Exam ID: ${results.examId}`;
        completedAtElement.textContent = `Completed: ${formatDate(results.completedAt)}`;
        
        // Update score
        totalScoreElement.textContent = results.totalScore;
        totalPossibleScoreElement.textContent = results.totalPossibleScore;
        
        // Update rank
        rankTextElement.textContent = results.rank === 'high' ? 'High Score' : 
                                    results.rank === 'medium' ? 'Medium Score' : 'Low Score';
        
        // Apply rank class
        rankBadgeElement.className = 'rank-badge';
        rankBadgeElement.classList.add(`rank-${results.rank}`);
        
        // Clear questions container
        questionsContainer.innerHTML = '';
        
        // Add questions and verifications
        if (results.evaluationResults && results.evaluationResults.length > 0) {
            // Sort questions by ID (convert to number for proper numeric sorting)
            const sortedQuestions = [...results.evaluationResults].sort((a, b) => {
                const idA = parseInt(a.id);
                const idB = parseInt(b.id);
                return idA - idB;
            });
            
            sortedQuestions.forEach(question => {
                // Sort verification steps by ID
                const sortedVerifications = [...question.verificationResults].sort((a, b) => {
                    const idA = parseInt(a.id);
                    const idB = parseInt(b.id);
                    return idA - idB;
                });
                
                // Calculate question score
                const questionScore = sortedVerifications.reduce((total, v) => total + v.score, 0);
                const questionPossibleScore = sortedVerifications.reduce((total, v) => total + v.weightage, 0);
                
                // Create question card
                const questionCard = document.createElement('div');
                questionCard.className = 'question-card';
                
                // Create question header
                const questionHeader = document.createElement('div');
                questionHeader.className = 'question-header';
                questionHeader.innerHTML = `
                    <h3 class="question-title">Question ${question.id}</h3>
                    <div class="question-score">${questionScore} of ${questionPossibleScore}</div>
                `;
                
                // Create verification list
                const verificationList = document.createElement('ul');
                verificationList.className = 'verification-items';
                
                // Add verification items
                sortedVerifications.forEach(verification => {
                    const item = document.createElement('li');
                    item.className = 'verification-item';
                    
                    item.innerHTML = `
                        <div class="verification-description">${verification.description}</div>
                        <div class="verification-status ${verification.validAnswer ? 'status-success' : 'status-failure'}">
                            ${verification.validAnswer ? 
                                '<i class="fas fa-check-circle"></i>' : 
                                '<i class="fas fa-times-circle"></i>'}
                        </div>
                    `;
                    
                    verificationList.appendChild(item);
                });
                
                // Assemble question card
                questionCard.appendChild(questionHeader);
                questionCard.appendChild(verificationList);
                
                // Add to container
                questionsContainer.appendChild(questionCard);
            });
        } else {
            questionsContainer.innerHTML = '<p>No evaluation results available</p>';
        }
        
        // Hide loader and show content
        pageLoader.style.display = 'none';
        resultsContent.style.display = 'block';
    }
    
    // Add retry button event listener
    retryButton.addEventListener('click', fetchExamResults);
    
    // Start by fetching exam results
    fetchExamResults();
    
    // Clean up when leaving the page
    window.addEventListener('beforeunload', () => {
        stopPolling();
    });
}); 