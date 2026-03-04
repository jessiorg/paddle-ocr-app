#!/bin/bash
# PaddleOCR Deployment Fix Script
# Fixes path configurations and deployment issues in docker-compose.yml and deploy.sh
# Author: Deployment Automation
# Date: 2026-03-04

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATA_DIR="/data"
DOCKER_DIR="${DATA_DIR}/docker"
DOCKER_COMPOSE_FILE="${DOCKER_DIR}/docker-compose.yml"
DEPLOY_SCRIPT="${SCRIPT_DIR}/deploy.sh"
BACKUP_DIR="${DATA_DIR}/backups/paddle-ocr-fixes-$(date +%Y%m%d-%H%M%S)"

# Counter for fixes applied
FIXES_APPLIED=0

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to create backup
create_backup() {
    local file=$1
    if [ -f "$file" ]; then
        mkdir -p "${BACKUP_DIR}"
        cp "$file" "${BACKUP_DIR}/$(basename $file).backup"
        print_success "Backed up: $file -> ${BACKUP_DIR}/$(basename $file).backup"
    fi
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run with sudo or as root"
        exit 1
    fi
}

echo "======================================"
echo "PaddleOCR Deployment Fix Script"
echo "======================================"
echo ""
print_status "Starting deployment configuration fixes..."
echo ""

# Check root privileges
check_root

# Check if docker-compose.yml exists
if [ ! -f "${DOCKER_COMPOSE_FILE}" ]; then
    print_warning "docker-compose.yml not found at ${DOCKER_COMPOSE_FILE}"
    print_status "Creating docker-compose.yml from service template..."
    
    if [ -f "${REPO_DIR}/docker-compose.service.yml" ]; then
        mkdir -p "${DOCKER_DIR}"
        cp "${REPO_DIR}/docker-compose.service.yml" "${DOCKER_COMPOSE_FILE}"
        print_success "Created docker-compose.yml"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    else
        print_error "Template file docker-compose.service.yml not found in repository"
        exit 1
    fi
else
    print_success "Found docker-compose.yml at ${DOCKER_COMPOSE_FILE}"
fi

# Backup files before making changes
echo ""
print_status "Creating backups..."
create_backup "${DOCKER_COMPOSE_FILE}"
if [ -f "${DEPLOY_SCRIPT}" ]; then
    create_backup "${DEPLOY_SCRIPT}"
fi

# Fix 1: Check and fix build context path in docker-compose.yml
echo ""
print_status "Fix 1: Checking build context path in docker-compose.yml..."

if grep -q "context:.*paddle-ocr-backend" "${DOCKER_COMPOSE_FILE}"; then
    CURRENT_CONTEXT=$(grep "context:" "${DOCKER_COMPOSE_FILE}" | grep "paddle-ocr-backend" | sed -n 's/.*context:\s*//p' | tr -d ' ')
    
    if [ "$CURRENT_CONTEXT" = "/data/paddle-ocr-backend" ]; then
        print_success "Build context path is correct: /data/paddle-ocr-backend"
    else
        print_warning "Build context path needs fixing: ${CURRENT_CONTEXT}"
        sed -i 's|context:.*paddle-ocr-backend.*|      context: /data/paddle-ocr-backend|g' "${DOCKER_COMPOSE_FILE}"
        print_success "Fixed build context path to: /data/paddle-ocr-backend"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
else
    print_warning "No paddle-ocr-backend context found in docker-compose.yml"
fi

# Fix 2: Check and fix health check endpoint
echo ""
print_status "Fix 2: Checking health check endpoint..."

if grep -q "http://localhost:8000/health\"" "${DOCKER_COMPOSE_FILE}"; then
    print_warning "Health check endpoint needs updating"
    sed -i 's|http://localhost:8000/health|http://localhost:8000/api/v1/health|g' "${DOCKER_COMPOSE_FILE}"
    print_success "Fixed health check endpoint to: /api/v1/health"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
elif grep -q "http://localhost:8000/api/v1/health\"" "${DOCKER_COMPOSE_FILE}"; then
    print_success "Health check endpoint is correct: /api/v1/health"
else
    print_warning "Health check endpoint not found in expected format"
fi

# Fix 3: Update deploy.sh to build only paddle-ocr-api service
echo ""
print_status "Fix 3: Checking deploy.sh for service-specific build..."

if [ -f "${DEPLOY_SCRIPT}" ]; then
    # Check if deploy.sh already builds only paddle-ocr-api
    if grep -q "docker-compose build paddle-ocr-api" "${DEPLOY_SCRIPT}"; then
        print_success "deploy.sh already builds paddle-ocr-api service specifically"
    else
        print_warning "deploy.sh needs to be updated to build paddle-ocr-api specifically"
        
        # Create updated deploy.sh with service-specific build
        sed -i 's/docker-compose build$/docker-compose build paddle-ocr-api/g' "${DEPLOY_SCRIPT}"
        sed -i 's/docker-compose build $/docker-compose build paddle-ocr-api /g' "${DEPLOY_SCRIPT}"
        
        print_success "Updated deploy.sh to build only paddle-ocr-api service"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
    
    # Check if deploy.sh uses correct up command
    if grep -q "docker-compose up -d paddle-ocr-api" "${DEPLOY_SCRIPT}"; then
        print_success "deploy.sh already uses 'docker-compose up -d paddle-ocr-api'"
    else
        print_warning "deploy.sh may not use service-specific up command"
        
        # Fix up command to be service-specific
        sed -i 's/docker-compose up -d$/docker-compose up -d paddle-ocr-api/g' "${DEPLOY_SCRIPT}"
        sed -i 's/docker-compose up -d $/docker-compose up -d paddle-ocr-api /g' "${DEPLOY_SCRIPT}"
        
        print_success "Updated deploy.sh to use 'docker-compose up -d paddle-ocr-api'"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
else
    print_warning "deploy.sh not found at ${DEPLOY_SCRIPT}"
    print_status "You may need to update the deploy.sh script manually"
fi

# Fix 4: Verify health check endpoint in deploy.sh
echo ""
print_status "Fix 4: Checking health check endpoint in deploy.sh..."

if [ -f "${DEPLOY_SCRIPT}" ]; then
    if grep -q "http://localhost:8001/health" "${DEPLOY_SCRIPT}"; then
        print_warning "deploy.sh health check needs updating"
        sed -i 's|http://localhost:8001/health|http://localhost:8001/api/v1/health|g' "${DEPLOY_SCRIPT}"
        print_success "Fixed deploy.sh health check endpoint to: /api/v1/health"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    elif grep -q "http://localhost:8001/api/v1/health" "${DEPLOY_SCRIPT}"; then
        print_success "deploy.sh health check endpoint is correct"
    else
        print_warning "Health check endpoint not found in deploy.sh in expected format"
    fi
fi

# Fix 5: Ensure proper port mapping
echo ""
print_status "Fix 5: Verifying port mapping configuration..."

if grep -q "8001:8000" "${DOCKER_COMPOSE_FILE}"; then
    print_success "Port mapping is correct: 8001:8000 (host:container)"
else
    print_warning "Port mapping may need attention - please verify manually"
fi

# Fix 6: Verify network configuration
echo ""
print_status "Fix 6: Checking network configuration..."

if grep -q "webproxy:" "${DOCKER_COMPOSE_FILE}"; then
    if grep -q "external: true" "${DOCKER_COMPOSE_FILE}"; then
        print_success "Network configuration is correct: webproxy (external)"
    else
        print_warning "Network 'webproxy' exists but may not be configured as external"
    fi
else
    print_warning "Network 'webproxy' not found in configuration"
fi

# Verify the webproxy network exists
echo ""
print_status "Verifying Docker network 'webproxy' exists..."
if docker network ls | grep -q "webproxy"; then
    print_success "Docker network 'webproxy' exists"
else
    print_warning "Docker network 'webproxy' does not exist"
    print_status "Creating 'webproxy' network..."
    docker network create webproxy
    print_success "Created Docker network 'webproxy'"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi

# Summary
echo ""
echo "======================================"
echo "Fix Summary"
echo "======================================"
echo ""
print_status "Total fixes applied: ${FIXES_APPLIED}"
echo ""

if [ ${FIXES_APPLIED} -gt 0 ]; then
    print_success "Configuration has been updated!"
    echo ""
    print_status "Backup location: ${BACKUP_DIR}"
    echo ""
    print_status "Modified files:"
    [ -f "${DOCKER_COMPOSE_FILE}" ] && echo "  - ${DOCKER_COMPOSE_FILE}"
    [ -f "${DEPLOY_SCRIPT}" ] && echo "  - ${DEPLOY_SCRIPT}"
    echo ""
    print_status "Next steps:"
    echo "  1. Review the changes in docker-compose.yml"
    echo "  2. Test the deployment with: sudo ${DEPLOY_SCRIPT}"
    echo "  3. Verify service health: curl http://localhost:8001/api/v1/health"
    echo ""
    print_warning "If issues occur, restore from: ${BACKUP_DIR}"
else
    print_success "No fixes needed - configuration is already correct!"
fi

echo ""
print_status "Detailed configuration check:"
echo ""
echo "Build Context Path:"
grep -A 1 "build:" "${DOCKER_COMPOSE_FILE}" | grep "context:" || echo "  Not found"
echo ""
echo "Health Check Endpoint:"
grep "test:" "${DOCKER_COMPOSE_FILE}" | grep "health" || echo "  Not found"
echo ""
echo "Port Mapping:"
grep "8001:8000" "${DOCKER_COMPOSE_FILE}" || echo "  Not found"
echo ""
echo "Network Configuration:"
grep -A 1 "networks:" "${DOCKER_COMPOSE_FILE}" | tail -1 || echo "  Not found"
echo ""

echo "======================================"
echo "Fix Script Complete!"
echo "======================================"
echo ""
