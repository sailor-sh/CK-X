/**
 * Panel Resizer - Handles resizing of panels by dragging
 */
class PanelResizer {
    constructor(options) {
        this.divider = document.getElementById(options.dividerId);
        this.leftPanel = document.getElementById(options.leftPanelId);
        this.rightPanel = document.getElementById(options.rightPanelId);
        this.container = document.getElementById(options.containerId) || this.leftPanel.parentElement;
        this.minLeftWidth = options.minLeftWidth || 200;
        this.minRightWidth = options.minRightWidth || 200;

        this.isDragging = false;
        this.startX = 0;
        this.startLeftWidth = 0;

        // Store initial panel width in local storage if it exists
        this.storageKey = options.storageKey || 'panelWidth';

        // Add debug option
        this.debug = options.debug || false;

        this.init();
    }

    init() {
        if (this.debug) console.log('Initializing panel resizer');

        // Try to restore previous panel width from localStorage
        const savedWidth = localStorage.getItem(this.storageKey);
        if (savedWidth) {
            this.leftPanel.style.width = savedWidth;
            if (this.debug) console.log('Restored width from localStorage:', savedWidth);
        }

        // Mouse events for desktop
        this.divider.addEventListener('mousedown', this.startDrag.bind(this));
        window.addEventListener('mousemove', this.drag.bind(this));
        window.addEventListener('mouseup', this.stopDrag.bind(this));

        // Touch events for mobile
        this.divider.addEventListener('touchstart', this.startDrag.bind(this));
        window.addEventListener('touchmove', this.drag.bind(this));
        window.addEventListener('touchend', this.stopDrag.bind(this));

        // Double click to reset
        this.divider.addEventListener('dblclick', this.resetPanels.bind(this));
    }

    startDrag(e) {
        // Exit if the divider doesn't exist
        if (!this.divider) return;

        this.isDragging = true;
        this.divider.classList.add('dragging');

        // Get the starting horizontal position
        this.startX = e.clientX || (e.touches && e.touches[0].clientX) || 0;
        this.startLeftWidth = this.leftPanel.offsetWidth;

        // Prevent text selection during drag
        document.body.classList.add('no-select');

        if (this.debug) {
            console.log('Drag started:', {
                startX: this.startX,
                startLeftWidth: this.startLeftWidth
            });
        }

        // Prevent default behavior
        e.preventDefault();
    }

    drag(e) {
        if (!this.isDragging) return;

        // Calculate the new width based on mouse/touch position
        const clientX = e.clientX || (e.touches && e.touches[0].clientX) || 0;
        const deltaX = clientX - this.startX;

        // Calculate container width
        const containerWidth = this.container.offsetWidth;

        // Calculate new widths
        let newLeftWidth = this.startLeftWidth + deltaX;

        // Apply min width constraints
        if (newLeftWidth < this.minLeftWidth) {
            newLeftWidth = this.minLeftWidth;
        } else if (containerWidth - newLeftWidth < this.minRightWidth) {
            newLeftWidth = containerWidth - this.minRightWidth;
        }

        if (this.debug) {
            console.log('Dragging:', {
                clientX: clientX,
                deltaX: deltaX,
                containerWidth: containerWidth,
                newLeftWidth: newLeftWidth
            });
        }

        // Apply the new width
        this.leftPanel.style.width = `${newLeftWidth}px`;

        // Prevent default behavior to avoid text selection
        e.preventDefault();
        e.stopPropagation();
    }

    stopDrag() {
        if (!this.isDragging) return;

        this.isDragging = false;
        this.divider.classList.remove('dragging');
        document.body.classList.remove('no-select');

        // Save the current width to localStorage
        localStorage.setItem(this.storageKey, this.leftPanel.style.width);

        if (this.debug) {
            console.log('Drag stopped. New width:', this.leftPanel.style.width);
        }
    }

    resetPanels() {
        // Reset to default width (30%)
        this.leftPanel.style.width = '30%';
        localStorage.setItem(this.storageKey, '30%');

        if (this.debug) {
            console.log('Panels reset to default width');
        }
    }
}

// Initialize the panel resizer when the DOM is loaded
document.addEventListener('DOMContentLoaded', function () {
    // Create a global instance of PanelResizer
    window.panelResizer = new PanelResizer({
        dividerId: 'panelDivider',
        leftPanelId: 'questionPanel',
        rightPanelId: 'vncPanel',
        containerId: 'mainContainer',
        minLeftWidth: 200, // Minimum width for question panel
        minRightWidth: 300, // Minimum width for VNC panel
        storageKey: 'examPanelWidth',
        debug: true // Enable debug for troubleshooting
    });
}); 