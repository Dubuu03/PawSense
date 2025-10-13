// widgets/appointment_header.dart
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';

class AppointmentHeader extends StatelessWidget {
  const AppointmentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0,24.0,24.0,0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text(
                'Appointment Management',
                style: kTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage and track all veterinary appointments',
                style: TextStyle(
                  fontSize: kFontSizeRegular-2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}