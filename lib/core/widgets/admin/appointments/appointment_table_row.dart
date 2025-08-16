// widgets/appointment_table_row.dart
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';
import '../../../models/appointment_models.dart';
import 'status_badge.dart';

class AppointmentTableRow extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const AppointmentTableRow({
    super.key,
    required this.appointment,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              appointment.date,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontSize: kFontSizeSmall,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  appointment.time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontSize: kFontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Text(
                  appointment.pet.emoji,
                  style: const TextStyle(fontSize: kFontSizeLarge),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.pet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      appointment.pet.type,
                      style: const TextStyle(
                        fontSize: kFontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              appointment.diseaseReason,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.owner.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  appointment.owner.phone,
                  style: const TextStyle(
                    fontSize: kFontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: StatusBadge(status: appointment.status),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  onPressed: onView,
                  color: AppColors.textSecondary,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (appointment.status == AppointmentStatus.pending) ...[
                  IconButton(
                    icon: const Icon(Icons.check, size: 16),
                    onPressed: onEdit,
                    color: AppColors.success,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onDelete,
                    color: AppColors.error,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  onPressed: onEdit,
                  color: AppColors.textSecondary,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}