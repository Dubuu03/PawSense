// widgets/appointment_summary.dart
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../models/appointment_models.dart';
import 'summary_card.dart';

class AppointmentSummary extends StatelessWidget {
  final List<Appointment> appointments;

  const AppointmentSummary({super.key, required this.appointments});

  @override
  Widget build(BuildContext context) {
    final pendingCount = appointments.where((a) => a.status == AppointmentStatus.pending).length;
    final confirmedCount = appointments.where((a) => a.status == AppointmentStatus.confirmed).length;
    final completedCount = appointments.where((a) => a.status == AppointmentStatus.completed).length;
    final cancelledCount = appointments.where((a) => a.status == AppointmentStatus.cancelled).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          SummaryCard(
            count: pendingCount,
            label: 'Pending Approval',
            color: AppColors.warning,
          ),
          const SizedBox(width: 24),
          SummaryCard(
            count: confirmedCount,
            label: 'Confirmed',
            color: AppColors.info,
          ),
          const SizedBox(width: 24),
          SummaryCard(
            count: completedCount,
            label: 'Completed',
            color: AppColors.success,
          ),
          const SizedBox(width: 24),
          SummaryCard(
            count: cancelledCount,
            label: 'Cancelled',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}