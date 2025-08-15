import 'package:flutter/material.dart';

class WeekNavigation extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const WeekNavigation({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            onDateChanged(selectedDate.subtract(Duration(days: 7)));
          },
          icon: Icon(Icons.chevron_left, color: Color(0xFF6B7280)),
        ),
        SizedBox(width: 16),
        Column(
          children: [
            Text(
              _formatWeekRange(selectedDate),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Week Schedule',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        SizedBox(width: 16),
        IconButton(
          onPressed: () {
            onDateChanged(selectedDate.add(Duration(days: 7)));
          },
          icon: Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  String _formatWeekRange(DateTime date) {
    // Assume week starts on Sunday and ends on Saturday
    final weekday = date.weekday % 7; // DateTime.weekday: Mon=1..Sun=7
    final sunday = date.subtract(Duration(days: weekday));
    final saturday = sunday.add(Duration(days: 6));

    String fmt(DateTime d) {
      final month = _monthAbbrev(d.month);
      return '$month ${d.day}';
    }

    return '${fmt(sunday)} - ${fmt(saturday)}, ${saturday.year}';
  }

  String _monthAbbrev(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }
}