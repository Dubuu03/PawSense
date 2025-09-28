import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/shared/buttons/primary_button.dart';
import 'package:pawsense/core/services/pet_detection_service.dart';

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
  final PetDetectionService _detectionService = PetDetectionService();
  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _detectionResults = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _showPreparationTips = false;
  bool _serverConnected = false;

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
    
    // Check API server connectivity
    _checkServerConnection();
  }

  Future<void> _checkServerConnection() async {
    try {
      print('🔍 Checking server connection...');
      final health = await _detectionService.checkServerHealth();
      setState(() {
        _serverConnected = health.isHealthy;
      });
      
      if (health.isHealthy) {
        print('✅ Detection server is healthy');
      } else {
        print('⚠️ Detection server is not healthy: ${health.message}');
        _showServerConnectionWarning();
      }
    } catch (e) {
      print('❌ Server connection check failed: $e');
      setState(() {
        _serverConnected = false;
      });
      _showServerConnectionWarning();
    }
  }

  void _showServerConnectionWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cannot connect to detection server. Please ensure the API server is running.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _checkServerConnection,
        ),
      ),
    );
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
        
        // Run API detection on the new photo
        await _runAPIDetection(photo);
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
        
        // Run API detection on all new photos
        for (final image in images) {
          await _runAPIDetection(image);
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to upload photos: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runAPIDetection(XFile imageFile) async {
    setState(() => _isAnalyzing = true);
    
    try {
      print('🖼️ Starting API detection on: ${imageFile.path}');
      
      // Determine pet type from assessment data
      final selectedPetType = widget.assessmentData['selectedPetType']?.toString().toLowerCase() ?? 'dogs';
      final String apiPetType = selectedPetType == 'cat' ? PetDetectionService.CATS : PetDetectionService.DOGS;
      
      print('� Pet type for API: $apiPetType');
      
      // Check server connection first
      if (!_serverConnected) {
        await _checkServerConnection();
        if (!_serverConnected) {
          throw Exception('Cannot connect to detection server. Please ensure the server is running.');
        }
      }
      
      // Convert XFile to File for API
      final File imageFileForAPI = File(imageFile.path);
      
      print('� Image file path: ${imageFile.path}');
      print('📊 Image file size: ${await imageFile.length()} bytes');
      
      // Run detection via API
      final DetectionResult result = await _detectionService.detectConditions(
        imageFile: imageFileForAPI,
        petType: apiPetType,
      );
      
      print('🎯 API Detection results: ${result.totalDetections} detections');
      print('� Model info: ${result.modelInfo.description}');
      
      // Convert API detections to the format expected by existing code
      final List<Map<String, dynamic>> detections = result.detections
          .map((detection) => detection.toYoloFormat())
          .toList();
      
      // Log individual detections with bounding box details
      for (int i = 0; i < detections.length; i++) {
        final detection = detections[i];
        final bbox = detection['box'] as List<double>?;
        print('Detection $i: ${detection['label']} - Confidence: ${detection['confidence']?.toStringAsFixed(3)} - BBox: [${bbox?.map((v) => v.toStringAsFixed(1)).join(', ')}]');
      }
      
      // Find and log the highest confidence detection
      if (detections.isNotEmpty) {
        detections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
        final topDetection = detections.first;
        final topBbox = topDetection['box'] as List<double>?;
        print('🏆 HIGHEST DETECTION: ${topDetection['label']} - Confidence: ${(topDetection['confidence'] * 100).toStringAsFixed(2)}%');
        if (topBbox != null && topBbox.length >= 4) {
          print('📍 Bounding Box: [x1=${topBbox[0].toStringAsFixed(1)}, y1=${topBbox[1].toStringAsFixed(1)}, x2=${topBbox[2].toStringAsFixed(1)}, y2=${topBbox[3].toStringAsFixed(1)}]');
          print('📏 Box Size: width=${(topBbox[2] - topBbox[0]).toStringAsFixed(1)}, height=${(topBbox[3] - topBbox[1]).toStringAsFixed(1)}');
        }
      }
      
      setState(() {
        _detectionResults.add({
          'imagePath': imageFile.path,
          'detections': detections,
          'apiResult': result.toMap(), // Store original API result for reference
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
      print('❌ API detection error: $e');
      
      // Show more specific error messages
      String errorMessage = 'Failed to analyze image';
      if (e.toString().contains('connect')) {
        errorMessage = 'Cannot connect to detection server. Please ensure the server is running at ${PetDetectionService.baseUrl}';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Detection request timed out. Please try again.';
      } else if (e.toString().contains('too large')) {
        errorMessage = 'Image file is too large. Please use a smaller image.';
      }
      
      _showErrorDialog('$errorMessage\n\nError details: ${e.toString()}');
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
    final List<double>? bbox = topDetection['box'] as List<double>?;
    
    String bboxInfo = '';
    if (bbox != null && bbox.length >= 4) {
      bboxInfo = '\nLocation: [${bbox[0].toStringAsFixed(0)}, ${bbox[1].toStringAsFixed(0)}, ${bbox[2].toStringAsFixed(0)}, ${bbox[3].toStringAsFixed(0)}]';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Detected: $condition (${(confidence * 100).toStringAsFixed(1)}% confidence)$bboxInfo\nTotal detections: ${detections.length}',
          style: const TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Details',
          textColor: Colors.white,
          onPressed: () => _showDetailedDetectionDialog(detections),
        ),
      ),
    );
  }

  void _showDetailedDetectionDialog(List<Map<String, dynamic>> detections) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detection Results (${detections.length} found)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: detections.asMap().entries.map((entry) {
                final int index = entry.key;
                final Map<String, dynamic> detection = entry.value;
                final List<double>? bbox = detection['box'] as List<double>?;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: index == 0 ? Colors.green.shade50 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (index == 0) 
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                              '${detection['label']}',
                              style: TextStyle(
                                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (bbox != null && bbox.length >= 4) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Bounding Box: [${bbox[0].toStringAsFixed(1)}, ${bbox[1].toStringAsFixed(1)}, ${bbox[2].toStringAsFixed(1)}, ${bbox[3].toStringAsFixed(1)}]',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                          Text(
                            'Size: ${(bbox[2] - bbox[0]).toStringAsFixed(1)} × ${(bbox[3] - bbox[1]).toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
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
                
                // Pet Type and Server Status Indicators
                Row(
                  children: [
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
                    const SizedBox(width: kSpacingSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: kSpacingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: _serverConnected 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _serverConnected 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3)
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _serverConnected ? Icons.check_circle : Icons.error,
                            color: _serverConnected ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: kSpacingXSmall),
                          Text(
                            _serverConnected ? 'Server Online' : 'Server Offline',
                            style: kMobileTextStyleServiceTitle.copyWith(
                              color: _serverConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
