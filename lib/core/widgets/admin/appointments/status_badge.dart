import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';
import '../../../models/clinic/appointment_models.dart';

class StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  final Appointment? appointment; // Optional: for detailed cancelled status

  const StatusBadge({
    super.key, 
    required this.status,
    this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData? icon;

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
        // Check if it's a no-show or auto-cancelled
        if (appointment?.isNoShow == true) {
          backgroundColor = const Color(0xFFFF9800).withOpacity(0.1); // Orange
          textColor = const Color(0xFFFF9800);
          text = 'Cancelled - No Show';
          icon = Icons.person_off_outlined;
        } else if (appointment?.autoCancelled == true) {
          backgroundColor = AppColors.error.withOpacity(0.1);
          textColor = AppColors.error;
          text = 'Cancelled - Auto';
          icon = Icons.schedule_outlined;
        } else {
          backgroundColor = AppColors.error.withOpacity(0.1);
          textColor = AppColors.error;
          text = 'Cancelled';
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // smaller padding
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: kFontSizeSmall,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
