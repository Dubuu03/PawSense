import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class NotificationSettingsModal extends StatefulWidget {
  const NotificationSettingsModal({super.key});

  @override
  State<NotificationSettingsModal> createState() => _NotificationSettingsModalState();
}

class _NotificationSettingsModalState extends State<NotificationSettingsModal> {
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool smsNotifications = false;
  bool appointmentReminders = true;
  bool emergencyAlerts = true;
  bool messageAlerts = true;
  bool systemUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingSwitch(
              'Email Notifications',
              emailNotifications,
              (value) => setState(() => emailNotifications = value),
            ),
            _buildSettingSwitch(
              'Push Notifications',
              pushNotifications,
              (value) => setState(() => pushNotifications = value),
            ),
            _buildSettingSwitch(
              'SMS Notifications',
              smsNotifications,
              (value) => setState(() => smsNotifications = value),
            ),
            _buildSettingSwitch(
              'Appointment Reminders',
              appointmentReminders,
              (value) => setState(() => appointmentReminders = value),
            ),
            _buildSettingSwitch(
              'Emergency Alerts',
              emergencyAlerts,
              (value) => setState(() => emergencyAlerts = value),
            ),
            _buildSettingSwitch(
              'Message Alerts',
              messageAlerts,
              (value) => setState(() => messageAlerts = value),
            ),
            _buildSettingSwitch(
              'System Updates',
              systemUpdates,
              (value) => setState(() => systemUpdates = value),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Save notification settings
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
