# Example Images

This directory contains sample images for testing the PaddleOCR application.

## Sample Images

1. **receipt.jpg** - Receipt with printed text
2. **document.png** - Typed document
3. **business-card.jpg** - Business card with contact information
4. **handwritten.png** - Handwritten notes

## Usage

These example images can be used to:
- Test OCR accuracy
- Demonstrate different text types
- Benchmark processing performance
- Validate language support

## Adding Your Own Examples

To add custom example images:

1. Place image files in this directory
2. Update the frontend to reference new examples
3. Ensure images are optimized (< 2MB recommended)
4. Include various text styles and languages

## Testing Different Scenarios

### Receipt Processing
```bash
curl -X POST http://localhost:8001/api/v1/ocr \
  -F "file=@examples/receipt.jpg" \
  -F "language=en"
```

### Multi-language Documents
```bash
# Chinese text
curl -X POST http://localhost:8001/api/v1/ocr \
  -F "file=@examples/chinese-doc.jpg" \
  -F "language=ch"

# French text
curl -X POST http://localhost:8001/api/v1/ocr \
  -F "file=@examples/french-doc.jpg" \
  -F "language=fr"
```

## Best Practices

- Use high-resolution images (300 DPI+)
- Ensure good lighting and contrast
- Keep text horizontal when possible
- Avoid blurry or distorted images
- Use appropriate language settings
