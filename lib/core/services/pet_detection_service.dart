import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

/// Service for communicating with YOLO detection backend API
class PetDetectionService {
  static final PetDetectionService _instance = PetDetectionService._internal();
  factory PetDetectionService() => _instance;
  PetDetectionService._internal();

  // API Configuration - Railway backend server
  static const String baseUrl = 'https://pawsensebackend-production.up.railway.app';
  static const int timeoutSeconds = 30;
  
  // Supported pet types for API endpoints
  static const String CATS = 'cats';
  static const String DOGS = 'dogs';

  /// Health check to verify backend connectivity
  Future<HealthStatus> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HealthStatus.fromMap(data);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Health check failed: $e');
      return HealthStatus(status: 'error', message: e.toString());
    }
  }

  /// Preprocess image to 640x640 for consistent YOLO model input
  Future<File> _preprocessImageTo640x640(File originalImage) async {
    try {
      print('🔄 Preprocessing image to 640x640...');
      
      // Read original image
      final Uint8List originalBytes = await originalImage.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(originalBytes);
      
      if (decodedImage == null) {
        throw Exception('Failed to decode image for preprocessing');
      }
      
      print('📏 Original image dimensions: ${decodedImage.width}x${decodedImage.height}');
      
      // Resize to exactly 640x640 (YOLO model input size)
      // This ensures consistent coordinate mapping
      final img.Image resizedImage = img.copyResize(
        decodedImage,
        width: 640,
        height: 640,
        interpolation: img.Interpolation.linear,
      );
      
      print('✅ Resized image to: 640x640');
      
      // Encode back to JPEG with high quality
      final List<int> processedBytes = img.encodeJpg(resizedImage, quality: 95);
      
      // Create temporary file for processed image
      final Directory tempDir = Directory.systemTemp;
      final String tempPath = '${tempDir.path}/pawsense_processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File processedFile = File(tempPath);
      
      await processedFile.writeAsBytes(processedBytes);
      print('💾 Processed image saved: $tempPath');
      print('📊 Processed image size: ${_formatFileSize(processedBytes.length)}');
      
      return processedFile;
    } catch (e) {
      print('❌ Image preprocessing failed: $e');
      throw Exception('Image preprocessing failed: $e');
    }
  }

  /// Detect skin conditions for pets using the backend API
  Future<DetectionResult> detectConditions({
    required File imageFile,
    required String petType, // 'cats' or 'dogs'
  }) async {
    if (petType != CATS && petType != DOGS) {
      throw ArgumentError('Pet type must be "cats" or "dogs"');
    }

    try {
      print('🔍 Sending detection request for $petType...');
      print('📁 Original image file: ${imageFile.path}');
      
      // Validate file exists and is readable
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      
      final int originalFileSize = await imageFile.length();
      print('📊 Original image size: ${_formatFileSize(originalFileSize)}');
      
      // Preprocess image to 640x640 for consistent coordinate mapping
      final File processedImage = await _preprocessImageTo640x640(imageFile);
      
      final int processedFileSize = await processedImage.length();
      print('📊 Processed image size: ${_formatFileSize(processedFileSize)}');
      
      // Check file size (exact limit: 10,485,760 bytes)
      const maxSizeBytes = AppConfig.maxImageSizeBytes;
      if (processedFileSize > maxSizeBytes) {
        throw Exception('Processed image file too large. Maximum size: ${_formatFileSize(maxSizeBytes)}');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect/$petType'),
      );
      
      // Use processed image (640x640) for consistent coordinates
      final multipartFile = await http.MultipartFile.fromPath(
        'file', // Field name must be exactly "file"  
        processedImage.path,
        contentType: MediaType.parse('image/jpeg'),
      );
      request.files.add(multipartFile);
      
      // Add headers - do NOT set Content-Type manually, let http package handle it
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'PawSense-Flutter/1.0',
      });
      
      print('🚀 Sending request to: $baseUrl/detect/$petType');
      print('📄 File type: ${multipartFile.contentType}');
      print('📋 Request headers: ${request.headers}');
      print('📂 File field name: ${multipartFile.field}');
      print('📝 File filename: ${multipartFile.filename}');
      print('📏 Processed file size being sent: ${await processedImage.length()} bytes (640x640)');
      print('✅ Image preprocessed to consistent 640x640 dimensions for accurate bounding boxes');
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: timeoutSeconds),
      );
      
      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ Detection successful: ${responseData['total_detections']} detections found');
        
        // Clean up temporary processed image file
        try {
          if (await processedImage.exists()) {
            await processedImage.delete();
            print('🗑️ Cleaned up temporary processed image');
          }
        } catch (e) {
          print('⚠️ Failed to clean up temporary file: $e');
        }
        
        return DetectionResult.fromMap(responseData);
      } else {
        final errorMessage = _parseErrorMessage(response);
        
        // Clean up temporary processed image file on error too
        try {
          if (await processedImage.exists()) {
            await processedImage.delete();
            print('🗑️ Cleaned up temporary processed image');
          }
        } catch (e) {
          print('⚠️ Failed to clean up temporary file: $e');
        }
        
        throw Exception('Detection failed (${response.statusCode}): $errorMessage');
      }
      
    } on TimeoutException {
      // Clean up temporary file on timeout
      try {
        final File processedImage = File('${Directory.systemTemp.path}/pawsense_processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
        if (await processedImage.exists()) {
          await processedImage.delete();
        }
      } catch (_) {}
      throw Exception('Request timed out after $timeoutSeconds seconds. Please check your internet connection.');
    } on SocketException {
      throw Exception('Unable to connect to Railway backend server. Server may be sleeping or unavailable.');
    } on HttpException {
      throw Exception('HTTP error occurred. Please check your network connection.');
    } on FormatException catch (e) {
      throw Exception('Invalid response format from server: $e');
    } catch (e) {
      print('❌ Detection error: $e');
      rethrow;
    }
  }
  
  /// Parse error message from response
  String _parseErrorMessage(http.Response response) {
    try {
      print('📥 Raw response body: ${response.body}');
      final Map<String, dynamic> errorData = json.decode(response.body);
      return errorData['detail'] ?? errorData['message'] ?? 'Unknown error';
    } catch (e) {
      print('📥 Failed to parse error JSON: $e');
      return response.body.isNotEmpty ? response.body : 'Unknown error';
    }
  }
  
  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Health status response model
class HealthStatus {
  final String status;
  final String message;
  final List<String> modelsLoaded;
  final List<String> availableModels;
  final String? version;
  final DateTime? timestamp;

  HealthStatus({
    required this.status,
    this.message = '',
    this.modelsLoaded = const [],
    this.availableModels = const [],
    this.version,
    this.timestamp,
  });

  factory HealthStatus.fromMap(Map<String, dynamic> map) {
    return HealthStatus(
      status: map['status'] ?? 'unknown',
      message: map['message'] ?? '',
      modelsLoaded: (map['models_loaded'] as List<dynamic>? ?? [])
          .map((model) => model.toString())
          .toList(),
      availableModels: (map['available_models'] as List<dynamic>? ?? [])
          .map((model) => model.toString())
          .toList(),
      version: map['version'],
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp']) 
          : null,
    );
  }

  bool get isHealthy => status == 'healthy' || status == 'ok';
}

/// Detection result model matching the FastAPI backend response
class DetectionResult {
  final String filename;
  final ModelInfo modelInfo;
  final List<Detection> detections;
  final int totalDetections;

  DetectionResult({
    required this.filename,
    required this.modelInfo,
    required this.detections,
    required this.totalDetections,
  });

  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      filename: map['filename'] ?? '',
      modelInfo: ModelInfo.fromMap(map['model_info'] ?? {}),
      detections: (map['detections'] as List<dynamic>? ?? [])
          .map((detection) => Detection.fromMap(detection))
          .toList(),
      totalDetections: map['total_detections'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'filename': filename,
      'model_info': modelInfo.toMap(),
      'detections': detections.map((detection) => detection.toMap()).toList(),
      'total_detections': totalDetections,
    };
  }
}

/// Model information from the backend
class ModelInfo {
  final String description;
  final String author;
  final String version;
  final String task;
  final Map<String, String>? names;

  ModelInfo({
    required this.description,
    required this.author,
    required this.version,
    required this.task,
    this.names,
  });

  factory ModelInfo.fromMap(Map<String, dynamic> map) {
    Map<String, String>? namesMap;
    final names = map['names'];
    if (names != null && names is Map) {
      namesMap = <String, String>{};
      names.forEach((key, value) {
        namesMap![key.toString()] = value.toString();
      });
    }

    return ModelInfo(
      description: map['description'] ?? 'Pet skin condition detection model',
      author: map['author'] ?? 'PawSense Team',
      version: map['version'] ?? '1.0.0',
      task: map['task'] ?? 'detection',
      names: namesMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'author': author,
      'version': version,
      'task': task,
      if (names != null) 'names': names,
    };
  }
}

/// Individual detection result
class Detection {
  final int classId;
  final String label;
  final double confidence;
  final List<double> bbox; // [x1, y1, x2, y2]

  Detection({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.bbox,
  });

  factory Detection.fromMap(Map<String, dynamic> map) {
    final bboxList = (map['bbox'] as List<dynamic>? ?? [])
        .map((coord) => coord.toDouble())
        .toList()
        .cast<double>();
    
    return Detection(
      classId: map['class_id'] ?? 0,
      label: map['label'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      bbox: bboxList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'class_id': classId,
      'label': label,
      'confidence': confidence,
      'bbox': bbox,
    };
  }

  /// Convert to the format expected by the existing codebase
  Map<String, dynamic> toYoloFormat() {
    return {
      'label': label,
      'confidence': confidence,
      'classId': classId,
      'box': bbox, // [x1, y1, x2, y2]
      'rect': {
        'left': bbox[0],
        'top': bbox[1],
        'width': bbox[2] - bbox[0],
        'height': bbox[3] - bbox[1],
      },
    };
  }
}

/// Pet assessment data model
class PetAssessment {
  final String petName;
  final String petType;
  final int petAge;
  final String breed;
  final String gender;
  final String ownerName;
  final DateTime assessmentDate;
  final List<File> images;
  final DetectionResult? result;
  final DateTime createdAt;
  
  // Optional fields
  final String? petWeight;
  final String? medicalHistory;
  final String? currentSymptoms;

  PetAssessment({
    required this.petName,
    required this.petType,
    required this.petAge,
    required this.breed,
    required this.gender,
    required this.ownerName,
    required this.assessmentDate,
    required this.images,
    this.result,
    required this.createdAt,
    this.petWeight,
    this.medicalHistory,
    this.currentSymptoms,
  });

  Map<String, dynamic> toMap() {
    return {
      'petName': petName,
      'petType': petType,
      'petAge': petAge,
      'breed': breed,
      'gender': gender,
      'ownerName': ownerName,
      'assessmentDate': assessmentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'petWeight': petWeight,
      'medicalHistory': medicalHistory,
      'currentSymptoms': currentSymptoms,
      'result': result?.toMap(),
    };
  }
}

/// Configuration class for API settings
class AppConfig {
  static const String apiBaseUrl = 'https://pawsensebackend-production.up.railway.app';
  static const int maxImagesPerAssessment = 5;
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB (10,485,760 bytes)
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'bmp', 'tiff'];
  static const List<String> supportedPetTypes = ['cats', 'dogs'];
  
  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String detectCatsEndpoint = '/detect/cats';
  static const String detectDogsEndpoint = '/detect/dogs';
}