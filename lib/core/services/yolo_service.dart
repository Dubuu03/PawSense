import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:pawsense/core/utils/image_preprocessor.dart';

class YoloService {
  static final YoloService _instance = YoloService._internal();
  factory YoloService() => _instance;
  YoloService._internal();

  FlutterVision? _vision;
  Map<String, String>? _labels;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // YOLOv8 model specifications from metadata.yaml
  static const int MODEL_INPUT_SIZE = 640;
  static const List<int> MODEL_INPUT_SHAPE = [1, 640, 640, 3];
  static const double DEFAULT_CONF_THRESHOLD = 0.25;  // Ultralytics default
  static const double DEFAULT_IOU_THRESHOLD = 0.7;    // Ultralytics default

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    try {
      print('🔧 Initializing YoloService...');
      
      // Initialize FlutterVision
      _vision = FlutterVision();
      
      // Load labels first
      await _loadLabels();
      print('✅ Labels loaded successfully: ${_labels?.length} classes');
      
      // Load YOLOv8 model
      await _vision!.loadYoloModel(
        labels: 'assets/models/dog/labels.json',
        modelPath: 'assets/models/dog/best_float32.tflite',
        modelVersion: 'yolov8',
        numThreads: 4,
        useGpu: false,
      );
      
      _isInitialized = true;
      print('✅ YOLOv8 model loaded successfully');
      
    } catch (e) {
      print('❌ Error initializing YoloService: $e');
      _isInitialized = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Load labels from the JSON file
  Future<void> _loadLabels() async {
    try {
      print('📂 Loading labels from assets/models/dog/labels.json...');
      
      // Try to load the asset
      final String labelsString = await rootBundle.loadString('assets/models/dog/labels.json');
      
      if (labelsString.isEmpty) {
        throw Exception('Labels file is empty');
      }
      
      print('📄 Labels file content: $labelsString');
      
      // Parse JSON
      final Map<String, dynamic> labelsJson = json.decode(labelsString);
      
      // Convert to Map<String, String>
      _labels = labelsJson.map((key, value) => MapEntry(key, value.toString()));
      
      print('🏷️ Parsed labels: $_labels');
      
    } catch (e) {
      print('❌ Error loading labels: $e');
      
      // Fallback to hardcoded labels based on metadata.yaml
      print('🔄 Using fallback labels...');
      _labels = {
        '0': 'dermatitis',
        '1': 'fleas',
        '2': 'fungal_infection',
        '3': 'hotspot',
        '4': 'mange',
        '5': 'pyoderma',
        '6': 'ringworm',
        '7': 'ticks',
        '8': 'unknown_abnormality',
      };
      
      print('✅ Fallback labels loaded: $_labels');
    }
  }

  /// Preprocess image to match YOLOv8 requirements
  Future<Uint8List> _preprocessImage(Uint8List imageBytes) async {
    try {
      print('🔧 Preprocessing image for YOLOv8...');
      
      // Decode image to get original dimensions
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      
      print('� Original image: ${originalImage.width}x${originalImage.height}');
      
      // Calculate scaling and padding for letterboxing (maintains aspect ratio)
      final double scaleX = MODEL_INPUT_SIZE / originalImage.width;
      final double scaleY = MODEL_INPUT_SIZE / originalImage.height;
      final double scale = scaleX < scaleY ? scaleX : scaleY;
      
      final int newWidth = (originalImage.width * scale).round();
      final int newHeight = (originalImage.height * scale).round();
      
      print('� Scaled dimensions: ${newWidth}x${newHeight} (scale: $scale)');
      
      // Create picture recorder for drawing
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder);
      
      // Fill with gray background (0.5 normalized) - standard YOLO padding
      final ui.Paint backgroundPaint = ui.Paint()..color = const ui.Color(0xFF808080);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, MODEL_INPUT_SIZE.toDouble(), MODEL_INPUT_SIZE.toDouble()),
        backgroundPaint,
      );
      
      // Calculate centering offsets
      final double offsetX = (MODEL_INPUT_SIZE - newWidth) / 2;
      final double offsetY = (MODEL_INPUT_SIZE - newHeight) / 2;
      
      print('📍 Letterbox offsets: x=$offsetX, y=$offsetY');
      
      // Draw scaled image centered
      canvas.drawImageRect(
        originalImage,
        ui.Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
        ui.Rect.fromLTWH(offsetX, offsetY, newWidth.toDouble(), newHeight.toDouble()),
        ui.Paint(),
      );
      
      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image processedImage = await picture.toImage(MODEL_INPUT_SIZE, MODEL_INPUT_SIZE);
      
      // Convert to bytes
      final ByteData? byteData = await processedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert processed image to bytes');
      }
      
      final Uint8List processedBytes = byteData.buffer.asUint8List();
      print('✅ Image preprocessed: ${MODEL_INPUT_SIZE}x${MODEL_INPUT_SIZE}, ${processedBytes.length} bytes');
      
      return processedBytes;
      
    } catch (e) {
      print('❌ Error preprocessing image: $e');
      rethrow;
    }
  }

  /// Detect objects in an image with proper preprocessing
  Future<List<Map<String, dynamic>>> detectOnImage(
    Uint8List bytes,
    int height,
    int width,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_vision == null) {
      throw Exception('YoloService not properly initialized');
    }

    try {
      print('🔍 Running YOLO detection on image ${width}x${height}...');
      print('📊 Original image size: ${bytes.length} bytes');
      print('🏷️ Using model: assets/models/dog/best_float32.tflite');
      print('📋 Available classes: $_labels');
      
      // CRITICAL FIX: Preprocess image to match YOLOv8 input requirements
      final Uint8List preprocessedBytes = await _preprocessImage(bytes);
      print('✅ Image preprocessed for YOLOv8 inference');
      
      // Use Ultralytics default thresholds for consistency
      final List<Map<String, dynamic>> recognitions = await _vision!.yoloOnImage(
        bytesList: preprocessedBytes,  // Use preprocessed image
        imageHeight: MODEL_INPUT_SIZE,  // Fixed model input size
        imageWidth: MODEL_INPUT_SIZE,   // Fixed model input size
        iouThreshold: DEFAULT_IOU_THRESHOLD,    // 0.7 - Ultralytics default
        confThreshold: DEFAULT_CONF_THRESHOLD,  // 0.25 - Ultralytics default
        classThreshold: DEFAULT_CONF_THRESHOLD, // 0.25 - Ultralytics default
      );

      print('🎯 Raw detections (${recognitions.length}): $recognitions');
      
      // If no detections with default thresholds, try lower ones for debugging
      if (recognitions.isEmpty) {
        print('🔍 No detections with default thresholds, trying lower thresholds...');
        final List<Map<String, dynamic>> lowThresholdRecognitions = await _vision!.yoloOnImage(
          bytesList: preprocessedBytes,
          imageHeight: MODEL_INPUT_SIZE,
          imageWidth: MODEL_INPUT_SIZE,
          iouThreshold: 0.5,    // Slightly lower IoU
          confThreshold: 0.1,   // Lower confidence for debugging
          classThreshold: 0.1,  // Lower class threshold for debugging
        );
        print('🔍 Low threshold detections (${lowThresholdRecognitions.length}): $lowThresholdRecognitions');
        recognitions.addAll(lowThresholdRecognitions);
      }

      // Process and format results with proper coordinate mapping
      final List<Map<String, dynamic>> results = [];
      
      // Get proper scaling factors for coordinate mapping (accounts for letterboxing)
      final Map<String, double> scalingFactors = ImagePreprocessor.getScalingFactors(
        width,
        height, 
        MODEL_INPUT_SIZE,
      );
      print('📐 Coordinate scaling factors: $scalingFactors');
      
      for (int i = 0; i < recognitions.length; i++) {
        final recognition = recognitions[i];
        try {
          print('🔍 Processing detection $i: $recognition');
          
          // FlutterVision format analysis from logs:
          // box: [x1, y1, x2, y2, confidence]
          // tag: "classId": "className"
          
          // Extract bounding box - it's a List with 5 elements [x1, y1, x2, y2, confidence]
          final dynamic boxData = recognition['box'];
          if (boxData == null || !(boxData is List) || boxData.length < 5) {
            print('⚠️ Invalid box format: $boxData');
            continue;
          }
          
          final List boxList = boxData;
          // Coordinates are in model input space (640x640), need to scale back to original image
          final double x1_model = boxList[0].toDouble();
          final double y1_model = boxList[1].toDouble(); 
          final double x2_model = boxList[2].toDouble();
          final double y2_model = boxList[3].toDouble();
          final double confidence = boxList[4].toDouble();
          
          // Map coordinates back to original image space using proper letterbox mapping
          final Map<String, double> originalCoords = ImagePreprocessor.mapCoordinatesBackToOriginal(
            {'box': [x1_model, y1_model, x2_model, y2_model]},
            scalingFactors,
          );
          
          final double x1 = originalCoords['x1']!;
          final double y1 = originalCoords['y1']!;
          final double x2 = originalCoords['x2']!;
          final double y2 = originalCoords['y2']!;
          
          // Extract class information from tag
          final dynamic tagData = recognition['tag'];
          print('🏷️ Tag data: $tagData (type: ${tagData.runtimeType})');
          
          int classId = 0;
          String label = 'unknown';
          
          if (tagData is String) {
            // Parse tag like "0": "dermatitis"
            final RegExp regExp = RegExp(r'"(\d+)": "([^"]+)"');
            final Match? match = regExp.firstMatch(tagData);
            if (match != null) {
              classId = int.parse(match.group(1)!);
              label = match.group(2)!;
            }
          } else if (tagData is Map) {
            // If it's already a map, extract directly
            final entry = tagData.entries.first;
            classId = int.parse(entry.key.toString());
            label = entry.value.toString();
          }
          
          print('🎯 Extracted: classId=$classId, label=$label, confidence=${confidence.toStringAsFixed(3)}');
          print('🎯 Scaled coordinates: (${x1.toStringAsFixed(1)}, ${y1.toStringAsFixed(1)}) -> (${x2.toStringAsFixed(1)}, ${y2.toStringAsFixed(1)})');
          
          final result = {
            'label': label,
            'confidence': confidence,
            'rect': {
              'left': x1,
              'top': y1,
              'width': x2 - x1,
              'height': y2 - y1,
            },
            'box': [x1, y1, x2, y2],
            'classId': classId,
          };
          
          print('✅ Processed detection: $result');
          results.add(result);
          
        } catch (e) {
          print('⚠️ Error processing detection $i: $e');
          print('🔍 Raw recognition data: $recognition');
          continue;
        }
      }

      print('✅ Final processed detections (${results.length}): $results');
      
      // If no detections, provide detailed feedback
      if (results.isEmpty) {
        print('❌ No detections found!');
        print('📊 Possible reasons:');
        print('   - Image doesn\'t contain detectable skin conditions');
        print('   - Confidence thresholds are too high');
        print('   - Image quality/resolution issues');
        print('   - Model needs different input format');
      }
      
      return results;
      
    } catch (e) {
      print('❌ Error during detection: $e');
      rethrow;
    }
  }

  /// Dispose of all resources
  Future<void> dispose() async {
    if (_vision != null) {
      try {
        await _vision!.closeYoloModel();
        print('🧹 YoloService disposed');
      } catch (e) {
        print('⚠️ Error disposing YoloService: $e');
      }
    }
    _isInitialized = false;
    _vision = null;
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
}