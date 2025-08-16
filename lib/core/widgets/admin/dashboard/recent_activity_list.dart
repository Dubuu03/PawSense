import 'package:flutter/material.dart';
import '../../../models/activity_item.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import 'activity_list_item.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      ActivityItem(
        title: 'New appointment booked',
        subtitle: 'Max (Golden Retriever) - Skin condition check',
        time: '2 minutes ago',
        icon: Icons.calendar_today,
        iconColor: AppColors.primary,
      ),
      ActivityItem(
        title: 'Consultation completed',
        subtitle: 'Luna (Persian Cat) - Routine checkup',
        time: '15 minutes ago',
        icon: Icons.check_circle,
        iconColor: AppColors.success,
      ),
      ActivityItem(
        title: 'Appointment cancelled',
        subtitle: 'Buddy (Labrador) - Vaccination',
        time: '1 hour ago',
        icon: Icons.cancel,
        iconColor: AppColors.warning,
      ),
      ActivityItem(
        title: 'Patient record updated',
        subtitle: 'Whiskers (Siamese) - Added prescription',
        time: '2 hours ago',
        icon: Icons.description,
        iconColor: AppColors.info,
      ),
      ActivityItem(
        title: 'New appointment booked',
        subtitle: 'Rocky (German Shepherd) - Emergency visit',
        time: '3 hours ago',
        icon: Icons.calendar_today,
        iconColor: AppColors.error,
      ),
    ];

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
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (context, index) => SizedBox(height: 20),
              itemBuilder: (context, index) {
                return ActivityListItem(activity: activities[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}