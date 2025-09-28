import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Utility class for detection-related operations
class DetectionUtils {
  /// Format condition name from snake_case to Title Case
  static String formatConditionName(String condition) {
    return condition
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get confidence color based on confidence level
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    if (confidence >= 0.4) return Colors.yellow.shade700;
    return Colors.red;
  }

  /// Calculate bounding box area
  static double calculateBoundingBoxArea(Map<String, dynamic> detection) {
    final Map<String, dynamic>? rectData = detection['rect'];
    final List<dynamic>? box = detection['box'];

    if (rectData != null) {
      final double width = (rectData['width'] as num?)?.toDouble() ?? 0.0;
      final double height = (rectData['height'] as num?)?.toDouble() ?? 0.0;
      return width * height;
    } else if (box != null && box.length >= 4) {
      final double x1 = (box[0] as num).toDouble();
      final double y1 = (box[1] as num).toDouble();
      final double x2 = (box[2] as num).toDouble();
      final double y2 = (box[3] as num).toDouble();
      return (x2 - x1) * (y2 - y1);
    }
    
    return 0.0;
  }

  /// Extract bounding box coordinates from detection data
  static Map<String, double>? extractBoundingBoxCoordinates(Map<String, dynamic> detection) {
    final Map<String, dynamic>? rectData = detection['rect'];
    final List<dynamic>? box = detection['box'];

    if (rectData != null) {
      // Rect format: {left: x, top: y, width: w, height: h}
      final double left = (rectData['left'] as num?)?.toDouble() ?? 0.0;
      final double top = (rectData['top'] as num?)?.toDouble() ?? 0.0;
      final double width = (rectData['width'] as num?)?.toDouble() ?? 0.0;
      final double height = (rectData['height'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'x1': left,
        'y1': top,
        'x2': left + width,
        'y2': top + height,
      };
    } else if (box != null && box.length >= 4) {
      // Box format: [x1, y1, x2, y2]
      return {
        'x1': (box[0] as num).toDouble(),
        'y1': (box[1] as num).toDouble(),
        'x2': (box[2] as num).toDouble(),
        'y2': (box[3] as num).toDouble(),
      };
    }

    return null;
  }
}

/// Custom painter for drawing bounding boxes on images
class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Color boxColor;
  final double strokeWidth;
  final bool showLabels;
  final bool showConfidence;
  final double originalImageWidth;
  final double originalImageHeight;

  BoundingBoxPainter(
    this.detections, {
    this.boxColor = AppColors.primary,
    this.strokeWidth = 3.0,
    this.showLabels = true,
    this.showConfidence = true,
    this.originalImageWidth = 640.0,
    this.originalImageHeight = 640.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      final coordinates = DetectionUtils.extractBoundingBoxCoordinates(detection);
      if (coordinates == null) continue;

      final String label = detection['label'] ?? 'unknown';
      final double confidence = detection['confidence'] ?? 0.0;

      double x1 = coordinates['x1']!;
      double y1 = coordinates['y1']!;
      double x2 = coordinates['x2']!;
      double y2 = coordinates['y2']!;

      print('🎨 Original coordinates: ($x1, $y1) to ($x2, $y2) for $label');
      print('🖼️ Canvas size: ${size.width} x ${size.height}');
      print('🖼️ Original image size: ${originalImageWidth} x ${originalImageHeight}');

      // Calculate scale factors from original image to display canvas
      final double scaleX = size.width / originalImageWidth;
      final double scaleY = size.height / originalImageHeight;
      
      // Scale coordinates directly from original image space to display space
      // This preserves the exact proportions without aspect ratio adjustments
      x1 = x1 * scaleX;
      y1 = y1 * scaleY;
      x2 = x2 * scaleX;
      y2 = y2 * scaleY;
      
      print('🔍 Scale factors - X: ${scaleX.toStringAsFixed(3)}, Y: ${scaleY.toStringAsFixed(3)}');

      // Ensure coordinates are within canvas bounds
      x1 = x1.clamp(0.0, size.width);
      y1 = y1.clamp(0.0, size.height);
      x2 = x2.clamp(0.0, size.width);
      y2 = y2.clamp(0.0, size.height);

      print('🎨 Scaled coordinates: ($x1, $y1) to ($x2, $y2)');

      // Draw bounding box
      final boundingRect = Rect.fromLTRB(x1, y1, x2, y2);
      canvas.drawRect(boundingRect, paint);

      // Draw label if enabled
      if (showLabels) {
        _drawLabel(canvas, textPainter, x1, y1, label, confidence);
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    TextPainter textPainter,
    double x1,
    double y1,
    String label,
    double confidence,
  ) {
    // Create label text
    String labelText = DetectionUtils.formatConditionName(label);
    if (showConfidence) {
      labelText += ' ${(confidence * 100).toStringAsFixed(1)}%';
    }

    textPainter.text = TextSpan(
      text: labelText,
      style: TextStyle(
        color: AppColors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            color: Colors.black.withOpacity(0.7),
          ),
        ],
      ),
    );
    textPainter.layout();

    // Calculate label position
    final double labelY = y1 > textPainter.height + 8 ? y1 - textPainter.height - 4 : y1 + 4;
    
    // Draw label background
    final labelBackground = Paint()..color = boxColor;
    final labelRect = Rect.fromLTWH(
      x1,
      labelY,
      textPainter.width + 8,
      textPainter.height + 4,
    );
    canvas.drawRect(labelRect, labelBackground);

    // Draw label text
    textPainter.paint(canvas, Offset(x1 + 4, labelY + 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! BoundingBoxPainter) return true;
    return detections != oldDelegate.detections ||
           boxColor != oldDelegate.boxColor ||
           strokeWidth != oldDelegate.strokeWidth ||
           showLabels != oldDelegate.showLabels ||
           showConfidence != oldDelegate.showConfidence ||
           originalImageWidth != oldDelegate.originalImageWidth ||
           originalImageHeight != oldDelegate.originalImageHeight;
  }
}

/// Widget that displays an image with bounding boxes overlay
class ImageWithBoundingBoxes extends StatelessWidget {
  final Widget imageWidget;
  final List<Map<String, dynamic>> detections;
  final Color? boxColor;
  final double? strokeWidth;
  final bool showLabels;
  final bool showConfidence;
  final double? originalImageWidth;  // Add original image dimensions
  final double? originalImageHeight;

  const ImageWithBoundingBoxes({
    super.key,
    required this.imageWidget,
    required this.detections,
    this.boxColor,
    this.strokeWidth,
    this.showLabels = true,
    this.showConfidence = true,
    this.originalImageWidth,  // Default to YOLO model size
    this.originalImageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        imageWidget,
        if (detections.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: BoundingBoxPainter(
                detections,
                boxColor: boxColor ?? AppColors.primary,
                strokeWidth: strokeWidth ?? 3.0,
                showLabels: showLabels,
                showConfidence: showConfidence,
                originalImageWidth: originalImageWidth ?? 640.0,
                originalImageHeight: originalImageHeight ?? 640.0,
              ),
            ),
          ),
      ],
    );
  }
}