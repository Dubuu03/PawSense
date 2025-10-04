# MIME Type Fix for 400 Bad Request Error

## 🚨 Issue Identified
The Flutter app was receiving **400 Bad Request** errors from the Railway backend because:
- Image files were being sent with incorrect MIME type: `application/octet-stream`
- FastAPI backend expects proper image MIME types: `image/jpeg`, `image/png`, etc.

## 🔧 Root Cause
The `http.MultipartFile.fromPath()` method was not correctly detecting the content type from file extensions, defaulting to `application/octet-stream`.

## ✅ Solution Applied

### 1. **Added http_parser Dependency**
```yaml
dependencies:
  http_parser: ^4.0.2
```

### 2. **Enhanced MIME Type Detection**
```dart
// Determine correct MIME type based on file extension
final String fileExtension = imageFile.path.split('.').last.toLowerCase();
String mimeType = 'image/jpeg'; // default
switch (fileExtension) {
  case 'jpg':
  case 'jpeg':
    mimeType = 'image/jpeg';
    break;
  case 'png':
    mimeType = 'image/png';
    break;
  case 'bmp':
    mimeType = 'image/bmp';
    break;
  case 'tiff':
  case 'tif':
    mimeType = 'image/tiff';
    break;
  default:
    mimeType = 'image/jpeg';
}

// Add file to request with explicit MIME type
final multipartFile = await http.MultipartFile.fromPath(
  'file',
  imageFile.path,
  contentType: MediaType.parse(mimeType), // 🔥 Fix applied here
);
```

### 3. **Import Added**
```dart
import 'package:http_parser/http_parser.dart';
```

## 🎯 Expected Result
Now the Flutter app will send images with proper MIME types:
- ✅ `scaled_43.jpg` → `image/jpeg`
- ✅ `photo.png` → `image/png`
- ✅ `image.bmp` → `image/bmp`

This should resolve the **400 Bad Request** errors from your Railway FastAPI backend.

## 🧪 Testing Required
1. **Run the Flutter app**
2. **Take/select a photo**
3. **Check logs for**: `📄 File type: image/jpeg` (instead of `application/octet-stream`)
4. **Verify**: Detection request returns **200 OK** instead of **400 Bad Request**

---

**Status:** ✅ **FIX APPLIED** - Ready for testing with Railway backend