import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class AssessmentProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AssessmentProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final stepLabels = ['General Information', 'Scan', 'Results'];

    return Column(
      children: [
        Row(
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              stepLabels[currentStep],
              style: kMobileTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: kMobileSizedBoxMedium),
        LinearProgressIndicator(
          value: (currentStep + 1) / totalSteps,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
        ),
      ],
    );
  }
}
