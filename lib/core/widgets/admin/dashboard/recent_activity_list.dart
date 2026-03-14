import 'package:flutter/material.dart';
import '../../../models/activity_item.dart';
import '../../../utils/app_colors.dart';
import '../../../services/admin/dashboard_service.dart';
import 'activity_list_item.dart';

class RecentActivityList extends StatelessWidget {
  final List<RecentActivity> activities;
  
  const RecentActivityList({
    super.key,
    this.activities = const [],
  });

  /// Convert RecentActivity to ActivityItem for display
  ActivityItem _convertToActivityItem(RecentActivity activity) {
    // Determine title and icon based on status
    String title;
    IconData icon;
    Color iconColor;

    switch (activity.status.toLowerCase()) {
      case 'completed':
        title = 'Consultation completed';
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case 'cancelled':
        title = 'Appointment cancelled';
        icon = Icons.cancel;
        iconColor = AppColors.warning;
        break;
      case 'confirmed':
        title = 'Appointment confirmed';
        icon = Icons.event_available;
        iconColor = AppColors.info;
        break;
      case 'pending':
        title = 'New appointment booked';
        icon = Icons.calendar_today;
        iconColor = AppColors.primary;
        break;
      default:
        title = 'Appointment updated';
        icon = Icons.update;
        iconColor = AppColors.textSecondary;
    }

    // Format subtitle
    final subtitle = '${activity.petName} - ${activity.ownerName}';

    // Format time
    final now = DateTime.now();
    final difference = now.difference(activity.timestamp);
    String timeText;

    if (difference.inMinutes < 1) {
      timeText = 'Just now';
    } else if (difference.inMinutes < 60) {
      timeText = '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      timeText = '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      timeText = '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      timeText = '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() == 1 ? '' : 's'} ago';
    }

    return ActivityItem(
      title: title,
      subtitle: subtitle,
      time: timeText,
      icon: icon,
      iconColor: iconColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert activities to display format
    final displayActivities = activities.map(_convertToActivityItem).toList();
    
    // Show message if no activities
    final hasActivities = displayActivities.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.history,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          hasActivities
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: displayActivities.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: entry.key < displayActivities.length - 1 ? 20 : 0),
                      child: ActivityListItem(activity: entry.value),
                    );
                  }).toList(),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Text(
                    'No recent activity',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}