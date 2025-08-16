import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class ConfidenceIndicator extends StatelessWidget {
  final int percentage;
  final String label;

  const ConfidenceIndicator({
    super.key,
    required this.percentage,
    required this.label,
  });

  Color get confidenceColor {
    if (percentage >= 95) return AppColors.success;
    if (percentage >= 85) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Disease Detection',
              style: TextStyle(
                fontSize: kFontSizeSmall,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage% confidence',
              style: TextStyle(
                fontSize: kFontSizeSmall,
                color: confidenceColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: kFontSizeRegular,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}