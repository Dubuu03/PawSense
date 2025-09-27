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
  
  @override
  void initState() {
    super.initState();
    _processDetectionResults();
  }

  void _processDetectionResults() {
    final detectionResults = widget.assessmentData['detectionResults'] as List<Map<String, dynamic>>? ?? [];
    
    // Aggregate all detections from all images
    final Map<String, List<double>> conditionConfidences = {};
    
    for (final result in detectionResults) {
      final detections = result['detections'] as List<Map<String, dynamic>>? ?? [];
      for (final detection in detections) {
        final String condition = detection['label'];
        final double confidence = detection['confidence'];
        
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

      // Create assessment result model and handle pet creation if needed
      final assessmentResult = await _createAssessmentResult(userModel);
      
      // If this is a new pet, save it to Firebase first
      await _handleNewPetCreation(userModel);
      
      // Save assessment result to Firebase
      final assessmentService = AssessmentResultService();
      await assessmentService.saveAssessmentResult(assessmentResult);
      
      // Generate PDF
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
        msg: 'Assessment and PDF generated successfully!',
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

    // Convert photos to image URLs (for now, just use file paths)
    final imageUrls = photos.map((photo) => photo.path).toList();

    // Convert detection results
    final detectionResultModels = detectionResults.map((result) {
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

      return DetectionResult(
        imageUrl: result['imageUrl'] ?? '',
        detections: detections,
      );
    }).toList();

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
              const Text('• Assessment data saved to Firebase'),
              const Text('• PDF report generated'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'To access your PDF easily:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Tap "Save to Main Downloads"'),
                    const Text('2. Choose "Downloads" from the menu'),
                    const Text('3. Find it in your main Downloads folder'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton.icon(
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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.info,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await PDFGenerationService.sharePDF(
                    Uint8List.fromList(pdfBytes), 
                    fileName,
                  );
                  Fluttertoast.showToast(
                    msg: 'Choose "Downloads" to save to main Downloads folder',
                    toastLength: Toast.LENGTH_LONG,
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                  );
                } catch (e) {
                  print('Error sharing PDF: $e');
                  Fluttertoast.showToast(
                    msg: 'Failed to share PDF',
                    backgroundColor: AppColors.error,
                    textColor: Colors.white,
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Save to Downloads'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showFileLocationHelp(filePath);
              },
              child: const Text('Show Path'),
            ),
          ],
        );
      },
    );
  }

  void _showFileLocationHelp(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PDF File Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your PDF is saved at:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('To find this file:'),
              const Text('1. Open File Manager'),
              const Text('2. Go to Internal Storage'),
              const Text('3. Navigate to: Android > data > com.example.pawsense > files > Downloads'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Tip: Use "Save to Main Downloads" for easier access!')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: filePath));
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: 'File path copied to clipboard',
                  backgroundColor: AppColors.success,
                  textColor: Colors.white,
                );
              },
              child: const Text('Copy Path'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
                  onPressed: () {
                    // Navigate back to home with history tab
                    context.go('/home?tab=history');
                  },
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
          
          // Display each analyzed image
          ...List.generate(photos.length, (index) {
            final photo = photos[index];
            final hasDetection = index < detectionResults.length;
            final detections = hasDetection 
                ? detectionResults[index]['detections'] as List<Map<String, dynamic>>? ?? []
                : <Map<String, dynamic>>[];

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
                    // Image with bounding boxes
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(kBorderRadius),
                        topRight: Radius.circular(kBorderRadius),
                      ),
                      child: ImageWithBoundingBoxes(
                        imageWidget: Image.file(
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
                        detections: detections,
                        boxColor: AppColors.primary,
                        strokeWidth: 3.0,
                        showLabels: true,
                        showConfidence: true,
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
                              if (detections.isNotEmpty) ...[
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
                                  child: Text(
                                    '${detections.length} detection${detections.length > 1 ? 's' : ''}',
                                    style: kMobileTextStyleLegend.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                          
                          if (detections.isNotEmpty) ...[
                            const SizedBox(height: kSpacingSmall),
                            ...detections.map((detection) {
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
