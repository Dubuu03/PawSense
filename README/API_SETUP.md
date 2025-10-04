# PawSense API Configuration

## Backend API Setup

The app is configured to use the Railway-hosted FastAPI YOLO detection server for pet skin condition analysis.

### Current Server Configuration

The app is configured to use your Railway backend:

```dart
static const String baseUrl = 'https://pawsensebackend-production.up.railway.app';
```

**✅ Backend Server:** `https://pawsensebackend-production.up.railway.app`

### Required API Endpoints

Your FastAPI server must provide these endpoints:

1. **Health Check**
   - `GET /health`
   - Returns: `{"status": "healthy", "message": "API is running"}`

2. **Cat Detection**
   - `POST /detect/cats`
   - Content-Type: `multipart/form-data`
   - Body: `file` (image file)

3. **Dog Detection**
   - `POST /detect/dogs`
   - Content-Type: `multipart/form-data`
   - Body: `file` (image file)

### Expected Response Format

```json
{
  "filename": "pet_image.jpg",
  "model_info": {
    "description": "YOLOv8 pet skin condition detection model",
    "author": "YourName",
    "version": "1.0.0",
    "task": "detect",
    "names": {
      "0": "dermatitis",
      "1": "fleas",
      "2": "fungal_infection",
      "3": "hotspot",
      "4": "mange",
      "5": "pyoderma",
      "6": "ringworm",
      "7": "ticks",
      "8": "unknown_abnormality"
    }
  },
  "detections": [
    {
      "class_id": 0,
      "label": "dermatitis",
      "confidence": 0.85,
      "bbox": [120.5, 45.2, 300.8, 200.1]
    }
  ],
  "total_detections": 1
}
```

### Backend Server Example

You can create a simple FastAPI server with:

```python
from fastapi import FastAPI, File, UploadFile
from ultralytics import YOLO
import cv2
import numpy as np

app = FastAPI()

# Load your models
cat_model = YOLO('path/to/cat_model.pt')
dog_model = YOLO('path/to/dog_model.pt')

@app.get('/health')
def health_check():
    return {"status": "healthy", "message": "API is running"}

@app.post('/detect/cats')
async def detect_cats(file: UploadFile = File(...)):
    # Process image and run detection
    # Return results in expected format
    pass

@app.post('/detect/dogs')  
async def detect_dogs(file: UploadFile = File(...)):
    # Process image and run detection
    # Return results in expected format
    pass
```

### Testing Your API

You can test the server connectivity directly in the app - the UI shows server status indicators.

For manual testing:
```bash
# Health check
curl http://localhost:8000/health

# File upload test
curl -X POST "http://localhost:8000/detect/dogs" \
     -H "accept: application/json" \
     -H "Content-Type: multipart/form-data" \
     -F "file=@test_image.jpg"
```