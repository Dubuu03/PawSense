// widgets/appointment_table_row.dart
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../utils/app_colors.dart';
import '../../../models/clinic/appointment_models.dart';
import 'status_badge.dart';

class AppointmentTableRow extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onMarkDone;

  const AppointmentTableRow({
    super.key,
    required this.appointment,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    this.onAccept,
    this.onReject,
    this.onMarkDone,
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
                // Pet profile picture or emoji fallback
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: appointment.pet.imageUrl != null && appointment.pet.imageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            appointment.pet.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  appointment.pet.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            appointment.pet.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
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
                  tooltip: 'View Appointment Details',
                ),
                if (appointment.status == AppointmentStatus.pending) ...[
                  IconButton(
                    icon: const Icon(Icons.check, size: 16),
                    onPressed: onAccept,
                    color: AppColors.success,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Accept Appointment',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onReject,
                    color: AppColors.error,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Reject Appointment',
                  ),
                ] else if (appointment.status == AppointmentStatus.confirmed) ...[
                  IconButton(
                    icon: const Icon(Icons.task_alt, size: 16),
                    onPressed: onMarkDone,
                    color: AppColors.success,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Mark as Done',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: onEdit,
                    color: AppColors.textSecondary,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Edit Appointment',
                  ),
                ] else if (appointment.status == AppointmentStatus.cancelled) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: onEdit,
                    color: AppColors.textSecondary,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Edit Appointment',
                  ),
                ],
                // No edit button for completed appointments
              ],
            ),
          ),
        ],
      ),
    );
  }
}