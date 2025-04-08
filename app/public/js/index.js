document.addEventListener('DOMContentLoaded', function() {
    const startExamBtn = document.getElementById('startExamBtn');
    const pageLoader = document.getElementById('pageLoader');
    const loaderMessage = document.getElementById('loaderMessage');
    const examSelectionModal = new bootstrap.Modal(document.getElementById('examSelectionModal'));
    
    // Form elements
    const examCategorySelect = document.getElementById('examCategory');
    const examNameSelect = document.getElementById('examName');
    const examDescription = document.getElementById('examDescription');
    const startSelectedExamBtn = document.getElementById('startSelectedExam');
    const viewPastResultsBtn = document.getElementById('viewPastResultsBtn');
    
    // Hide View Results button by default - only show when current exam is EVALUATING or EVALUATED
    if (viewPastResultsBtn) {
        viewPastResultsBtn.closest('li').style.display = 'none';
    }
    
    let labs = []; // Will store all labs fetched from the API
    let selectedLab = null; // Will store the currently selected lab
    
    // Check for current exam status on page load
    checkCurrentExamStatus();
    
    console.log('Loading labs on page load...');
    // Load labs data when the page loads
    fetchLabs(false);

    // Function to check current exam status
    function checkCurrentExamStatus() {
        fetch('/facilitator/api/v1/exams/current')
            .then(response => {
                if (!response.ok) {
                    if (response.status !== 404) {
                        console.error('Error checking current exam status:', response.status);
                    }
                    return null;
                }
                return response.json();
            })
            .then(data => {
                if (data && data.id) {
                    // Store current exam data in localStorage for the View Results functionality
                    localStorage.setItem('currentExamData', JSON.stringify(data));
                    
                    // Show View Results button only if status is EVALUATING or EVALUATED
                    if (data.status === 'EVALUATING' || data.status === 'EVALUATED') {
                        if (viewPastResultsBtn) {
                            viewPastResultsBtn.closest('li').style.display = 'block';
                        }
                    }
                    
                    // If exam is in PREPARING state, show loading overlay and start polling
                    if (data.status === 'PREPARING') {
                        console.log('Exam is in PREPARING state, showing loading overlay');
                        showLoadingOverlay();
                        updateLoadingMessage('Preparing lab environment...');
                        updateExamInfo(data.info?.name || 'Unknown Exam');
                        // Start polling for status
                        pollExamStatus(data.id).then(statusData => {
                            if (statusData.status === 'READY') {
                                // Redirect to exam page when ready
                                window.location.href = `/exam.html?id=${data.id}`;
                            }
                        });
                    }
                }
            })
            .catch(error => {
                console.error('Error checking current exam status:', error);
            });
    }

    // Event listener for the "Start Exam" button
    startExamBtn.addEventListener('click', function(e) {
        e.preventDefault();
        
        console.log('Checking for active exam sessions...');
        // First check if there's any active exam
        fetch('/facilitator/api/v1/exams/current')
            .then(response => {
                if (response.status === 404) {
                    console.log('No active exam found, proceeding with new exam');
                    // No active exam, proceed as normal
                    if (labs.length > 0) {
                        console.log('Using pre-loaded labs data');
                        examSelectionModal.show();
                    } else {
                        console.log('No pre-loaded labs data available, fetching now...');
                        fetchLabs(true);
                    }
                    return null;
                }
                
                if (!response.ok) {
                    console.error('Error checking current exam status:', response.status);
                    return null;
                }
                
                return response.json();
            })
            .then(data => {
                if (data && data.id) {
                    console.log('Active exam found:', data.id, 'Status:', data.status);
                    // Active exam found, show warning modal
                    showActiveExamWarningModal(data);
                }
            })
            .catch(error => {
                console.error('Error checking for active exam:', error);
                // Proceed anyway in case of error
                if (labs.length > 0) {
                    examSelectionModal.show();
                } else {
                    fetchLabs(true);
                }
            });
    });
    
    // Function to show warning modal for active exam
    function showActiveExamWarningModal(examData) {
        // Create modal HTML
        const modalHTML = `
            <div class="modal fade" id="activeExamWarningModal" tabindex="-1" aria-labelledby="activeExamWarningModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-dialog-centered">
                    <div class="modal-content rounded">
                        <div class="modal-header bg-dark text-white rounded-top">
                            <h5 class="modal-title text-white" id="activeExamWarningModalLabel">Active Exam Detected</h5>
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body">
                            <div class="alert alert-info">
                                <p>You already have an active exam session:</p>
                                <p><strong>${examData.info?.name || 'Unknown Exam'}</strong></p>
                                <p class="mb-0">Only one active exam session can be present at a time.</p>
                            </div>
                        </div>
                        <div class="modal-footer rounded-bottom">
                            <button type="button" class="btn btn-sm btn-primary" id="continueSessionBtn">CONTINUE CURRENT SESSION</button>
                            <button type="button" class="btn btn-sm btn-danger" id="terminateAndProceedBtn">TERMINATE AND PROCEED</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Add modal to DOM if it doesn't exist
        if (!document.getElementById('activeExamWarningModal')) {
            document.body.insertAdjacentHTML('beforeend', modalHTML);
        }
        
        // Get modal element and create Bootstrap modal
        const modalElement = document.getElementById('activeExamWarningModal');
        const warningModal = new bootstrap.Modal(modalElement);
        
        // Show the modal
        warningModal.show();
        
        // Remove any existing event listeners by cloning and replacing the buttons
        const oldTerminateBtn = document.getElementById('terminateAndProceedBtn');
        const newTerminateBtn = oldTerminateBtn.cloneNode(true);
        oldTerminateBtn.parentNode.replaceChild(newTerminateBtn, oldTerminateBtn);
        
        const oldContinueBtn = document.getElementById('continueSessionBtn');
        const newContinueBtn = oldContinueBtn.cloneNode(true);
        oldContinueBtn.parentNode.replaceChild(newContinueBtn, oldContinueBtn);
        
        // Add event listener for continue session button
        document.getElementById('continueSessionBtn').addEventListener('click', function() {
            // Redirect to the current exam
            window.location.href = `/exam.html?id=${examData.id}`;
        });
        
        // Add event listener for terminate and proceed button
        document.getElementById('terminateAndProceedBtn').addEventListener('click', function() {
            // Update button to show progress
            const terminateBtn = document.getElementById('terminateAndProceedBtn');
            terminateBtn.disabled = true;
            terminateBtn.innerHTML = '<div class="d-flex align-items-center justify-content-center"><span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span><span>TERMINATING...</span></div>';
            
            // Show loading overlay
            showLoadingOverlay();
            updateLoadingMessage('Terminating active session...');
            
            console.log('Attempting to terminate exam:', examData.id);
            // Call API to terminate the active exam
            fetch(`/facilitator/api/v1/exams/${examData.id}/terminate`, {
                method: 'POST'
            })
            .then(response => {
                if (!response.ok) {
                    console.error('Termination failed with status:', response.status);
                    throw new Error('Failed to terminate exam. Status: ' + response.status);
                }
                return response.json();
            })
            .then((data) => {
                console.log('Exam terminated successfully:', examData.id);
                // Hide the warning modal
                warningModal.hide();
                
                // Clear any stored exam data
                localStorage.removeItem('currentExamData');
                localStorage.removeItem('currentExamId');
                
                // Proceed with starting a new exam
                hideLoadingOverlay();
                if (labs.length > 0) {
                    examSelectionModal.show();
                } else {
                    fetchLabs(true);
                }
            })
            .catch(error => {
                console.error('Error terminating exam:', error);
                hideLoadingOverlay();
                
                // Reset button state
                terminateBtn.disabled = false;
                terminateBtn.innerHTML = 'Terminate and Proceed';
                
                alert('Failed to terminate the active exam. Please try again later.');
            });
            
            // Clean up the modal when it's hidden
            modalElement.addEventListener('hidden.bs.modal', function() {
                console.log('Modal hidden, cleaning up event listeners');
                
                // Remove event listeners by replacing buttons with clones if they exist
                if (document.getElementById('terminateAndProceedBtn')) {
                    const oldTerminateBtn = document.getElementById('terminateAndProceedBtn');
                    const newTerminateBtn = oldTerminateBtn.cloneNode(true);
                    oldTerminateBtn.parentNode.replaceChild(newTerminateBtn, oldTerminateBtn);
                }
                
                if (document.getElementById('continueSessionBtn')) {
                    const oldContinueBtn = document.getElementById('continueSessionBtn');
                    const newContinueBtn = oldContinueBtn.cloneNode(true);
                    oldContinueBtn.parentNode.replaceChild(newContinueBtn, oldContinueBtn);
                }
            });
        });
    }
    
    // Fetch labs from the facilitator API
    function fetchLabs(showLoader = true) {
        console.log('Fetching labs, showLoader:', showLoader);
        if (showLoader) {
            pageLoader.style.display = 'flex';
            loaderMessage.textContent = 'Loading labs...';
        }
        
        fetch('/facilitator/api/v1/assements/')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to fetch labs. Status: ' + response.status);
                }
                return response.json();
            })
            .then(data => {
                labs = data;
                console.log('Labs loaded successfully, count:', labs.length);
                if (showLoader) {
                    pageLoader.style.display = 'none';
                    examSelectionModal.show();
                }
                populateLabCategories();
            })
            .catch(error => {
                console.error('Error fetching labs:', error);
                if (showLoader) {
                    pageLoader.style.display = 'none';
                    alert('Failed to load labs. Please try again later.');
                }
            });
    }
    
    // Populate the lab categories dropdown
    function populateLabCategories() {
        // Get unique categories
        const categories = [...new Set(labs.map(lab => lab.category))];
        
        // If CKAD is available, select it by default
        if (categories.includes('CKAD')) {
            examCategorySelect.value = 'CKAD';
            filterLabsByCategory('CKAD');
        } else if (categories.length > 0) {
            examCategorySelect.value = categories[0];
            filterLabsByCategory(categories[0]);
        }
    }
    
    // Filter labs by category and populate the labs dropdown
    function filterLabsByCategory(category) {
        const filteredLabs = labs.filter(lab => lab.category === category);
        
        // Clear existing options
        examNameSelect.innerHTML = '<option value="">Select a lab</option>';
        
        // Add filtered labs to the dropdown
        filteredLabs.forEach(lab => {
            const option = document.createElement('option');
            option.value = lab.id;
            option.textContent = lab.name;
            examNameSelect.appendChild(option);
        });
        
        // Enable the lab name select
        examNameSelect.disabled = false;
        
        // If there are labs in this category, select the first one
        if (filteredLabs.length > 0) {
            examNameSelect.value = filteredLabs[0].id;
            updateLabDescription(filteredLabs[0]);
        } else {
            examDescription.textContent = 'No labs available for this category.';
            startSelectedExamBtn.disabled = true;
        }
    }
    
    // Update the lab description when a lab is selected
    function updateLabDescription(lab) {
        // Create a nicely formatted description
        const difficultyText = lab.difficulty || 'Medium';
        const examTimeText = lab.examDurationInMinutes || lab.estimatedTime || '30';
        
        const descriptionHTML = `
            <div class="exam-details">
                <p class="mb-0">${lab.description || 'No description available.'}</p>
            </div>
            <div class="exam-meta-container mt-3 pt-2 border-top">
                <div class="d-flex justify-content-start align-items-center">
                    <div class="exam-meta me-4">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-bar-chart-fill me-1" viewBox="0 0 16 16">
                            <path d="M1 11a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1v-3zm5-4a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v7a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V7zm5-5a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1V2z"/>
                        </svg>
                        Difficulty: ${difficultyText}
                    </div>
                    <div class="exam-meta">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-clock me-1" viewBox="0 0 16 16">
                            <path d="M8 3.5a.5.5 0 0 0-1 0V9a.5.5 0 0 0 .252.434l3.5 2a.5.5 0 0 0 .496-.868L8 8.71V3.5z"/>
                            <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16zm7-8A7 7 0 1 1 1 8a7 7 0 0 1 14 0z"/>
                        </svg>
                        Exam Time: ${examTimeText} minutes
                    </div>
                </div>
            </div>
        `;
        
        // No need to add styles dynamically anymore since they're in the CSS file
        
        // Use innerHTML to render the HTML content
        examDescription.innerHTML = descriptionHTML;
        selectedLab = lab;
        startSelectedExamBtn.disabled = false;
    }
    
    // Event listener for the exam category select
    examCategorySelect.addEventListener('change', function() {
        filterLabsByCategory(this.value);
    });
    
    // Event listener for the exam name select
    examNameSelect.addEventListener('change', function() {
        if (this.value) {
            const lab = labs.find(lab => lab.id === this.value);
            if (lab) {
                updateLabDescription(lab);
            }
        } else {
            examDescription.textContent = 'No lab selected.';
            selectedLab = null;
            startSelectedExamBtn.disabled = true;
        }
    });
    
    // Event listener for the start selected exam button
    startSelectedExamBtn.addEventListener('click', function() {
        if (selectedLab) {
            examSelectionModal.hide();
            showLoadingOverlay(); // Show the loading overlay instead of pageLoader
            updateLoadingMessage('Starting lab environment...');
            updateExamInfo(`Lab: ${selectedLab.name} | Difficulty: ${selectedLab.difficulty || 'Medium'}`);
            let userAgent = '';
            try {
                userAgent = navigator.userAgent;
            } catch (error) {
                console.error('Error getting user agent:', error);
            }
            selectedLab.userAgent = userAgent;
            
            // Make a POST request to the facilitator API - using exams endpoint for POST
            fetch('/facilitator/api/v1/exams/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(selectedLab)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to start lab. Status: ' + response.status);
                }
                return response.json();
            })
            .then(data => {
                // Store exam ID in localStorage
                localStorage.setItem('currentExamId', data.id);
                
                // Start polling for status
                const warmUpTime = data.warmUpTimeInSeconds || 30;
                updateLoadingMessage(`Preparing your lab environment (${warmUpTime}s estimated)`);
                
                // Poll for exam status until it's ready
                return pollExamStatus(data.id);
            })
            .then(() => {
                // Redirect to the lab page after status is READY
                const examId = localStorage.getItem('currentExamId');
                window.location.href = `/exam.html?id=${examId}`;
            })
            .catch(error => {
                console.error('Error starting lab:', error);
                hideLoadingOverlay();
                alert('Failed to start the lab. Please try again later.');
            });
        }
    });

    // Add new functions for exam status handling
    function showLoadingOverlay() {
        document.getElementById('loadingOverlay').style.display = 'flex';
    }

    function hideLoadingOverlay() {
        document.getElementById('loadingOverlay').style.display = 'none';
    }

    function updateProgressBar(progress) {
        document.getElementById('progressBar').style.width = `${progress}%`;
    }

    function updateLoadingMessage(message) {
        document.getElementById('loadingMessage').textContent = message;
    }

    function updateExamInfo(info) {
        document.getElementById('examInfo').textContent = info;
    }

    async function pollExamStatus(examId) {
        const startTime = Date.now();
        const pollInterval = 1000; // Poll every 1 second
        
        return new Promise((resolve, reject) => {
            const poll = async () => {
                try {
                    const response = await fetch(`/facilitator/api/v1/exams/${examId}/status`);
                    const data = await response.json();
                    
                    // set warmup time in seconds
                    const warmUpTimeInSeconds = data.warmUpTimeInSeconds || 30;

                    if (data.status === 'READY') {
                        // Set progress to 100% when ready
                        updateProgressBar(100);
                        updateLoadingMessage('Lab environment is ready! Redirecting...');
                        // Wait a moment for the user to see the 100% progress
                        setTimeout(() => resolve(data), 1000);
                        return;
                    }
                    
                    // Calculate progress based on warm-up time
                    const elapsedTime = (Date.now() - startTime) / 1000;
                    const progress = Math.min((elapsedTime / warmUpTimeInSeconds) * 100, 95);
                    updateProgressBar(progress);
                    updateLoadingMessage(data.message || 'Preparing lab environment...');
                    
                    // Continue polling
                    setTimeout(poll, pollInterval);
                } catch (error) {
                    console.error('Error polling exam status:', error);
                    // Show error in the loading overlay
                    updateLoadingMessage(`Error: ${error.message}. Retrying...`);
                    // Continue polling despite errors
                    setTimeout(poll, pollInterval);
                }
            };
            
            poll();
        });
    }

    // Modify the existing startExam function
    async function startExam(examId) {
        try {
            showLoadingOverlay();
            updateLoadingMessage('Starting exam environment...');
            
            const response = await fetch('/facilitator/api/v1/exams', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ examId })
            });
            
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.message || 'Failed to start exam');
            }
            
            // Store exam ID in localStorage
            localStorage.setItem('currentExamId', data.id);
            
            // Start polling for status
            await pollExamStatus(data.id, data.warmUpTimeInSeconds || 30);
            
            // Redirect to exam page when ready
            window.location.href = `/exam.html?id=${data.id}`;
        } catch (error) {
            console.error('Error starting exam:', error);
            hideLoadingOverlay();
            alert('Failed to start exam: ' + error.message);
        }
    }

    // Modify the dropdown population to include difficulty info
    function populateDropdown(labs) {
        const dropdown = document.getElementById('examDropdown');
        dropdown.innerHTML = '';
        
        labs.forEach(lab => {
            const option = document.createElement('option');
            option.value = lab.id;
            option.textContent = `${lab.name} (${lab.difficulty || 'Medium'})`;
            option.title = `${lab.description}\nDifficulty: ${lab.difficulty || 'Medium'}\nEstimated Time: ${lab.estimatedTime || '30'} minutes`;
            dropdown.appendChild(option);
        });
    }

    // Add event listener for View Past Results button
    viewPastResultsBtn.addEventListener('click', function() {
        // Check if we have current exam data
        const currentExamDataStr = localStorage.getItem('currentExamData');
        
        if (currentExamDataStr) {
            try {
                const currentExamData = JSON.parse(currentExamDataStr);
                
                // If the current exam is evaluated or being evaluated, go directly to results
                if (currentExamData.status === 'EVALUATED' || currentExamData.status === 'EVALUATING') {
                    window.location.href = `/results?id=${currentExamData.id}`;
                    return;
                } else {
                    // If the exam exists but isn't in the right state, show an alert
                    alert('Exam results are not available yet. The exam must be evaluated first.');
                    return;
                }
            } catch (error) {
                console.error('Error parsing current exam data:', error);
            }
        }
        
        // If there's no current exam at all, inform the user
        alert('No active exam found. Please start an exam first.');
    });
}); 