import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: kTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage your account and clinic configuration',
              style: TextStyle(
                fontSize: kFontSizeRegular-2,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      
      ],
    );
  }
}
