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
        _buildSettingsButton(),
      ],
    );
  }


  Widget _buildSettingsButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}