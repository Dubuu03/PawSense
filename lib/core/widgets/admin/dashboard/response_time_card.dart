import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../services/admin/dashboard_service.dart';

class ResponseTimeCard extends StatelessWidget {
  final ResponseTimeData responseData;
  final bool isLoading;

  const ResponseTimeCard({
    Key? key,
    required this.responseData,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Response Time Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Average Response Time
          _buildMetricRow(
            icon: Icons.access_time,
            label: 'Average Response Time',
            value: _formatHours(responseData.averageHours),
            subtitle: 'Time to confirm appointment',
            color: _getResponseColor(responseData.averageHours),
          ),
          const Divider(height: 32),
          // Within 24 Hours
          _buildMetricRow(
            icon: Icons.timer,
            label: 'Within 24 Hours',
            value: '${responseData.percentageWithin24h.toStringAsFixed(1)}%',
            subtitle: '${responseData.within24Hours} of ${responseData.totalSampled} appointments',
            color: AppColors.success,
          ),
          const Divider(height: 32),
          // Within 48 Hours
          _buildMetricRow(
            icon: Icons.schedule,
            label: 'Within 48 Hours',
            value: '${responseData.percentageWithin48h.toStringAsFixed(1)}%',
            subtitle: '${responseData.within48Hours} of ${responseData.totalSampled} appointments',
            color: AppColors.info,
          ),
          const SizedBox(height: 16),
          _buildResponseGauge(),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponseGauge() {
    final percentage24h = responseData.percentageWithin24h;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Response Rate',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${percentage24h.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getQuickResponseColor(percentage24h),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage24h / 100,
              minHeight: 8,
              backgroundColor: AppColors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getQuickResponseColor(percentage24h),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getQuickResponseMessage(percentage24h),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      final minutes = (hours * 60).round();
      return '$minutes min';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} hrs';
    } else {
      final days = (hours / 24).toStringAsFixed(1);
      return '$days days';
    }
  }

  Color _getResponseColor(double hours) {
    if (hours <= 24) return AppColors.success;
    if (hours <= 48) return AppColors.warning;
    return AppColors.error;
  }

  Color _getQuickResponseColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String _getQuickResponseMessage(double percentage) {
    if (percentage >= 80) return 'Excellent response time! 🎉';
    if (percentage >= 60) return 'Good response time. Room for improvement.';
    return 'Response time needs improvement. Consider faster confirmations.';
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Center(
        heightFactor: 8,
        child: CircularProgressIndicator(),
      ),
    );
  }
}
