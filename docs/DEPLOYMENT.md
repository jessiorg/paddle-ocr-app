# Deployment Guide

## Prerequisites

- Ubuntu 20.04+ or Debian 11+
- Docker 24.0+
- Docker Compose 2.20+
- Nginx (in Docker)
- Minimum 4GB RAM
- 10GB free disk space
- Domain name (optional, for production)

## Quick Deployment

### 1. Automated Deployment

Use the deployment script for automatic setup:

```bash
sudo ./scripts/deploy.sh
```

This script will:
- Create directory structure
- Copy all files to appropriate locations
- Build Docker images
- Start services
- Configure Nginx

### 2. Manual Deployment

If you prefer manual deployment:

#### Step 1: Create Directory Structure

```bash
sudo mkdir -p /data/websites/paddle-ocr/{css,js,examples/sample-images}
sudo mkdir -p /data/paddle-ocr-backend/{api,logs}
sudo mkdir -p /data/docker/nginx/conf.d
```

#### Step 2: Copy Files

```bash
# Frontend
sudo cp frontend/* /data/websites/paddle-ocr/
sudo cp frontend/css/* /data/websites/paddle-ocr/css/
sudo cp frontend/js/* /data/websites/paddle-ocr/js/

# Backend
sudo cp -r api/ /data/paddle-ocr-backend/
sudo cp Dockerfile /data/paddle-ocr-backend/
sudo cp requirements.txt /data/paddle-ocr-backend/

# Nginx
sudo cp nginx/paddle-ocr.conf /data/docker/nginx/conf.d/
```

#### Step 3: Configure Environment

```bash
cp .env.example /data/paddle-ocr-backend/.env
nano /data/paddle-ocr-backend/.env
```

Update these critical settings:
```env
CORS_ORIGINS=https://your-domain.com
OCR_USE_GPU=false  # Set to true if GPU available
```

#### Step 4: Update Nginx Configuration

```bash
sudo nano /data/docker/nginx/conf.d/paddle-ocr.conf
```

Replace `your-domain.com` with your actual domain.

#### Step 5: Add to Docker Compose

```bash
cat docker-compose.service.yml >> /data/docker/docker-compose.yml
```

#### Step 6: Build and Start

```bash
cd /data/docker
docker-compose build paddle-ocr-api
docker-compose up -d paddle-ocr-api
docker-compose restart nginx
```

## SSL/TLS Configuration

### Using Let's Encrypt (Recommended)

1. **Install Certbot**

```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

2. **Obtain Certificate**

```bash
sudo certbot --nginx -d your-domain.com
```

3. **Auto-renewal**

Certbot automatically sets up renewal. Test it:

```bash
sudo certbot renew --dry-run
```

### Manual SSL Configuration

1. Uncomment SSL section in `/data/docker/nginx/conf.d/paddle-ocr.conf`
2. Update certificate paths
3. Restart Nginx:

```bash
docker-compose restart nginx
```

## Production Optimization

### 1. Enable GPU Support (If Available)

Update `.env`:
```env
OCR_USE_GPU=true
```

Update `docker-compose.yml` to include GPU:
```yaml
services:
  paddle-ocr-api:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

### 2. Scale Workers

Increase worker count for high traffic:

```yaml
environment:
  - API_WORKERS=8  # Increase based on CPU cores
```

### 3. Configure Caching

Add to Nginx config:

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=1g inactive=60m;

location /api/ {
    proxy_cache api_cache;
    proxy_cache_valid 200 5m;
    proxy_cache_key "$request_uri";
    # ... rest of config
}
```

### 4. Set up Monitoring

#### Using Docker Stats

```bash
docker stats paddle-ocr-api
```

#### Using Prometheus (Advanced)

Add Prometheus exporter to your setup for detailed metrics.

### 5. Configure Log Rotation

Create `/etc/logrotate.d/paddle-ocr`:

```
/data/paddle-ocr-backend/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 appuser appuser
    sharedscripts
}
```

## Backup Strategy

### Automated Backups

```bash
# Add to crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /path/to/scripts/backup.sh
```

### Manual Backup

```bash
./scripts/backup.sh
```

### Restore from Backup

```bash
tar -xzf paddle-ocr-backup-YYYYMMDD_HHMMSS.tar.gz -C /
docker-compose restart paddle-ocr-api nginx
```

## Monitoring & Alerts

### Health Check Monitoring

Set up monitoring with:
- UptimeRobot
- Pingdom
- Custom scripts with cron

Example monitoring script:

```bash
#!/bin/bash
if ! curl -f http://localhost:8001/health; then
    echo "API is down!" | mail -s "PaddleOCR Alert" admin@example.com
    docker-compose restart paddle-ocr-api
fi
```

### Log Monitoring

```bash
# Real-time logs
docker-compose logs -f paddle-ocr-api

# Error logs only
docker-compose logs paddle-ocr-api | grep ERROR

# Last hour of logs
docker-compose logs --since="1h" paddle-ocr-api
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs paddle-ocr-api

# Check if port is in use
sudo netstat -tlnp | grep 8001

# Rebuild container
docker-compose build --no-cache paddle-ocr-api
docker-compose up -d paddle-ocr-api
```

### High Memory Usage

1. Reduce worker count
2. Decrease OCR batch size
3. Add memory limits in docker-compose.yml

### Slow Processing

1. Enable GPU if available
2. Increase workers
3. Optimize images before processing
4. Check network latency

### 502 Bad Gateway

```bash
# Check API status
curl http://localhost:8001/health

# Check Nginx config
docker-compose exec nginx nginx -t

# Restart services
docker-compose restart paddle-ocr-api nginx
```

## Security Checklist

- [ ] Change default CORS origins
- [ ] Enable HTTPS/SSL
- [ ] Set up firewall rules
- [ ] Configure rate limiting
- [ ] Regular security updates
- [ ] Disable API docs in production (optional)
- [ ] Use strong passwords for admin interfaces
- [ ] Regular backups
- [ ] Monitor logs for suspicious activity

## Performance Tuning

### System Level

```bash
# Increase file descriptors
ulimit -n 65536

# Optimize kernel parameters
sudo sysctl -w net.core.somaxconn=1024
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=1024
```

### Docker Level

```yaml
# In docker-compose.yml
services:
  paddle-ocr-api:
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    sysctls:
      - net.core.somaxconn=1024
```

## Scaling

### Horizontal Scaling

For high-traffic deployments:

1. Deploy multiple instances
2. Use load balancer (Nginx, HAProxy)
3. Share persistent volumes
4. Use Redis for session storage

### Vertical Scaling

Increase resources:

```yaml
deploy:
  resources:
    limits:
      cpus: '8'
      memory: 8G
```

## Updating

### Update Application

```bash
git pull
./scripts/deploy.sh
```

### Update Dependencies

```bash
# Update requirements.txt
pip list --outdated

# Rebuild
docker-compose build --no-cache paddle-ocr-api
docker-compose up -d paddle-ocr-api
```

## Support

For issues:
- Check logs: `docker-compose logs paddle-ocr-api`
- GitHub Issues: https://github.com/jessiorg/paddle-ocr-app/issues
- PaddleOCR Docs: https://github.com/PaddlePaddle/PaddleOCR
