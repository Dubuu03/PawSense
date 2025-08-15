import 'package:flutter/material.dart';
import 'week_days_grid.dart';

class DayCard extends StatelessWidget {
  final DayData day;
  final bool isSelected;
  final VoidCallback onTap;

  const DayCard({
    Key? key,
    required this.day,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: day.isDisabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Color(0xFFE5E7EB),
            width: 1,
          ),
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
            if (day.appointments.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                day.appointments,
                style: TextStyle(
                  fontSize: 12,
                  color: _getSubtextColor(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (day.isDisabled) return Color(0xFFF9FAFB);
    if (isSelected) return Color(0xFF8B5CF6); // Purple for selected
    return Colors.white;
  }

  Color _getTextColor() {
    if (day.isDisabled) return Color(0xFF9CA3AF);
    if (isSelected) return Colors.white;
    return Color(0xFF111827);
  }

  Color _getSubtextColor() {
    if (day.isDisabled) return Color(0xFF9CA3AF);
    if (isSelected) return Colors.white.withOpacity(0.9);
    return Color(0xFF6B7280);
  }
}