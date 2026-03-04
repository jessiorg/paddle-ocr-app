#!/bin/bash
# Monitoring Script for PaddleOCR Application
# Checks health and sends alerts if needed

set -e

API_URL="${API_URL:-http://localhost:8001}"
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"
LOG_FILE="/var/log/paddle-ocr-monitor.log"

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send alert
send_alert() {
    local subject="$1"
    local message="$2"
    
    # Send email (requires mail to be configured)
    echo "$message" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || true
    
    log_message "ALERT: $subject - $message"
}

# Check API health
check_api_health() {
    log_message "Checking API health..."
    
    if curl -s -f "${API_URL}/health" > /dev/null 2>&1; then
        log_message "API health check: PASSED"
        return 0
    else
        log_message "API health check: FAILED"
        send_alert "PaddleOCR API Down" "The PaddleOCR API at ${API_URL} is not responding. Please investigate."
        return 1
    fi
}

# Check container status
check_container_status() {
    log_message "Checking container status..."
    
    if docker ps | grep -q "paddle-ocr-api"; then
        log_message "Container status: RUNNING"
        return 0
    else
        log_message "Container status: NOT RUNNING"
        send_alert "PaddleOCR Container Down" "The paddle-ocr-api container is not running."
        return 1
    fi
}

# Check disk space
check_disk_space() {
    log_message "Checking disk space..."
    
    USAGE=$(df -h /data | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$USAGE" -gt 90 ]; then
        log_message "Disk space: WARNING (${USAGE}% used)"
        send_alert "PaddleOCR Disk Space Warning" "Disk usage is at ${USAGE}%. Please free up space."
        return 1
    else
        log_message "Disk space: OK (${USAGE}% used)"
        return 0
    fi
}

# Check memory usage
check_memory_usage() {
    log_message "Checking memory usage..."
    
    CONTAINER_MEM=$(docker stats --no-stream --format "{{.MemPerc}}" paddle-ocr-api 2>/dev/null | sed 's/%//' || echo "0")
    
    if [ -n "$CONTAINER_MEM" ] && [ "$(echo "$CONTAINER_MEM > 90" | bc)" -eq 1 ]; then
        log_message "Memory usage: WARNING (${CONTAINER_MEM}%)"
        send_alert "PaddleOCR High Memory Usage" "Container memory usage is at ${CONTAINER_MEM}%."
        return 1
    else
        log_message "Memory usage: OK (${CONTAINER_MEM}%)"
        return 0
    fi
}

# Main monitoring loop
log_message "Starting PaddleOCR monitoring..."

FAILURES=0

# Run checks
check_container_status || ((FAILURES++))
check_api_health || ((FAILURES++))
check_disk_space || ((FAILURES++))
check_memory_usage || ((FAILURES++))

if [ $FAILURES -eq 0 ]; then
    log_message "All checks passed successfully"
    exit 0
else
    log_message "$FAILURES check(s) failed"
    exit 1
fi
