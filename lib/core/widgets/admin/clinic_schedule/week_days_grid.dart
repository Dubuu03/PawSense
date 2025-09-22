import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'day_card.dart';

class WeekDaysGrid extends StatefulWidget {
  final String selectedDay;
  final Function(String) onDaySelected;
  final String? clinicId;
  final DateTime selectedDate; // Add selected date parameter

  const WeekDaysGrid({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    this.clinicId,
    required this.selectedDate, // Make it required
  });

  @override
  State<WeekDaysGrid> createState() => _WeekDaysGridState();
}

class _WeekDaysGridState extends State<WeekDaysGrid> {
  Map<String, Map<String, dynamic>>? _weeklyAvailability;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadScheduleWithAvailability();
  }

  @override
  void didUpdateWidget(WeekDaysGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload schedule if clinic ID changed OR if selected date changed
    if (oldWidget.clinicId != widget.clinicId || 
        oldWidget.selectedDate != widget.selectedDate) {
      print('WeekDaysGrid: Date changed, reloading data for ${widget.selectedDate.toString().split(' ')[0]}');
      setState(() {
        _weeklyAvailability = null; // Clear old data
        _hasLoaded = false; // Reset loading state
      });
      _loadScheduleWithAvailability();
    }
  }

  void _loadScheduleWithAvailability() async {
    if (widget.clinicId == null) {
      setState(() {
        _hasLoaded = true;
      });
      return;
    }

    try {
      print('WeekDaysGrid: Loading data for week starting ${widget.selectedDate.toString().split(' ')[0]}');
      // Get weekly availability data for the selected week
      final weeklyData = await ClinicScheduleService.getWeeklyScheduleWithAvailability(
        widget.clinicId!,
        widget.selectedDate, // Use the selected date instead of DateTime.now()
      );
      
      print('WeekDaysGrid: Loaded data for ${weeklyData.keys.length} days');
      setState(() {
        _weeklyAvailability = weeklyData;
        _hasLoaded = true;
      });
    } catch (e) {
      print('Error loading schedule availability: $e');
      setState(() {
        _hasLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show empty container while loading (no message)
    if (!_hasLoaded) {
      return Container();
    }
    
    // Only show "no operating days" message after loading is complete
    if (_weeklyAvailability == null || _weeklyAvailability!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No operating days configured. Please configure your clinic schedule first.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    // Get only open days from the schedule with availability data
    final openDays = <DayData>[];
    for (final day in WeeklySchedule.daysOfWeek) {
      final dayData = _weeklyAvailability![day];
      
      if (dayData != null && dayData['schedule'] != null) {
        final schedule = dayData['schedule'] as ClinicScheduleModel;
        if (schedule.isOpen) {
          final bookedSlots = dayData['bookedSlots'] as int;
          final utilization = dayData['utilization'] as int;
          
          // Remove slots information, only show time
          openDays.add(DayData(
            day,
            '', // Remove appointment text
            true,
            slotsInfo: null, // Remove slots info
            openTime: schedule.openTime,
            closeTime: schedule.closeTime,
            bookedSlots: bookedSlots,
            utilization: utilization,
          ));
        }
      }
    }

    if (openDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No operating days configured. Please configure your clinic schedule first.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: openDays.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == openDays.length - 1 ? 0 : 12),
            child: DayCard(
              day: day,
              isSelected: widget.selectedDay == day.name,
              onTap: () => widget.onDaySelected(day.name),
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
  final String? slotsInfo;
  final String? openTime;
  final String? closeTime;
  final int? bookedSlots;
  final int? utilization;

  DayData(
    this.name,
    this.appointments,
    this.hasData, {
    this.isDisabled = false,
    this.slotsInfo,
    this.openTime,
    this.closeTime,
    this.bookedSlots,
    this.utilization,
  });
}