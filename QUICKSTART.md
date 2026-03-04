# Quick Start Guide

## 5-Minute Setup

Get PaddleOCR running in 5 minutes!

### Step 1: Prerequisites

Ensure you have:
```bash
# Check Docker
docker --version  # Should be 24.0+

# Check Docker Compose
docker-compose --version  # Should be 2.20+
```

If not installed:
```bash
# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sudo sh

# Install Docker Compose
sudo apt install docker-compose-plugin
```

### Step 2: Clone Repository

```bash
git clone https://github.com/jessiorg/paddle-ocr-app.git
cd paddle-ocr-app
```

### Step 3: Deploy

```bash
# Make script executable
chmod +x scripts/deploy.sh

# Run deployment
sudo ./scripts/deploy.sh
```

That's it! ✨

### Step 4: Access Application

Open your browser:
- **Frontend**: http://localhost/paddle-ocr/
- **API Docs**: http://localhost/api/v1/docs
- **Health Check**: http://localhost/api/v1/health

## Quick Test

### Using Web Interface

1. Go to http://localhost/paddle-ocr/
2. Drag and drop an image
3. Click "Extract Text"
4. View results!

### Using API

```bash
# Test with curl
curl -X POST http://localhost/api/v1/ocr \
  -F "file=@your-image.jpg" \
  -F "language=en"
```

### Using Python

```python
import requests

url = "http://localhost/api/v1/ocr"
files = {"file": open("document.jpg", "rb")}
data = {"language": "en"}

response = requests.post(url, files=files, data=data)
print(response.json()["text"])
```

## Configuration

### Change Port

Edit `/data/docker/docker-compose.yml`:
```yaml
services:
  paddle-ocr-api:
    ports:
      - "9000:8000"  # Change 8001 to your preferred port
```

### Change Domain

Edit `/data/docker/nginx/conf.d/paddle-ocr.conf`:
```nginx
server_name your-domain.com;  # Replace with your domain
```

### Enable GPU

Edit `/data/paddle-ocr-backend/.env`:
```env
OCR_USE_GPU=true
```

Restart:
```bash
cd /data/docker
docker-compose restart paddle-ocr-api
```

## Common Commands

```bash
# View logs
docker-compose logs -f paddle-ocr-api

# Restart service
docker-compose restart paddle-ocr-api

# Stop service
docker-compose stop paddle-ocr-api

# Rebuild container
docker-compose build --no-cache paddle-ocr-api
docker-compose up -d paddle-ocr-api

# Check status
docker-compose ps
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 8001
sudo lsof -i :8001

# Kill process or change port in docker-compose.yml
```

### Container Won't Start

```bash
# Check logs
docker-compose logs paddle-ocr-api

# Remove and recreate
docker-compose down
docker-compose up -d
```

### Can't Access Web Interface

```bash
# Check if files exist
ls -la /data/websites/paddle-ocr/

# Check Nginx config
docker-compose exec nginx nginx -t

# Restart Nginx
docker-compose restart nginx
```

## Next Steps

1. **Production Setup**: Read [DEPLOYMENT.md](docs/DEPLOYMENT.md)
2. **API Details**: Check [API.md](docs/API.md)
3. **Architecture**: See [ARCHITECTURE.md](docs/ARCHITECTURE.md)
4. **SSL Setup**: Configure HTTPS for production

## Support

- **Issues**: https://github.com/jessiorg/paddle-ocr-app/issues
- **Documentation**: Check the `docs/` folder
- **PaddleOCR**: https://github.com/PaddlePaddle/PaddleOCR

## What's Next?

Now that you're up and running:

✅ Upload some test images  
✅ Try different languages  
✅ Check the API documentation  
✅ Monitor the logs  
✅ Configure for your needs  

Enjoy! 🎉
