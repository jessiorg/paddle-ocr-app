"""
PaddleOCR API - FastAPI Backend
Provides OCR processing endpoints with error handling and logging
"""

import os
import time
import logging
import tempfile
from typing import Optional, List, Dict, Any
from pathlib import Path

from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import uvicorn
from paddleocr import PaddleOCR
import cv2
import numpy as np

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/var/log/paddle-ocr.log')
    ]
)
logger = logging.getLogger(__name__)

# Configuration
class Config:
    APP_NAME = "PaddleOCR API"
    APP_VERSION = "1.0.0"
    API_PREFIX = "/api/v1"
    
    # File upload limits
    MAX_FILE_SIZE = int(os.getenv('MAX_FILE_SIZE', 10 * 1024 * 1024))  # 10MB default
    ALLOWED_EXTENSIONS = os.getenv('ALLOWED_EXTENSIONS', 'png,jpg,jpeg,pdf').split(',')
    
    # OCR settings
    OCR_USE_GPU = os.getenv('OCR_USE_GPU', 'false').lower() == 'true'
    # OCR_ENABLE_MKLDNN = os.getenv('OCR_ENABLE_MKLDNN', 'false').lower() == 'true'  # DISABLED
    # Removed: enable_mkldnn causes issues with paddlepaddle 3.x
    OCR_USE_ANGLE_CLS = os.getenv('OCR_USE_ANGLE_CLS', 'true').lower() == 'true'
    OCR_DET_LIMIT_SIDE_LEN = int(os.getenv('OCR_DET_LIMIT_SIDE_LEN', 960))
    OCR_REC_BATCH_NUM = int(os.getenv('OCR_REC_BATCH_NUM', 6))
    
    # CORS settings
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')

config = Config()

# Initialize FastAPI app
app = FastAPI(
    title=config.APP_NAME,
    version=config.APP_VERSION,
    description="Production-ready PaddleOCR API for text extraction from images",
    docs_url=f"{config.API_PREFIX}/docs",
    redoc_url=f"{config.API_PREFIX}/redoc",
    openapi_url=f"{config.API_PREFIX}/openapi.json"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    logger.info(
        f"{request.method} {request.url.path} - "
        f"Status: {response.status_code} - "
        f"Time: {process_time:.3f}s"
    )
    return response

# Initialize OCR models cache
ocr_models: Dict[str, PaddleOCR] = {}

def get_ocr_model(language: str = 'en') -> PaddleOCR:
    """Get or create OCR model for specified language"""
    if language not in ocr_models:
        logger.info(f"Initializing OCR model for language: {language}")
        try:
            ocr_models[language] = PaddleOCR(
                use_angle_cls=config.OCR_USE_ANGLE_CLS,
                lang=language,
                use_gpu=config.OCR_USE_GPU,
                
                det_limit_side_len=config.OCR_DET_LIMIT_SIDE_LEN,
                rec_batch_num=config.OCR_REC_BATCH_NUM,
                
            )
            logger.info(f"OCR model initialized successfully for {language}")
        except Exception as e:
            logger.error(f"Failed to initialize OCR model: {str(e)}")
            raise HTTPException(status_code=500, detail="OCR initialization failed")
    
    return ocr_models[language]

# Response models
class OCRDetection(BaseModel):
    text: str = Field(..., description="Detected text")
    confidence: float = Field(..., description="Confidence score (0-1)")
    bbox: Optional[List[List[int]]] = Field(None, description="Bounding box coordinates")

class OCRResponse(BaseModel):
    success: bool = Field(..., description="Whether OCR was successful")
    text: str = Field(..., description="Extracted text")
    confidence: float = Field(..., description="Average confidence score")
    language: str = Field(..., description="Language used for OCR")
    detections: List[OCRDetection] = Field(..., description="Individual text detections")
    processing_time: float = Field(..., description="Processing time in seconds")
    image_size: Dict[str, int] = Field(..., description="Image dimensions")

class HealthResponse(BaseModel):
    status: str
    version: str
    models_loaded: List[str]

class ErrorResponse(BaseModel):
    detail: str

# Utility functions
def validate_file(file: UploadFile) -> None:
    """Validate uploaded file"""
    # Check file extension
    file_ext = Path(file.filename).suffix.lower().replace('.', '')
    if file_ext not in config.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(config.ALLOWED_EXTENSIONS)}"
        )
    
    # Check file size would be done by reading, but we'll set a limit in the endpoint

def process_image_file(file_path: str) -> np.ndarray:
    """Load and process image file"""
    try:
        # Read image
        img = cv2.imread(file_path)
        if img is None:
            raise ValueError("Failed to read image file")
        return img
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise HTTPException(status_code=400, detail="Invalid image file")

def calculate_average_confidence(result: List) -> float:
    """Calculate average confidence from OCR results"""
    if not result or not result[0]:
        return 0.0
    
    confidences = [line[1][1] for line in result[0] if len(line) > 1 and len(line[1]) > 1]
    return sum(confidences) / len(confidences) if confidences else 0.0

def format_ocr_result(result: List, language: str, processing_time: float, img_shape: tuple) -> OCRResponse:
    """Format OCR results into response model"""
    detections = []
    full_text = []
    
    if result and result[0]:
        for line in result[0]:
            if len(line) >= 2:
                bbox = line[0]
                text_info = line[1]
                text = text_info[0] if len(text_info) > 0 else ""
                confidence = text_info[1] if len(text_info) > 1 else 0.0
                
                detections.append(OCRDetection(
                    text=text,
                    confidence=confidence,
                    bbox=[[int(coord) for coord in point] for point in bbox]
                ))
                full_text.append(text)
    
    avg_confidence = calculate_average_confidence(result)
    
    return OCRResponse(
        success=True,
        text="\n".join(full_text) if full_text else "",
        confidence=avg_confidence,
        language=language,
        detections=detections,
        processing_time=processing_time,
        image_size={
            "height": img_shape[0],
            "width": img_shape[1]
        }
    )

# API Endpoints
@app.get("/health", response_model=HealthResponse, tags=["System"])
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        version=config.APP_VERSION,
        models_loaded=list(ocr_models.keys())
    )

@app.get(f"{config.API_PREFIX}/health", response_model=HealthResponse, tags=["System"])
async def health_check_v1():
    """Health check endpoint (versioned)"""
    return await health_check()

@app.get(f"{config.API_PREFIX}/languages", tags=["OCR"])
async def get_supported_languages():
    """Get list of supported languages"""
    languages = [
        {"code": "en", "name": "English"},
        {"code": "ch", "name": "Chinese"},
        {"code": "fr", "name": "French"},
        {"code": "german", "name": "German"},
        {"code": "korean", "name": "Korean"},
        {"code": "japan", "name": "Japanese"},
        {"code": "arabic", "name": "Arabic"},
        {"code": "spanish", "name": "Spanish"},
        {"code": "portuguese", "name": "Portuguese"},
        {"code": "russian", "name": "Russian"},
    ]
    return {"languages": languages}

@app.post(
    f"{config.API_PREFIX}/ocr",
    response_model=OCRResponse,
    responses={
        400: {"model": ErrorResponse, "description": "Bad Request"},
        500: {"model": ErrorResponse, "description": "Internal Server Error"}
    },
    tags=["OCR"]
)
async def perform_ocr(
    file: UploadFile = File(..., description="Image file (PNG, JPG, JPEG, PDF)"),
    language: str = Form("en", description="Language code for OCR")
):
    """
    Perform OCR on uploaded image
    
    - **file**: Image file to process
    - **language**: Language code (en, ch, fr, german, korean, japan, arabic, spanish, portuguese, russian)
    
    Returns extracted text with confidence scores and detailed detection information.
    """
    start_time = time.time()
    temp_file_path = None
    
    try:
        # Validate file
        validate_file(file)
        
        # Read file content
        content = await file.read()
        file_size = len(content)
        
        # Check file size
        if file_size > config.MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"File size exceeds maximum allowed size of {config.MAX_FILE_SIZE / (1024*1024):.1f}MB"
            )
        
        logger.info(f"Processing file: {file.filename} ({file_size} bytes) - Language: {language}")
        
        # Save to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=Path(file.filename).suffix) as temp_file:
            temp_file.write(content)
            temp_file_path = temp_file.name
        
        # Process image
        img = process_image_file(temp_file_path)
        
        # Get OCR model
        ocr = get_ocr_model(language)
        
        # Perform OCR
        logger.info("Starting OCR processing...")
        ocr_start = time.time()
        result = ocr.ocr(temp_file_path, cls=config.OCR_USE_ANGLE_CLS)
        ocr_time = time.time() - ocr_start
        logger.info(f"OCR processing completed in {ocr_time:.3f}s")
        
        # Format response
        processing_time = time.time() - start_time
        response = format_ocr_result(result, language, processing_time, img.shape)
        
        logger.info(f"Total request processed in {processing_time:.3f}s - Confidence: {response.confidence:.3f}")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"OCR processing error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="An error occurred during OCR processing"
        )
    finally:
        # Clean up temporary file
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.unlink(temp_file_path)
                logger.debug(f"Temporary file deleted: {temp_file_path}")
            except Exception as e:
                logger.warning(f"Failed to delete temporary file: {str(e)}")

@app.get(f"{config.API_PREFIX}/metrics", tags=["System"])
async def get_metrics():
    """Get API metrics"""
    return {
        "models_loaded": len(ocr_models),
        "languages_available": list(ocr_models.keys()),
        "config": {
            "max_file_size_mb": config.MAX_FILE_SIZE / (1024 * 1024),
            "allowed_extensions": config.ALLOWED_EXTENSIONS,
            "gpu_enabled": config.OCR_USE_GPU
        }
    }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    logger.warning(f"HTTP {exc.status_code}: {exc.detail} - Path: {request.url.path}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

# Startup event
@app.on_event("startup")
async def startup_event():
    logger.info(f"Starting {config.APP_NAME} v{config.APP_VERSION}")
    logger.info(f"GPU Enabled: {config.OCR_USE_GPU}")
    logger.info(f"Max file size: {config.MAX_FILE_SIZE / (1024*1024):.1f}MB")
    
    # Pre-load English model
    try:
        get_ocr_model('en')
        logger.info("Default English model pre-loaded")
    except Exception as e:
        logger.error(f"Failed to pre-load default model: {str(e)}")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    logger.info(f"Shutting down {config.APP_NAME}")
    ocr_models.clear()

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=os.getenv('API_HOST', '0.0.0.0'),
        port=int(os.getenv('API_PORT', 8000)),
        workers=int(os.getenv('API_WORKERS', 1)),
        log_level=os.getenv('LOG_LEVEL', 'info').lower(),
        reload=os.getenv('RELOAD', 'false').lower() == 'true'
    )
