import 'package:flutter/material.dart';
import 'package:pawsense/core/models/analytics/system_analytics_models.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Analytics Filters Widget - Period selector and action buttons
class AnalyticsFilters extends StatelessWidget {
  final AnalyticsPeriod selectedPeriod;
  final Function(AnalyticsPeriod) onPeriodChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onExport;
  final bool isLoading;
  final DateTime? lastUpdated;

  const AnalyticsFilters({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onRefresh,
    this.onExport,
    this.isLoading = false,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
      child: Row(
        children: [
          // Period Label
          const Text(
            'Time Period:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),

          // Period Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AnalyticsPeriod>(
                value: selectedPeriod,
                onChanged: isLoading
                    ? null
                    : (AnalyticsPeriod? newValue) {
                        if (newValue != null) {
                          onPeriodChanged(newValue);
                        }
                      },
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppColors.textSecondary),
                items: AnalyticsPeriod.values.map((period) {
                  return DropdownMenuItem<AnalyticsPeriod>(
                    value: period,
                    child: Text(period.label),
                  );
                }).toList(),
              ),
            ),
          ),

          const Spacer(),

          // Last Updated Indicator
          if (lastUpdated != null) ...[
            const Icon(
              Icons.access_time,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Updated: ${_formatTime(lastUpdated!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 24),
          ],

          // Refresh Button
          ElevatedButton.icon(
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          if (onExport != null) ...[
            const SizedBox(width: 12),
            // Export Button
            ElevatedButton.icon(
              onPressed: isLoading ? null : onExport,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
