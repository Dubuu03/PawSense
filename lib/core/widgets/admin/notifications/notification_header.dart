import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class NotificationHeader extends StatelessWidget {
  final int unreadCount;
  final int actionRequired;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSettings;

  const NotificationHeader({
    super.key,
    required this.unreadCount,
    required this.actionRequired,
    required this.onMarkAllRead,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: kTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Row(
              children: [
                Text(
                  '$unreadCount unread notifications',
                  style: kTextStyleRegular.copyWith(
                    fontSize: kFontSizeRegular - 2,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (actionRequired > 0) ...[
                  SizedBox(width: kSpacingSmall),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: kSpacingSmall,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    ),
                    child: Text(
                      '$actionRequired action required',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: onMarkAllRead,
              icon: Icon(
                Icons.done_all,
                color: AppColors.primary,
                size: kIconSizeMedium,
              ),
              label: Text(
                'Mark All Read',
                style: kTextStyleRegular.copyWith(
                  color: AppColors.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: kSpacingMedium,
                  vertical: kSpacingMedium,
                ),
              ),
            ),
            SizedBox(width: kSpacingMedium),
            ElevatedButton.icon(
              onPressed: onSettings,
              icon: Icon(
                Icons.settings,
                color: AppColors.white,
                size: kIconSizeMedium,
              ),
              label: Text(
                'Settings',
                style: kTextStyleRegular.copyWith(
                  color: AppColors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: kSpacingMedium,
                  vertical: kSpacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
