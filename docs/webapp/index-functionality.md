# CK-X Simulator: index.html Functionality Documentation

This document provides a detailed technical overview of the `index.html` file, focusing on its structure, interactions, and API calls.

## Table of Contents

1. [HTML Structure](#html-structure)
2. [Functionality Overview](#functionality-overview)
3. [Component Interactions](#component-interactions)
4. [API Integration](#api-integration)
5. [Event Handlers](#event-handlers)
6. [State Management](#state-management)
7. [Error Handling](#error-handling)

## HTML Structure

The `index.html` file serves as the main landing page for the CK-X Simulator. Here's a detailed breakdown of its structure:

### 1. Head Section
```html
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="mobile-web-app-capable" content="yes">
    <title>CK-X | Kubernetes Certification Simulator</title>
    <!-- External Dependencies -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="/css/index.css">
</head>
```

### 2. Body Components

#### Loader Component
```html
<div class="loader" id="pageLoader">
    <div class="spinner-border text-light" role="status">
        <span class="visually-hidden">Loading...</span>
    </div>
    <div class="loader-message" id="loaderMessage">Lab is getting ready...</div>
</div>
```
- **Purpose**: Displays during API calls and lab initialization
- **State Management**: Controlled by `showLoader()` and `hideLoader()` functions
- **Message Updates**: Dynamic updates via `updateLoaderMessage()`

#### Navigation Bar
```html
<nav class="navbar navbar-expand-lg navbar-dark bg-dark fixed-top">
    <div class="container">
        <a class="navbar-brand" href="/">CK-X</a>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item me-3 view-results-btn-container" style="display: none;">
                    <a class="nav-link" href="#" id="viewPastResultsBtn">
                        <!-- SVG Icon -->
                        View Result
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="https://github.com/nishanb/CK-X" target="_blank">
                        <!-- GitHub Icon -->
                        GitHub
                    </a>
                </li>
            </ul>
        </div>
    </div>
</nav>
```
- **Dynamic Elements**: Results button visibility controlled by exam state
- **Event Handling**: Results button click triggers navigation to results page

#### Hero Section
```html
<section class="hero-section full-height d-flex align-items-center text-center position-relative">
    <div class="container hero-content">
        <h1 class="display-4 mb-4">Kubernetes Certification Exam Simulator</h1>
        <p class="lead mb-5">Practice in a realistic environment...</p>
        <a href="#" class="btn btn-light btn-lg start-exam-btn" id="startExamBtn">START EXAM</a>
    </div>
    <div class="scroll-indicator">
        <p>SCROLL TO EXPLORE</p>
        <i class="fas fa-chevron-down"></i>
    </div>
</section>
```
- **Main CTA**: "START EXAM" button triggers exam selection flow
- **Scroll Indicator**: Visual cue for content below

#### Features Section
```html
<section id="features">
    <div class="container">
        <div class="features-wrapper">
            <!-- Feature Cards -->
        </div>
    </div>
</section>
```
- **Static Content**: Displays six feature cards
- **Responsive Layout**: Bootstrap grid system for responsive design

#### Loading Overlay
```html
<div class="loading-overlay" id="loadingOverlay">
    <div class="loading-content">
        <h2>Preparing Your Lab Environment</h2>
        <div class="custom-progress-bar">
            <div class="custom-progress" id="progressBar"></div>
        </div>
        <div class="loading-message" id="loadingMessage">Initializing environment...</div>
        <div class="exam-info" id="examInfo"></div>
    </div>
</div>
```
- **Progress Tracking**: Visual feedback during lab initialization
- **Dynamic Updates**: Progress bar and message updates via API responses

#### Exam Selection Modal
```html
<div class="modal fade" id="examSelectionModal">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Select Your Exam</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <form id="examSelectionForm">
                    <!-- Exam Selection Form -->
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">CANCEL</button>
                <button type="button" class="btn btn-primary" id="startSelectedExam" disabled>START EXAM</button>
            </div>
        </div>
    </div>
</div>
```
- **Form Elements**: Dynamic exam selection options
- **Validation**: Start button enabled only when valid selection made

## Functionality Overview

The `index.html` file serves as the main entry point for the CK-X Simulator, providing a comprehensive interface for exam selection and management. Here's a detailed breakdown of its functionality:

### 1. User Interface Flow

#### Initial Load
1. **Page Initialization**
   - Checks for existing exam sessions
   - Preloads available labs data
   - Initializes UI components
   - Sets up event listeners

2. **Navigation Bar**
   - Displays CK-X branding
   - Shows/hides "View Result" button based on exam state
   - Provides GitHub repository link
   - Fixed position for easy access

3. **Hero Section**
   - Main landing area with exam simulator title
   - "START EXAM" call-to-action button
   - Scroll indicator for content discovery

4. **Features Section**
   - Displays six key features of the simulator
   - Responsive grid layout
   - Visual icons and descriptions

### 2. Exam Selection Process

#### Start Exam Flow
1. **Initial Check**
   - Validates current exam status
   - Checks for active sessions
   - Verifies system requirements

2. **Exam Selection Modal**
   - Displays available exam categories
   - Shows exam descriptions
   - Validates user selection
   - Enables/disables start button

3. **Lab Environment Setup**
   - Shows loading overlay
   - Displays progress bar
   - Provides status updates
   - Handles initialization errors

### 3. State Management

#### Local Storage
- Stores current exam data
- Manages exam session state
- Handles user preferences
- Maintains UI state

#### UI State
- Controls loading indicators
- Manages modal visibility
- Updates button states
- Handles responsive layout

### 4. API Integration

#### Endpoints
1. **Exam Status**
   - `/facilitator/api/v1/exams/current`
   - Checks active exam sessions
   - Returns exam details

2. **Labs Data**
   - `/facilitator/api/v1/assements/`
   - Fetches available labs
   - Updates exam options

3. **Exam Creation**
   - `/facilitator/api/v1/exams`
   - Creates new exam sessions
   - Handles session initialization

### 5. Error Handling

#### User Feedback
- Displays error messages
- Shows loading states
- Provides network status
- Handles API failures

#### Recovery Mechanisms
- Auto-dismissing alerts
- Network status monitoring
- Session state recovery
- Graceful error handling

### 6. Security Features

#### Access Control
- Validates exam sessions
- Checks user permissions
- Manages secure redirects
- Handles session timeouts

#### Data Protection
- Secure API communication
- Safe data storage
- Protected user information
- Secure state management

### 7. Performance Optimization

#### Loading Strategy
- Lazy loading of components
- Preloading of essential data
- Efficient state updates
- Optimized resource loading

#### UI Responsiveness
- Smooth transitions
- Non-blocking operations
- Efficient DOM updates
- Responsive design

### 8. Browser Compatibility

#### Cross-browser Support
- Modern browser features
- Fallback mechanisms
- Consistent rendering
- Progressive enhancement

#### Mobile Support
- Responsive design
- Touch-friendly interface
- Mobile-optimized layout
- Adaptive UI elements

### 9. User Experience

#### Feedback Mechanisms
- Loading indicators
- Progress updates
- Status messages
- Error notifications

#### Navigation
- Clear call-to-actions
- Intuitive flow
- Easy access to features
- Consistent navigation

### 10. Maintenance and Updates

#### Code Organization
- Modular structure
- Clear separation of concerns
- Maintainable components
- Extensible design

#### Future Enhancements
- Feature addition points
- Integration capabilities
- Scalability considerations
- Update mechanisms

## Component Interactions

### 1. Initial Page Load
```javascript
document.addEventListener('DOMContentLoaded', async () => {
    // Check for existing exam
    await checkCurrentExamStatus();
    
    // Preload labs data
    await fetchLabs(false);
    
    // Initialize UI elements
    initializeUI();
});
```

### 2. Exam Selection Flow
```javascript
// Start Exam Button Click
document.getElementById('startExamBtn').addEventListener('click', async () => {
    // Check for active exam
    const currentExam = await checkCurrentExamStatus();
    
    if (currentExam) {
        showActiveExamWarningModal(currentExam);
    } else {
        showExamSelectionModal();
    }
});

// Exam Category Selection
document.getElementById('examCategory').addEventListener('change', async (e) => {
    const category = e.target.value;
    await loadExamOptions(category);
    updateExamDescription();
});

// Start Selected Exam
document.getElementById('startSelectedExam').addEventListener('click', async () => {
    const examId = document.getElementById('examName').value;
    await startSelectedExam(examId);
});
```

### 3. Loading State Management
```javascript
// Show Loading Overlay
function showLoadingOverlay(message) {
    document.getElementById('loadingOverlay').style.display = 'flex';
    document.getElementById('loadingMessage').textContent = message;
}

// Update Progress
function updateProgress(progress) {
    document.getElementById('progressBar').style.width = `${progress}%`;
}

// Hide Loading Overlay
function hideLoadingOverlay() {
    document.getElementById('loadingOverlay').style.display = 'none';
}
```

## API Integration

### 1. Exam Status Check
```javascript
async function checkCurrentExamStatus() {
    try {
        const response = await fetch('/facilitator/api/v1/exams/current');
        if (response.ok) {
            const data = await response.json();
            return data;
        }
        return null;
    } catch (error) {
        console.error('Error checking exam status:', error);
        return null;
    }
}
```

### 2. Labs Data Fetching
```javascript
async function fetchLabs(showLoader = true) {
    try {
        if (showLoader) showLoadingOverlay('Loading available labs...');
        
        const response = await fetch('/facilitator/api/v1/assements/');
        const data = await response.json();
        
        // Update exam options
        updateExamOptions(data);
        
        return data;
    } catch (error) {
        console.error('Error fetching labs:', error);
        showError('Failed to load available labs');
        return null;
    } finally {
        if (showLoader) hideLoadingOverlay();
    }
}
```

### 3. Exam Session Creation
```javascript
async function startSelectedExam(examId) {
    try {
        showLoadingOverlay('Creating exam session...');
        
        const response = await fetch('/facilitator/api/v1/exams', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ examId })
        });
        
        if (!response.ok) throw new Error('Failed to create exam session');
        
        const data = await response.json();
        await pollExamStatus(data.id);
        
        // Redirect to exam page
        window.location.href = `/exam.html?id=${data.id}`;
    } catch (error) {
        console.error('Error starting exam:', error);
        showError('Failed to start exam session');
    }
}
```

## Event Handlers

### 1. Modal Management
```javascript
// Show Exam Selection Modal
function showExamSelectionModal() {
    const modal = new bootstrap.Modal(document.getElementById('examSelectionModal'));
    modal.show();
}

// Show Active Exam Warning
function showActiveExamWarningModal(exam) {
    const modal = new bootstrap.Modal(document.getElementById('activeExamWarningModal'));
    modal.show();
    
    // Update modal content
    document.getElementById('examInfo').textContent = 
        `You have an active ${exam.type} exam session.`;
}
```

### 2. Form Validation
```javascript
// Validate Exam Selection
function validateExamSelection() {
    const category = document.getElementById('examCategory').value;
    const exam = document.getElementById('examName').value;
    
    const startButton = document.getElementById('startSelectedExam');
    startButton.disabled = !category || !exam;
}

// Update Exam Description
function updateExamDescription() {
    const exam = document.getElementById('examName').value;
    const description = document.getElementById('examDescription');
    
    if (exam) {
        const examData = getExamData(exam);
        description.textContent = examData.description;
    } else {
        description.textContent = 'Select an exam to see its description.';
    }
}
```

## State Management

### 1. Local Storage
```javascript
// Save Current Exam
function saveCurrentExam(examData) {
    localStorage.setItem('currentExamData', JSON.stringify(examData));
    localStorage.setItem('currentExamId', examData.id);
}

// Get Current Exam
function getCurrentExam() {
    const examData = localStorage.getItem('currentExamData');
    return examData ? JSON.parse(examData) : null;
}

// Clear Current Exam
function clearCurrentExam() {
    localStorage.removeItem('currentExamData');
    localStorage.removeItem('currentExamId');
}
```

### 2. UI State
```javascript
// Update Results Button Visibility
function updateResultsButtonVisibility() {
    const container = document.querySelector('.view-results-btn-container');
    const currentExam = getCurrentExam();
    
    if (currentExam && currentExam.status === 'EVALUATED') {
        container.style.display = 'block';
    } else {
        container.style.display = 'none';
    }
}

// Update Loading State
function updateLoadingState(isLoading, message = '') {
    const loader = document.getElementById('pageLoader');
    const loaderMessage = document.getElementById('loaderMessage');
    
    if (isLoading) {
        loader.style.display = 'flex';
        if (message) loaderMessage.textContent = message;
    } else {
        loader.style.display = 'none';
    }
}
```

## Error Handling

### 1. API Error Handling
```javascript
// Show Error Message
function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'alert alert-danger alert-dismissible fade show';
    errorDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.querySelector('.container').prepend(errorDiv);
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        errorDiv.remove();
    }, 5000);
}

// Handle API Errors
function handleApiError(error, context) {
    console.error(`Error in ${context}:`, error);
    
    let message = 'An unexpected error occurred.';
    if (error.response) {
        switch (error.response.status) {
            case 404:
                message = 'Resource not found.';
                break;
            case 403:
                message = 'Access denied.';
                break;
            case 500:
                message = 'Server error. Please try again later.';
                break;
            default:
                message = error.response.data.message || message;
        }
    }
    
    showError(message);
}
```

### 2. Network Error Handling
```javascript
// Check Network Status
function checkNetworkStatus() {
    if (!navigator.onLine) {
        showError('No internet connection. Please check your network.');
        return false;
    }
    return true;
}

// Network Status Event Listeners
window.addEventListener('online', () => {
    showError('Connection restored. You can continue.');
});

window.addEventListener('offline', () => {
    showError('No internet connection. Please check your network.');
});
```

## Conclusion

The `index.html` file serves as the entry point for the CK-X Simulator, providing a user-friendly interface for exam selection and management. It implements robust error handling, state management, and API integration to ensure a smooth user experience. The modular design allows for easy maintenance and future enhancements.

Key aspects of the implementation include:
- Clean separation of concerns between UI and business logic
- Comprehensive error handling and user feedback
- Efficient state management using localStorage
- Responsive design for various screen sizes
- Clear user flow for exam selection and management 