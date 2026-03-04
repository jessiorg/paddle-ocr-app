# PaddleOCR API Documentation

## Base URL

```
http://your-domain.com/api/v1
```

## Authentication

Currently, no authentication is required. For production use with sensitive data, implement authentication using JWT tokens or API keys.

## Endpoints

### Health Check

#### GET /health

Check API health status.

**Response**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "models_loaded": ["en"]
}
```

### Get Supported Languages

#### GET /api/v1/languages

Retrieve list of supported OCR languages.

**Response**
```json
{
  "languages": [
    {"code": "en", "name": "English"},
    {"code": "ch", "name": "Chinese"},
    {"code": "fr", "name": "French"},
    ...
  ]
}
```

### Perform OCR

#### POST /api/v1/ocr

Extract text from an image using OCR.

**Parameters**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| file | File | Yes | Image file (PNG, JPG, JPEG, PDF) |
| language | String | No | Language code (default: "en") |

**Request Example**

```bash
curl -X POST http://your-domain.com/api/v1/ocr \
  -F "file=@document.jpg" \
  -F "language=en"
```

**Response**

```json
{
  "success": true,
  "text": "Extracted text content...",
  "confidence": 0.95,
  "language": "en",
  "detections": [
    {
      "text": "First line",
      "confidence": 0.98,
      "bbox": [[10, 10], [100, 10], [100, 30], [10, 30]]
    },
    {
      "text": "Second line",
      "confidence": 0.92,
      "bbox": [[10, 35], [120, 35], [120, 55], [10, 55]]
    }
  ],
  "processing_time": 1.234,
  "image_size": {
    "height": 1000,
    "width": 800
  }
}
```

**Error Response**

```json
{
  "detail": "Invalid file type. Allowed: png, jpg, jpeg, pdf"
}
```

### Get Metrics

#### GET /api/v1/metrics

Retrieve API metrics and configuration.

**Response**
```json
{
  "models_loaded": 1,
  "languages_available": ["en"],
  "config": {
    "max_file_size_mb": 10,
    "allowed_extensions": ["png", "jpg", "jpeg", "pdf"],
    "gpu_enabled": false
  }
}
```

## Error Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request - Invalid parameters or file |
| 422 | Unprocessable Entity - Missing required parameters |
| 500 | Internal Server Error - Processing failed |

## Rate Limiting

The API implements rate limiting to prevent abuse:
- **Limit**: 100 requests per minute per IP
- **Headers**: Rate limit information is included in response headers

## Best Practices

1. **Image Quality**: Use high-resolution images (300 DPI+) for best results
2. **File Size**: Keep files under 10MB for optimal performance
3. **Language**: Always specify the correct language for better accuracy
4. **Error Handling**: Implement proper error handling and retry logic
5. **Async Processing**: For large batches, consider implementing async processing

## SDK Examples

### Python

```python
import requests

url = "http://your-domain.com/api/v1/ocr"
files = {"file": open("document.jpg", "rb")}
data = {"language": "en"}

response = requests.post(url, files=files, data=data)
result = response.json()

if result["success"]:
    print(f"Text: {result['text']}")
    print(f"Confidence: {result['confidence']:.2%}")
```

### JavaScript (Node.js)

```javascript
const FormData = require('form-data');
const fs = require('fs');
const axios = require('axios');

const form = new FormData();
form.append('file', fs.createReadStream('document.jpg'));
form.append('language', 'en');

axios.post('http://your-domain.com/api/v1/ocr', form, {
  headers: form.getHeaders()
})
.then(response => {
  if (response.data.success) {
    console.log('Text:', response.data.text);
    console.log('Confidence:', response.data.confidence);
  }
})
.catch(error => console.error(error));
```

### cURL

```bash
# Basic OCR
curl -X POST http://your-domain.com/api/v1/ocr \
  -F "file=@document.jpg" \
  -F "language=en"

# With custom language
curl -X POST http://your-domain.com/api/v1/ocr \
  -F "file=@chinese-doc.jpg" \
  -F "language=ch"

# Save response to file
curl -X POST http://your-domain.com/api/v1/ocr \
  -F "file=@document.jpg" \
  -F "language=en" \
  -o result.json
```

## Interactive Documentation

Interactive API documentation is available at:
- Swagger UI: `http://your-domain.com/api/v1/docs`
- ReDoc: `http://your-domain.com/api/v1/redoc`
