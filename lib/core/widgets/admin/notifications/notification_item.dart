import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class NotificationItem extends StatelessWidget {
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isEmergency;
  final bool isUnread;
  final bool requiresAction;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final VoidCallback? onAction;
  final String? actionButtonText;
  final IconData icon;
  final Color iconColor;
  final Map<String, String>? details;

  const NotificationItem({
    super.key,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isEmergency = false,
    this.isUnread = false,
    this.requiresAction = false,
    required this.onMarkRead,
    required this.onDelete,
    this.onAction,
    this.actionButtonText,
    required this.icon,
    required this.iconColor,
    this.details,
  });

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colored border (only for unread messages)
            if (isUnread)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isEmergency 
                      ? AppColors.error 
                      : requiresAction 
                          ? AppColors.warning 
                          : AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kBorderRadius),
                    bottomLeft: Radius.circular(kBorderRadius),
                  ),
                ),
              ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(kSpacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon, title, badges, and actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(kSpacingSmall),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          ),
                          child: Icon(icon, color: iconColor, size: kIconSizeMedium),
                        ),
                        SizedBox(width: kSpacingMedium),
                        // Title and badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: kTextStyleLarge.copyWith(
                                        fontSize: kFontSizeRegular,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (requiresAction) ...[
                                    Padding(
                                      padding: EdgeInsets.only(top: kSpacingSmall, right: kSpacingSmall),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: kSpacingSmall,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(kBorderRadius),
                                        ),
                                        child: Text(
                                          'Action Required',
                                          style: kTextStyleSmall.copyWith(
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                description,
                                style: kTextStyleRegular.copyWith(
                                  fontSize: kFontSizeRegular - 2,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Timestamp and actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: kIconSizeSmall,
                                  color: AppColors.textTertiary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _getTimeAgo(),
                                  style: kTextStyleSmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                SizedBox(width: kSpacingSmall),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: kIconSizeSmall,
                                    color: AppColors.textTertiary,
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: kIconSizeSmall,
                                            color: AppColors.error,
                                          ),
                                          SizedBox(width: kSpacingSmall),
                                          Text(
                                            'Delete',
                                            style: kTextStyleRegular.copyWith(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') onDelete();
                                  },
                                ),
                              ],
                            ),
                            if (isUnread) ...[
                              SizedBox(height: kSpacingSmall),
                              TextButton(
                                onPressed: onMarkRead,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: kSpacingMedium,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  'Mark as read',
                                  style: kTextStyleSmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    
                    // Details section
                    if (details != null) ...[
                      SizedBox(height: kSpacingMedium),
                      Container(
                        padding: EdgeInsets.all(kSpacingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: details!.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: entry == details!.entries.last ? 0 : kSpacingSmall,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '${entry.key}:',
                                      style: kTextStyleSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: kTextStyleSmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (entry.key.toLowerCase().contains('contact') || 
                                      entry.key.toLowerCase().contains('phone'))
                                    Icon(
                                      Icons.phone,
                                      size: kIconSizeSmall,
                                      color: AppColors.textTertiary,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Action buttons
                    if (requiresAction && onAction != null) ...[
                      SizedBox(height: kSpacingMedium),
                      Row(
                        children: [
                          if (isEmergency)
                            ElevatedButton(
                              onPressed: onAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: kSpacingMedium,
                                  vertical: kSpacingMedium,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                ),
                              ),
                              child: Text(
                                'Emergency Response',
                                style: kTextStyleRegular.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            )
                          else ...[
                            ElevatedButton(
                              onPressed: onAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: kSpacingMedium,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                ),
                              ),
                              child: Text(
                                'Approve',
                                style: kTextStyleRegular.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: kSpacingMedium),
                            OutlinedButton(
                              onPressed: () {
                                // TODO: Handle decline action - integrate with Firebase
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: BorderSide(color: AppColors.error),
                                padding: EdgeInsets.symmetric(
                                  horizontal: kSpacingMedium,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                                ),
                              ),
                              child: Text(
                                'Decline',
                                style: kTextStyleRegular.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
