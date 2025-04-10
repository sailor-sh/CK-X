/**
 * Exam Application
 * Main entry point for the exam functionality
 */

// Import services and utilities
import * as ExamApi from './components/exam-api.js';
import * as TerminalService from './components/terminal-service.js';
import * as RemoteDesktopService from './components/remote-desktop-service.js';
import * as QuestionService from './components/question-service.js';
import * as TimerService from './components/timer-service.js';
import * as UiUtils from './components/ui-utils.js';
import * as WakeLockService from './components/wake-lock-service.js';
import * as ClipboardService from './components/clipboard-service.js';

document.addEventListener('DOMContentLoaded', function () {
    // DOM Elements
    const pageLoader = document.getElementById('pageLoader');
    const endExamBtnDropdown = document.getElementById('endExamBtnDropdown');
    const confirmEndBtn = document.getElementById('confirmEndBtn');
    const terminateSessionBtn = document.getElementById('terminateSessionBtn');
    const confirmTerminateBtn = document.getElementById('confirmTerminateBtn');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    const questionDropdown = document.getElementById('questionDropdown');
    const questionDropdownMenu = document.getElementById('questionDropdownMenu');
    const questionContent = document.getElementById('questionContent');
    const examTimer = document.getElementById('examTimer');
    const vncFrame = document.getElementById('vnc-frame');
    const connectionStatus = document.getElementById('connectionStatus');
    const startExamBtn = document.getElementById('startExamBtn');
    const toggleViewBtn = document.getElementById('toggleViewBtn');
    const sshTerminalContainer = document.getElementById('sshTerminalContainer');
    const sshConnectionStatus = document.getElementById('sshConnectionStatus');
    const viewResultsBtn = document.getElementById('viewResultsBtn');

    // Modals
    const confirmModal = new bootstrap.Modal(document.getElementById('confirmModal'));
    const terminateModal = new bootstrap.Modal(document.getElementById('terminateModal'));
    const startExamModal = new bootstrap.Modal(document.getElementById('startExamModal'));
    const examEndModal = new bootstrap.Modal(document.getElementById('examEndModal'));

    // State variables
    let examInfo = {}; // Store exam information
    let currentQuestionId = 1;
    let questions = [];
    let isTerminalActive = false;
    let isCompletedExamMode = false;

    // Add event listener for page unload to clean up resources
    window.addEventListener('beforeunload', cleanupResources);

    // Initialize by fetching questions
    fetchExamQuestions();

    // Listen for examCompletedSession event and handle connecting to a finished exam session
    document.addEventListener('examCompletedSession', function (event) {
        const { examId } = event.detail;
        console.log('Connecting to completed exam session for exam:', examId);

        // Get DOM elements
        const pageLoader = document.getElementById('pageLoader');
        const vncFrame = document.getElementById('vnc-frame');
        const connectionStatus = document.getElementById('connectionStatus');
        const examTimer = document.getElementById('examTimer');

        // Set completed exam mode
        isCompletedExamMode = true;

        // Show loader
        pageLoader.style.display = 'flex';

        // Create a promises array for parallel fetching
        const promises = [
            // Fetch exam info
            ExamApi.fetchCurrentExamInfo(),
            // Fetch exam questions
            ExamApi.fetchExamData(examId)
        ];

        // Execute all promises in parallel
        Promise.all(promises)
            .then(([examInfoData, questionsData]) => {
                // Store exam info for later use
                examInfo = examInfoData;

                // Hide timer for completed exam
                examTimer.style.display = 'none';

                // Add Review Mode badge next to title
                const headerTitle = document.querySelector('.header-title');
                if (headerTitle) {
                    // Create the badge
                    const reviewBadge = document.createElement('span');
                    reviewBadge.className = 'review-mode-badge';
                    reviewBadge.textContent = 'Review Mode';

                    // Add badge next to title
                    headerTitle.appendChild(reviewBadge);
                }

                // Hide end exam button if it exists
                const endExamItem = document.querySelector('.dropdown-item[href="#"][id="endExamBtnDropdown"]');
                if (endExamItem) {
                    endExamItem.style.display = 'none';
                }

                if (questionsData) {
                    // Transform the questions
                    questions = QuestionService.transformQuestionsFromApi(questionsData);

                    // Initialize the exam UI with questions
                    initExamUI();

                    console.log('Loaded', questions.length, 'questions for completed exam');

                    // Add "View Results" button to header
                    const headerControls = document.querySelector('.header-controls');
                    if (headerControls) {
                        const viewResultsBtn = document.createElement('button');
                        viewResultsBtn.className = 'btn-custom';
                        viewResultsBtn.textContent = 'View Results';
                        viewResultsBtn.addEventListener('click', () => {
                            window.location.href = `/results?id=${examId}`;
                        });

                        // Add button to beginning of controls
                        headerControls.prepend(viewResultsBtn);
                    }
                }

                // Connect to Remote Desktop
                RemoteDesktopService.connectToRemoteDesktop(vncFrame, showVncConnectionStatus);

                // Hide loader after a short delay
                setTimeout(() => {
                    pageLoader.style.display = 'none';
                }, 1500);
            })
            .catch(error => {
                console.error('Error loading exam environment:', error);
                alert('Failed to connect to exam environment. Please try again.');
                pageLoader.style.display = 'none';
            });
    });

    // Function declarations

    // Function to show VNC connection status
    function showVncConnectionStatus(message, type) {
        UiUtils.showConnectionStatus(connectionStatus, message, type);
    }

    // Function to show SSH connection status
    function showSshConnectionStatus(message, type) {
        UiUtils.showConnectionStatus(sshConnectionStatus, message, type);
    }

    // Setup callbacks for terminal service
    TerminalService.setCallbacks({
        showConnectionStatus: showSshConnectionStatus
    });

    // Load exam environment for completed exams
    function loadExamEnvironment(examId) {
        // Show loader
        pageLoader.style.display = 'flex';

        // Fetch exam info for connection details only
        ExamApi.fetchCurrentExamInfo()
            .then(data => {
                examInfo = data;

                // Connect to environment
                connectToExamSession();

                // Hide loader after a short delay
                setTimeout(() => {
                    pageLoader.style.display = 'none';
                }, 1500);
            })
            .catch(error => {
                console.error('Error loading exam environment:', error);
                alert('Failed to connect to exam environment. Please try again.');
                pageLoader.style.display = 'none';
            });
    }

    // Connect to exam session for review
    function connectToExamSession() {
        console.log('Connecting to exam session in completed exam mode');

        // Connect to Remote Desktop
        RemoteDesktopService.connectToRemoteDesktop(vncFrame, showVncConnectionStatus);

        // Setup Remote Desktop frame handlers
        RemoteDesktopService.setupRemoteDesktopFrameHandlers(vncFrame, showVncConnectionStatus);

        // Enter fullscreen mode for better visibility
        UiUtils.requestFullscreen(document.documentElement);
    }

    // Fetch questions from API
    function fetchExamQuestions() {
        // Show loader while fetching questions
        pageLoader.style.display = 'flex';

        const examId = ExamApi.getExamId();
        if (!examId) return;

        // First check exam status to handle completed exams
        ExamApi.checkExamStatus(examId)
            .then(status => {
                if (status === 'EVALUATED' || status === 'EVALUATING') {
                    // Show option to view results for completed exams
                    UiUtils.showExamCompletedModal(examId, status);
                    pageLoader.style.display = 'none';
                    return null; // Skip loading questions
                }

                // First fetch current exam info
                return ExamApi.fetchCurrentExamInfo()
                    .then(data => {
                        examInfo = data;

                        // Set timer based on examDurationInMinutes and examStartTime if available
                        if (data.info?.events?.examStartTime && data.info.examDurationInMinutes) {
                            // Calculate remaining time for in-progress exams
                            const remainingMinutes = TimerService.calculateRemainingTime(data);
                            console.log(`Setting timer to ${remainingMinutes} minutes (based on start time)`);
                            TimerService.setTimerDuration(remainingMinutes);
                        } else if (data.info?.examDurationInMinutes) {
                            // For new exams, use the full duration
                            console.log(`Setting timer to ${data.info.examDurationInMinutes} minutes`);
                            TimerService.setTimerDuration(data.info.examDurationInMinutes);
                        } else if (data.info) {
                            console.warn('examDurationInMinutes not found in API response, using default duration');
                        }

                        return ExamApi.fetchExamData(examId);
                    })
                    .then(data => {
                        if (!data) return;

                        // Store exam info for later use
                        examInfo = data.info || examInfo;

                        // Transform the questions
                        questions = QuestionService.transformQuestionsFromApi(data);

                        // Initialize the exam UI after loading questions
                        initExamUI();

                        // Show the start exam modal
                        showStartExamModal();

                        // Hide loader
                        pageLoader.style.display = 'none';
                    })
                    .catch(error => {
                        console.error('Error loading exam:', error);
                        // Show an error message to the user
                        alert('Failed to load exam data. Please refresh the page or contact support.');
                        pageLoader.style.display = 'none';
                    });
            })
            .catch(error => {
                console.error('Error loading exam:', error);
                // Show an error message to the user
                alert('Failed to load exam data. Please refresh the page or contact support.');
                pageLoader.style.display = 'none';
            });
    }

    // Show start exam modal
    function showStartExamModal() {
        // Check if the exam has already been started or completed
        if (examInfo.info?.events?.examStartTime) {
            setupContinueExamButton();
        } else {
            setupNewExamButton();
        }

        // Always show the modal regardless of exam state
        startExamModal.show();
    }

    // Setup button for continuing an existing exam
    function setupContinueExamButton() {
        const modalTitle = document.getElementById('startExamModalLabel');

        // Hide default content
        document.getElementById('newExamContent').style.display = 'none';

        if (examInfo.info.events.examEndTime) {
            // Exam is finished - show completed content
            document.getElementById('examCompletedContent').style.display = 'block';
            document.getElementById('examInProgressContent').style.display = 'none';

            // Update modal title
            modalTitle.textContent = 'Exam Completed';
            startExamBtn.textContent = 'Continue to Session';
        } else {
            // Exam is in progress - show in-progress content
            document.getElementById('examInProgressContent').style.display = 'block';
            document.getElementById('examCompletedContent').style.display = 'none';

            // Update modal title
            modalTitle.textContent = 'Exam in Progress';
            startExamBtn.textContent = 'Continue Session';
        }

        // Remove countdown behavior and just continue to session
        startExamBtn.addEventListener('click', function () {
            startExamModal.hide();
            startExam();
        }, { once: true });
    }

    // Setup button for starting a new exam
    function setupNewExamButton() {
        // Show default content, hide others
        document.getElementById('newExamContent').style.display = 'block';
        document.getElementById('examInProgressContent').style.display = 'none';
        document.getElementById('examCompletedContent').style.display = 'none';

        // Reset modal title
        document.getElementById('startExamModalLabel').textContent = 'Ready to Begin Your Exam';

        // Initialize counter
        let countDown = 3;
        startExamBtn.innerHTML = `Start Exam (${countDown})`;

        // Remove any existing click handlers
        startExamBtn.replaceWith(startExamBtn.cloneNode(true));
        // Get the fresh reference after cloning
        const freshStartExamBtn = document.getElementById('startExamBtn');

        // Add event listener to start exam button
        if (freshStartExamBtn) {
            freshStartExamBtn.addEventListener('click', function handleStartClick() {
                // Decrease counter on each click
                countDown--;

                if (countDown > 0) {
                    // Update button text with new counter
                    freshStartExamBtn.innerHTML = `Start Exam (${countDown})`;
                } else {
                    // Start exam when counter reaches 0
                    freshStartExamBtn.removeEventListener('click', handleStartClick);
                    startExamModal.hide();
                    startExam();
                }
            });
        }
    }

    // Track exam start event
    function trackExamStartEvent() {
        // Track exam start event only if this is a new exam (not a continuation)
        const examId = ExamApi.getExamId();
        if (examId && !examInfo.info?.events?.examStartTime) {
            const currentTime = Date.now();
            console.log('Setting exam start time:', currentTime);

            ExamApi.trackExamEvent(examId, {
                examStartTime: currentTime,
                userAgent: navigator.userAgent,
                screenResolution: `${window.screen.width}x${window.screen.height}`
            });
        }
    }

    // Track exam end event
    function trackExamEndEvent() {
        const examId = ExamApi.getExamId();
        if (!examId) return;

        const currentEndTime = Date.now();
        console.log('Setting exam end time:', currentEndTime);

        return ExamApi.trackExamEvent(examId, {
            examEndTime: currentEndTime
        }).catch(error => {
            console.error('Error tracking exam end event:', error);
            // Continue with exam evaluation regardless of tracking error
        });
    }

    // Setup timer threshold notifications
    function setupTimerNotifications() {
        TimerService.registerTimeThresholdCallbacks({
            // 30 minutes remaining
            30: (minutes) => {
                UiUtils.showToast('30 minutes left in your exam', {
                    bgColor: 'bg-warning',
                    textColor: 'text-dark',
                    delay: 7000
                });
            },
            // 10 minutes remaining
            10: (minutes) => {
                UiUtils.showToast('Only 10 minutes remaining! ', {
                    bgColor: 'bg-danger',
                    textColor: 'text-white',
                    delay: 10000
                });
            },
            // Time's up
            0: (minutes) => {
                handleExamEnd();
            }
        });
    }

    // Start exam functionality
    function startExam() {
        // Show loader while starting exam
        pageLoader.style.display = 'flex';

        // Enter fullscreen mode
        UiUtils.requestFullscreen(document.documentElement);

        // Acquire wake lock to prevent device from sleeping
        WakeLockService.acquireWakeLock()
            .then(success => {
                if (success) {
                    console.log('Wake lock acquired successfully');
                } else {
                    console.warn('Wake lock not acquired, device may sleep during exam');
                }
            });

        // Connect to Remote Desktop
        RemoteDesktopService.connectToRemoteDesktop(vncFrame, showVncConnectionStatus);

        // Calculate remaining time
        const remainingTime = TimerService.calculateRemainingTime(examInfo);

        // Handle timer visibility and initialization
        if (remainingTime <= 0 || examInfo.info?.events?.examEndTime) {
            // Hide timer if time is up or exam has ended
            examTimer.style.display = 'none';
        } else {
            // Show and initialize timer with remaining time
            examTimer.style.display = 'block';

            // Initialize timer with DOM element
            TimerService.initTimer(examTimer, remainingTime, {
                onTimerEnd: () => {
                    handleExamEnd();
                }
            });

            // Set up timer notifications
            setupTimerNotifications();

            // Start the timer
            TimerService.startTimer();
        }

        // Track exam start
        trackExamStartEvent();

        // Hide loader after a short delay
        setTimeout(() => {
            pageLoader.style.display = 'none';
        }, 1500);
    }

    // Handle exam end when timer reaches zero
    function handleExamEnd() {
        // Release wake lock as exam is ending
        WakeLockService.releaseWakeLock()
            .then(success => {
                if (success) {
                    console.log('Wake lock released successfully');
                }
            });

        // Show the exam end modal
        examEndModal.show();

        // Get exam ID
        const examId = ExamApi.getExamId();
        if (!examId) return;

        // Track exam end event
        trackExamEndEvent()
            .then(() => {
                // Make API call to end and evaluate the exam
                return ExamApi.evaluateExam(examId);
            })
            .then(data => {
                console.log('Exam evaluation started:', data);
                // Set up the View Results button
                if (viewResultsBtn) {
                    viewResultsBtn.addEventListener('click', () => {
                        window.location.href = `/results?id=${examId}`;
                    });
                }
            })
            .catch(error => {
                console.error('Error ending exam:', error);
                alert('There was an error evaluating your exam. Please try manually ending the exam.');
            });
    }

    // Update question content
    function updateQuestionContent(questionId) {
        const question = questions.find(q => q.id === questionId || q.id === questionId.toString());

        if (!question) {
            console.error(`Question with ID ${questionId} not found`);
            questionContent.innerHTML = '<div class="alert alert-danger">Question not found. Please try another question.</div>';
            return;
        }

        // Add fade effect
        questionContent.classList.add('content-fade');

        // Use requestAnimationFrame for a smoother transition
        requestAnimationFrame(() => {
            // Short timeout for the transition to take effect
            setTimeout(() => {
                try {
                    // Get formatted content from QuestionService
                    const formattedContent = QuestionService.generateQuestionContent(question);

                    // Update content
                    questionContent.innerHTML = formattedContent;

                    // Hide action buttons in completed exam review mode
                    if (isCompletedExamMode) {
                        const actionButtonsContainer = document.querySelector('.action-buttons-container');
                        if (actionButtonsContainer) {
                            actionButtonsContainer.style.display = 'none';
                        }
                    } else {
                        // Add functionality to flag button
                        const flagQuestionBtn = document.getElementById('flagQuestionBtn');
                        if (flagQuestionBtn) {
                            flagQuestionBtn.addEventListener('click', function () {
                                toggleQuestionFlag(questionId);
                            });
                        }

                        // Add functionality to next button
                        const nextQuestionBtn = document.getElementById('nextQuestionBtn');
                        if (nextQuestionBtn) {
                            nextQuestionBtn.addEventListener('click', function () {
                                const currentIndex = questions.findIndex(q => q.id === currentQuestionId || q.id === currentQuestionId.toString());
                                if (currentIndex < questions.length - 1) {
                                    currentQuestionId = questions[currentIndex + 1].id;
                                    updateQuestionContent(currentQuestionId);
                                    updateNavigationButtons();
                                }
                            });
                        }
                    }

                    // Update dropdown button text
                    questionDropdown.textContent = question.title || `Question ${questionId}`;

                    // Add subtle transition indicator
                    questionContent.classList.add('question-transition');

                    // Remove fade effect
                    requestAnimationFrame(() => {
                        questionContent.classList.remove('content-fade');

                        // Remove transition indicator after animation completes
                        setTimeout(() => {
                            questionContent.classList.remove('question-transition');
                        }, 1000);
                    });
                } catch (error) {
                    console.error('Error updating question content:', error);
                    questionContent.innerHTML = '<div class="alert alert-danger">Error displaying question content. Please try refreshing the page.</div>';
                    questionContent.classList.remove('content-fade');
                }
            }, 100);
        });
    }

    // Toggle between VNC and Terminal views
    function toggleView() {
        const terminalContainer = document.querySelector('.terminal-container');

        if (isTerminalActive) {
            // Switch to VNC
            sshTerminalContainer.style.display = 'none';
            terminalContainer.style.display = 'flex';
            toggleViewBtn.textContent = 'Switch to Terminal';
            isTerminalActive = false;
        } else {
            // Switch to Terminal
            terminalContainer.style.display = 'none';
            sshTerminalContainer.style.display = 'flex';
            toggleViewBtn.textContent = 'Switch to Remote Desktop';
            isTerminalActive = true;

            // Show toast notification about real exam constraints
            UiUtils.showToast('Note: In the actual certification exam, only remote desktop access is available. Terminal access is provided here for practice convenience.', {
                bgColor: 'bg-info',
                textColor: 'text-white',
                delay: 8000
            });

            // Initialize terminal if not already done
            if (!TerminalService.isInitialized()) {
                TerminalService.initTerminal(sshTerminalContainer, true);
            } else {
                // Resize terminal to fit container
                TerminalService.resizeTerminal(sshTerminalContainer);
            }

            // Give a little time for the display change to take effect, then resize again
            setTimeout(() => {
                TerminalService.resizeTerminal(sshTerminalContainer);
            }, 300);
        }
    }

    // Initialize the exam UI
    function initExamUI() {
        // Set the first question
        updateQuestionContent(currentQuestionId);

        // Dynamically populate question dropdown with fetched questions
        updateQuestionDropdown();

        // Update navigation buttons
        updateNavigationButtons();

        // Setup Remote Desktop frame handlers
        RemoteDesktopService.setupRemoteDesktopFrameHandlers(vncFrame, showVncConnectionStatus);

        // Setup UI event listeners
        setupUIEventListeners();

        // Setup clipboard copy for inline code elements
        ClipboardService.setupInlineCodeCopy();

        // If in completed exam mode, ensure the question pane is visible
        if (isCompletedExamMode) {
            console.log('Setting up completed exam review mode UI');

            // Make sure question panel is visible and sized correctly
            const questionPanel = document.getElementById('questionPanel');
            if (questionPanel) {
                questionPanel.style.display = 'block';

                // Initialize panel resizer if available to ensure question pane is correctly sized
                if (window.panelResizer) {
                    setTimeout(() => {
                        window.panelResizer.resetPanels();
                    }, 500);
                }
            }

            // Add read-only indicator to question panel
            const questionContent = document.getElementById('questionContent');
            if (questionContent) {
                const reviewBanner = document.createElement('div');
                reviewBanner.className = 'alert alert-info mb-3';
                reviewBanner.textContent = 'Review Mode: This exam has been completed. You can review questions and your environment.';

                // Insert at the beginning of question content
                if (questionContent.firstChild) {
                    questionContent.insertBefore(reviewBanner, questionContent.firstChild);
                } else {
                    questionContent.appendChild(reviewBanner);
                }
            }
        }
    }

    // Setup all UI event listeners
    function setupUIEventListeners() {
        // Setup fullscreen toggle button for page
        const fullscreenBtn = document.getElementById('fullscreenBtn');
        if (fullscreenBtn) {
            fullscreenBtn.addEventListener('click', function (e) {
                e.preventDefault();
                UiUtils.toggleFullscreen();
            });
        }

        // Setup fullscreen toggle button for VNC iframe
        const fullscreenVncBtn = document.getElementById('fullscreenVncBtn');
        if (fullscreenVncBtn) {
            fullscreenVncBtn.addEventListener('click', function (e) {
                e.preventDefault();
                // Request fullscreen for the VNC iframe
                UiUtils.requestFullscreen(vncFrame);
            });
        }

        // Setup reconnect button for VNC
        const reconnectVncBtn = document.getElementById('reconnectVncBtn');
        if (reconnectVncBtn) {
            reconnectVncBtn.addEventListener('click', function (e) {
                e.preventDefault();
                showVncConnectionStatus('Reconnecting to Remote Desktop...', 'info');
                RemoteDesktopService.connectToRemoteDesktop(vncFrame, showVncConnectionStatus);
            });
        }

        // Setup fullscreen toggle button for Terminal
        const fullscreenTerminalBtn = document.getElementById('fullscreenTerminalBtn');
        if (fullscreenTerminalBtn) {
            fullscreenTerminalBtn.addEventListener('click', function (e) {
                e.preventDefault();
                // Request fullscreen for the terminal container
                UiUtils.requestFullscreen(sshTerminalContainer);
            });
        }

        // Setup toggle view button
        if (toggleViewBtn) {
            toggleViewBtn.addEventListener('click', function (e) {
                e.preventDefault();
                toggleView();
            });
        }

        // Add fullscreen change event listener to update UI accordingly
        document.addEventListener('fullscreenchange', () => UiUtils.updateFullscreenUI(fullscreenBtn));
        document.addEventListener('webkitfullscreenchange', () => UiUtils.updateFullscreenUI(fullscreenBtn));
        document.addEventListener('mozfullscreenchange', () => UiUtils.updateFullscreenUI(fullscreenBtn));
        document.addEventListener('MSFullscreenChange', () => UiUtils.updateFullscreenUI(fullscreenBtn));

        // Setup resize terminal button
        const resizeTerminalBtn = document.getElementById('resizeTerminalBtn');
        if (resizeTerminalBtn) {
            resizeTerminalBtn.addEventListener('click', function (e) {
                e.preventDefault();
                // Use the globally exposed PanelResizer instance
                if (window.panelResizer) {
                    window.panelResizer.resetPanels();
                }
                // Fallback: simulate a double-click on the divider
                else {
                    const divider = document.getElementById('panelDivider');
                    if (divider) {
                        const dblClickEvent = new MouseEvent('dblclick', {
                            bubbles: true,
                            cancelable: true,
                            view: window
                        });
                        divider.dispatchEvent(dblClickEvent);
                    }
                }
            });
        }
    }

    // Event listeners for navigation
    prevBtn.addEventListener('click', () => {
        const currentIndex = questions.findIndex(q => q.id === currentQuestionId || q.id === currentQuestionId.toString());
        if (currentIndex > 0) {
            currentQuestionId = questions[currentIndex - 1].id;
            updateQuestionContent(currentQuestionId);
            updateNavigationButtons();
        }
    });

    nextBtn.addEventListener('click', () => {
        const currentIndex = questions.findIndex(q => q.id === currentQuestionId || q.id === currentQuestionId.toString());
        if (currentIndex < questions.length - 1) {
            currentQuestionId = questions[currentIndex + 1].id;
            updateQuestionContent(currentQuestionId);
            updateNavigationButtons();
        }
    });

    // End exam button (dropdown option)
    endExamBtnDropdown.addEventListener('click', () => {
        confirmModal.show();
    });

    // Confirm end exam
    confirmEndBtn.addEventListener('click', () => {
        pageLoader.style.display = 'flex';
        confirmModal.hide();

        // Release wake lock as exam is ending
        WakeLockService.releaseWakeLock();

        // Get exam ID
        const examId = ExamApi.getExamId();
        if (!examId) return;

        // Track exam end event
        trackExamEndEvent()
            .then(() => {
                // Make API call to end and evaluate the exam
                return ExamApi.evaluateExam(examId);
            })
            .then(data => {
                console.log('Exam evaluation started:', data);
                TimerService.stopTimer();

                // Show loader for 3 seconds before redirecting
                setTimeout(() => {
                    window.location.href = `/results?id=${examId}`;
                }, 3000);
            })
            .catch(error => {
                console.error('Error ending exam:', error);
                pageLoader.style.display = 'none';
                alert('There was an error ending your exam. Please try again or contact support.');
            });
    });

    // Terminate session button
    terminateSessionBtn.addEventListener('click', () => {
        terminateModal.show();
    });

    // Confirm terminate session
    confirmTerminateBtn.addEventListener('click', () => {
        // Show loader
        pageLoader.style.display = 'flex';
        terminateModal.hide();

        // Release wake lock as session is terminating
        WakeLockService.releaseWakeLock();

        // Get exam ID
        const examId = ExamApi.getExamId();
        if (!examId) return;

        // Make API call to terminate session
        ExamApi.terminateSession(examId)
            .then(data => {
                console.log('Session terminated successfully:', data);
                // Stop timer
                TimerService.stopTimer();
                // Redirect to main page
                window.location.href = '/';
            })
            .catch(error => {
                console.error('Error terminating session:', error);
                alert('Failed to terminate session. Please try again or contact support.');
                // Hide loader
                pageLoader.style.display = 'none';
            });
    });

    // Update question dropdown
    function updateQuestionDropdown() {
        QuestionService.updateQuestionDropdown(questions, questionDropdownMenu, currentQuestionId, (clickedQuestionId) => {
            currentQuestionId = clickedQuestionId;
            updateQuestionContent(currentQuestionId);
            updateNavigationButtons();
        });
    }

    // Update navigation buttons (disabled state)
    function updateNavigationButtons() {
        const currentIndex = questions.findIndex(q => q.id === currentQuestionId || q.id === currentQuestionId.toString());

        // Disable prev button if on first question
        prevBtn.disabled = currentIndex <= 0;
        prevBtn.classList.toggle('nav-arrow-disabled', currentIndex <= 0);

        // Disable next button if on last question
        nextBtn.disabled = currentIndex >= questions.length - 1;
        nextBtn.classList.toggle('nav-arrow-disabled', currentIndex >= questions.length - 1);
    }

    // Function to toggle flag for a question
    function toggleQuestionFlag(questionId) {
        const questionIndex = questions.findIndex(q => q.id === questionId || q.id === questionId.toString());
        if (questionIndex !== -1) {
            // Toggle flag
            questions[questionIndex].flagged = !questions[questionIndex].flagged;

            // Update the UI
            updateQuestionContent(questionId);

            // Update the dropdown display
            updateQuestionDropdown();
        }
    }

    // Function to clean up resources when page is unloaded
    function cleanupResources() {
        // Release wake lock
        WakeLockService.releaseWakeLock();

        // Stop timer if running
        if (TimerService.isTimerActive) {
            TimerService.stopTimer();
        }

        console.log('Resources cleaned up before page unload');
    }
}); 