// widgets/appointment_header.dart
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../utils/app_colors.dart';

class AppointmentHeader extends StatelessWidget {
  final VoidCallback onNewAppointment;

  const AppointmentHeader({Key? key, required this.onNewAppointment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Appointment Management',
                style: TextStyle(
                  fontSize: kFontSizeTitle,
                  fontWeight: FontWeight.bold,
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
        ElevatedButton.icon(
          onPressed: onNewAppointment,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Appointment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        )

        ],
      ),
    );
  }
}