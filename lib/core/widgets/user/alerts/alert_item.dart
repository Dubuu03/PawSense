import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

enum AlertType {
  appointment,
  reschedule,
  declined,
  reappointment,
  systemUpdate,
}

class AlertData {
  final String title;
  final String subtitle;
  final AlertType type;
  final DateTime timestamp;
  final bool isRead;

  AlertData({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

class AlertItem extends StatelessWidget {
  final AlertData alert;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const AlertItem({
    super.key,
    required this.alert,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: kMobileBorderRadiusCardPreset,
          child: Padding(
            padding: kMobilePaddingCard,
            child: Row(
              children: [
                // Alert Icon
                Container(
                  width: kMobileIconContainerSize,
                  height: kMobileIconContainerSize,
                  decoration: BoxDecoration(
                    color: _getAlertColor().withValues(alpha: 0.1),
                    borderRadius: kMobileBorderRadiusIconPreset,
                  ),
                  child: Icon(
                    _getAlertIcon(),
                    color: _getAlertColor(),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: kMobileSizedBoxLarge),
                
                // Alert Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.subtitle,
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mark as Read Button
                if (!alert.isRead && onMarkAsRead != null) ...[
                  const SizedBox(width: kMobileSizedBoxMedium),
                  TextButton(
                    onPressed: onMarkAsRead,
                    style: TextButton.styleFrom(
                      padding: kMobileButtonPadding,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Mark read',
                      style: kMobileTextStyleViewAll.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAlertColor() {
    switch (alert.type) {
      case AlertType.appointment:
        return AppColors.success;
      case AlertType.reschedule:
        return AppColors.info;
      case AlertType.declined:
        return AppColors.error;
      case AlertType.reappointment:
        return AppColors.warning;
      case AlertType.systemUpdate:
        return AppColors.primary;
    }
  }

  IconData _getAlertIcon() {
    switch (alert.type) {
      case AlertType.appointment:
        return Icons.check_circle_outline;
      case AlertType.reschedule:
        return Icons.schedule;
      case AlertType.declined:
        return Icons.cancel_outlined;
      case AlertType.reappointment:
        return Icons.warning_amber_outlined;
      case AlertType.systemUpdate:
        return Icons.info_outline;
    }
  }
}
