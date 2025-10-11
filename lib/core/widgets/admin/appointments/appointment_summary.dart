// widgets/appointment_summary.dart
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../services/clinic/paginated_appointment_service.dart';
import 'summary_card.dart';

class AppointmentSummary extends StatelessWidget {
  final AppointmentStatusCounts statusCounts;
  final bool isLoading;

  const AppointmentSummary({
    super.key, 
    required this.statusCounts,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = statusCounts.pendingCount;
    final confirmedCount = statusCounts.confirmedCount;
    final completedCount = statusCounts.completedCount;
    final cancelledCount = statusCounts.cancelledCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          SummaryCard(
            count: pendingCount,
            label: 'Pending Approval',
            color: AppColors.warning,
            isLoading: isLoading,
          ),
          const SizedBox(width: 24),
          SummaryCard(
            count: confirmedCount,
            label: 'Confirmed',
            color: AppColors.info,
            isLoading: isLoading,
          ),
          const SizedBox(width: 24),
          SummaryCard(
            count: completedCount,
            label: 'Completed',
            color: AppColors.success,
            isLoading: isLoading,
          ),
          const SizedBox(width: 24),
          SummaryCard(
            count: cancelledCount,
            label: 'Cancelled',
            color: AppColors.error,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}