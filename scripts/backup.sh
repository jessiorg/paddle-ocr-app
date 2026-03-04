#!/bin/bash
# Backup Script for PaddleOCR Application

set -e

BACKUP_DIR="${BACKUP_DIR:-/backup/paddle-ocr}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="paddle-ocr-backup-${TIMESTAMP}.tar.gz"

echo "Creating backup: ${BACKUP_FILE}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup files
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    /data/websites/paddle-ocr \
    /data/paddle-ocr-backend \
    /data/docker/nginx/conf.d/paddle-ocr.conf \
    2>/dev/null

echo "Backup created: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "Size: $(du -h ${BACKUP_DIR}/${BACKUP_FILE} | cut -f1)"

# Keep only last 7 backups
cd "${BACKUP_DIR}"
ls -t paddle-ocr-backup-*.tar.gz | tail -n +8 | xargs -r rm

echo "Old backups cleaned up (keeping last 7)"
