import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/home/appointment_history_detail_modal.dart';

enum AppointmentStatus {
  confirmed,
  pending,
  completed,
  cancelled,
}

class AppointmentHistoryData {
  final String id; // Added ID field for navigation
  final String title;
  final String subtitle;
  final AppointmentStatus status;
  final DateTime timestamp;
  final String? clinicName;
  final DateTime createdAt; // Added for sorting by booking creation date
  final bool isFollowUp; // Indicates if this is a follow-up appointment

  AppointmentHistoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.timestamp,
    this.clinicName,
    required this.createdAt, // Required for sorting
    this.isFollowUp = false, // Default to false
  });
}

class AppointmentHistoryList extends StatelessWidget {
  final List<AppointmentHistoryData> appointmentHistory;
  final VoidCallback? onAppointmentUpdated;

  const AppointmentHistoryList({
    super.key,
    required this.appointmentHistory,
    this.onAppointmentUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (appointmentHistory.isEmpty) {
      return _buildEmptyState();
    }

  // Sort appointments by booking creation date (most recently booked first)
  final sortedAppointments = List<AppointmentHistoryData>.from(appointmentHistory);
  sortedAppointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      children: [
        ...sortedAppointments.map((item) => AppointmentHistoryItem(
          data: item,
          onTap: () {
            _showAppointmentDetails(context, item.id);
          },
          onDetailsPressed: () {
            _showAppointmentDetails(context, item.id);
          },
          onAppointmentUpdated: onAppointmentUpdated,
        )),
      ],
    );
  }

  void _showAppointmentDetails(BuildContext context, String appointmentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppointmentHistoryDetailModal(
          appointmentId: appointmentId,
          onAppointmentUpdated: onAppointmentUpdated,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: kMobilePaddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'No appointments yet',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AppointmentHistoryItem extends StatelessWidget {
  final AppointmentHistoryData data;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsPressed;
  final VoidCallback? onAppointmentUpdated;

  const AppointmentHistoryItem({
    super.key,
    required this.data,
    this.onTap,
    this.onDetailsPressed,
    this.onAppointmentUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // Debug print
    print('AppointmentHistoryItem: ${data.title}, isFollowUp: ${data.isFollowUp}');
    
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: kMobileBorderRadiusSmallPreset,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Padding(
            padding: const EdgeInsets.all(kMobilePaddingSmall),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: kMobileSizedBoxLarge),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              data.title,
                              style: kMobileTextStyleTitle.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (data.isFollowUp) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Follow-up appointment',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  size: 10,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle,
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Details button
                if (onDetailsPressed != null)
                  TextButton(
                    onPressed: onDetailsPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (data.status) {
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.completed:
        return AppColors.info;
      case AppointmentStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (data.status) {
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
