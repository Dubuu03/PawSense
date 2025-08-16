// widgets/appointment_table_header.dart
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class AppointmentTableHeader extends StatelessWidget {
  const AppointmentTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 1,
            child: Text(
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Time',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Pet',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Disease/Reason',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Owner',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}