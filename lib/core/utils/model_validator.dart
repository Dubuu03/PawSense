import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pawsense/core/services/yolo_service.dart';

/// Utility class for validating YOLO model performance and debugging
class ModelValidator {
  static final YoloService _yoloService = YoloService();
  
  /// Test the model with a sample image and log detailed results
  static Future<void> validateModel() async {
    try {
      print('🧪 Starting model validation...');
      
      // Initialize YOLO service
      await _yoloService.initialize();
      print('✅ Model initialized successfully');
      
      // Load a test image (you should replace this with an actual test image)
      final ByteData imageData = await rootBundle.load('assets/img/test_dog_image.jpg');
      final Uint8List imageBytes = imageData.buffer.asUint8List();
      
      print('📸 Loaded test image: ${imageBytes.length} bytes');
      
      // Run detection
      final List<Map<String, dynamic>> detections = await _yoloService.detectOnImage(
        imageBytes,
        1080, // Sample original height
        1920, // Sample original width
      );
      
      print('🎯 Validation Results:');
      print('   Total detections: ${detections.length}');
      
      if (detections.isNotEmpty) {
        for (int i = 0; i < detections.length; i++) {
          final detection = detections[i];
          print('   Detection ${i + 1}:');
          print('     Class: ${detection['label']} (ID: ${detection['classId']})');
          print('     Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%');
          print('     Bounding Box: ${detection['rect']}');
        }
        print('✅ Model is working correctly!');
      } else {
        print('⚠️ No detections found. This could indicate:');
        print('   - Test image has no detectable conditions');
        print('   - Model thresholds are too high');
        print('   - Preprocessing pipeline issue');
      }
      
    } catch (e) {
      print('❌ Model validation failed: $e');
      rethrow;
    }
  }
  
  /// Compare different threshold settings
  static Future<void> testThresholds() async {
    print('🧪 Testing different threshold configurations...');
    
    final List<Map<String, double>> thresholdConfigs = [
      {'conf': 0.1, 'iou': 0.3},   // Very permissive
      {'conf': 0.15, 'iou': 0.5},  // Moderate
      {'conf': 0.25, 'iou': 0.7},  // Ultralytics default
      {'conf': 0.5, 'iou': 0.7},   // Conservative
    ];
    
    for (final config in thresholdConfigs) {
      print('\n🔧 Testing: conf=${config['conf']}, iou=${config['iou']}');
      // Note: This would require modifying YoloService to accept threshold parameters
      // For now, this is a placeholder for future enhancement
    }
  }
  
  /// Log model information for debugging
  static void logModelInfo() {
    print('📋 Model Information:');
    print('   Model file: assets/models/dog/best_float32.tflite');
    print('   Input size: 640x640x3');
    print('   Format: RGB, normalized [0.0-1.0]');
    print('   Classes: 9 dog skin conditions');
    print('   Architecture: YOLOv8n');
    print('   Framework: Ultralytics -> TensorFlow Lite');
  }
}

/// Extension methods for detection analysis
extension DetectionAnalysis on List<Map<String, dynamic>> {
  /// Get detection statistics
  Map<String, dynamic> getStats() {
    if (isEmpty) return {'total': 0};
    
    // Count detections per class
    final Map<String, int> classCounts = {};
    double totalConfidence = 0.0;
    double maxConfidence = 0.0;
    
    for (final detection in this) {
      final String label = detection['label'] ?? 'unknown';
      final double confidence = detection['confidence']?.toDouble() ?? 0.0;
      
      classCounts[label] = (classCounts[label] ?? 0) + 1;
      totalConfidence += confidence;
      
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
      }
    }
    
    return {
      'total': length,
      'classes': classCounts,
      'avgConfidence': totalConfidence / length,
      'maxConfidence': maxConfidence,
    };
  }
  
  /// Filter detections by confidence threshold
  List<Map<String, dynamic>> filterByConfidence(double threshold) {
    return where((detection) => 
      (detection['confidence']?.toDouble() ?? 0.0) >= threshold
    ).toList();
  }
  
  /// Get the highest confidence detection for each class
  List<Map<String, dynamic>> getBestDetectionPerClass() {
    final Map<String, Map<String, dynamic>> bestPerClass = {};
    
    for (final detection in this) {
      final String label = detection['label'] ?? 'unknown';
      final double confidence = detection['confidence']?.toDouble() ?? 0.0;
      
      if (!bestPerClass.containsKey(label) || 
          (bestPerClass[label]!['confidence']?.toDouble() ?? 0.0) < confidence) {
        bestPerClass[label] = detection;
      }
    }
    
    return bestPerClass.values.toList();
  }
}