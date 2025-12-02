/**
 * Question Service
 * Handles question display and navigation
 */

// Process question content to improve formatting and highlighting
function processQuestionContent(content) {
    // First, preserve existing HTML formatting
    let processedContent = content;

    // 1) Style inline code delimited by backticks: `code`
    processedContent = processedContent.replace(/`([^`]+)`/g, '<span class="inline-code">$1</span>');

    // 2) Style inline code delimited by single quotes: 'code'
    processedContent = processedContent.replace(/'([^'<>]+)'/g, '<span class="inline-code">$1</span>');

    // 2a) Style inline code delimited by double quotes in prose (avoid HTML attributes)
    // Match a leading whitespace or '>' before the quote to avoid attribute contexts like class="..."
    processedContent = processedContent.replace(/(^|[\s>])"([^"<>\n]+)"/g, (m, pre, inner) => `${pre}<span class="inline-code">${inner}</span>`);

    // 3) Style absolute file paths like /opt/course/exam3/q01/namespaces (avoid matching inside tags)
    processedContent = processedContent.replace(/(^|\s)(\/(?:opt|etc|var|home|tmp|root|usr)(?:\/[A-Za-z0-9._-]+)+)/g,
        (m, ws, path) => `${ws}<span class="inline-code">${path}</span>`
    );

    // 4) Style kubectl commands inline (from the verb onward, until line break)
    processedContent = processedContent.replace(/(^|\n)(\s*)(kubectl[^\n<]+)/g,
        (m, br, sp, cmd) => `${br}${sp}<span class="inline-code">${cmd}</span>`
    );

    // 4a) Also style other common CLI commands
    processedContent = processedContent.replace(/(^|\n)(\s*)((?:helm|docker|podman)\s+[^\n<]+)/g,
        (m, br, sp, cmd) => `${br}${sp}<span class="inline-code">${cmd}</span>`
    );

    // 5) Style resource names following common keywords in prose (Pod/Deployment/etc.)
    processedContent = processedContent.replace(/\b(Pod|Deployment|Service|ConfigMap|Secret|StorageClass|PersistentVolumeClaim|PersistentVolume|PVC|PV|Job|CronJob|ServiceAccount)\s+(?:named|called)?\s*([A-Za-z0-9._-]+)/gi,
        (m, kind, name) => `${kind} <span class="inline-code">${name}</span>`
    );

    // 6) Style image references (image: nginx:1.17.3-alpine)
    processedContent = processedContent.replace(/\b(Image|image)\s*[:=]\s*([A-Za-z0-9._\/-]+:[A-Za-z0-9._-]+)/g,
        (m, key, img) => `${key}: <span class="inline-code">${img}</span>`
    );

    // 7) Style file names with common extensions
    processedContent = processedContent.replace(/(^|\s)([A-Za-z0-9._-]+\.(?:ya?ml|json|sh|txt|log))\b/g,
        (m, ws, file) => `${ws}<span class="inline-code">${file}</span>`
    );

    // 8) Style any token that looks like a path (contains a slash), erring on inclusion
    processedContent = processedContent.replace(/(^|\s)([A-Za-z0-9._-]+(?:\/[A-Za-z0-9._-]+)+)\b/g,
        (m, ws, p) => `${ws}<span class="inline-code">${p}</span>`
    );

    // 9) Style IP addresses
    processedContent = processedContent.replace(/\b\d{1,3}(?:\.\d{1,3}){3}\b/g, '<span class="inline-code">$&</span>');

    // 10) Style port references (port: 30100, nodePort: 30100)
    processedContent = processedContent.replace(/\b(node)?[Pp]ort\s*[:=]\s*(\d{2,5})/g,
        (m, np, port) => `${np ? 'nodePort' : 'port'}: <span class="inline-code">${port}</span>`
    );

    // 5) Style bold text
    processedContent = processedContent.replace(
        /\*\*([^*]+)\*\*/g, 
        '<strong>$1</strong>'
    );
    
    // 6) Style italic text
    processedContent = processedContent.replace(
        /\*([^*]+)\*/g, 
        '<em>$1</em>'
    );
    
    // Convert literal newline characters to HTML line breaks
    processedContent = processedContent.replace(/\n/g, '<br>');
    
    // Ensure paragraphs have proper spacing and line breaks
    processedContent = processedContent.replace(
        /<\/p><p>/g, 
        '</p>\n<p>'
    );
    
    // Add more spacing between list items
    processedContent = processedContent.replace(
        /<\/li><li>/g, 
        '</li>\n<li>'
    );
    
    return processedContent;
}

// Generate question content HTML
function generateQuestionContent(question) {
    try {
        // Get original data
        const originalData = question.originalData || {};
        const machineHostname = originalData.machineHostname || 'N/A';
        const namespace = originalData.namespace || 'N/A';
        const concepts = originalData.concepts || [];
        const conceptsString = concepts.join(', ');
        
        // Format question content with improved styling
        const formattedQuestionContent = processQuestionContent(question.content);
        
        // Create formatted content with minimal layout
        return `
            <div class="d-flex flex-column" style="height: 100%;">
                <div class="question-header">
                    
                    <div class="mb-3">
                        <strong>Solve this question on instance:</strong> <span class="inline-code">ssh ${machineHostname}</span>
                    </div>
                    
                    <div class="mb-3">
                        <strong>Namespace:</strong> <span class="inline-code">${namespace}</span>
                    </div>
                    
                    <div class="mb-3">
                        <strong>Concepts:</strong> <span class="text-primary">${conceptsString}</span>
                    </div>
                    
                    <hr class="my-3">
                </div>
                
                <div class="question-body">
                    ${formattedQuestionContent}
                </div>
                
                <div class="action-buttons-container mt-auto">
                    <div class="d-flex justify-content-between py-2">
                        <button class="btn ${question.flagged ? 'btn-warning' : 'btn-outline-warning'}" id="flagQuestionBtn">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-flag${question.flagged ? '-fill' : ''} me-2" viewBox="0 0 16 16">
                                <path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/>
                            </svg>
                            ${question.flagged ? 'Flagged' : 'Flag for review'}
                        </button>
                        <button class="btn btn-success" id="nextQuestionBtn">
                            Satisfied with answer
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right ms-2" viewBox="0 0 16 16">
                                <path fill-rule="evenodd" d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"/>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error generating question content:', error);
        return '<div class="alert alert-danger">Error displaying question content. Please try refreshing the page.</div>';
    }
}

// Transform API response to question objects
function transformQuestionsFromApi(data) {
    if (data.questions && Array.isArray(data.questions)) {
        // Transform the questions to match our expected format
        return data.questions.map(q => ({
            id: q.id,
            content: q.question || '', // Map 'question' field to 'content'
            title: `Question ${q.id}`,  // Create a title from the ID
            originalData: q, // Keep original data for reference if needed
            flagged: false // Add flagged status property
        }));
    }
    return [];
}

// Update question dropdown
function updateQuestionDropdown(questionsArray, dropdownMenu, currentId, onQuestionSelect) {
    // Clear existing dropdown items
    dropdownMenu.innerHTML = '';
    
    // Add items for each question
    questionsArray.forEach((question) => {
        const li = document.createElement('li');
        const a = document.createElement('a');
        a.className = 'dropdown-item';
        a.href = '#';
        a.dataset.question = question.id;
        a.textContent = `Question ${question.id}`;
        
        // Add flag icon if question is flagged
        if (question.flagged) {
            const flagIcon = document.createElement('span');
            flagIcon.className = 'flag-icon ms-2';
            flagIcon.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-flag-fill text-warning" viewBox="0 0 16 16"><path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/></svg>';
            a.appendChild(flagIcon);
        }
        
        // Add click event
        a.addEventListener('click', function(e) {
            e.preventDefault();
            const clickedQuestionId = this.dataset.question;
            if (onQuestionSelect) {
                onQuestionSelect(clickedQuestionId);
            }
        });
        
        li.appendChild(a);
        dropdownMenu.appendChild(li);
    });
}

export {
    processQuestionContent,
    generateQuestionContent,
    transformQuestionsFromApi,
    updateQuestionDropdown
}; 
