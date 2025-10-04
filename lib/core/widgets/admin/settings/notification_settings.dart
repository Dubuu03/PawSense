import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _pushNotifications = true;
  bool _appointmentReminders = true;
  bool _appointmentConfirmations = true;
  bool _cancellationAlerts = true;
  bool _emergencyAlerts = true;
  bool _systemUpdates = true;
  bool _marketingEmails = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          _buildNotificationToggle(
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildNotificationToggle(
            title: 'SMS Notifications',
            subtitle: 'Receive text message notifications',
            value: _smsNotifications,
            onChanged: (value) => setState(() => _smsNotifications = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildNotificationToggle(
            title: 'Push Notifications',
            subtitle: 'Receive push notifications in your browser',
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
          ),
          SizedBox(height: kSpacingLarge),
          
          _buildNotificationToggle(
            title: 'Appointment Reminders',
            subtitle: 'Reminders for upcoming appointments',
            value: _appointmentReminders,
            onChanged: (value) => setState(() => _appointmentReminders = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildNotificationToggle(
            title: 'Appointment Confirmations',
            subtitle: 'Confirmation notifications for new appointments',
            value: _appointmentConfirmations,
            onChanged: (value) => setState(() => _appointmentConfirmations = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildNotificationToggle(
            title: 'Cancellation Alerts',
            subtitle: 'Alerts when appointments are cancelled',
            value: _cancellationAlerts,
            onChanged: (value) => setState(() => _cancellationAlerts = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildNotificationToggle(
            title: 'Emergency Alerts',
            subtitle: 'Immediate notifications for emergency appointments',
            value: _emergencyAlerts,
            onChanged: (value) => setState(() => _emergencyAlerts = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildNotificationToggle(
            title: 'System Updates',
            subtitle: 'Updates about system maintenance and features',
            value: _systemUpdates,
            onChanged: (value) => setState(() => _systemUpdates = value),
          ),
          SizedBox(height: kSpacingMedium),
          
          _buildNotificationToggle(
            title: 'Marketing Emails',
            subtitle: 'Marketing and promotional emails',
            value: _marketingEmails,
            onChanged: (value) => setState(() => _marketingEmails = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: kFontSizeRegular,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: kFontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
