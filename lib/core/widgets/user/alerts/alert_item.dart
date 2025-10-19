import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pawsense/core/utils/app_colors.dart';

enum AlertType {
  appointment,
  appointmentPending,
  message,
  task,
  reschedule,
  declined,
  reappointment,
  followUp,
  systemUpdate,
}

class AlertData {
  final String id;
  final String title;
  final String subtitle;
  final AlertType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final String? actionLabel;
  final Map<String, dynamic>? metadata;

  AlertData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.actionLabel,
    this.metadata,
  });

  /// Get time ago string (e.g., "2h ago", "3 days ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    }
  }
}

class AlertItem extends StatelessWidget {
  final AlertData alert;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const AlertItem({
    super.key,
    required this.alert,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final alertContent = Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: !alert.isRead
            ? Border(
                left: BorderSide(
                  color: _getAlertColor(),
                  width: 3,
                ),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Compact Alert Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getAlertColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getAlertIcon(),
                    color: _getAlertColor(),
                    size: 16,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Compact Alert Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 11,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            alert.timeAgo,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Compact trailing icon and unread indicator
                Column(
                  children: [
                    if (!alert.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getAlertColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with Slidable if this is a message alert and onDelete is provided
    if (alert.type == AlertType.message && onDelete != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Slidable(
          key: ValueKey(alert.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            dismissible: DismissiblePane(onDismissed: () {
              onDelete?.call();
            }),
            children: [
              SlidableAction(
                onPressed: (context) {
                  onDelete?.call();
                },
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ],
          ),
          child: alertContent,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: alertContent,
    );
  }

  Color _getAlertColor() {
    // Check for auto-cancelled appointments (RED color, no emoji)
    if (alert.metadata?['isAutoCancelled'] == true) {
      return AppColors.error; // RED for auto-cancelled
    }
    
    // Check for no-show appointments (ORANGE color)
    if (alert.metadata?['isNoShow'] == true) {
      return const Color(0xFFFF9800); // ORANGE for no-show
    }
    
    switch (alert.type) {
      case AlertType.appointment:
        return AppColors.success;
      case AlertType.appointmentPending:
        return Colors.orange;
      case AlertType.message:
        return AppColors.info;
      case AlertType.task:
        return AppColors.warning;
      case AlertType.reschedule:
        return Colors.orange;
      case AlertType.declined:
        return AppColors.error;
      case AlertType.reappointment:
        return AppColors.warning;
      case AlertType.followUp:
        return const Color(0xFF3B82F6); // Blue color for follow-ups
      case AlertType.systemUpdate:
        return AppColors.primary;
    }
  }

  IconData _getAlertIcon() {
    switch (alert.type) {
      case AlertType.appointment:
        return Icons.event_available;
      case AlertType.appointmentPending:
        return Icons.schedule;
      case AlertType.message:
        return Icons.message;
      case AlertType.task:
        return Icons.assignment;
      case AlertType.reschedule:
        return Icons.update;
      case AlertType.declined:
        return Icons.cancel_outlined;
      case AlertType.reappointment:
        return Icons.repeat;
      case AlertType.followUp:
        return Icons.sync; // Sync icon for follow-ups
      case AlertType.systemUpdate:
        return Icons.system_update;
    }
  }
}
