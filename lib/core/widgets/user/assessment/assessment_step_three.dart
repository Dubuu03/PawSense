import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
import 'package:pawsense/core/services/user/skin_disease_service.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/utils/data_cache.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

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
  bool _isCompletingAssessment = false;
  bool _showRemedies = false;
  late List<AnalysisResult> _analysisResults;
  Set<int> _previewingImages = {}; // Track which images are showing bounding boxes
  Set<int> _fullscreenBoundingBoxes = {}; // Track bounding boxes in fullscreen mode
  SkinDiseaseModel? _detectedDisease; // Store the fetched disease info
  bool _isLoadingDiseaseInfo = false;
  
  @override
  void initState() {
    super.initState();
    _processDetectionResults();
    _fetchDiseaseInfo();
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
                                        // Build disease color map for consistent coloring
                                        final diseaseColorMap = _buildDiseaseColorMap();
                                        
                                        return CustomPaint(
                                          painter: BoundingBoxPainter(
                                            detectionsToShow,
                                            strokeWidth: 4.0,
                                            showLabels: true,
                                            showConfidence: true,
                                            originalImageWidth: 640.0,
                                            originalImageHeight: 640.0,
                                            useRankColors: false, // Disable rank colors
                                            diseaseColorMap: diseaseColorMap, // Use disease-based colors
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
    
    // Configuration
    const double CONFIDENCE_THRESHOLD = 0.25; // 25% minimum confidence (lowered to include more detections)
    const double IOU_THRESHOLD = 0.5; // Intersection over Union threshold for duplicate detection
    // Show ALL unique detections in graph (no limit)
    
    // Collect all detections with their image indices for deduplication
    final List<Map<String, dynamic>> allDetectionsWithContext = [];
    
    for (int imageIndex = 0; imageIndex < detectionResults.length; imageIndex++) {
      final result = detectionResults[imageIndex];
      final detections = result['detections'] as List<Map<String, dynamic>>? ?? [];
      
      for (final detection in detections) {
        final confidence = detection['confidence'] as double? ?? 0.0;
        
        // Apply confidence threshold
        if (confidence >= CONFIDENCE_THRESHOLD) {
          allDetectionsWithContext.add({
            'label': detection['label'],
            'confidence': confidence,
            'box': detection['box'],
            'boundingBox': detection['boundingBox'],
            'imageIndex': imageIndex,
          });
        }
      }
    }
    
    if (allDetectionsWithContext.isEmpty) {
      // No detections meet the threshold
      _analysisResults = [
        AnalysisResult(
          condition: 'No skin disease detected',
          percentage: 100.0,
          color: const Color(0xFF34C759),
        ),
      ];
      return;
    }
    
    // Sort all detections by confidence
    allDetectionsWithContext.sort((a, b) => 
      (b['confidence'] as double).compareTo(a['confidence'] as double)
    );
    
    // Remove duplicates ONLY within the same image (same condition at similar location)
    // Keep all detections from different images or different locations
    final List<Map<String, dynamic>> uniqueDetections = [];
    
    for (final detection in allDetectionsWithContext) {
      bool isDuplicate = false;
      final label = detection['label'] as String;
      final imageIndex = detection['imageIndex'] as int;
      final box = detection['box'] as List?;
      
      for (final existing in uniqueDetections) {
        final existingLabel = existing['label'] as String;
        final existingImageIndex = existing['imageIndex'] as int;
        final existingBox = existing['box'] as List?;
        
        // Only check for duplicates within the SAME image
        if (label == existingLabel && imageIndex == existingImageIndex) {
          // Check if bounding boxes overlap significantly
          if (box != null && existingBox != null && box.length >= 4 && existingBox.length >= 4) {
            final iou = _calculateIOU(
              [box[0], box[1], box[2], box[3]],
              [existingBox[0], existingBox[1], existingBox[2], existingBox[3]],
            );
            
            if (iou > IOU_THRESHOLD) {
              isDuplicate = true;
              break;
            }
          }
        }
      }
      
      if (!isDuplicate) {
        uniqueDetections.add(detection);
      }
      
      // NO LIMIT - collect all unique detections for the graph
    }
    
    // Aggregate detections by condition for statistics
    // Now includes all instances of each disease across all images
    final Map<String, List<double>> conditionConfidences = {};
    for (final detection in uniqueDetections) {
      final label = detection['label'] as String;
      final confidence = detection['confidence'] as double;
      
      if (!conditionConfidences.containsKey(label)) {
        conditionConfidences[label] = [];
      }
      conditionConfidences[label]!.add(confidence);
    }
    
    // Calculate average confidence for each condition
    final Map<String, double> avgConfidences = {};
    conditionConfidences.forEach((condition, confidences) {
      avgConfidences[condition] = confidences.reduce((a, b) => a + b) / confidences.length;
    });
    
    // Sort by average confidence
    final sortedConditions = avgConfidences.entries.toList();
    sortedConditions.sort((a, b) => b.value.compareTo(a.value));
    
    // Define expanded color palette for diseases (support more than 3)
    final diseaseColorPalette = [
      const Color(0xFFFF9500), // Orange
      const Color(0xFF007AFF), // Blue
      const Color(0xFF34C759), // Green
      const Color(0xFFFF3B30), // Red
      const Color(0xFFAF52DE), // Purple
      const Color(0xFFFF2D92), // Pink
      const Color(0xFF5856D6), // Indigo
      const Color(0xFFFF9F0A), // Amber
      const Color(0xFF30B0C7), // Cyan
      const Color(0xFF8E8E93), // Gray
      const Color(0xFFFFCC00), // Yellow
      const Color(0xFF00C7BE), // Teal
    ];
    
    // Convert to AnalysisResult objects - INCLUDE ALL DETECTIONS
    // Assign colors based on the order they appear in sortedConditions
    _analysisResults = sortedConditions.asMap().entries.map((entry) {
      final index = entry.key;
      final condition = entry.value.key;
      final confidence = entry.value.value;
      
      return AnalysisResult(
        condition: _formatConditionName(condition),
        percentage: _validateConfidence(confidence) * 100,
        color: diseaseColorPalette[index % diseaseColorPalette.length],
      );
    }).toList();
    
    print('📊 Processed ${_analysisResults.length} unique skin disease detections:');
    for (final result in _analysisResults) {
      print('   • ${result.condition}: ${result.percentage.toStringAsFixed(1)}%');
    }
  }
  
  /// Calculate Intersection over Union (IoU) for two bounding boxes
  /// Format: [x1, y1, x2, y2]
  double _calculateIOU(List<dynamic> box1, List<dynamic> box2) {
    try {
      final x1_1 = box1[0].toDouble();
      final y1_1 = box1[1].toDouble();
      final x2_1 = box1[2].toDouble();
      final y2_1 = box1[3].toDouble();
      
      final x1_2 = box2[0].toDouble();
      final y1_2 = box2[1].toDouble();
      final x2_2 = box2[2].toDouble();
      final y2_2 = box2[3].toDouble();
      
      // Calculate intersection area
      final xLeft = x1_1 > x1_2 ? x1_1 : x1_2;
      final yTop = y1_1 > y1_2 ? y1_1 : y1_2;
      final xRight = x2_1 < x2_2 ? x2_1 : x2_2;
      final yBottom = y2_1 < y2_2 ? y2_1 : y2_2;
      
      if (xRight < xLeft || yBottom < yTop) {
        return 0.0; // No intersection
      }
      
      final intersectionArea = (xRight - xLeft) * (yBottom - yTop);
      
      // Calculate union area
      final box1Area = (x2_1 - x1_1) * (y2_1 - y1_1);
      final box2Area = (x2_2 - x1_2) * (y2_2 - y1_2);
      final unionArea = box1Area + box2Area - intersectionArea;
      
      if (unionArea <= 0) {
        return 0.0;
      }
      
      return intersectionArea / unionArea;
    } catch (e) {
      print('Error calculating IOU: $e');
      return 0.0;
    }
  }

  String _formatConditionName(String condition) {
    return DetectionUtils.formatConditionName(condition);
  }

  /// Get consistent color for a disease across all images
  /// Same disease always gets the same color
  Color _getColorForDisease(String diseaseLabel) {
    final formattedLabel = _formatConditionName(diseaseLabel);
    
    // Find the disease in analysis results to get its assigned color
    for (final result in _analysisResults) {
      if (result.condition == formattedLabel) {
        return result.color;
      }
    }
    
    // Fallback to a default color if not found in analysis results
    return const Color(0xFF9E9E9E); // Gray
  }

  /// Build disease color map for consistent coloring across all images
  Map<String, Color> _buildDiseaseColorMap() {
    final Map<String, Color> colorMap = {};
    
    for (final result in _analysisResults) {
      // Map both formatted and original labels to handle variations
      colorMap[result.condition] = result.color;
    }
    
    return colorMap;
  }

  /// Fetch skin disease information based on highest confidence detection
  Future<void> _fetchDiseaseInfo() async {
    if (_analysisResults.isEmpty) {
      return;
    }
    
    setState(() {
      _isLoadingDiseaseInfo = true;
    });
    
    try {
      // Get the highest confidence condition
      final highestConfidenceCondition = _analysisResults.first.condition;
      print('🔍 Searching for disease info for: "$highestConfidenceCondition"');
      
      // Search for the disease in the database
      final diseaseService = SkinDiseaseService();
      final allDiseases = await diseaseService.getAllDiseases();
      print('📚 Total diseases in database: ${allDiseases.length}');
      
      // Normalize the detected condition for better matching
      final normalizedCondition = _normalizeConditionName(highestConfidenceCondition);
      print('🔄 Normalized condition: "$normalizedCondition"');
      
      // Try to match by name (case-insensitive, fuzzy matching)
      SkinDiseaseModel? matchedDisease;
      
      for (var disease in allDiseases) {
        final diseaseName = disease.name.toLowerCase();
        final normalizedDiseaseName = _normalizeConditionName(disease.name);
        
        // 1. Exact normalized match
        if (normalizedDiseaseName == normalizedCondition) {
          matchedDisease = disease;
          print('✅ Found exact normalized match: "${disease.name}"');
          break;
        }
        
        // 2. Direct contains match
        if (diseaseName.contains(normalizedCondition) || 
            normalizedCondition.contains(normalizedDiseaseName)) {
          matchedDisease = disease;
          print('✅ Found contains match: "${disease.name}"');
          break;
        }
        
        // 3. Word-based matching (check if key words match)
        final conditionWords = normalizedCondition.split(' ');
        final diseaseWords = normalizedDiseaseName.split(' ');
        
        // If main word(s) match (e.g., "flea" matches "flea allergy dermatitis")
        bool hasCommonWords = conditionWords.any((word) => 
          diseaseWords.any((diseaseWord) => 
            diseaseWord.contains(word) || word.contains(diseaseWord)
          )
        );
        
        if (hasCommonWords && conditionWords.first.length > 3) {
          matchedDisease = disease;
          print('✅ Found word-based match: "${disease.name}"');
          break;
        }
      }
      
      if (matchedDisease == null) {
        print('❌ No matching disease found in database for: "$highestConfidenceCondition"');
        print('💡 Available diseases: ${allDiseases.map((d) => d.name).join(", ")}');
      }
      
      if (mounted) {
        setState(() {
          _detectedDisease = matchedDisease;
          _isLoadingDiseaseInfo = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching disease info: $e');
      if (mounted) {
        setState(() {
          _isLoadingDiseaseInfo = false;
        });
      }
    }
  }
  
  /// Normalize condition names for better matching
  /// Converts AI detection labels to searchable format
  String _normalizeConditionName(String name) {
    return name
        .toLowerCase()
        .replaceAll('_', ' ')  // feline_acne -> feline acne
        .replaceAll('-', ' ')  // hot-spot -> hot spot
        .trim();
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
    if (_isCompletingAssessment) return; // Prevent multiple taps
    
    setState(() {
      _isCompletingAssessment = true;
    });
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Completing assessment...',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      print('DEBUG: Starting assessment completion...');
      // Save assessment first
      await saveAssessment();
      print('DEBUG: Assessment saved successfully, waiting for propagation...');
      
      // Small delay to ensure Firebase write has propagated
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Invalidate assessment history cache to ensure fresh data
      await _invalidateAssessmentHistoryCache();
      print('DEBUG: Assessment history cache invalidated');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Navigate to home with history tab and force refresh with timestamp
      if (mounted) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        context.go('/home?tab=history&refresh=assessment&t=$timestamp');
        print('DEBUG: Navigation completed to /home?tab=history&refresh=assessment&t=$timestamp');
      }
    } catch (e) {
      print('Error completing assessment: $e');
      
      // Close loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing assessment: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingAssessment = false;
        });
      }
    }
  }

  Future<void> _generatePDF() async {
    if (_isGeneratingPDF) return; // Prevent multiple taps
    
    setState(() => _isGeneratingPDF = true);
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Generating PDF...',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

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

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() => _isGeneratingPDF = false);

      // Show success dialog with preview and save options
      _showPDFGeneratedDialog(filePath, pdfBytes, fileName);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'PDF generated successfully!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      // Close loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      setState(() => _isGeneratingPDF = false);
      
      print('Error generating PDF: $e');
      
      // Show error dialog
      if (mounted) {
        _showDialog(
          'Error',
          'Failed to generate PDF: ${e.toString()}',
          'OK',
          () => Navigator.of(context).pop(),
        );
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to generate PDF. Please try again.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleNewPetCreation(UserModel user) async {
    final selectedPetId = widget.assessmentData['selectedPet'] as String?;
    final newPetData = widget.assessmentData['newPetData'] != null 
        ? Map<String, dynamic>.from(widget.assessmentData['newPetData'] as Map)
        : <String, dynamic>{};
    
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
            initialAge: petAge,
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
    final newPetData = widget.assessmentData['newPetData'] != null 
        ? Map<String, dynamic>.from(widget.assessmentData['newPetData'] as Map)
        : <String, dynamic>{};
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



  void _bookAppointment() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Saving assessment...',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

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
      
      // Save assessment result to Firebase and get the document ID
      final assessmentService = AssessmentResultService();
      final assessmentResultId = await assessmentService.saveAssessmentResult(assessmentResult);

      print('✅ Assessment saved to Firebase with ID: $assessmentResultId');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Invalidate assessment history cache since we just saved an assessment
      await _invalidateAssessmentHistoryCache();
      print('DEBUG: Assessment history cache invalidated after saving for appointment booking');

      // Also invalidate appointment history cache as we're about to create an appointment
      await _invalidateAppointmentHistoryCache();
      print('DEBUG: Appointment history cache invalidated in preparation for booking');

      // Navigate to book appointment page with assessment result ID
      if (mounted) {
        context.go('/book-appointment?assessment_result_id=$assessmentResultId&skip_service=true');
      }

    } catch (e) {
      print('❌ Error saving assessment and booking appointment: $e');
      
      // Close loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error dialog
      if (mounted) {
        _showDialog(
          'Error',
          'Failed to save assessment: ${e.toString()}',
          'OK',
          () => Navigator.of(context).pop(),
        );
      }
    }
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

  // Cache invalidation methods
  Future<void> _invalidateAssessmentHistoryCache() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final cache = DataCache();
        
        // Invalidate assessment results cache
        final assessmentCacheKey = CacheKeys.userAssessments(user.uid);
        cache.invalidate(assessmentCacheKey);
        
        print('DEBUG: Assessment history cache invalidated for user: ${user.uid}');
      }
    } catch (e) {
      print('DEBUG: Error invalidating assessment history cache: $e');
    }
  }

  Future<void> _invalidateAppointmentHistoryCache() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final cache = DataCache();
        
        // Invalidate appointment history cache using the same pattern as home_page.dart
        final appointmentCacheKey = 'user_appointments_${user.uid}';
        cache.invalidate(appointmentCacheKey);
        
        print('DEBUG: Appointment history cache invalidated for user: ${user.uid}');
      }
    } catch (e) {
      print('DEBUG: Error invalidating appointment history cache: $e');
    }
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
            padding: const EdgeInsets.all(kSpacingSmall),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 0, 0),
                  child: Text(
                    'Differential Analysis Results',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                
                // Pie Chart
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _analysisResults.length == 1
                            ? // Single result - center the percentage inside
                            Stack(
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sections: _analysisResults.map((result) {
                                        return PieChartSectionData(
                                          color: result.color,
                                          value: result.percentage,
                                          title: '', // Remove title from pie section for single result
                                          radius: 60,
                                        );
                                      }).toList(),
                                      borderData: FlBorderData(show: false),
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 0,
                                    ),
                                  ),
                                  // Centered percentage overlay for single result
                                  Center(
                                    child: Text(
                                      '${_analysisResults.first.percentage.toStringAsFixed(1)}%',
                                      style: kMobileTextStyleTitle.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : // Multiple results - show pie chart with side labels
                            PieChart(
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
                      const SizedBox(width: kSpacingMedium),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: kSpacingSmall),
          
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
          _buildRemediesSection(),
          const SizedBox(height: kSpacingMedium),
          
          // Action Buttons
          Column(
            children: [
              PrimaryButton(
                text: 'Download as PDF',
                icon: Icons.download,
                onPressed: _generatePDF,
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

            // Get top 3 UNIQUE detections for this image (filtered for duplicates and threshold)
            const double CONFIDENCE_THRESHOLD = 0.0; // 50% minimum confidence
            const double IOU_THRESHOLD = 0.5; // For duplicate detection
            const int MAX_DETECTIONS_PER_IMAGE = 3;
            
            List<Map<String, dynamic>> detectionsToShow = [];
            Set<String> seenDiseases = {}; // Track unique disease names
            
            if (allDetections.isNotEmpty) {
              // Sort by confidence descending
              final sortedDetections = List<Map<String, dynamic>>.from(allDetections);
              sortedDetections.sort((a, b) => 
                (b['confidence'] as double).compareTo(a['confidence'] as double)
              );
              
              // Filter duplicates and apply threshold
              for (final detection in sortedDetections) {
                final confidence = detection['confidence'] as double? ?? 0.0;
                
                // Skip if below threshold
                if (confidence < CONFIDENCE_THRESHOLD) continue;
                
                final label = detection['label'] as String;
                final formattedLabel = _formatConditionName(label);
                
                // Skip if we've already seen this disease
                if (seenDiseases.contains(formattedLabel)) {
                  continue;
                }
                
                bool isDuplicate = false;
                final box = detection['box'] as List?;
                
                // Check for duplicates (same disease at overlapping location)
                for (final existing in detectionsToShow) {
                  final existingLabel = existing['label'] as String;
                  final existingBox = existing['box'] as List?;
                  
                  if (label == existingLabel) {
                    if (box != null && existingBox != null && box.length >= 4 && existingBox.length >= 4) {
                      final iou = _calculateIOU(
                        [box[0], box[1], box[2], box[3]],
                        [existingBox[0], existingBox[1], existingBox[2], existingBox[3]],
                      );
                      
                      if (iou > IOU_THRESHOLD) {
                        isDuplicate = true;
                        break;
                      }
                    }
                  }
                }
                
                if (!isDuplicate) {
                  detectionsToShow.add(detection);
                  seenDiseases.add(formattedLabel); // Mark this disease as seen
                  
                  if (detectionsToShow.length >= MAX_DETECTIONS_PER_IMAGE) {
                    break;
                  }
                }
              }
            }

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
                                            ? '${detectionsToShow.length} Detection${detectionsToShow.length > 1 ? 's' : ''}'
                                            : '${detectionsToShow.length} Detection${detectionsToShow.length > 1 ? 's' : ''} Available',
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
                            ...detectionsToShow.asMap().entries.map((entry) {
                              final int detectionIndex = entry.key;
                              final detection = entry.value;
                              final String condition = detection['label'];
                              final double confidence = detection['confidence'];
                              
                              // Get color based on disease type (same disease = same color across all images)
                              final detectionColor = _getColorForDisease(condition);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: detectionColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: detectionColor.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: kSpacingSmall),
                                    Expanded(
                                      child: Text(
                                        _formatConditionName(condition),
                                        style: kMobileTextStyleLegend.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: detectionIndex == 0 
                                              ? FontWeight.w600 
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: detectionColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: detectionColor.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        '${(confidence * 100).toStringAsFixed(1)}%',
                                        style: kMobileTextStyleLegend.copyWith(
                                          color: detectionColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
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

  Widget _buildRemediesSection() {
    // Don't show remedies if no skin diseases were detected
    if (_analysisResults.isEmpty || 
        (_analysisResults.length == 1 && 
         (_analysisResults.first.condition == 'No high-confidence detections' ||
          _analysisResults.first.condition == 'No skin disease detected'))) {
      return const SizedBox.shrink();
    }
    
    // Check if we have disease info with remedies
    final hasRemedies = _detectedDisease?.initialRemedies != null;
    final remedies = _detectedDisease?.initialRemedies;
    
    return Container(
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
                  Expanded(
                    child: Text(
                      'Initial Remedies & Suggestions',
                      style: kMobileTextStyleTitle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (_isLoadingDiseaseInfo)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  else
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
              child: hasRemedies
                  ? _buildDynamicRemedies(remedies!)
                  : _buildPlaceholderRemedies(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDynamicRemedies(Map<String, dynamic> remedies) {
    final List<Widget> remedyWidgets = [];
    
    // Immediate Care
    if (remedies.containsKey('immediateCare')) {
      final immediateCare = remedies['immediateCare'] as Map<String, dynamic>;
      final actions = List<String>.from(immediateCare['actions'] ?? []);
      remedyWidgets.add(_buildRemedyItem(
        Icons.local_hospital,
        immediateCare['title'] ?? 'Immediate Care',
        actions.join('\n• '),
        isListFormat: true,
      ));
    }
    
    // Topical Treatment / Environmental Disinfection
    if (remedies.containsKey('topicalTreatment')) {
      final topicalTreatment = remedies['topicalTreatment'] as Map<String, dynamic>;
      final actions = List<String>.from(topicalTreatment['actions'] ?? []);
      final note = topicalTreatment['note'] as String?;
      
      String content = actions.join('\n• ');
      if (note != null && note.isNotEmpty) {
        content += '\n\n⚠️ Note: $note';
      }
      
      remedyWidgets.add(_buildRemedyItem(
        Icons.medication,
        topicalTreatment['title'] ?? 'Treatment',
        content,
        isListFormat: true,
      ));
    }
    
    // Monitoring
    if (remedies.containsKey('monitoring')) {
      final monitoring = remedies['monitoring'] as Map<String, dynamic>;
      final actions = List<String>.from(monitoring['actions'] ?? []);
      remedyWidgets.add(_buildRemedyItem(
        Icons.schedule,
        monitoring['title'] ?? 'Monitor Progress',
        actions.join('\n• '),
        isListFormat: true,
      ));
    }
    
    // When to Seek Help
    if (remedies.containsKey('whenToSeekHelp')) {
      final whenToSeekHelp = remedies['whenToSeekHelp'] as Map<String, dynamic>;
      final actions = List<String>.from(whenToSeekHelp['actions'] ?? []);
      final urgency = whenToSeekHelp['urgency'] as String?;
      
      String content = actions.join('\n• ');
      if (urgency != null) {
        content = '⏰ Urgency: ${urgency.replaceAll('_', ' ')}\n\n$content';
      }
      
      remedyWidgets.add(_buildRemedyItem(
        Icons.warning,
        whenToSeekHelp['title'] ?? 'When to Seek Help',
        content,
        isListFormat: true,
        isWarning: true,
      ));
    }
    
    return Column(children: remedyWidgets);
  }
  
  Widget _buildPlaceholderRemedies() {
    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(kSpacingMedium),
          margin: const EdgeInsets.only(bottom: kSpacingMedium),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: kSpacingSmall),
              Expanded(
                child: Text(
                  'Specific remedies for this condition are being updated. Please follow general care guidelines below.',
                  style: kMobileTextStyleLegend.copyWith(
                    color: AppColors.info,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Generic remedies
        _buildRemedyItem(
          Icons.local_hospital,
          'Immediate Care',
          '• Keep the affected area clean and dry\n• Prevent your pet from scratching or licking the area\n• Avoid applying any products without vet approval\n• Document symptoms with photos for your vet',
          isListFormat: true,
        ),
        _buildRemedyItem(
          Icons.schedule,
          'Monitor Progress',
          '• Track symptoms daily and note any changes\n• Take photos to monitor progression\n• Keep a log of your pet\'s behavior and appetite\n• Note if symptoms worsen or improve',
          isListFormat: true,
        ),
        _buildRemedyItem(
          Icons.warning,
          'When to Seek Help',
          '⏰ Consult a veterinarian immediately if:\n\n• Symptoms worsen or spread rapidly\n• Your pet shows signs of pain or distress\n• The affected area becomes infected\n• Symptoms persist beyond 7 days',
          isListFormat: true,
          isWarning: true,
        ),
      ],
    );
  }

  Widget _buildRemedyItem(
    IconData icon, 
    String title, 
    String description, {
    bool isListFormat = false,
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(kSpacingSmall),
            decoration: BoxDecoration(
              color: (isWarning ? AppColors.error : AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: Icon(
              icon,
              color: isWarning ? AppColors.error : AppColors.primary,
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: kSpacingXSmall),
                Text(
                  isListFormat ? '• $description' : description,
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
