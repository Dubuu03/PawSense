import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/shared/buttons/primary_button.dart';
import 'package:pawsense/core/services/yolo_service.dart';

class AssessmentStepTwo extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const AssessmentStepTwo({
    super.key,
    required this.assessmentData,
    required this.onDataUpdate,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<AssessmentStepTwo> createState() => _AssessmentStepTwoState();
}

class _AssessmentStepTwoState extends State<AssessmentStepTwo> {
  final ImagePicker _picker = ImagePicker();
  final YoloService _yoloService = YoloService();
  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _detectionResults = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _showPreparationTips = false;

  // Expose analyzing state to parent
  bool get isAnalyzing => _isAnalyzing;

  @override
  void initState() {
    super.initState();
    // Initialize with existing photos if available
    if (widget.assessmentData['photos'] != null) {
      final photoList = widget.assessmentData['photos'] as List;
      _selectedImages = photoList.cast<XFile>();
    }
    
    // Initialize with existing detection results if available
    if (widget.assessmentData['detectionResults'] != null) {
      final detectionList = widget.assessmentData['detectionResults'] as List;
      _detectionResults = detectionList.cast<Map<String, dynamic>>();
    }
    
    // Initialize YOLO service
    _initializeYoloService();
  }

  Future<void> _initializeYoloService() async {
    try {
      await _yoloService.initialize();
      print('YoloService initialized successfully');
    } catch (e) {
      print('Error initializing YoloService: $e');
    }
  }

  Future<void> _takePhoto() async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
        widget.onDataUpdate('photos', _selectedImages);
        
        // Run YOLO detection on the new photo
        await _runYoloDetection(photo);
      }
    } catch (e) {
      _showErrorDialog('Failed to take photo: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        widget.onDataUpdate('photos', _selectedImages);
        
        // Run YOLO detection on all new photos
        for (final image in images) {
          await _runYoloDetection(image);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to upload photos: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runYoloDetection(XFile imageFile) async {
    setState(() => _isAnalyzing = true);
    
    try {
      print('🖼️ Starting YOLO detection on: ${imageFile.path}');
      
      // Read image bytes
      final Uint8List bytes = await imageFile.readAsBytes();
      print('📊 Image bytes: ${bytes.length}');
      
      // Get actual image dimensions
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      final int imageWidth = image.width;
      final int imageHeight = image.height;
      
      print('📐 Actual image dimensions: ${imageWidth}x${imageHeight}');
      
      // Run detection
      final detections = await _yoloService.detectOnImage(
        bytes,
        imageHeight,
        imageWidth,
      );
      
      print('🎯 Detection results: $detections');
      print('🔢 Number of detections: ${detections.length}');
      
      // Log individual detections
      for (int i = 0; i < detections.length; i++) {
        final detection = detections[i];
        print('Detection $i: ${detection['label']} - Confidence: ${detection['confidence']} - Box: ${detection['rect']}');
      }
      
      setState(() {
        _detectionResults.add({
          'imagePath': imageFile.path,
          'detections': detections,
        });
      });
      
      // Update assessment data
      widget.onDataUpdate('detectionResults', _detectionResults);
      
      // Show appropriate message
      if (detections.isNotEmpty) {
        _showDetectionSummary(detections);
      } else {
        _showNoDetectionDialog();
      }
      
    } catch (e) {
      print('❌ YOLO detection error: $e');
      _showErrorDialog('Failed to analyze image: ${e.toString()}');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _showNoDetectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Skin Conditions Detected'),
          content: const Text(
            'The AI analysis didn\'t detect any visible skin conditions in this image. '
            'This could mean:\n\n'
            '• The skin appears healthy\n'
            '• The image quality needs improvement\n'
            '• The condition is not visible in this photo\n\n'
            'Try taking a clearer, closer photo of the affected area.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDetectionSummary(List<Map<String, dynamic>> detections) {
    // Sort detections by confidence
    detections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    
    final topDetection = detections.first;
    final String condition = topDetection['label'];
    final double confidence = topDetection['confidence'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Detected: $condition (${(confidence * 100).toStringAsFixed(1)}% confidence)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      // Also remove corresponding detection results
      if (index < _detectionResults.length) {
        _detectionResults.removeAt(index);
      }
    });
    widget.onDataUpdate('photos', _selectedImages);
    widget.onDataUpdate('detectionResults', _detectionResults);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showFullscreenImage(XFile imageFile, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Fullscreen image
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(imageFile.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.background,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              color: AppColors.textSecondary,
                              size: 64,
                            ),
                            const SizedBox(height: kSpacingMedium),
                            Text(
                              'Image ${index + 1}',
                              style: kMobileTextStyleTitle.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              
              // Image info
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(kSpacingMedium),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image ${index + 1}',
                        style: kMobileTextStyleTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: kSpacingSmall),
                      
                      // Show analysis status only
                      if (index < _detectionResults.length) ...[
                        Text(
                          'Analysis completed',
                          style: kMobileTextStyleSubtitle.copyWith(
                            color: Colors.green.shade300,
                          ),
                        ),
                      ] else if (_isAnalyzing) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                              ),
                            ),
                            const SizedBox(width: kSpacingSmall),
                            Text(
                              'Analyzing...',
                              style: kMobileTextStyleSubtitle.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Ready for analysis',
                          style: kMobileTextStyleSubtitle.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take or Upload Photos',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  'Capture multiple photos for better differential analysis.',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: kSpacingMedium),
                
                // Pet Type Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kSpacingMedium,
                    vertical: kSpacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: kSpacingXSmall),
                      Text(
                        'Scanning: ${widget.assessmentData['selectedPetType'] ?? 'Dog'}',
                        style: kMobileTextStyleServiceTitle.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Photo Capture Buttons
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Take Photo',
                        icon: Icons.camera_alt,
                        onPressed: (_isLoading || _isAnalyzing) ? null : _takePhoto,
                      ),
                    ),
                    const SizedBox(width: kSpacingMedium),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isLoading || _isAnalyzing) ? null : _uploadPhotos,
                        icon: Icon(Icons.upload),
                        label: Text('Upload Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kButtonRadius),
                          ),
                          minimumSize: Size(double.infinity, kButtonHeight),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Photos Section
          if (_selectedImages.isNotEmpty) ...[
            Container(
              width: double.infinity, // Full width
              padding: const EdgeInsets.all(kSpacingMedium),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Photos (${_selectedImages.length})',
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_detectionResults.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kSpacingSmall,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Analyzed',
                                style: kMobileTextStyleLegend.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: kSpacingMedium),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_selectedImages.length, (index) {
                        final isAnalyzed = index < _detectionResults.length;
                        final hasDetection = isAnalyzed && 
                                           _detectionResults[index]['detections'].isNotEmpty;
                        
                        // Determine border color based on analysis status
                        Color borderColor;
                        double borderWidth;
                        
                        if (!isAnalyzed && _isAnalyzing) {
                          // Yellow for analyzing/pending
                          borderColor = AppColors.warning;
                          borderWidth = 2;
                        } else if (isAnalyzed && hasDetection) {
                          // Green for completed with detections
                          borderColor = AppColors.success;
                          borderWidth = 2;
                        } else if (isAnalyzed && !hasDetection) {
                          // Red for completed with no detections
                          borderColor = AppColors.error;
                          borderWidth = 2;
                        } else {
                          // Default border for unanalyzed when not analyzing
                          borderColor = AppColors.border;
                          borderWidth = 1;
                        }
                        
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < _selectedImages.length - 1 ? kSpacingSmall : 0,
                          ),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showFullscreenImage(_selectedImages[index], index),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(kBorderRadius),
                                    border: Border.all(
                                      color: borderColor,
                                      width: borderWidth,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(kBorderRadius),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.background,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.image,
                                                color: AppColors.textSecondary,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${index + 1}',
                                                style: kMobileTextStyleLegend.copyWith(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (isAnalyzed && hasDetection) ...[
                                Positioned(
                                  bottom: 2,
                                  left: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: AppColors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ],
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: AppColors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  // Analysis Status Indicator (instead of detection summary)
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: kSpacingMedium),
                    Container(
                      padding: const EdgeInsets.all(kSpacingMedium),
                      decoration: BoxDecoration(
                        color: _isAnalyzing 
                            ? AppColors.warning.withOpacity(0.1)
                            : (_detectionResults.length == _selectedImages.length 
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.primary.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        border: Border.all(
                          color: _isAnalyzing 
                              ? AppColors.warning.withOpacity(0.3)
                              : (_detectionResults.length == _selectedImages.length 
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.primary.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isAnalyzing) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                              ),
                            ),
                            const SizedBox(width: kSpacingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analyzing Images...',
                                    style: kMobileTextStyleSubtitle.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Please wait while we analyze your photos',
                                    style: kMobileTextStyleLegend.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_detectionResults.length == _selectedImages.length) ...[
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: kSpacingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analysis Complete',
                                    style: kMobileTextStyleSubtitle.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_detectionResults.length} image${_detectionResults.length > 1 ? 's' : ''} analyzed successfully',
                                    style: kMobileTextStyleLegend.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.pending,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: kSpacingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready for Analysis',
                                    style: kMobileTextStyleSubtitle.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Images will be analyzed automatically',
                                    style: kMobileTextStyleLegend.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: kSpacingMedium),
          ],
          
          // Preparation Tips (Collapsible)
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showPreparationTips = !_showPreparationTips),
                  child: Container(
                    padding: const EdgeInsets.all(kSpacingMedium),
                    child: Row(
                      children: [
                        Text(
                          'Preparation Tips',
                          style: kMobileTextStyleTitle.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                      
                        Icon(
                          _showPreparationTips ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showPreparationTips) ...[
                  const Divider(height: 1, color: AppColors.primary),
                  Padding(
                    padding: const EdgeInsets.all(kSpacingMedium),
                    child: Column(
                      children: [
                        _buildTip(Icons.wb_sunny, 'Use natural light'),
                        _buildTip(Icons.straighten, 'Hold 10-15 cm away'),
                        _buildTip(Icons.pets, 'Keep pet calm'),
                        _buildTip(Icons.cleaning_services, 'Clean affected area'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Text(
              'This is a preliminary differential analysis. For a confirmed diagnosis, please consult a licensed veterinarian.',
              style: kMobileTextStyleLegend.copyWith(
                color: AppColors.info,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingSmall),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: kSpacingSmall),
          Text(
            text,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
