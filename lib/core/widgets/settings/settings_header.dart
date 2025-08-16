import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({Key? key}) : super(key: key);

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
              style: TextStyle(
                fontSize: kFontSizeLarge,
                fontWeight: FontWeight.w700,
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
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Clinic Status:',
                    style: TextStyle(
                      fontSize: kFontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: kFontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: kSpacingMedium),
            ElevatedButton.icon(
              onPressed: (){},
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }
}
