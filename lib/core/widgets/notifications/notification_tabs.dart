import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';

enum NotificationType {
  all,
  unread,
  appointments,
  messages,
  system,
}

class NotificationTabs extends StatelessWidget {
  final NotificationType selectedTab;
  final Function(NotificationType) onTabSelected;

  const NotificationTabs({
    Key? key,
    required this.selectedTab,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 24),
      child: Row(
        children: [
          FilterChip(
            selected: selectedTab == NotificationType.all,
            onSelected: (_) => onTabSelected(NotificationType.all),
            label: Text('All'),
            backgroundColor: Colors.transparent,
            selectedColor: AppColors.primary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: selectedTab == NotificationType.all
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selectedTab == NotificationType.all
                    ? AppColors.primary
                    : Colors.transparent,
              ),
            ),
          ),
          SizedBox(width: 12),
          FilterChip(
            selected: selectedTab == NotificationType.unread,
            onSelected: (_) => onTabSelected(NotificationType.unread),
            label: Text('Unread'),
            backgroundColor: Colors.transparent,
            selectedColor: AppColors.primary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: selectedTab == NotificationType.unread
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selectedTab == NotificationType.unread
                    ? AppColors.primary
                    : Colors.transparent,
              ),
            ),
          ),
          SizedBox(width: 12),
          FilterChip(
            selected: selectedTab == NotificationType.appointments,
            onSelected: (_) => onTabSelected(NotificationType.appointments),
            label: Text('Appointments'),
            backgroundColor: Colors.transparent,
            selectedColor: AppColors.primary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: selectedTab == NotificationType.appointments
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selectedTab == NotificationType.appointments
                    ? AppColors.primary
                    : Colors.transparent,
              ),
            ),
          ),
          SizedBox(width: 12),
          FilterChip(
            selected: selectedTab == NotificationType.messages,
            onSelected: (_) => onTabSelected(NotificationType.messages),
            label: Text('Messages'),
            backgroundColor: Colors.transparent,
            selectedColor: AppColors.primary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: selectedTab == NotificationType.messages
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selectedTab == NotificationType.messages
                    ? AppColors.primary
                    : Colors.transparent,
              ),
            ),
          ),
          SizedBox(width: 12),
          FilterChip(
            selected: selectedTab == NotificationType.system,
            onSelected: (_) => onTabSelected(NotificationType.system),
            label: Text('System'),
            backgroundColor: Colors.transparent,
            selectedColor: AppColors.primary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: selectedTab == NotificationType.system
                  ? AppColors.primary
                  : Colors.grey[600],
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selectedTab == NotificationType.system
                    ? AppColors.primary
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
