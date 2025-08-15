import 'package:flutter/material.dart';
import 'day_card.dart';

class WeekDaysGrid extends StatelessWidget {
  final String selectedDay;
  final Function(String) onDaySelected;

  const WeekDaysGrid({
    Key? key,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final days = [
      DayData('Monday', '15 appointments', true),
      DayData('Tuesday', '18 appointments', true),
      DayData('Wednesday', '12 appointments', true),
      DayData('Thursday', '8 appointments', true),
      DayData('Friday', '22 appointments', true),
      DayData('Saturday', '6 appointments', true),
      DayData('Sunday', '4 appointments', true),
    ];

    return Row(
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == days.length - 1 ? 0 : 12),
            child: DayCard(
              day: day,
              isSelected: selectedDay == day.name,
              onTap: () => onDaySelected(day.name),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DayData {
  final String name;
  final String appointments;
  final bool hasData;
  final bool isDisabled;

  DayData(
    this.name,
    this.appointments,
    this.hasData, {
    this.isDisabled = false,
  });
}