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
          if (assessment.analysisResults.isNotEmpty) 
            _buildAnalysisResultsCard(assessment),
          
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
              onPressed: _isGeneratingPDF ? null : _generatePDF,
              isLoading: _isGeneratingPDF,
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
                return Container(
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
                    child: Image.network(
                      assessment.imageUrls[index],
                      fit: BoxFit.cover,
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
    // Get only the highest confidence detection
    final highestDetection = _getHighestConfidenceDetection(detectionResult);
    
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
        if (highestDetection != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DetectionUtils.formatConditionName(highestDetection.label),
                              style: kMobileTextStyleTitle.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Highest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confidence: ${(highestDetection.confidence * 100).toStringAsFixed(1)}%',
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: highestDetection.confidence,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(highestDetection.confidence),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildAnalysisResultsCard(AssessmentResult assessment) {
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
                Icons.analytics,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Text(
                'Analysis Results',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          ...assessment.analysisResults.map((analysis) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis.condition,
                          style: kMobileTextStyleTitle.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: analysis.percentage / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(analysis.colorHex.substring(1), radix: 16) + 0xFF000000),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: kMobileSizedBoxMedium),
                            Text(
                              '${analysis.percentage.toStringAsFixed(1)}%',
                              style: kMobileTextStyleSubtitle.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
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

  /// Get only the highest confidence detection from a DetectionResult
  Detection? _getHighestConfidenceDetection(DetectionResult detectionResult) {
    if (detectionResult.detections.isEmpty) return null;
    
    // Sort by confidence and return the highest
    final sortedDetections = List<Detection>.from(detectionResult.detections);
    sortedDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return sortedDetections.first;
  }

  Future<void> _generatePDF() async {
    if (_assessmentResult == null || _isGeneratingPDF) return;
    
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

      // Generate PDF using the existing assessment result
      final pdfBytes = await PDFGenerationService.generateAssessmentPDF(
        user: userModel,
        assessmentResult: _assessmentResult!,
      );

      // Save PDF to device
      final fileName = 'PawSense_Assessment_${_assessmentResult!.petName}_${DateTime.now().millisecondsSinceEpoch}';
      final filePath = await PDFGenerationService.savePDFToDevice(pdfBytes, fileName);

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
