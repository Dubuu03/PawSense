import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class SupportHeader extends StatelessWidget {
  const SupportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Center',
          style: kTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
            ),
        ),
        SizedBox(height: kSpacingSmall),
        Text(
          'Manage customer inquiries and provide assistance',
          style: TextStyle(
            fontSize: kFontSizeRegular-2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}