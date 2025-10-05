import 'package:flutter/material.dart';
import '../../../models/activity_item.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
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
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: hasActivities
                ? ListView.separated(
                    itemCount: displayActivities.length,
                    separatorBuilder: (context, index) => SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return ActivityListItem(activity: displayActivities[index]);
                    },
                  )
                : Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}