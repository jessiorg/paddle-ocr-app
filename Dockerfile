# PaddleOCR API Dockerfile
# Python 3.12+ with PaddleOCR, FastAPI, and dependencies
# Optimized for production deployment

FROM python:3.12-slim

# Metadata
LABEL maintainer="Organiser <jessiorg@github.com>"
LABEL description="PaddleOCR API with FastAPI backend"
LABEL version="1.0.0"

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # OpenCV dependencies
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    # Image processing
    libopencv-dev \
    # Network utilities
    wget \
    curl \
    # Build tools (for some Python packages)
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /var/log && \
    mkdir -p /root/.paddleocr && \
    chmod 755 /var/log

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt && \
    # Pre-download PaddleOCR models for English (speeds up first run)
    python -c "from paddleocr import PaddleOCR; PaddleOCR(lang='en', show_log=False)" || true

# Copy application code
COPY api/ ./api/

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app /var/log /root/.paddleocr

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
