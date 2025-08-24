import 'package:flutter/material.dart';
import '../../../core/widgets/admin/notifications/notification_header.dart';
import '../../../core/widgets/admin/notifications/notification_tabs.dart';
import '../../../core/widgets/admin/notifications/notification_item.dart';
import '../../../core/widgets/admin/notifications/notification_settings_modal.dart';
import '../../../core/utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationType _selectedTab = NotificationType.all;
  
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'Emergency Appointment Request',
      'description': 'Pet owner reports severe breathing difficulty in a 2-year-old German Shepherd.',
      'timestamp': DateTime.now().subtract(Duration(minutes: 5)),
      'isEmergency': true,
      'isUnread': true,
      'requiresAction': true,
      'icon': Icons.pets,
      'iconColor': Colors.red,
      'actionButtonText': 'Review Request',
      'type': NotificationType.appointments,
      'details': {
        'Owner': 'John Smith',
        'Pet': 'Max (German Shepherd)',
        'Contact': '+1 (555) 123-4567',
      },
    },
    {
      'id': '2',
      'title': 'New Appointment Scheduled',
      'description': 'Regular checkup appointment scheduled for tomorrow at 2:30 PM.',
      'timestamp': DateTime.now().subtract(Duration(hours: 2)),
      'isEmergency': false,
      'isUnread': true,
      'requiresAction': false,
      'icon': Icons.calendar_today,
      'iconColor': AppColors.primary,
      'type': NotificationType.appointments,
      'details': {
        'Date': 'Aug 16, 2025',
        'Time': '2:30 PM',
        'Service': 'Regular Checkup',
      },
    },
    {
      'id': '3',
      'title': 'Lab Results Available',
      'description': 'Blood work results for patient "Bella" are now available for review.',
      'timestamp': DateTime.now().subtract(Duration(hours: 4)),
      'isEmergency': false,
      'isUnread': true,
      'requiresAction': true,
      'icon': Icons.science,
      'iconColor': Colors.orange,
      'actionButtonText': 'View Results',
      'type': NotificationType.system,
      'details': {
        'Patient': 'Bella (Maine Coon)',
        'Test Type': 'Blood Work',
        'Ordered By': 'Dr. Sarah Johnson',
      },
    },
    {
      'id': '4',
      'title': 'Profile Update Required',
      'description': 'Please update your certification information. Your dermatology certification expires in 30 days.',
      'timestamp': DateTime.now().subtract(Duration(days: 1)),
      'isEmergency': false,
      'isUnread': false,
      'requiresAction': false,
      'icon': Icons.warning_amber,
      'iconColor': Colors.amber,
      'type': NotificationType.system,
      'details': {
        'Certificate': 'Board Certification in Dermatology',
        'Expires': 'Sep 14, 2025',
      },
    },
    {
      'id': '5',
      'title': 'Appointment Cancelled',
      'description': 'The 3:00 PM vaccination appointment for "Charlie" has been cancelled by the owner.',
      'timestamp': DateTime.now().subtract(Duration(days: 1)),
      'isEmergency': false,
      'isUnread': false,
      'requiresAction': false,
      'icon': Icons.event_busy,
      'iconColor': Colors.grey,
      'type': NotificationType.appointments,
      'details': {
        'Original Date': 'Aug 14, 2025',
        'Time': '3:00 PM',
        'Service': 'Vaccination',
      },
    },
  ];

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_selectedTab == NotificationType.all) {
      return notifications;
    } else if (_selectedTab == NotificationType.unread) {
      return notifications.where((n) => n['isUnread'] == true).toList();
    } else {
      return notifications.where((n) => n['type'] == _selectedTab).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n['isUnread']).length;
    final actionRequired = notifications.where((n) => n['requiresAction']).length;

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotificationHeader(
            unreadCount: unreadCount,
            actionRequired: actionRequired,
            onMarkAllRead: () {
              setState(() {
                for (var notification in notifications) {
                  notification['isUnread'] = false;
                }
              });
            },
            onSettings: () {
              showDialog(
                context: context,
                builder: (context) => const NotificationSettingsModal(),
              );
            },
          ),
          NotificationTabs(
            selectedTab: _selectedTab,
            onTabSelected: (tab) {
              setState(() {
                _selectedTab = tab;
              });
            },
          ),
          SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.builder(
                  padding: EdgeInsets.all(24),
                  itemCount: _getFilteredNotifications().length,
                  itemBuilder: (context, index) {
                    final notification = _getFilteredNotifications()[index];
                    return NotificationItem(
                      title: notification['title'],
                      description: notification['description'],
                      timestamp: notification['timestamp'],
                      isEmergency: notification['isEmergency'],
                      isUnread: notification['isUnread'],
                      requiresAction: notification['requiresAction'],
                      icon: notification['icon'],
                      iconColor: notification['iconColor'],
                      actionButtonText: notification['actionButtonText'],
                      details: notification['details']?.cast<String, String>(),
                      onMarkRead: () {
                        setState(() {
                          notification['isUnread'] = false;
                        });
                      },
                      onDelete: () {
                        setState(() {
                          notifications.removeWhere((n) => n['id'] == notification['id']);
                        });
                      },
                      onAction: () {
                        // TODO: Handle action based on notification type
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
