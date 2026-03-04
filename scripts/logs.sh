#!/bin/bash
# Log Viewer Script for PaddleOCR Application
# Convenient log viewing with filtering options

SERVICE="paddle-ocr-api"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
PaddleOCR Log Viewer

Usage: $0 [OPTIONS]

Options:
    -f, --follow        Follow log output (tail -f)
    -e, --errors        Show only errors
    -w, --warnings      Show errors and warnings
    -n, --lines NUM     Show last NUM lines (default: 100)
    -s, --since TIME    Show logs since TIME (e.g., "1h", "30m")
    -t, --timestamps    Show timestamps
    -h, --help          Show this help message

Examples:
    $0 -f                    # Follow logs in real-time
    $0 -e                    # Show only errors
    $0 -n 50                 # Show last 50 lines
    $0 -s "1h"               # Show logs from last hour
    $0 -f -e                 # Follow errors only

EOF
}

# Default values
FOLLOW=false
FILTER=""
LINES=100
SINCE=""
TIMESTAMPS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -e|--errors)
            FILTER="ERROR"
            shift
            ;;
        -w|--warnings)
            FILTER="WARN|ERROR"
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -s|--since)
            SINCE="$2"
            shift 2
            ;;
        -t|--timestamps)
            TIMESTAMPS=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Build docker-compose logs command
CMD="docker-compose logs"

if [ "$FOLLOW" = true ]; then
    CMD="$CMD -f"
fi

if [ -n "$SINCE" ]; then
    CMD="$CMD --since=$SINCE"
fi

if [ "$TIMESTAMPS" = true ]; then
    CMD="$CMD -t"
fi

if [ "$FOLLOW" = false ]; then
    CMD="$CMD --tail=$LINES"
fi

CMD="$CMD $SERVICE"

# Apply filter if specified
if [ -n "$FILTER" ]; then
    if [ "$FOLLOW" = true ]; then
        # For follow mode, colorize errors and warnings
        cd /data/docker 2>/dev/null || cd .
        eval $CMD | grep -E "$FILTER" | sed -e "s/ERROR/${RED}ERROR${NC}/g" -e "s/WARN/${YELLOW}WARN${NC}/g"
    else
        cd /data/docker 2>/dev/null || cd .
        eval $CMD | grep -E "$FILTER" | sed -e "s/ERROR/${RED}ERROR${NC}/g" -e "s/WARN/${YELLOW}WARN${NC}/g"
    fi
else
    # No filter, show all logs with colors
    cd /data/docker 2>/dev/null || cd .
    eval $CMD | sed -e "s/ERROR/${RED}ERROR${NC}/g" -e "s/WARN/${YELLOW}WARN${NC}/g" -e "s/INFO/${GREEN}INFO${NC}/g"
fi
