#!/bin/bash
# PaddleOCR Application Deployment Script
# Automates the deployment process

set -e  # Exit on error

echo "======================================"
echo "PaddleOCR Application Deployment"
echo "======================================"
echo ""

# Configuration
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="/data"
WEBSITES_DIR="${DATA_DIR}/websites/paddle-ocr"
BACKEND_DIR="${DATA_DIR}/paddle-ocr-backend"
NGINX_CONF_DIR="${DATA_DIR}/docker/nginx/conf.d"
DOCKER_DIR="${DATA_DIR}/docker"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo or as root"
    exit 1
fi

# Function to create directory
create_dir() {
    if [ ! -d "$1" ]; then
        echo "Creating directory: $1"
        mkdir -p "$1"
    else
        echo "Directory exists: $1"
    fi
}

# Create required directories
echo "Step 1: Creating directory structure..."
create_dir "${WEBSITES_DIR}/css"
create_dir "${WEBSITES_DIR}/js"
create_dir "${WEBSITES_DIR}/examples/sample-images"
create_dir "${BACKEND_DIR}/api"
create_dir "${BACKEND_DIR}/logs"
create_dir "${NGINX_CONF_DIR}"

# Copy frontend files
echo ""
echo "Step 2: Copying frontend files..."
cp -v "${REPO_DIR}/frontend/index.html" "${WEBSITES_DIR}/"
cp -v "${REPO_DIR}/frontend/css/style.css" "${WEBSITES_DIR}/css/"
cp -v "${REPO_DIR}/frontend/js/app.js" "${WEBSITES_DIR}/js/"

# Copy backend files
echo ""
echo "Step 3: Copying backend files..."
cp -rv "${REPO_DIR}/api/" "${BACKEND_DIR}/"
cp -v "${REPO_DIR}/Dockerfile" "${BACKEND_DIR}/"
cp -v "${REPO_DIR}/requirements.txt" "${BACKEND_DIR}/"

# Copy example files
echo ""
echo "Step 4: Copying example files..."
if [ -d "${REPO_DIR}/examples" ]; then
    cp -v "${REPO_DIR}/examples/"*.{jpg,png,pdf} "${WEBSITES_DIR}/examples/sample-images/" 2>/dev/null || echo "No example images found"
fi

# Copy Nginx configuration
echo ""
echo "Step 5: Copying Nginx configuration..."
cp -v "${REPO_DIR}/nginx/paddle-ocr.conf" "${NGINX_CONF_DIR}/"

# Update docker-compose.yml
echo ""
echo "Step 6: Checking docker-compose.yml..."
if [ -f "${DOCKER_DIR}/docker-compose.yml" ]; then
    if ! grep -q "paddle-ocr-api" "${DOCKER_DIR}/docker-compose.yml"; then
        echo "Adding paddle-ocr service to docker-compose.yml..."
        cat "${REPO_DIR}/docker-compose.service.yml" >> "${DOCKER_DIR}/docker-compose.yml"
    else
        echo "paddle-ocr service already exists in docker-compose.yml"
    fi
else
    echo "Creating docker-compose.yml..."
    cp -v "${REPO_DIR}/docker-compose.service.yml" "${DOCKER_DIR}/docker-compose.yml"
fi

# Set permissions
echo ""
echo "Step 7: Setting permissions..."
chown -R www-data:www-data "${WEBSITES_DIR}" 2>/dev/null || chown -R $SUDO_USER:$SUDO_USER "${WEBSITES_DIR}"
chown -R $SUDO_USER:$SUDO_USER "${BACKEND_DIR}"
chmod -R 755 "${WEBSITES_DIR}"
chmod -R 755 "${BACKEND_DIR}"

# Create environment file
echo ""
echo "Step 8: Creating environment file..."
if [ ! -f "${BACKEND_DIR}/.env" ]; then
    cp -v "${REPO_DIR}/.env.example" "${BACKEND_DIR}/.env"
    echo "Please edit ${BACKEND_DIR}/.env to configure your environment"
else
    echo "Environment file already exists"
fi

# Build and start containers
echo ""
echo "Step 9: Building and starting Docker containers..."
cd "${DOCKER_DIR}"

# Build the image
echo "Building paddle-ocr-api image..."
docker-compose build paddle-ocr-api

# Start the service
echo "Starting paddle-ocr-api service..."
docker-compose up -d paddle-ocr-api

# Wait for service to be healthy
echo ""
echo "Waiting for service to be ready..."
sleep 10

# Test health endpoint
echo ""
echo "Step 10: Testing API health..."
for i in {1..10}; do
    if curl -f http://localhost:8001/health > /dev/null 2>&1; then
        echo "✓ API is healthy!"
        break
    else
        echo "Waiting for API to be ready... (attempt $i/10)"
        sleep 3
    fi
    
    if [ $i -eq 10 ]; then
        echo "⚠ Warning: API health check failed"
        echo "Check logs with: docker-compose logs paddle-ocr-api"
    fi
done

# Restart Nginx to apply configuration
echo ""
echo "Step 11: Restarting Nginx..."
docker-compose restart nginx || echo "Note: Nginx restart failed or not running"

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "Access the application at:"
echo "  Frontend: http://your-domain.com/paddle-ocr/"
echo "  API Docs: http://your-domain.com/api/v1/docs"
echo "  Health:   http://your-domain.com/api/v1/health"
echo ""
echo "Useful commands:"
echo "  View logs:    docker-compose logs -f paddle-ocr-api"
echo "  Restart:      docker-compose restart paddle-ocr-api"
echo "  Stop:         docker-compose stop paddle-ocr-api"
echo "  Rebuild:      docker-compose build --no-cache paddle-ocr-api"
echo ""
echo "Next steps:"
echo "1. Update Nginx config with your domain: ${NGINX_CONF_DIR}/paddle-ocr.conf"
echo "2. Configure environment: ${BACKEND_DIR}/.env"
echo "3. Set up SSL with Let's Encrypt (see README.md)"
echo ""
