# PaddleOCR Application - Production Ready

![PaddleOCR](https://img.shields.io/badge/PaddleOCR-Latest-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115.0-green)
![Python](https://img.shields.io/badge/Python-3.12+-yellow)
![Docker](https://img.shields.io/badge/Docker-Enabled-blue)

## 🚀 Overview

A production-ready PaddleOCR application with a modern web interface, FastAPI backend, and complete Docker deployment setup. Designed as a template for multi-website architectures.

## ✨ Features

- **Modern Web Interface**: Clean, responsive UI with drag-and-drop support
- **FastAPI Backend**: High-performance API with async support
- **PaddleOCR Integration**: Latest OCR capabilities with multiple language support
- **Docker Deployment**: Complete containerized setup with Nginx reverse proxy
- **Production Ready**: Error handling, logging, security headers, rate limiting
- **Multi-format Support**: PNG, JPG, JPEG, PDF
- **Real-time Processing**: Instant OCR results with confidence scores
- **Template Architecture**: Easily adaptable for other applications

## 📁 Architecture

```
/data/
├── websites/
│   └── paddle-ocr/              # Static frontend files
│       ├── index.html
│       ├── css/
│       │   └── style.css
│       ├── js/
│       │   └── app.js
│       └── examples/
│           └── sample-images/
├── docker/
│   ├── nginx/
│   │   └── conf.d/
│   │       └── paddle-ocr.conf  # Nginx reverse proxy config
│   └── docker-compose.yml       # Main compose file
└── paddle-ocr-backend/          # API backend (this repo)
    ├── api/
    ├── Dockerfile
    └── requirements.txt
```

## 🛠️ Installation

### Prerequisites

- Docker 24.0+
- Docker Compose 2.20+
- Minimum 4GB RAM
- 10GB free disk space

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/jessiorg/paddle-ocr-app.git
   cd paddle-ocr-app
   ```

2. **Set up directory structure**
   ```bash
   # Create required directories
   sudo mkdir -p /data/websites/paddle-ocr/{css,js,examples/sample-images}
   sudo mkdir -p /data/docker/nginx/conf.d
   sudo mkdir -p /data/paddle-ocr-backend
   
   # Copy frontend files
   sudo cp frontend/* /data/websites/paddle-ocr/
   sudo cp frontend/css/* /data/websites/paddle-ocr/css/
   sudo cp frontend/js/* /data/websites/paddle-ocr/js/
   sudo cp examples/* /data/websites/paddle-ocr/examples/sample-images/
   
   # Copy backend files
   sudo cp -r api /data/paddle-ocr-backend/
   sudo cp Dockerfile /data/paddle-ocr-backend/
   sudo cp requirements.txt /data/paddle-ocr-backend/
   
   # Copy nginx config
   sudo cp nginx/paddle-ocr.conf /data/docker/nginx/conf.d/
   
   # Set permissions
   sudo chown -R $USER:$USER /data/websites/paddle-ocr
   sudo chown -R $USER:$USER /data/paddle-ocr-backend
   ```

3. **Add to docker-compose.yml**
   ```bash
   # Add the service definition from docker-compose.service.yml to your main docker-compose.yml
   cat docker-compose.service.yml >> /data/docker/docker-compose.yml
   ```

4. **Deploy the application**
   ```bash
   cd /data/docker
   docker-compose up -d paddle-ocr-api
   docker-compose restart nginx
   ```

5. **Verify deployment**
   ```bash
   # Check API health
   curl http://localhost:8001/health
   
   # Check logs
   docker-compose logs -f paddle-ocr-api
   ```

## 🌐 Usage

### Web Interface

Access the application at: `http://your-domain.com/paddle-ocr/`

1. **Upload Image**: Drag and drop or click to select
2. **Select Language**: Choose detection language (default: English)
3. **Process**: Click "Extract Text" button
4. **Results**: View extracted text with confidence scores
5. **Export**: Copy text or download as TXT file

### API Endpoints

#### Health Check
```bash
curl http://localhost:8001/health
```

#### OCR Processing
```bash
curl -X POST http://localhost:8001/api/v1/ocr \
  -F "file=@image.jpg" \
  -F "language=en"
```

#### Supported Languages
```bash
curl http://localhost:8001/api/v1/languages
```

### Python Client Example

```python
import requests

url = "http://localhost:8001/api/v1/ocr"
files = {"file": open("document.jpg", "rb")}
data = {"language": "en"}

response = requests.post(url, files=files, data=data)
result = response.json()

if result["success"]:
    print(f"Extracted Text: {result['text']}")
    print(f"Confidence: {result['confidence']:.2%}")
```

### JavaScript Example

```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('language', 'en');

fetch('/api/v1/ocr', {
    method: 'POST',
    body: formData
})
.then(response => response.json())
.then(data => {
    if (data.success) {
        console.log('Text:', data.text);
        console.log('Confidence:', data.confidence);
    }
});
```

## 🔧 Configuration

### Environment Variables

Create `.env` file in backend directory:

```bash
# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
LOG_LEVEL=info

# PaddleOCR Settings
OCR_USE_GPU=false
OCR_ENABLE_MKLDNN=true
OCR_USE_ANGLE_CLS=true
OCR_DET_LIMIT_SIDE_LEN=960
OCR_REC_BATCH_NUM=6

# Upload Limits
MAX_FILE_SIZE=10485760  # 10MB
ALLOWED_EXTENSIONS=png,jpg,jpeg,pdf

# Security
CORS_ORIGINS=http://localhost,https://your-domain.com
RATE_LIMIT=100/minute
```

### Nginx Configuration

Modify `/data/docker/nginx/conf.d/paddle-ocr.conf` for custom domains:

```nginx
server_name your-domain.com;
```

### Resource Limits

Adjust in docker-compose.yml:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
    reservations:
      memory: 2G
```

## 📊 Monitoring & Logging

### View Logs
```bash
# Real-time logs
docker-compose logs -f paddle-ocr-api

# Last 100 lines
docker-compose logs --tail=100 paddle-ocr-api

# Logs for specific time
docker-compose logs --since="2026-03-04T10:00:00" paddle-ocr-api
```

### Performance Metrics
```bash
# Container stats
docker stats paddle-ocr-api

# API metrics endpoint
curl http://localhost:8001/metrics
```

## 🔒 Security Features

- **Rate Limiting**: Prevents API abuse
- **File Validation**: Type, size, and content verification
- **CORS Protection**: Configurable origin whitelist
- **Security Headers**: HSTS, CSP, X-Frame-Options
- **Input Sanitization**: Prevents injection attacks
- **Error Masking**: Generic error messages to clients
- **Temporary File Cleanup**: Automatic cleanup after processing

## 🐛 Troubleshooting

### Common Issues

#### Container won't start
```bash
# Check logs
docker-compose logs paddle-ocr-api

# Rebuild container
docker-compose build --no-cache paddle-ocr-api
docker-compose up -d paddle-ocr-api
```

#### OCR not working
```bash
# Verify PaddleOCR models downloaded
docker-compose exec paddle-ocr-api ls /root/.paddleocr/

# Test API directly
curl -X POST http://localhost:8001/api/v1/ocr \
  -F "file=@test.jpg" -v
```

#### High memory usage
- Reduce `OCR_REC_BATCH_NUM` in environment variables
- Decrease `OCR_DET_LIMIT_SIDE_LEN` for smaller images
- Add memory limits in docker-compose.yml

#### 502 Bad Gateway
```bash
# Check if API is running
curl http://localhost:8001/health

# Restart nginx
docker-compose restart nginx

# Check nginx config
docker-compose exec nginx nginx -t
```

## 🚀 Production Deployment

### 1. SSL/TLS Setup
```bash
# Using Let's Encrypt
sudo certbot --nginx -d your-domain.com
```

### 2. Performance Tuning
- Enable GPU support if available
- Increase worker count for high traffic
- Use CDN for static assets
- Enable Nginx caching

### 3. Backup Strategy
```bash
# Backup configuration
tar -czf paddle-ocr-backup-$(date +%Y%m%d).tar.gz \
  /data/websites/paddle-ocr \
  /data/docker/nginx/conf.d/paddle-ocr.conf
```

### 4. Monitoring Setup
- Integrate with Prometheus for metrics
- Set up health check alerts
- Configure log aggregation (ELK stack)

## 🔄 Updates & Maintenance

### Update PaddleOCR
```bash
# Pull latest code
cd paddle-ocr-app
git pull

# Rebuild container
docker-compose build paddle-ocr-api
docker-compose up -d paddle-ocr-api
```

### Update Dependencies
```bash
# Update requirements.txt
pip list --outdated

# Rebuild and restart
docker-compose build --no-cache paddle-ocr-api
docker-compose up -d paddle-ocr-api
```

## 📝 Template Usage

This architecture can be adapted for other applications:

1. **Clone structure**: Copy folder layout
2. **Modify API**: Replace OCR logic with your service
3. **Update frontend**: Customize UI for your needs
4. **Adjust configs**: Update Nginx and Docker configs
5. **Deploy**: Follow same deployment process

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) - OCR engine
- [FastAPI](https://fastapi.tiangolo.com/) - Web framework
- [Docker](https://www.docker.com/) - Containerization
- [Nginx](https://nginx.org/) - Web server

## 📧 Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/jessiorg/paddle-ocr-app/issues)
- Documentation: This README
- PaddleOCR Docs: [Official Documentation](https://github.com/PaddlePaddle/PaddleOCR)

---

**Version**: 1.0.0  
**Last Updated**: March 4, 2026  
**Maintained by**: Organiser (@jessiorg)