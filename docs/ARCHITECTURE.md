# Architecture Documentation

## System Overview

The PaddleOCR application follows a modern microservices architecture with clear separation between frontend, backend, and infrastructure components.

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
          ┌──────────────────────┐
          │   Nginx Reverse      │
          │   Proxy (Port 80)    │
          │   SSL/TLS Termination│
          └──────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌────────────────┐    ┌──────────────────┐
│  Static Files  │    │   FastAPI        │
│  Frontend      │    │   Backend API    │
│  /paddle-ocr/  │    │   Port 8000      │
│                │    │   (Internal)     │
│  - HTML        │    │                  │
│  - CSS         │    │  - OCR Engine    │
│  - JavaScript  │    │  - PaddleOCR     │
└────────────────┘    │  - Image Process │
                      └──────────┬───────┘
                                 │
                                 ▼
                      ┌──────────────────┐
                      │  PaddleOCR       │
                      │  Models Cache    │
                      │  (Persistent)    │
                      └──────────────────┘
```

## Component Details

### 1. Frontend Layer

**Location**: `/data/websites/paddle-ocr/`

**Components**:
- `index.html` - Single page application
- `css/style.css` - Styling and responsive design
- `js/app.js` - Client-side logic and API communication

**Features**:
- Drag-and-drop file upload
- Real-time preview
- Responsive design
- Error handling
- Progress indicators

**Technology Stack**:
- Pure HTML5
- CSS3 with CSS Variables
- Vanilla JavaScript (ES6+)
- Fetch API for HTTP requests

### 2. Backend API Layer

**Location**: `/data/paddle-ocr-backend/`

**Components**:
- `api/main.py` - FastAPI application
- `api/__init__.py` - Package initialization
- `Dockerfile` - Container definition
- `requirements.txt` - Python dependencies

**Features**:
- RESTful API endpoints
- Multi-language OCR support
- File validation and processing
- Error handling and logging
- Health checks and metrics
- Automatic cleanup of temporary files

**Technology Stack**:
- Python 3.12+
- FastAPI (async web framework)
- PaddleOCR (OCR engine)
- OpenCV (image processing)
- Uvicorn (ASGI server)

### 3. Infrastructure Layer

**Components**:

#### Docker Containers
```yaml
paddle-ocr-api:
  - Python 3.12-slim base image
  - 4 Uvicorn workers
  - Health checks enabled
  - Resource limits configured
  - Persistent model cache

nginx:
  - Reverse proxy
  - SSL termination
  - Static file serving
  - Load balancing ready
```

#### Volumes
```
paddle-ocr-models/
  - PaddleOCR model files
  - Persistent across restarts
  - Shared between instances (for scaling)

logs/
  - Application logs
  - Nginx access logs
  - Error logs
```

#### Networks
```
webproxy:
  - Internal Docker network
  - Isolates services
  - Allows inter-container communication
```

## Data Flow

### OCR Processing Flow

```
┌──────────┐
│  Client  │
└────┬─────┘
     │
     │ 1. Upload image
     ▼
┌──────────────┐
│   Nginx      │
└────┬─────────┘
     │
     │ 2. Route to API
     ▼
┌──────────────┐
│  FastAPI     │
│  Endpoint    │
└────┬─────────┘
     │
     │ 3. Validate file
     ▼
┌──────────────┐
│  File        │
│  Validation  │
└────┬─────────┘
     │
     │ 4. Save to temp
     ▼
┌──────────────┐
│  Temp File   │
│  Storage     │
└────┬─────────┘
     │
     │ 5. Load image
     ▼
┌──────────────┐
│  OpenCV      │
│  Processing  │
└────┬─────────┘
     │
     │ 6. Perform OCR
     ▼
┌──────────────┐
│  PaddleOCR   │
│  Engine      │
└────┬─────────┘
     │
     │ 7. Format results
     ▼
┌──────────────┐
│  Response    │
│  Builder     │
└────┬─────────┘
     │
     │ 8. Clean temp files
     ▼
┌──────────────┐
│  Cleanup     │
└────┬─────────┘
     │
     │ 9. Return JSON
     ▼
┌──────────────┐
│  Client      │
└──────────────┘
```

## Security Architecture

### Defense in Depth

```
Layer 1: Network
  - Firewall rules
  - Rate limiting
  - DDoS protection

Layer 2: Nginx
  - SSL/TLS encryption
  - Security headers
  - Request validation
  - Size limits

Layer 3: Application
  - CORS configuration
  - File type validation
  - Input sanitization
  - Error masking

Layer 4: Container
  - Non-root user
  - Read-only filesystem
  - Resource limits
  - Isolated network

Layer 5: Monitoring
  - Access logs
  - Error tracking
  - Health checks
  - Alerts
```

## Deployment Architecture

### Single Server Deployment

```
┌─────────────────────────────────────────┐
│  Server (Ubuntu 20.04+)                 │
│                                          │
│  ┌────────────────────────────────┐    │
│  │  Docker Engine                  │    │
│  │                                 │    │
│  │  ┌──────────┐  ┌────────────┐ │    │
│  │  │  Nginx   │  │ PaddleOCR  │ │    │
│  │  │Container │  │ Container  │ │    │
│  │  └──────────┘  └────────────┘ │    │
│  │                                 │    │
│  │  ┌──────────────────────────┐ │    │
│  │  │  Shared Volumes          │ │    │
│  │  │  - Models                │ │    │
│  │  │  - Logs                  │ │    │
│  │  └──────────────────────────┘ │    │
│  └────────────────────────────────┘    │
│                                          │
│  /data/                                  │
│  ├── websites/paddle-ocr/               │
│  ├── paddle-ocr-backend/                │
│  └── docker/                             │
└─────────────────────────────────────────┘
```

### Multi-Server Deployment (Scalable)

```
                 ┌────────────┐
                 │ Load       │
                 │ Balancer   │
                 └──────┬─────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
      ┌────▼───┐   ┌───▼────┐   ┌──▼─────┐
      │Server 1│   │Server 2│   │Server 3│
      │        │   │        │   │        │
      │ Nginx  │   │ Nginx  │   │ Nginx  │
      │  API   │   │  API   │   │  API   │
      └────┬───┘   └───┬────┘   └──┬─────┘
           │            │            │
           └────────────┼────────────┘
                        │
                 ┌──────▼─────┐
                 │ Shared     │
                 │ Storage    │
                 │ (NFS/EFS)  │
                 └────────────┘
```

## API Architecture

### Endpoint Structure

```
/
├── /health                    # System health
│
├── /api/v1/
│   ├── /health               # API health (versioned)
│   ├── /languages            # Supported languages
│   ├── /metrics              # API metrics
│   ├── /ocr                  # Main OCR endpoint
│   ├── /docs                 # Interactive docs (Swagger)
│   └── /redoc                # Alternative docs (ReDoc)
```

### Request/Response Flow

```
Client Request
  └─> Middleware Chain
       ├─> CORS Handler
       ├─> Request Logger
       └─> Rate Limiter
            └─> Route Handler
                 ├─> Validation
                 ├─> Business Logic
                 └─> Response
                      └─> Error Handler
                           └─> Client Response
```

## Storage Architecture

### Directory Structure

```
/data/
├── websites/
│   └── paddle-ocr/                # Frontend static files
│       ├── index.html
│       ├── css/
│       │   └── style.css
│       ├── js/
│       │   └── app.js
│       └── examples/
│           └── sample-images/
│
├── paddle-ocr-backend/            # Backend application
│   ├── api/
│   │   ├── __init__.py
│   │   └── main.py
│   ├── logs/                      # Application logs
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env
│
└── docker/
    ├── nginx/
    │   └── conf.d/
    │       └── paddle-ocr.conf
    └── docker-compose.yml
```

### Volume Persistence

```
paddle-ocr-models:
  Type: Named Docker volume
  Purpose: Cache PaddleOCR model files
  Size: ~2GB per language
  Backup: Not required (re-downloadable)

logs:
  Type: Bind mount
  Purpose: Application and access logs
  Rotation: Daily, keep 7 days
  Backup: Weekly

static files:
  Type: Bind mount
  Purpose: Frontend assets
  Backup: Daily
```

## Performance Architecture

### Optimization Layers

```
1. Browser Cache
   - Static assets: 30 days
   - HTML: No cache

2. Nginx Cache
   - API responses: 5 minutes (optional)
   - Static files: served directly

3. Application Cache
   - OCR models: In-memory
   - Language models: Lazy loading

4. Resource Management
   - Worker processes: 4 (configurable)
   - Memory limit: 4GB
   - CPU limit: 4 cores
```

### Scalability Strategy

```
Vertical Scaling:
  ├─> Increase CPU cores
  ├─> Add more RAM
  ├─> Enable GPU
  └─> Increase worker count

Horizontal Scaling:
  ├─> Multiple API instances
  ├─> Load balancer
  ├─> Shared storage
  └─> Distributed cache
```

## Monitoring Architecture

### Health Checks

```
Docker Level:
  - Container health: 30s interval
  - Endpoint: /health
  - Retries: 3
  - Timeout: 10s

Application Level:
  - API health: Model status
  - Memory usage
  - Request latency

Infrastructure Level:
  - CPU usage
  - Disk space
  - Network traffic
```

### Logging Strategy

```
Access Logs:
  - Location: /var/log/nginx/
  - Format: JSON
  - Retention: 7 days

Application Logs:
  - Location: /data/paddle-ocr-backend/logs/
  - Level: INFO (configurable)
  - Format: JSON with timestamps
  - Retention: 7 days

Error Logs:
  - Location: /var/log/nginx/error.log
  - Level: WARN+
  - Alerts: Email on ERROR
```

## Template Architecture

### Adaptability for Other Applications

This architecture serves as a template that can be adapted:

```
1. Frontend
   - Replace HTML/CSS/JS with your UI
   - Maintain structure and API calls

2. Backend
   - Replace PaddleOCR with your service
   - Keep FastAPI framework
   - Maintain endpoint structure

3. Infrastructure
   - Keep Docker/Nginx setup
   - Adjust resource limits
   - Update environment variables

4. Deployment
   - Use same scripts
   - Update configuration
   - Maintain security practices
```

## Technology Decisions

### Why FastAPI?
- Modern async support
- Automatic API documentation
- Type validation with Pydantic
- High performance
- Easy to test

### Why PaddleOCR?
- Multi-language support
- High accuracy
- Active development
- CPU-optimized
- Free and open source

### Why Docker?
- Consistent environments
- Easy deployment
- Resource isolation
- Scalability
- Version control

### Why Nginx?
- High performance
- Reverse proxy capabilities
- SSL/TLS termination
- Static file serving
- Load balancing

## Future Enhancements

### Planned Features

```
1. Authentication & Authorization
   - JWT tokens
   - API keys
   - User management

2. Batch Processing
   - Multiple file upload
   - Async processing
   - Job queue

3. Advanced Features
   - Table detection
   - Form recognition
   - Handwriting recognition

4. Storage Integration
   - S3/MinIO support
   - Result caching
   - History tracking

5. Monitoring & Analytics
   - Prometheus integration
   - Grafana dashboards
   - Usage analytics
```

## Conclusion

This architecture provides:
- ✅ Production-ready deployment
- ✅ Scalable design
- ✅ Security best practices
- ✅ Easy maintenance
- ✅ Template for other projects
- ✅ Comprehensive documentation
