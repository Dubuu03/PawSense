import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/services/notifications/notification_overlay_manager.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class NotificationTestButton extends StatelessWidget {
  const NotificationTestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showTestNotification(context),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.notifications_active, color: Colors.white),
    );
  }

  void _showTestNotification(BuildContext context) {
    final testAlert = AlertData(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Appointment Approved!',
      subtitle: 'Your appointment for tomorrow at 2:00 PM has been confirmed.',
      type: AlertType.appointment,
      timestamp: DateTime.now(),
      isRead: false,
    );

    NotificationOverlayManager.showNotification(
      context,
      testAlert,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification tapped!'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }
}