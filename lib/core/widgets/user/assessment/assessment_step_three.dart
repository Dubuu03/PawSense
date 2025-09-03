import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/shared/buttons/primary_button.dart';

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
  
  // Mock analysis results - in a real app, this would come from AI analysis
  final List<AnalysisResult> _analysisResults = [
    AnalysisResult(condition: 'Mange', percentage: 35.5, color: const Color(0xFFFF9500)),
    AnalysisResult(condition: 'Ringworm', percentage: 28.2, color: const Color(0xFF007AFF)),
    AnalysisResult(condition: 'Dermatitis', percentage: 20.3, color: const Color(0xFF34C759)),
    AnalysisResult(condition: 'Allergic Reaction', percentage: 16.0, color: const Color(0xFFFF3B30)),
  ];

  Future<void> _generatePDF() async {
    setState(() => _isGeneratingPDF = true);
    
    // Simulate PDF generation
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isGeneratingPDF = false);
    
    // Show success dialog
    _showDialog(
      'PDF Generated',
      'Assessment report has been saved to your downloads folder.',
      'OK',
      () => Navigator.of(context).pop(),
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
