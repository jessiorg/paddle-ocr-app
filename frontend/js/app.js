/**
 * PaddleOCR Application - Frontend JavaScript
 * Handles file uploads, API communication, and UI interactions
 */

// Configuration
const CONFIG = {
    API_BASE_URL: '/api/v1',
    MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
    ALLOWED_TYPES: ['image/png', 'image/jpeg', 'image/jpg', 'application/pdf'],
    ALLOWED_EXTENSIONS: ['.png', '.jpg', '.jpeg', '.pdf']
};

// Global state
let currentFile = null;
let processingStartTime = null;

// Initialize application
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
    checkApiHealth();
});

/**
 * Initialize all event listeners
 */
function initializeEventListeners() {
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('fileInput');

    // File input change
    fileInput.addEventListener('change', handleFileSelect);

    // Drag and drop
    uploadArea.addEventListener('dragover', handleDragOver);
    uploadArea.addEventListener('dragleave', handleDragLeave);
    uploadArea.addEventListener('drop', handleDrop);

    // Click to upload
    uploadArea.addEventListener('click', () => {
        if (!currentFile) {
            fileInput.click();
        }
    });

    // Prevent default drag behavior on document
    document.addEventListener('dragover', (e) => e.preventDefault());
    document.addEventListener('drop', (e) => e.preventDefault());
}

/**
 * Check API health status
 */
async function checkApiHealth() {
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/health`);
        if (!response.ok) {
            showStatus('API connection issue. Some features may not work.', 'error');
        }
    } catch (error) {
        console.error('Health check failed:', error);
        showStatus('Unable to connect to API. Please check your connection.', 'error');
    }
}

/**
 * Handle drag over event
 */
function handleDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    e.currentTarget.classList.add('dragover');
}

/**
 * Handle drag leave event
 */
function handleDragLeave(e) {
    e.preventDefault();
    e.stopPropagation();
    e.currentTarget.classList.remove('dragover');
}

/**
 * Handle file drop event
 */
function handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    e.currentTarget.classList.remove('dragover');

    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handleFile(files[0]);
    }
}

/**
 * Handle file selection from input
 */
function handleFileSelect(e) {
    const files = e.target.files;
    if (files.length > 0) {
        handleFile(files[0]);
    }
}

/**
 * Validate and process selected file
 */
function handleFile(file) {
    // Validate file type
    if (!CONFIG.ALLOWED_TYPES.includes(file.type)) {
        showStatus('Invalid file type. Please upload PNG, JPG, JPEG, or PDF.', 'error');
        return;
    }

    // Validate file size
    if (file.size > CONFIG.MAX_FILE_SIZE) {
        showStatus(`File size exceeds ${CONFIG.MAX_FILE_SIZE / 1024 / 1024}MB limit.`, 'error');
        return;
    }

    currentFile = file;
    displayFilePreview(file);
    document.getElementById('extractBtn').disabled = false;
    hideResults();
}

/**
 * Display file preview
 */
function displayFilePreview(file) {
    const uploadArea = document.getElementById('uploadArea');
    const previewArea = document.getElementById('previewArea');
    const previewImage = document.getElementById('previewImage');
    const fileName = document.getElementById('fileName');
    const fileSize = document.getElementById('fileSize');

    // Hide upload area, show preview
    uploadArea.style.display = 'none';
    previewArea.style.display = 'block';

    // Set file info
    fileName.textContent = file.name;
    fileSize.textContent = formatFileSize(file.size);

    // Load image preview
    const reader = new FileReader();
    reader.onload = (e) => {
        previewImage.src = e.target.result;
    };
    reader.readAsDataURL(file);

    showStatus('File loaded successfully. Ready to extract text.', 'success');
}

/**
 * Clear current image and reset
 */
function clearImage() {
    currentFile = null;
    document.getElementById('fileInput').value = '';
    document.getElementById('uploadArea').style.display = 'block';
    document.getElementById('previewArea').style.display = 'none';
    document.getElementById('extractBtn').disabled = true;
    hideResults();
    closeStatus();
}

/**
 * Extract text from current image
 */
async function extractText() {
    if (!currentFile) {
        showStatus('Please select an image first.', 'error');
        return;
    }

    const language = document.getElementById('languageSelect').value;
    showLoading();
    processingStartTime = Date.now();

    try {
        const formData = new FormData();
        formData.append('file', currentFile);
        formData.append('language', language);

        const response = await fetch(`${CONFIG.API_BASE_URL}/ocr`, {
            method: 'POST',
            body: formData
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.detail || 'OCR processing failed');
        }

        if (data.success) {
            displayResults(data);
            showStatus('Text extracted successfully!', 'success');
        } else {
            throw new Error(data.error || 'Unknown error occurred');
        }
    } catch (error) {
        console.error('OCR Error:', error);
        showStatus(`Error: ${error.message}`, 'error');
    } finally {
        hideLoading();
    }
}

/**
 * Display OCR results
 */
function displayResults(data) {
    const processingTime = Date.now() - processingStartTime;
    const resultsSection = document.getElementById('resultsSection');
    const extractedText = document.getElementById('extractedText');
    const confidenceValue = document.getElementById('confidenceValue');
    const processingTimeEl = document.getElementById('processingTime');
    const wordCount = document.getElementById('wordCount');
    const charCount = document.getElementById('charCount');

    // Set text
    extractedText.value = data.text || 'No text detected.';

    // Set statistics
    confidenceValue.textContent = `${(data.confidence * 100).toFixed(1)}%`;
    processingTimeEl.textContent = `${(processingTime / 1000).toFixed(2)}s`;
    
    const words = data.text.trim().split(/\s+/).filter(w => w.length > 0);
    wordCount.textContent = words.length;
    charCount.textContent = data.text.length;

    // Display detailed results
    if (data.detections && data.detections.length > 0) {
        displayDetailedResults(data.detections);
    }

    // Show results section
    resultsSection.style.display = 'block';
    resultsSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/**
 * Display detailed OCR detection results
 */
function displayDetailedResults(detections) {
    const container = document.getElementById('detailedResultsContent');
    container.innerHTML = '';

    detections.forEach((detection, index) => {
        const item = document.createElement('div');
        item.className = 'detection-item';
        
        const text = document.createElement('div');
        text.className = 'detection-text';
        text.textContent = `${index + 1}. ${detection.text}`;
        
        const confidence = document.createElement('div');
        confidence.className = 'detection-confidence';
        confidence.textContent = `Confidence: ${(detection.confidence * 100).toFixed(1)}%`;
        
        const confidenceBar = document.createElement('div');
        confidenceBar.className = 'confidence-bar';
        
        const confidenceFill = document.createElement('div');
        confidenceFill.className = 'confidence-fill';
        confidenceFill.style.width = `${detection.confidence * 100}%`;
        
        confidenceBar.appendChild(confidenceFill);
        item.appendChild(text);
        item.appendChild(confidence);
        item.appendChild(confidenceBar);
        container.appendChild(item);
    });
}

/**
 * Hide results section
 */
function hideResults() {
    document.getElementById('resultsSection').style.display = 'none';
}

/**
 * Toggle detailed results accordion
 */
function toggleDetailedResults() {
    const content = document.getElementById('detailedResults');
    const toggle = event.currentTarget;
    
    if (content.style.display === 'none' || !content.style.display) {
        content.style.display = 'block';
        toggle.classList.add('active');
    } else {
        content.style.display = 'none';
        toggle.classList.remove('active');
    }
}

/**
 * Copy extracted text to clipboard
 */
async function copyText() {
    const text = document.getElementById('extractedText').value;
    
    try {
        await navigator.clipboard.writeText(text);
        showStatus('Text copied to clipboard!', 'success');
    } catch (error) {
        // Fallback for older browsers
        const textarea = document.getElementById('extractedText');
        textarea.select();
        document.execCommand('copy');
        showStatus('Text copied to clipboard!', 'success');
    }
}

/**
 * Download extracted text as file
 */
function downloadText() {
    const text = document.getElementById('extractedText').value;
    const blob = new Blob([text], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = `extracted-text-${Date.now()}.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    showStatus('Text downloaded successfully!', 'success');
}

/**
 * Load example image
 */
function loadExample(type) {
    showStatus('Example images coming soon! Please upload your own image.', 'info');
}

/**
 * Show status banner
 */
function showStatus(message, type = 'info') {
    const banner = document.getElementById('statusBanner');
    const messageEl = banner.querySelector('.status-message');
    const iconEl = banner.querySelector('.status-icon');
    
    messageEl.textContent = message;
    
    // Set icon based on type
    const icons = {
        success: '✓',
        error: '✗',
        info: 'ℹ'
    };
    iconEl.textContent = icons[type] || icons.info;
    
    // Remove all type classes and add current
    banner.className = 'status-banner ' + type;
    banner.style.display = 'flex';
    
    // Auto-hide after 5 seconds for success/info
    if (type !== 'error') {
        setTimeout(closeStatus, 5000);
    }
}

/**
 * Close status banner
 */
function closeStatus() {
    const banner = document.getElementById('statusBanner');
    banner.style.display = 'none';
}

/**
 * Show loading overlay
 */
function showLoading() {
    document.getElementById('loadingOverlay').style.display = 'flex';
}

/**
 * Hide loading overlay
 */
function hideLoading() {
    document.getElementById('loadingOverlay').style.display = 'none';
}

/**
 * Show API documentation
 */
function showApiDocs() {
    window.open(`${CONFIG.API_BASE_URL}/docs`, '_blank');
}

/**
 * Format file size for display
 */
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        handleFile,
        extractText,
        copyText,
        downloadText,
        formatFileSize
    };
}