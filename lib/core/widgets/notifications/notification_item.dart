import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';

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
    Key? key,
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
  }) : super(key: key);

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
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getTimeAgo(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    if (details != null) ...[
                      SizedBox(height: 12),
                      ...details!.entries.map((entry) => Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (requiresAction || isUnread) ...[
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUnread)
                  TextButton(
                    onPressed: onMarkRead,
                    child: Text('Mark as read'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                if (requiresAction && onAction != null) ...[
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionButtonText ?? 'Take Action'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmergency ? Colors.red : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                SizedBox(width: 12),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
