import 'dart:typed_data';
import 'dart:ui' as ui;

/// Image preprocessing utilities for YOLO models
/// Ensures consistent preprocessing between Ultralytics and Flutter Vision
class ImagePreprocessor {
  static const int YOLO_INPUT_SIZE = 640;
  static const double PADDING_COLOR_VALUE = 0.5; // Normalized gray (128/255)

  /// Apply letterboxing to maintain aspect ratio and resize to target size
  static Future<Uint8List> letterboxResize(
    Uint8List imageBytes,
    int targetSize,
  ) async {
    try {
      // Decode original image
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      
      // Calculate scale factor (fit the larger dimension)
      final double scaleX = targetSize / originalWidth;
      final double scaleY = targetSize / originalHeight;
      final double scale = scaleX < scaleY ? scaleX : scaleY;
      
      // Calculate new dimensions after scaling
      final int newWidth = (originalWidth * scale).round();
      final int newHeight = (originalHeight * scale).round();
      
      // Calculate padding offsets to center the image
      final double offsetX = (targetSize - newWidth) / 2;
      final double offsetY = (targetSize - newHeight) / 2;
      
      print('🔧 Letterbox preprocessing:');
      print('   Original: ${originalWidth}x${originalHeight}');
      print('   Target: ${targetSize}x${targetSize}');
      print('   Scale: ${scale.toStringAsFixed(3)}');
      print('   Scaled: ${newWidth}x${newHeight}');
      print('   Offsets: (${offsetX.toStringAsFixed(1)}, ${offsetY.toStringAsFixed(1)})');
      
      // Create canvas and draw
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      // Fill background with gray padding (standard YOLO preprocessing)
      final ui.Paint backgroundPaint = ui.Paint()
        ..color = const ui.Color(0xFF808080); // RGB(128, 128, 128)
      
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
        backgroundPaint,
      );
      
      // Draw scaled image in center
      canvas.drawImageRect(
        originalImage,
        ui.Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
        ui.Rect.fromLTWH(offsetX, offsetY, newWidth.toDouble(), newHeight.toDouble()),
        ui.Paint(),
      );
      
      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image processedImage = await picture.toImage(targetSize, targetSize);
      
      // Convert to PNG bytes
      final ByteData? byteData = await processedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) {
        throw Exception('Failed to convert processed image to bytes');
      }
      
      final Uint8List result = byteData.buffer.asUint8List();
      print('✅ Letterbox preprocessing complete: ${result.length} bytes');
      
      return result;
      
    } catch (e) {
      print('❌ Error in letterbox preprocessing: $e');
      rethrow;
    }
  }

  /// Get scaling factors for mapping detection coordinates back to original image
  static Map<String, double> getScalingFactors(
    int originalWidth,
    int originalHeight,
    int modelInputSize,
  ) {
    // Calculate the same scale factor used in letterboxing
    final double scaleX = modelInputSize / originalWidth;
    final double scaleY = modelInputSize / originalHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Calculate dimensions after scaling
    final int scaledWidth = (originalWidth * scale).round();
    final int scaledHeight = (originalHeight * scale).round();
    
    // Calculate padding offsets
    final double offsetX = (modelInputSize - scaledWidth) / 2;
    final double offsetY = (modelInputSize - scaledHeight) / 2;
    
    return {
      'scale': scale,
      'scaleX': 1.0 / scale,  // Inverse scale for coordinate mapping
      'scaleY': 1.0 / scale,  // Inverse scale for coordinate mapping
      'offsetX': offsetX,
      'offsetY': offsetY,
      'scaledWidth': scaledWidth.toDouble(),
      'scaledHeight': scaledHeight.toDouble(),
    };
  }

  /// Map detection coordinates from model space back to original image space
  static Map<String, double> mapCoordinatesBackToOriginal(
    Map<String, dynamic> detection,
    Map<String, double> scalingFactors,
  ) {
    final dynamic boxData = detection['box'] ?? detection['rect'];
    if (boxData == null) {
      throw Exception('No bounding box data found in detection');
    }
    
    final List<dynamic> box = boxData is List ? boxData : [];
    if (box.length < 4) {
      throw Exception('Invalid bounding box format: expected at least 4 coordinates');
    }
    
    // Extract coordinates (in model input space)
    final double x1Model = box[0].toDouble();
    final double y1Model = box[1].toDouble();
    final double x2Model = box.length > 2 ? box[2].toDouble() : x1Model + (detection['rect']?['width'] ?? 0.0);
    final double y2Model = box.length > 3 ? box[3].toDouble() : y1Model + (detection['rect']?['height'] ?? 0.0);
    
    // Account for letterbox padding offsets
    final double x1Scaled = x1Model - scalingFactors['offsetX']!;
    final double y1Scaled = y1Model - scalingFactors['offsetY']!;
    final double x2Scaled = x2Model - scalingFactors['offsetX']!;
    final double y2Scaled = y2Model - scalingFactors['offsetY']!;
    
    // Scale back to original image dimensions
    final double x1Original = x1Scaled * scalingFactors['scaleX']!;
    final double y1Original = y1Scaled * scalingFactors['scaleY']!;
    final double x2Original = x2Scaled * scalingFactors['scaleX']!;
    final double y2Original = y2Scaled * scalingFactors['scaleY']!;
    
    return {
      'x1': x1Original,
      'y1': y1Original,
      'x2': x2Original,
      'y2': y2Original,
      'width': x2Original - x1Original,
      'height': y2Original - y1Original,
    };
  }
}