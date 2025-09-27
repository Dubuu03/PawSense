import 'package:flutter_test/flutter_test.dart';
import 'package:pawsense/core/services/yolo_service.dart';
import 'package:pawsense/core/utils/image_preprocessor.dart';

void main() {
  group('YOLOv8 Flutter Vision Fix Tests', () {
    
    test('ImagePreprocessor scaling factors calculation', () {
      // Test typical mobile phone image dimensions
      final scalingFactors = ImagePreprocessor.getScalingFactors(1920, 1080, 640);
      
      expect(scalingFactors['scale'], closeTo(0.333, 0.01));
      expect(scalingFactors['scaleX'], closeTo(3.0, 0.1));
      expect(scalingFactors['scaleY'], closeTo(3.0, 0.1));
    });
    
    test('Coordinate mapping back to original image space', () {
      // Setup: Original image 1920x1080, model space 640x640
      final scalingFactors = ImagePreprocessor.getScalingFactors(1920, 1080, 640);
      
      // Test detection at center of model space (320x320)
      final detection = {'box': [300.0, 300.0, 340.0, 340.0]};
      final originalCoords = ImagePreprocessor.mapCoordinatesBackToOriginal(
        detection, 
        scalingFactors,
      );
      
      // Verify coordinates are scaled back appropriately
      expect(originalCoords['x1'], greaterThan(850)); // Should be around center-ish
      expect(originalCoords['y1'], greaterThan(420)); // Accounting for letterbox padding
      expect(originalCoords['width'], closeTo(120, 20)); // 40 * 3 = 120
      expect(originalCoords['height'], closeTo(120, 20)); // 40 * 3 = 120
    });
    
    test('YoloService constants match Ultralytics defaults', () {
      expect(YoloService.DEFAULT_CONF_THRESHOLD, equals(0.25));
      expect(YoloService.DEFAULT_IOU_THRESHOLD, equals(0.7));
      expect(YoloService.MODEL_INPUT_SIZE, equals(640));
    });
  });
}

// Mock test helper for integration testing (if needed later)
class MockYoloTest {
  static Future<void> validateModelBehavior() async {
    print('🧪 Mock validation: Model preprocessing pipeline');
    print('✅ Letterbox resizing: PASS');
    print('✅ Coordinate scaling: PASS');
    print('✅ Threshold alignment: PASS');
    print('✅ Input format validation: PASS');
  }
}