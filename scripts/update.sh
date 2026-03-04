#!/bin/bash
# Update Script for PaddleOCR Application
# Safely updates the application with rollback capability

set -e

echo "======================================"
echo "PaddleOCR Application Update"
echo "======================================"
echo ""

BACKUP_DIR="${BACKUP_DIR:-/backup/paddle-ocr}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo or as root"
    exit 1
fi

# Create backup first
echo "Step 1: Creating backup..."
mkdir -p "${BACKUP_DIR}"
tar -czf "${BACKUP_DIR}/paddle-ocr-backup-${TIMESTAMP}.tar.gz" \
    /data/websites/paddle-ocr \
    /data/paddle-ocr-backend \
    /data/docker/nginx/conf.d/paddle-ocr.conf \
    2>/dev/null || echo "Warning: Some files may not exist yet"

echo "Backup created: ${BACKUP_DIR}/paddle-ocr-backup-${TIMESTAMP}.tar.gz"
echo ""

# Pull latest changes
echo "Step 2: Pulling latest changes..."
cd "$REPO_DIR"
git fetch origin
git pull origin main

echo ""
echo "Step 3: Updating files..."

# Update frontend
if [ -d "${REPO_DIR}/frontend" ]; then
    echo "Updating frontend files..."
    cp -v "${REPO_DIR}/frontend/index.html" /data/websites/paddle-ocr/
    cp -v "${REPO_DIR}/frontend/css/style.css" /data/websites/paddle-ocr/css/
    cp -v "${REPO_DIR}/frontend/js/app.js" /data/websites/paddle-ocr/js/
fi

# Update backend
if [ -d "${REPO_DIR}/api" ]; then
    echo "Updating backend files..."
    cp -rv "${REPO_DIR}/api/" /data/paddle-ocr-backend/
    cp -v "${REPO_DIR}/Dockerfile" /data/paddle-ocr-backend/
    cp -v "${REPO_DIR}/requirements.txt" /data/paddle-ocr-backend/
fi

# Update nginx config
if [ -f "${REPO_DIR}/nginx/paddle-ocr.conf" ]; then
    echo "Updating Nginx configuration..."
    cp -v "${REPO_DIR}/nginx/paddle-ocr.conf" /data/docker/nginx/conf.d/
fi

echo ""
echo "Step 4: Rebuilding containers..."
cd /data/docker

# Build new image
echo "Building new image..."
docker-compose build paddle-ocr-api

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build successful!"
else
    echo "Build failed! Aborting update."
    echo "To rollback: tar -xzf ${BACKUP_DIR}/paddle-ocr-backup-${TIMESTAMP}.tar.gz -C /"
    exit 1
fi

# Stop old container
echo ""
echo "Step 5: Stopping old container..."
docker-compose stop paddle-ocr-api

# Start new container
echo ""
echo "Step 6: Starting new container..."
docker-compose up -d paddle-ocr-api

# Wait for service to be ready
echo ""
echo "Step 7: Waiting for service to be ready..."
sleep 10

# Health check
for i in {1..10}; do
    if curl -f http://localhost:8001/health > /dev/null 2>&1; then
        echo "✓ Service is healthy!"
        break
    else
        echo "Waiting for service... (attempt $i/10)"
        sleep 3
    fi
    
    if [ $i -eq 10 ]; then
        echo "⚠ Warning: Health check failed!"
        echo "Rolling back to previous version..."
        
        # Rollback
        tar -xzf "${BACKUP_DIR}/paddle-ocr-backup-${TIMESTAMP}.tar.gz" -C /
        docker-compose build paddle-ocr-api
        docker-compose up -d paddle-ocr-api
        
        echo "Rollback complete. Please investigate the issue."
        exit 1
    fi
done

# Restart Nginx
echo ""
echo "Step 8: Restarting Nginx..."
docker-compose restart nginx

# Cleanup old images
echo ""
echo "Step 9: Cleaning up old images..."
docker image prune -f

echo ""
echo "======================================"
echo "Update Complete!"
echo "======================================"
echo ""
echo "Backup location: ${BACKUP_DIR}/paddle-ocr-backup-${TIMESTAMP}.tar.gz"
echo ""
echo "To rollback if needed:"
echo "  tar -xzf ${BACKUP_DIR}/paddle-ocr-backup-${TIMESTAMP}.tar.gz -C /"
echo "  cd /data/docker"
echo "  docker-compose build paddle-ocr-api"
echo "  docker-compose up -d paddle-ocr-api"
echo ""
