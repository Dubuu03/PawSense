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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                      ? Colors.red 
                      : requiresAction 
                          ? Colors.orange 
                          : AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with icon, title, badges, and actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        SizedBox(width: 12),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.grey[900],
                                      ),
                                    ),
                                  ),
                                 if (requiresAction) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, right: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Action Required',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
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
                                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                SizedBox(width: 4),
                                Text(
                                  _getTimeAgo(),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[500]),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
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
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: onMarkRead,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  'Mark as read',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    
                    // Details section
                    if (details != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: details!.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: entry == details!.entries.last ? 0 : 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '${entry.key}:',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  if (entry.key.toLowerCase().contains('contact') || 
                                      entry.key.toLowerCase().contains('phone'))
                                    Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Action buttons
                    if (requiresAction && onAction != null) ...[
                      SizedBox(height: 16),
                      Row(
                        children: [
                          if (isEmergency)
                            ElevatedButton(
                              onPressed: onAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Emergency Response',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            )
                          else ...[
                            ElevatedButton(
                              onPressed: onAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Approve',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                // Handle decline action
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Decline',
                                style: TextStyle(fontWeight: FontWeight.w600),
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
