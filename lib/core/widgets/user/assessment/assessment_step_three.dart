import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/detection_utils.dart';
import 'package:pawsense/core/widgets/shared/buttons/primary_button.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';
import 'package:pawsense/core/services/user/assessment_result_service.dart';
import 'package:pawsense/core/services/user/pdf_generation_service.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';
import 'package:pawsense/core/services/user/user_services.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class AssessmentStepThree extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onPrevious;
  final VoidCallback onComplete;

  const AssessmentStepThree({
    super.key,
    required this.assessmentData,
    required this.onDataUpdate,
    required this.onPrevious,
    required this.onComplete,
  });

  @override
  State<AssessmentStepThree> createState() => _AssessmentStepThreeState();
}

class _AssessmentStepThreeState extends State<AssessmentStepThree> {
  bool _isGeneratingPDF = false;
  bool _showRemedies = false;
  late List<AnalysisResult> _analysisResults;
  Set<int> _previewingImages = {}; // Track which images are showing bounding boxes
  Set<int> _fullscreenBoundingBoxes = {}; // Track bounding boxes in fullscreen mode
  
  @override
  void initState() {
    super.initState();
    _processDetectionResults();
  }

  void _showFullscreenImage(XFile photo, int index, List<Map<String, dynamic>> detectionsToShow) {
    // Set bounding boxes to show by default in fullscreen
    _fullscreenBoundingBoxes.add(index);
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool showingBoundingBoxes = _fullscreenBoundingBoxes.contains(index);
            
            return Dialog.fullscreen(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      // Fullscreen image
                      Center(
                        child: InteractiveViewer(
                          panEnabled: true,
                          scaleEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: GestureDetector(
                            onTap: () {}, // Prevent dialog close when tapping image
                            child: Stack(
                              children: [
                                Image.file(
                                  File(photo.path),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: AppColors.background,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.textSecondary,
                                        size: 48,
                                      ),
                                    );
                                  },
                                ),
                                
                                // Bounding boxes overlay (only when toggled on)
                                if (showingBoundingBoxes && detectionsToShow.isNotEmpty)
                                  Positioned.fill(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return CustomPaint(
                                          painter: BoundingBoxPainter(
                                            detectionsToShow,
                                            boxColor: AppColors.primary,
                                            strokeWidth: 4.0,
                                            showLabels: true,
                                            showConfidence: true,
                                            originalImageWidth: 640.0,
                                            originalImageHeight: 640.0,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Top controls
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Close button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            
                            // Image info
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Image ${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom controls for bounding box toggle
                      if (detectionsToShow.isNotEmpty)
                        Positioned(
                          bottom: MediaQuery.of(context).padding.bottom + 32,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  if (_fullscreenBoundingBoxes.contains(index)) {
                                    _fullscreenBoundingBoxes.remove(index);
                                  } else {
                                    _fullscreenBoundingBoxes.add(index);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: showingBoundingBoxes 
                                      ? AppColors.primary 
                                      : Colors.black54,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: showingBoundingBoxes 
                                        ? AppColors.primary 
                                        : Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      showingBoundingBoxes 
                                          ? Icons.visibility 
                                          : Icons.visibility_off,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      showingBoundingBoxes 
                                          ? 'Hide Detection' 
                                          : 'Show Detection',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _processDetectionResults() {
    final detectionResults = widget.assessmentData['detectionResults'] as List<Map<String, dynamic>>? ?? [];
    
    // Aggregate only the highest confidence detection from each image
    final Map<String, List<double>> conditionConfidences = {};
    
    for (final result in detectionResults) {
      final allDetections = result['detections'] as List<Map<String, dynamic>>? ?? [];
      
      if (allDetections.isNotEmpty) {
        // Sort by confidence and get only the highest one
        final sortedDetections = List<Map<String, dynamic>>.from(allDetections);
        sortedDetections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
        final highestDetection = sortedDetections.first;
        
        final String condition = highestDetection['label'];
        final double confidence = highestDetection['confidence'];
        
        if (!conditionConfidences.containsKey(condition)) {
          conditionConfidences[condition] = [];
        }
        conditionConfidences[condition]!.add(confidence);
      }
    }
    
    if (conditionConfidences.isEmpty) {
      // Fallback to mock data if no detections
      _analysisResults = [
        AnalysisResult(condition: 'No conditions detected', percentage: 100.0, color: const Color(0xFF34C759)),
      ];
      return;
    }
    
    // Calculate average confidence for each condition
    final Map<String, double> avgConfidences = {};
    conditionConfidences.forEach((condition, confidences) {
      avgConfidences[condition] = confidences.reduce((a, b) => a + b) / confidences.length;
    });
    
    // Sort by average confidence
    final sortedConditions = avgConfidences.entries.toList();
    sortedConditions.sort((a, b) => b.value.compareTo(a.value));
    
    // Convert to AnalysisResult objects
    final colors = [
      const Color(0xFFFF9500),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF3B30),
      const Color(0xFFAF52DE),
      const Color(0xFFFF2D92),
      const Color(0xFF5856D6),
      const Color(0xFFFF9F0A),
      const Color(0xFF30B0C7),
    ];
    
    _analysisResults = sortedConditions.asMap().entries.map((entry) {
      final index = entry.key;
      final condition = entry.value.key;
      final confidence = entry.value.value;
      
      return AnalysisResult(
        condition: _formatConditionName(condition),
        percentage: _validateConfidence(confidence) * 100,
        color: colors[index % colors.length],
      );
    }).toList();
  }

  String _formatConditionName(String condition) {
    return DetectionUtils.formatConditionName(condition);
  }

  // Save assessment to Firebase without generating PDF
  Future<void> saveAssessment() async {
    try {
      // Get current user
      final authService = AuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user details
      final userService = UserServices();
      final userModel = await userService.getUserByUid(currentUser.uid);
      if (userModel == null) {
        throw Exception('User details not found');
      }

      // Create assessment result model and handle pet creation if needed
      final assessmentResult = await _createAssessmentResult(userModel);
      
      // If this is a new pet, save it to Firebase first
      await _handleNewPetCreation(userModel);
      
      // Save assessment result to Firebase
      final assessmentService = AssessmentResultService();
      await assessmentService.saveAssessmentResult(assessmentResult);

      print('✅ Assessment saved to Firebase successfully');
      
      // Show success toast
      Fluttertoast.showToast(
        msg: 'Assessment saved successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );

    } catch (e) {
      print('❌ Error saving assessment: $e');
      
      // Show error toast
      Fluttertoast.showToast(
        msg: 'Failed to save assessment. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  // Complete assessment (save and navigate)
  Future<void> _completeAssessment() async {
    try {
      // Save assessment first
      await saveAssessment();
      
      // Navigate to home with history tab
      if (mounted) {
        context.go('/home?tab=history');
      }
    } catch (e) {
      print('Error completing assessment: $e');
    }
  }

  Future<void> _generatePDF() async {
    setState(() => _isGeneratingPDF = true);
    
    try {
      // Get current user
      final authService = AuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user details
      final userService = UserServices();
      final userModel = await userService.getUserByUid(currentUser.uid);
      if (userModel == null) {
        throw Exception('User details not found');
      }

      // Create assessment result model for PDF generation only
      final assessmentResult = await _createAssessmentResult(userModel);
      
      // Generate PDF (without saving to Firebase)
      final pdfBytes = await PDFGenerationService.generateAssessmentPDF(
        user: userModel,
        assessmentResult: assessmentResult,
      );

      // Save PDF to device
      final fileName = 'PawSense_Assessment_${assessmentResult.petName}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = await PDFGenerationService.savePDFToDevice(pdfBytes, fileName);

      setState(() => _isGeneratingPDF = false);

      // Show success dialog with preview and save options
      _showPDFGeneratedDialog(filePath, pdfBytes, fileName);

      // Show success toast
      Fluttertoast.showToast(
        msg: 'PDF generated successfully!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.success,
        textColor: Colors.white,
      );

    } catch (e) {
      setState(() => _isGeneratingPDF = false);
      
      print('Error generating PDF: $e');
      
      // Show error dialog
      _showDialog(
        'Error',
        'Failed to generate PDF: ${e.toString()}',
        'OK',
        () => Navigator.of(context).pop(),
      );

      // Show error toast
      Fluttertoast.showToast(
        msg: 'Failed to generate PDF. Please try again.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleNewPetCreation(UserModel user) async {
    final selectedPetId = widget.assessmentData['selectedPet'] as String?;
    final newPetData = widget.assessmentData['newPetData'] as Map<String, dynamic>? ?? {};
    
    // Check if this is a new pet that needs to be saved
    if ((selectedPetId == null || selectedPetId.isEmpty) && newPetData.isNotEmpty) {
      final petName = newPetData['name']?.toString() ?? '';
      final petType = widget.assessmentData['selectedPetType']?.toString() ?? 'Dog';
      final petBreed = newPetData['breed']?.toString() ?? '';
      final petAge = int.tryParse(newPetData['age']?.toString() ?? '0') ?? 0;
      final petWeight = double.tryParse(newPetData['weight']?.toString() ?? '0.0') ?? 0.0;
      
      if (petName.isNotEmpty && petBreed.isNotEmpty) {
        try {
          final newPet = Pet(
            userId: user.uid,
            petName: petName,
            petType: petType,
            age: petAge,
            weight: petWeight,
            breed: petBreed,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final petId = await PetService.addPet(newPet);
          if (petId != null) {
            // Update the assessment data with the new pet ID
            widget.onDataUpdate('selectedPet', petId);
            print('New pet saved with ID: $petId');
          }
        } catch (e) {
          print('Error saving new pet: $e');
          // Continue with assessment even if pet saving fails
        }
      }
    }
  }

  Future<AssessmentResult> _createAssessmentResult(UserModel user) async {
    final selectedPetId = widget.assessmentData['selectedPet'] as String?;
    final newPetData = widget.assessmentData['newPetData'] as Map<String, dynamic>? ?? {};
    final photos = widget.assessmentData['photos'] as List<XFile>? ?? [];
    final symptoms = widget.assessmentData['symptoms'] as List<String>? ?? [];
    final notes = widget.assessmentData['notes'] as String? ?? '';
    final duration = widget.assessmentData['duration'] as String? ?? '';
    final detectionResults = widget.assessmentData['detectionResults'] as List<Map<String, dynamic>>? ?? [];

    // Determine pet details
    String petId, petName, petType, petBreed;
    int petAge;
    double petWeight;

    if (selectedPetId != null && selectedPetId.isNotEmpty) {
      // Use existing pet data - fetch the pet from the service
      try {
        final selectedPet = await PetService.getPetById(selectedPetId);
        
        if (selectedPet != null) {
          petId = selectedPet.id ?? selectedPetId;
          petName = selectedPet.petName;
          petType = selectedPet.petType;
          petBreed = selectedPet.breed;
          petAge = selectedPet.age;
          petWeight = selectedPet.weight;
        } else {
          // Fallback if pet not found
          throw Exception('Selected pet not found');
        }
      } catch (e) {
        print('Error fetching selected pet: $e');
        // Fallback to new pet data structure
        petId = selectedPetId;
        petName = 'Unknown Pet';
        petType = widget.assessmentData['selectedPetType']?.toString() ?? 'Dog';
        petBreed = 'Unknown';
        petAge = 0;
        petWeight = 0.0;
      }
    } else {
      // Use new pet data - check if pet was created and get its ID
      final updatedSelectedPetId = widget.assessmentData['selectedPet'] as String?;
      if (updatedSelectedPetId != null && updatedSelectedPetId.isNotEmpty && !updatedSelectedPetId.startsWith('new_pet_')) {
        // Pet was successfully created, use its ID
        petId = updatedSelectedPetId;
      } else {
        // Fallback to generated ID
        petId = 'new_pet_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      petName = newPetData['name']?.toString() ?? '';
      petType = widget.assessmentData['selectedPetType']?.toString() ?? 'Dog';
      petBreed = newPetData['breed']?.toString() ?? '';
      petAge = int.tryParse(newPetData['age']?.toString() ?? '0') ?? 0;
      petWeight = double.tryParse(newPetData['weight']?.toString() ?? '0.0') ?? 0.0;
    }

    // Upload photos to Cloudinary and get URLs
    final imageUrls = <String>[];
    final cloudinaryService = CloudinaryService();
    
    print('📤 Uploading ${photos.length} photos to Cloudinary...');
    for (int i = 0; i < photos.length; i++) {
      try {
        final photo = photos[i];
        final cloudinaryUrl = await cloudinaryService.uploadImageFromFile(
          photo.path,
          folder: 'assessment_images',
        );
        imageUrls.add(cloudinaryUrl);
        print('✅ Uploaded photo $i to Cloudinary: $cloudinaryUrl');
      } catch (e) {
        print('❌ Failed to upload photo $i to Cloudinary: $e');
        // Fallback to local path if Cloudinary upload fails
        imageUrls.add(photos[i].path);
      }
    }

    // Convert detection results and match with Cloudinary URLs
    final detectionResultModels = <DetectionResult>[];
    for (int i = 0; i < detectionResults.length; i++) {
      final result = detectionResults[i];
      final detections = (result['detections'] as List<dynamic>? ?? []).map((detection) {
        // Extract bounding box from YOLO detection format
        List<double>? boundingBox;
        if (detection['box'] != null) {
          // YOLO returns [x1, y1, x2, y2] format
          final box = detection['box'] as List<dynamic>;
          if (box.length >= 4) {
            boundingBox = [
              box[0].toDouble(), // x1
              box[1].toDouble(), // y1
              box[2].toDouble(), // x2
              box[3].toDouble(), // y2
            ];
            print('✅ Extracted bounding box for ${detection['label']}: $boundingBox');
          }
        } else if (detection['boundingBox'] != null) {
          // Fallback for legacy format
          boundingBox = List<double>.from(detection['boundingBox']);
          print('✅ Using legacy bounding box format: $boundingBox');
        } else {
          print('⚠️ No bounding box found for detection: ${detection['label']}');
        }
        
        return Detection(
          label: detection['label'] ?? '',
          confidence: detection['confidence']?.toDouble() ?? 0.0,
          boundingBox: boundingBox,
        );
      }).toList();

      // Use the Cloudinary URL if available, fallback to original
      final imageUrl = i < imageUrls.length ? imageUrls[i] : (result['imageUrl'] ?? '');
      
      detectionResultModels.add(DetectionResult(
        imageUrl: imageUrl,
        detections: detections,
      ));
    }

    // Convert analysis results
    final analysisResultModels = _analysisResults.map((result) {
      return AnalysisResultData(
        condition: result.condition,
        percentage: _validateConfidence(result.percentage / 100) * 100, // Ensure valid percentage
        colorHex: '#${result.color.value.toRadixString(16).substring(2)}',
      );
    }).toList();

    return AssessmentResult(
      userId: user.uid,
      petId: petId,
      petName: petName,
      petType: petType,
      petBreed: petBreed,
      petAge: petAge,
      petWeight: petWeight,
      symptoms: symptoms,
      imageUrls: imageUrls,
      notes: notes,
      duration: duration,
      detectionResults: detectionResultModels,
      analysisResults: analysisResultModels,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _showPDFGeneratedDialog(String filePath, List<int> pdfBytes, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              const Text('PDF Generated'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assessment report has been generated successfully!'),
              const SizedBox(height: 8),
              const Text('• PDF report generated'),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await PDFGenerationService.previewPDF(
                    Uint8List.fromList(pdfBytes), 
                    fileName,
                  );
                } catch (e) {
                  print('Error previewing PDF: $e');
                  Fluttertoast.showToast(
                    msg: 'Failed to preview PDF',
                    backgroundColor: AppColors.error,
                    textColor: Colors.white,
                  );
                }
              },
              icon: const Icon(Icons.preview),
              label: const Text('Preview PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }



  void _bookAppointment() {
    _showDialog(
      'Book Appointment',
      'Would you like to book an appointment with a veterinarian for further consultation?',
      'Book Now',
      () {
        Navigator.of(context).pop();
        // Handle appointment booking logic here
        _showDialog(
          'Appointment Booked',
          'Your appointment request has been submitted. You will receive confirmation shortly.',
          'OK',
          () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _showDialog(String title, String content, String buttonText, VoidCallback onPressed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(buttonText),
              onPressed: onPressed,
            ),
          ],
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
          // Summary Header
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
                  'Assessment Summary',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  'Based on the differential analysis of your pet\'s condition.',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
         // Analysis Results with Pie Chart
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
                  'Differential Analysis Results',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingMedium),
                
                // Pie Chart
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center align the row items
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sections: _analysisResults.map((result) {
                              return PieChartSectionData(
                                color: result.color,
                                value: result.percentage,
                                title: '${result.percentage.toStringAsFixed(1)}%',
                                titleStyle: kMobileTextStyleLegend.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                radius: 60,
                              );
                            }).toList(),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: kSpacingMedium), // Add spacing between chart and legend
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // Center the legend vertically
                          children: _analysisResults.map((result) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: kSpacingSmall),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: result.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: kSpacingSmall),
                                  Expanded(
                                    child: Text(
                                      result.condition,
                                      style: kMobileTextStyleSubtitle.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${result.percentage.toStringAsFixed(1)}%',
                                    style: kMobileTextStyleSubtitle.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingLarge),
          
          // Visual separator
          Container(
            height: 1,
            color: AppColors.border.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
          ),
          const SizedBox(height: kSpacingLarge),
          
          // Assessment Images Container
          _buildAssessmentImagesContainer(),
          const SizedBox(height: kSpacingMedium),
          
          // Initial Remedies/Suggestions (Collapsible)
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showRemedies = !_showRemedies),
                  child: Container(
                    padding: const EdgeInsets.all(kSpacingMedium),
                    child: Row(
                      children: [
                        Icon(
                          Icons.healing,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: kSpacingSmall),
                        Text(
                          'Initial Remedies & Suggestions',
                          style: kMobileTextStyleTitle.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),

                        Icon(
                          _showRemedies ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showRemedies) ...[
                  const Divider(height: 1, color: AppColors.primary),
                  Container(
                    padding: const EdgeInsets.all(kSpacingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(kBorderRadius),
                        bottomRight: Radius.circular(kBorderRadius),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildRemedyItem(
                          Icons.local_hospital,
                          'Immediate Care',
                          'Keep the affected area clean and dry. Avoid excessive scratching.',
                        ),
                        _buildRemedyItem(
                          Icons.medication,
                          'Topical Treatment',
                          'Apply antifungal cream twice daily if mange is suspected.',
                        ),
                        _buildRemedyItem(
                          Icons.schedule,
                          'Monitor Progress',
                          'Track symptoms daily and note any changes or improvements.',
                        ),
                        _buildRemedyItem(
                          Icons.warning,
                          'When to Seek Help',
                          'Consult a veterinarian if symptoms worsen or persist beyond 7 days.',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Action Buttons
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
                PrimaryButton(
                  text: 'Download as PDF',
                  icon: Icons.download,
                  onPressed: _isGeneratingPDF ? null : _generatePDF,
                  isLoading: _isGeneratingPDF,
                ),
                const SizedBox(height: kSpacingMedium),
                OutlinedButton.icon(
                  onPressed: _bookAppointment,
                  icon: Icon(Icons.calendar_today),
                  label: Text('Book Appointment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kButtonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: kSpacingMedium,
                    ),
                    minimumSize: const Size(double.infinity, kButtonHeight),
                  ),
                ),
                const SizedBox(height: kSpacingMedium),
                ElevatedButton.icon(
                  onPressed: _completeAssessment,
                  icon: Icon(Icons.check_circle),
                  label: Text('Complete Assessment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kButtonRadius),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: kSpacingMedium,
                    ),
                    minimumSize: const Size(double.infinity, kButtonHeight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Disclaimer
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  'Important Disclaimer',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  'This is a preliminary differential analysis based on visual assessment. For a confirmed diagnosis and proper treatment plan, please consult a licensed veterinarian immediately.',
                  style: kMobileTextStyleLegend.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentImagesContainer() {
    final photos = widget.assessmentData['photos'] as List<XFile>? ?? [];
    final detectionResults = widget.assessmentData['detectionResults'] as List<Map<String, dynamic>>? ?? [];

    if (photos.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_search,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Assessment Images',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'Analysis results for uploaded images',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          
          // Display each analyzed image with highest confidence detection only
          ...List.generate(photos.length, (index) {
            final photo = photos[index];
            final hasDetection = index < detectionResults.length;
            final allDetections = hasDetection 
                ? detectionResults[index]['detections'] as List<Map<String, dynamic>>? ?? []
                : <Map<String, dynamic>>[];

            // Get only the highest confidence detection
            Map<String, dynamic>? highestDetection;
            if (allDetections.isNotEmpty) {
              // Sort by confidence and get the highest
              final sortedDetections = List<Map<String, dynamic>>.from(allDetections);
              sortedDetections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
              highestDetection = sortedDetections.first;
            }

            // Create list with only the highest detection for display
            final detectionsToShow = highestDetection != null ? [highestDetection] : <Map<String, dynamic>>[];

            return Padding(
              padding: const EdgeInsets.only(bottom: kSpacingMedium),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clickable image to open fullscreen
                    GestureDetector(
                      onTap: () {
                        _showFullscreenImage(photo, index, detectionsToShow);
                      },
                      child: Stack(
                        children: [
                          // Base image
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(kBorderRadius),
                              topRight: Radius.circular(kBorderRadius),
                            ),
                            child: Image.file(
                              File(photo.path),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: AppColors.background,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.textSecondary,
                                        size: 48,
                                      ),
                                      const SizedBox(height: kSpacingSmall),
                                      Text(
                                        'Image ${index + 1}',
                                        style: kMobileTextStyleSubtitle.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          
                          // Fullscreen indicator overlay
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap to Enlarge',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Detection details
                    Container(
                      padding: const EdgeInsets.all(kSpacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Image ${index + 1}',
                                style: kMobileTextStyleSubtitle.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (detectionsToShow.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: kSpacingSmall,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _previewingImages.contains(index) 
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _previewingImages.contains(index) 
                                          ? AppColors.primary.withOpacity(0.3)
                                          : AppColors.success.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _previewingImages.contains(index) 
                                            ? Icons.visibility 
                                            : Icons.remove_red_eye_outlined,
                                        size: 12,
                                        color: _previewingImages.contains(index) 
                                            ? AppColors.primary
                                            : AppColors.success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _previewingImages.contains(index) 
                                            ? 'Showing Detection'
                                            : 'Detection Available',
                                        style: kMobileTextStyleLegend.copyWith(
                                          color: _previewingImages.contains(index) 
                                              ? AppColors.primary
                                              : AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: kSpacingSmall,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'No detections',
                                    style: kMobileTextStyleLegend.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          if (detectionsToShow.isNotEmpty) ...[
                            const SizedBox(height: kSpacingSmall),
                            ...detectionsToShow.map((detection) {
                              final String condition = detection['label'];
                              final double confidence = detection['confidence'];
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: kSpacingSmall),
                                    Expanded(
                                      child: Text(
                                        _formatConditionName(condition),
                                        style: kMobileTextStyleLegend.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(confidence * 100).toStringAsFixed(1)}%',
                                      style: kMobileTextStyleLegend.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRemedyItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(kSpacingSmall),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: kSpacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: kSpacingXSmall),
                Text(
                  description,
                  style: kMobileTextStyleServiceSubtitle.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to validate confidence values and prevent NaN/infinity
  double _validateConfidence(double confidence) {
    if (confidence.isNaN || confidence.isInfinite || confidence < 0) {
      return 0.0;
    }
    return confidence.clamp(0.0, 1.0);
  }
}

class AnalysisResult {
  final String condition;
  final double percentage;
  final Color color;

  AnalysisResult({
    required this.condition,
    required this.percentage,
    required this.color,
  });
}
