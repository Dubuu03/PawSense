import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/analytics/analytics_models.dart';

class OverviewCards extends StatelessWidget {
  final OverviewMetrics overview;

  const OverviewCards({
    super.key,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Total Users',
            overview.totalUsers.toString(),
            '${overview.userGrowthPercentage >= 0 ? '+' : ''}${overview.userGrowthPercentage.toStringAsFixed(1)}%',
            overview.userGrowthPercentage >= 0 ? AppColors.success : AppColors.error,
            Icons.people,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildOverviewCard(
            'Active Clinics',
            '${overview.activeClinics}/${overview.totalClinics}',
            _getClinicStatusLabel(overview.activeClinics, overview.totalClinics),
            _getClinicStatusColor(overview.activeClinics, overview.totalClinics),
            Icons.local_hospital,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildOverviewCard(
            'Total Appointments',
            overview.totalAppointments.toString(),
            '${overview.appointmentTrend >= 0 ? '+' : ''}${overview.appointmentTrend.toStringAsFixed(1)}% this month',
            overview.appointmentTrend >= 0 ? AppColors.success : AppColors.error,
            Icons.calendar_today,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildOverviewCard(
            'System Uptime',
            '${overview.systemUptime.toStringAsFixed(1)}%',
            _getHealthStatusLabel(overview.healthStatus),
            _getHealthStatusColor(overview.healthStatus),
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    String subtitle,
    Color statusColor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: statusColor,
                  size: kIconSizeLarge,
                ),
              ),
              Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingMedium),
          Text(
            title,
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: kSpacingSmall / 2),
          Text(
            value,
            style: kTextStyleHeader.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          SizedBox(height: kSpacingSmall / 2),
          Text(
            subtitle,
            style: kTextStyleSmall.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getClinicStatusLabel(int active, int total) {
    if (total == 0) return 'No clinics';
    double percentage = (active / total) * 100;
    return '${percentage.toStringAsFixed(0)}% active';
  }

  Color _getClinicStatusColor(int active, int total) {
    if (total == 0) return AppColors.textSecondary;
    double percentage = (active / total) * 100;
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _getHealthStatusLabel(SystemHealthStatus status) {
    switch (status) {
      case SystemHealthStatus.excellent:
        return 'Excellent';
      case SystemHealthStatus.good:
        return 'Good';
      case SystemHealthStatus.warning:
        return 'Warning';
      case SystemHealthStatus.critical:
        return 'Critical';
    }
  }

  Color _getHealthStatusColor(SystemHealthStatus status) {
    switch (status) {
      case SystemHealthStatus.excellent:
      case SystemHealthStatus.good:
        return AppColors.success;
      case SystemHealthStatus.warning:
        return AppColors.warning;
      case SystemHealthStatus.critical:
        return AppColors.error;
    }
  }
}
