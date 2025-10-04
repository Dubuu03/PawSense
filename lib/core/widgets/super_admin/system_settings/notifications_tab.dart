import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/system/system_settings_model.dart';

class NotificationsTab extends StatefulWidget {
  final SystemSettingsModel settings;
  final Function(SystemSettingsModel) onSettingsChanged;

  const NotificationsTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _appointmentReminders = true;
  bool _systemAlerts = true;
  bool _securityAlerts = true;
  bool _marketingEmails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Preferences',
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: kSpacingMedium),
        Text(
          'Choose what notifications you want to receive',
          style: kTextStyleRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: kSpacingXLarge),
        
        // Communication Preferences
        _buildSection(
          'Communication Methods',
          [
            _NotificationToggle(
              title: 'Email Notifications',
              description: 'Receive notifications via email',
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
            ),
            _NotificationToggle(
              title: 'Push Notifications',
              description: 'Receive push notifications in the app',
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
            _NotificationToggle(
              title: 'SMS Notifications',
              description: 'Receive important alerts via SMS',
              value: _smsNotifications,
              onChanged: (value) => setState(() => _smsNotifications = value),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingXLarge),
        
        // Notification Types
        _buildSection(
          'Notification Types',
          [
            _NotificationToggle(
              title: 'Appointment Reminders',
              description: 'Get reminded about upcoming appointments',
              value: _appointmentReminders,
              onChanged: (value) => setState(() => _appointmentReminders = value),
            ),
            _NotificationToggle(
              title: 'System Alerts',
              description: 'Important system updates and maintenance notices',
              value: _systemAlerts,
              onChanged: (value) => setState(() => _systemAlerts = value),
            ),
            _NotificationToggle(
              title: 'Security Alerts',
              description: 'Security-related notifications and warnings',
              value: _securityAlerts,
              onChanged: (value) => setState(() => _securityAlerts = value),
            ),
            _NotificationToggle(
              title: 'Marketing Emails',
              description: 'Product updates, tips, and promotional content',
              value: _marketingEmails,
              onChanged: (value) => setState(() => _marketingEmails = value),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingXLarge),
        
        // Save Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: Icon(Icons.save, size: kIconSizeMedium),
              label: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: kSpacingLarge,
                  vertical: kSpacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: kTextStyleRegular.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: kSpacingMedium),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(kBorderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      color: AppColors.border,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _saveChanges() {
    // Add save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification preferences updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final Function(bool) onChanged;

  const _NotificationToggle({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kSpacingLarge,
        vertical: kSpacingMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: kSpacingSmall / 2),
                Text(
                  description,
                  style: kTextStyleSmall.copyWith(
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
