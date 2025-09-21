import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'week_days_grid.dart';

class DayCard extends StatelessWidget {
  final DayData day;
  final bool isSelected;
  final VoidCallback onTap;

  const DayCard({
    super.key,
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: day.isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getTextColor(),
              ),
            ),
            if (day.openTime != null && day.closeTime != null) ...[
              const SizedBox(height: 4),
              Text(
                '${day.openTime} - ${day.closeTime}',
                style: TextStyle(
                  fontSize: 10,
                  color: _getSubtextColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (day.appointments.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                day.appointments,
                style: TextStyle(
                  fontSize: 12,
                  color: _getSubtextColor(),
                ),
              ),
            ],
            if (day.slotsInfo != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.white.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  day.slotsInfo!,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? AppColors.white : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (day.utilization != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isSelected 
                          ? AppColors.white.withOpacity(0.3)
                          : Colors.grey.shade300,
                      ),
                      child: LinearProgressIndicator(
                        value: day.utilization! / 100.0,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getUtilizationColor(day.utilization!),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${day.utilization}%',
                    style: TextStyle(
                      fontSize: 8,
                      color: _getSubtextColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  LinearGradient _getBackgroundGradient() {
    if (day.isDisabled) {
      return LinearGradient(
        colors: [AppColors.background, AppColors.background],
      );
    }
    if (isSelected) {
      return LinearGradient(
        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [AppColors.white, AppColors.bgsecond.withOpacity(0.3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getTextColor() {
    if (day.isDisabled) return AppColors.textSecondary;
    if (isSelected) return AppColors.white;
    return AppColors.primary;
  }

  Color _getSubtextColor() {
    if (day.isDisabled) return AppColors.textSecondary;
    if (isSelected) return AppColors.white.withOpacity(0.9);
    return AppColors.textSecondary;
  }

  Color _getUtilizationColor(int utilization) {
    if (utilization >= 90) return Colors.red.shade400;
    if (utilization >= 70) return Colors.orange.shade400;
    if (utilization >= 50) return Colors.amber.shade600;
    return Colors.green.shade400;
  }
}