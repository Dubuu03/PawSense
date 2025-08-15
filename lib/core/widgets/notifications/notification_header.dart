import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';

class NotificationHeader extends StatelessWidget {
  final int unreadCount;
  final int actionRequired;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSettings;

  const NotificationHeader({
    Key? key,
    required this.unreadCount,
    required this.actionRequired,
    required this.onMarkAllRead,
    required this.onSettings,
  }) : super(key: key);

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$unreadCount unread notifications',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (actionRequired > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$actionRequired action required',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
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
              icon: Icon(Icons.done_all, color: AppColors.primary),
              label: Text(
                'Mark All Read',
                style: TextStyle(color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onSettings,
              icon: Icon(Icons.settings, color: Colors.white),
              label: Text('Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
