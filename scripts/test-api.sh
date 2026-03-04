#!/bin/bash
# API Testing Script
# Tests all API endpoints

set -e

API_URL="${API_URL:-http://localhost:8001}"

echo "======================================"
echo "PaddleOCR API Testing"
echo "======================================"
echo "API URL: $API_URL"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test health endpoint
echo "Test 1: Health Check"
if curl -s -f "${API_URL}/health" | jq . ; then
    echo -e "${GREEN}✓ Health check passed${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
    exit 1
fi
echo ""

# Test versioned health endpoint
echo "Test 2: Versioned Health Check"
if curl -s -f "${API_URL}/api/v1/health" | jq . ; then
    echo -e "${GREEN}✓ Versioned health check passed${NC}"
else
    echo -e "${RED}✗ Versioned health check failed${NC}"
fi
echo ""

# Test languages endpoint
echo "Test 3: Supported Languages"
if curl -s -f "${API_URL}/api/v1/languages" | jq . ; then
    echo -e "${GREEN}✓ Languages endpoint passed${NC}"
else
    echo -e "${RED}✗ Languages endpoint failed${NC}"
fi
echo ""

# Test metrics endpoint
echo "Test 4: Metrics"
if curl -s -f "${API_URL}/api/v1/metrics" | jq . ; then
    echo -e "${GREEN}✓ Metrics endpoint passed${NC}"
else
    echo -e "${RED}✗ Metrics endpoint failed${NC}"
fi
echo ""

# Test OCR endpoint with test image
echo "Test 5: OCR Processing"
if [ -f "test-image.jpg" ]; then
    echo "Testing with test-image.jpg..."
    RESPONSE=$(curl -s -X POST "${API_URL}/api/v1/ocr" \
        -F "file=@test-image.jpg" \
        -F "language=en")
    
    if echo "$RESPONSE" | jq -e '.success == true' > /dev/null; then
        echo -e "${GREEN}✓ OCR processing passed${NC}"
        echo "Response:"
        echo "$RESPONSE" | jq .
    else
        echo -e "${RED}✗ OCR processing failed${NC}"
        echo "$RESPONSE" | jq .
    fi
else
    echo "⚠ Skipping OCR test (no test-image.jpg found)"
    echo "Create a test image to test OCR functionality"
fi
echo ""

# Test error handling
echo "Test 6: Error Handling (Invalid File)"
echo "test" > /tmp/test.txt
RESPONSE=$(curl -s -X POST "${API_URL}/api/v1/ocr" \
    -F "file=@/tmp/test.txt" \
    -F "language=en")

if echo "$RESPONSE" | jq -e '.detail' > /dev/null; then
    echo -e "${GREEN}✓ Error handling works correctly${NC}"
    echo "Error message: $(echo $RESPONSE | jq -r '.detail')"
else
    echo -e "${RED}✗ Error handling failed${NC}"
fi
rm /tmp/test.txt
echo ""

echo "======================================"
echo "Testing Complete!"
echo "======================================"
