import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class ScheduleHeader extends StatelessWidget {
  final String selectedView;
  final Function(String) onViewChanged;

  const ScheduleHeader({
    Key? key,
    required this.selectedView,
    required this.onViewChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinic Schedule',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your clinic\'s working hours and availability',
                style: TextStyle(
                  fontSize: kFontSizeRegular,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: kSpacingMedium),
       _buildSettingsButton(() {
          // Handle settings click
        })
      ],
    );
  }


    Widget _buildSettingsButton(VoidCallback onSettings) {
    return ElevatedButton.icon(
      onPressed: onSettings,
      icon: const Icon(Icons.settings, color: Colors.white),
      label: const Text('Settings'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

}