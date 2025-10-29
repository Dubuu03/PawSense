import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';
import 'package:pawsense/core/services/user/assessment_result_service.dart';
import 'package:pawsense/core/utils/detection_utils.dart';
import 'package:pawsense/core/services/user/pdf_generation_service.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';
import 'package:pawsense/core/services/user/user_services.dart';
import 'package:pawsense/core/widgets/shared/buttons/primary_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:typed_data';

class AIHistoryDetailPage extends StatefulWidget {
  final String aiHistoryId;

  const AIHistoryDetailPage({
    super.key,
    required this.aiHistoryId,
  });

  @override
  State<AIHistoryDetailPage> createState() => _AIHistoryDetailPageState();
}

class _AIHistoryDetailPageState extends State<AIHistoryDetailPage> {
  AssessmentResult? _assessmentResult;
  bool _loading = true;
  bool _isGeneratingPDF = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssessmentData();
  }

  Future<void> _loadAssessmentData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Extract assessment ID from the AI history ID
      // Format: "assessmentId_detectionIndex" or "assessmentId_no_detections"
      final assessmentId = widget.aiHistoryId.split('_').first;
      
      final assessmentService = AssessmentResultService();
      final result = await assessmentService.getAssessmentResultById(assessmentId);
      
      setState(() {
        _assessmentResult = result;
        _loading = false;
      });
    } catch (e) {
      print('Error loading assessment data: $e');
      setState(() {
        _error = 'Failed to load assessment details: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Assessment Details',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _assessmentResult == null
                  ? _buildNotFoundState()
                  : _buildDetailContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Error Loading Assessment',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            _error!,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kMobilePaddingLarge),
          ElevatedButton(
            onPressed: () => _loadAssessmentData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: kMobilePaddingLarge,
                vertical: kMobilePaddingMedium,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Assessment Not Found',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'The requested assessment details could not be found.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kMobilePaddingLarge),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: kMobilePaddingLarge,
                vertical: kMobilePaddingMedium,
              ),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    final assessment = _assessmentResult!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: kMobileSizedBoxLarge),
          // Header Card - Pet and Assessment Info
          _buildHeaderCard(assessment),
          
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Assessment Images
          if (assessment.imageUrls.isNotEmpty)
            _buildImagesCard(assessment),
          
          if (assessment.imageUrls.isNotEmpty)
            const SizedBox(height: kMobileSizedBoxLarge),
          
          // Symptoms
          if (assessment.symptoms.isNotEmpty)
            _buildSymptomsCard(assessment),
          
          if (assessment.symptoms.isNotEmpty)
            const SizedBox(height: kMobileSizedBoxLarge),
          
          // Detection Results
          if (assessment.detectionResults.isNotEmpty)
            _buildDetectionResultsCard(assessment),
          
          if (assessment.detectionResults.isNotEmpty)
            const SizedBox(height: kMobileSizedBoxLarge),
          
          // Analysis Results
          // if (assessment.analysisResults.isNotEmpty) 
          //   _buildAnalysisResultsCard(assessment),
          
          if (assessment.analysisResults.isNotEmpty)
            const SizedBox(height: kMobileSizedBoxLarge),
          
          // Notes
          if (assessment.notes.isNotEmpty)
            _buildNotesCard(assessment),
          
          if (assessment.notes.isNotEmpty)
            const SizedBox(height: kMobileSizedBoxLarge),
          
          // PDF Download Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
            child: PrimaryButton(
              text: 'Download as PDF',
              icon: Icons.download,
              onPressed: _generatePDF,
            ),
          ),
          
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Book Appointment Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
            child: OutlinedButton.icon(
              onPressed: () => _bookAppointment(assessment),
              icon: Icon(Icons.calendar_today, color: AppColors.primary),
              label: Text(
                'Book Appointment',
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: kMobilePaddingMedium,
                  horizontal: kMobilePaddingLarge,
                ),
                minimumSize: const Size(double.infinity, 48.0),
              ),
            ),
          ),
          
          const SizedBox(height: kMobilePaddingLarge),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(AssessmentResult assessment) {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                Icons.pets,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                'Pet Assessment',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTimestamp(assessment.createdAt),
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildPetInfoRow('Pet Name', assessment.petName),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildPetInfoRow('Type', assessment.petType),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildPetInfoRow('Breed', assessment.petBreed),
          const SizedBox(height: kMobileSizedBoxMedium),
          Row(
            children: [
              Expanded(child: _buildPetInfoRow('Age', '${assessment.petAge} ${assessment.petAge == 1 ? 'year' : 'years'}')),
              const SizedBox(width: kMobileSizedBoxLarge),
              Expanded(child: _buildPetInfoRow('Weight', '${assessment.petWeight} kg')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: kMobileSizedBoxMedium),
        Expanded(
          child: Text(
            value,
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesCard(AssessmentResult assessment) {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                Icons.photo_library,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                'Assessment Images',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: assessment.imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullscreenImage(assessment.imageUrls[index], index, assessment),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < assessment.imageUrls.length - 1 ? kMobileSizedBoxMedium : 0,
                    ),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        children: [
                          Image.network(
                            assessment.imageUrls[index],
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.border,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.textSecondary,
                                  size: 40,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColors.border,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Subtle tap indicator overlay
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard(AssessmentResult assessment) {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                Icons.medical_services,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                'Reported Symptoms',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: assessment.symptoms.map((symptom) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Text(
                  symptom,
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionResultsCard(AssessmentResult assessment) {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                Icons.visibility,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                'AI Detection Results',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          ...assessment.detectionResults.asMap().entries.map((entry) {
            final index = entry.key;
            final detectionResult = entry.value;
            
            return Column(
              children: [
                if (index > 0) const SizedBox(height: kMobileSizedBoxLarge),
                _buildDetectionResultItem(detectionResult, index),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetectionResultItem(DetectionResult detectionResult, int index) {
    // Get top 3 UNIQUE detections sorted by confidence (no duplicate diseases)
    const int MAX_DETECTIONS_TO_SHOW = 3;
    final sortedDetections = List<Detection>.from(detectionResult.detections);
    sortedDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Filter for unique diseases only
    final List<Detection> detectionsToShow = [];
    final Set<String> seenDiseases = {};
    
    for (final detection in sortedDetections) {
      final formattedLabel = DetectionUtils.formatConditionName(detection.label);
      if (!seenDiseases.contains(formattedLabel)) {
        detectionsToShow.add(detection);
        seenDiseases.add(formattedLabel);
        
        if (detectionsToShow.length >= MAX_DETECTIONS_TO_SHOW) {
          break;
        }
      }
    }
    
    // Define rank-based colors matching the UI
    final rankColors = [
      const Color(0xFFFF9500), // Orange - Highest (1st)
      const Color(0xFF007AFF), // Blue - Second (2nd)
      const Color(0xFF34C759), // Green - Third (3rd)
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image ${index + 1}',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: kMobileSizedBoxMedium),
        if (detectionsToShow.isNotEmpty) ...[
          // Show all detections (up to 3)
          ...detectionsToShow.asMap().entries.map((entry) {
            final detectionIndex = entry.key;
            final detection = entry.value;
            final detectionColor = rankColors[detectionIndex % rankColors.length];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Rank indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: detectionColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: detectionColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${detectionIndex + 1}',
                        style: kMobileTextStyleLegend.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DetectionUtils.formatConditionName(detection.label),
                          style: kMobileTextStyleTitle.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: detectionIndex == 0 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.show_chart,
                              size: 12,
                              color: _getConfidenceColor(detection.confidence),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                              style: kMobileTextStyleSubtitle.copyWith(
                                color: _getConfidenceColor(detection.confidence),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Confidence bar
                  Container(
                    width: 40,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: detection.confidence,
                      child: Container(
                        decoration: BoxDecoration(
                          color: detectionColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: kMobileSizedBoxMedium),
                Text(
                  'No conditions detected',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesCard(AssessmentResult assessment) {
    return Container(
      margin: kMobileMarginCard,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
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
                Icons.note,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                'Additional Notes',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              assessment.notes,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppColors.success;
    } else if (confidence >= 0.6) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Show fullscreen image viewer
  void _showFullscreenImage(String imageUrl, int index, AssessmentResult assessment) {
    // Get detections for this specific image
    List<Map<String, dynamic>> detectionsToShow = [];
    if (index < assessment.detectionResults.length) {
      final detectionResult = assessment.detectionResults[index];
      // Get top 3 UNIQUE detections sorted by confidence (no duplicate diseases)
      const int MAX_DETECTIONS_TO_SHOW = 3;
      final sortedDetections = List<Detection>.from(detectionResult.detections);
      sortedDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // Filter for unique diseases only
      final List<Detection> uniqueDetections = [];
      final Set<String> seenDiseases = {};
      
      for (final detection in sortedDetections) {
        final formattedLabel = DetectionUtils.formatConditionName(detection.label);
        if (!seenDiseases.contains(formattedLabel)) {
          uniqueDetections.add(detection);
          seenDiseases.add(formattedLabel);
          
          if (uniqueDetections.length >= MAX_DETECTIONS_TO_SHOW) {
            break;
          }
        }
      }
      
      // Convert Detection objects to Map format for BoundingBoxPainter
      detectionsToShow = uniqueDetections.map((detection) {
        return {
          'label': detection.label,
          'confidence': detection.confidence,
          'box': detection.boundingBox,
        };
      }).toList();
    }
    
    // State variable must be outside the builder to persist across rebuilds
    bool showingBoundingBoxes = detectionsToShow.isNotEmpty; // Show by default if detections exist
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                children: [
                  // Fullscreen image with bounding boxes
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: GestureDetector(
                        onTap: () {}, // Prevent dialog close when tapping image
                        child: Stack(
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(kMobilePaddingLarge),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                      const SizedBox(height: kMobileSizedBoxMedium),
                                      Text(
                                        'Failed to load image',
                                        style: kMobileTextStyleTitle.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: AppColors.primary,
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
                                        strokeWidth: 4.0,
                                        showLabels: true,
                                        showConfidence: true,
                                        originalImageWidth: 640.0,
                                        originalImageHeight: 640.0,
                                        useRankColors: true, // Enable color-coding for top 3
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
                            ),
                          ),
                        ),
                        
                        // Bounding box toggle button (only show if detections exist)
                        if (detectionsToShow.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: showingBoundingBoxes 
                                  ? AppColors.primary.withOpacity(0.9)
                                  : Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  showingBoundingBoxes = !showingBoundingBoxes;
                                });
                              },
                              icon: Icon(
                                showingBoundingBoxes 
                                    ? Icons.visibility 
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              tooltip: showingBoundingBoxes 
                                  ? 'Hide Detections' 
                                  : 'Show Detections',
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Bottom info panel
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Detection info badge (always visible when detections exist)
                        if (detectionsToShow.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${detectionsToShow.length} Detection${detectionsToShow.length > 1 ? 's' : ''} Found',
                                      style: kMobileTextStyleSubtitle.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        
                        // Image counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${index + 1} / ${assessment.imageUrls.length}',
                            style: kMobileTextStyleSubtitle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generatePDF() async {
    if (_assessmentResult == null || _isGeneratingPDF) return;
    
    setState(() => _isGeneratingPDF = true);
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(kMobilePaddingLarge),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: kMobileSizedBoxLarge),
                  Text(
                    'Generating PDF...',
                    style: kMobileTextStyleTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: kMobileSizedBoxMedium),
                  Text(
                    'Please wait while we create your assessment report',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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

      // Generate PDF using the existing assessment result
      final pdfBytes = await PDFGenerationService.generateAssessmentPDF(
        user: userModel,
        assessmentResult: _assessmentResult!,
      );

      // Save PDF to device
      final fileName = 'PawSense_Assessment_${_assessmentResult!.petName}_${DateTime.now().millisecondsSinceEpoch}';
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
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _bookAppointment(AssessmentResult assessment) {
    // Navigate to book appointment page with assessment result ID and skip service selection
    if (assessment.id != null && assessment.id!.isNotEmpty) {
      context.go('/book-appointment?assessment_result_id=${assessment.id}&skip_service=true&from=history');
    } else {
      // Show error if assessment ID is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to link assessment to appointment. Assessment ID not found.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
}
