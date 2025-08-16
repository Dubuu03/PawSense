import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';
import '../../../models/appointment_models.dart';

class StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case AppointmentStatus.pending:
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        text = 'Pending';
        break;
      case AppointmentStatus.confirmed:
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        text = 'Confirmed';
        break;
      case AppointmentStatus.completed:
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        text = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        text = 'Cancelled';
        break;
    }

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // smaller padding
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: kFontSizeSmall,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
