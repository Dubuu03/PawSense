import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/analytics/analytics_models.dart';

class DateRangeFilter extends StatelessWidget {
  final DateRangeData selectedRange;
  final Function(DateRangeData) onRangeChanged;
  final VoidCallback onRefresh;
  final VoidCallback onExport;

  const DateRangeFilter({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.onRefresh,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final predefinedRanges = [
      DateRangeData.getLast7Days(),
      DateRangeData.getLast30Days(),
      DateRangeData.getLast90Days(),
    ];

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
      child: Row(
        children: [
          // Date Range Selector
          Text(
            'Time Period:',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: kSpacingMedium),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateRangeData>(
                value: predefinedRanges.firstWhere(
                  (range) => range.filter == selectedRange.filter,
                  orElse: () => predefinedRanges.first,
                ),
                onChanged: (DateRangeData? newRange) {
                  if (newRange != null) {
                    onRangeChanged(newRange);
                  }
                },
                items: predefinedRanges.map((DateRangeData range) {
                  return DropdownMenuItem<DateRangeData>(
                    value: range,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                      child: Text(
                        range.displayName,
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Spacer(),
          
          // Last Updated Info
          Text(
            'Last updated: ${_formatDateTime(DateTime.now())}',
            style: kTextStyleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          SizedBox(width: kSpacingLarge),
          
          // Action Buttons
          Row(
            children: [
              _buildActionButton(
                icon: Icons.refresh,
                label: 'Refresh',
                onPressed: onRefresh,
                color: AppColors.info,
              ),
              SizedBox(width: kSpacingMedium),
              _buildActionButton(
                icon: Icons.download,
                label: 'Export',
                onPressed: onExport,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: kIconSizeMedium),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        padding: EdgeInsets.symmetric(
          horizontal: kSpacingMedium,
          vertical: kSpacingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
