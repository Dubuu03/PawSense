import 'package:flutter/material.dart';
import 'package:pawsense/core/models/schedule_stats.dart';
import 'stats_card.dart';

class ScheduleStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = ScheduleStats(
      totalAppointments: 15,
      maxCapacity: 28,
      utilization: 54.0,
      timeSlots: 9,
    );

    return Row(
      children: [
        Expanded(
          child: StatsCard(
            icon: Icons.calendar_today,
            iconColor: Colors.purple,
            value: '${stats.totalAppointments}',
            label: 'Total Appointments',
            backgroundColor: Colors.purple.withOpacity(0.1),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            icon: Icons.people_outline,
            iconColor: Colors.blue,
            value: '${stats.maxCapacity}',
            label: 'Max Capacity',
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            value: '${stats.utilization.toInt()}%',
            label: 'Utilization',
            backgroundColor: Colors.green.withOpacity(0.1),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            icon: Icons.access_time,
            iconColor: Colors.orange,
            value: '${stats.timeSlots}',
            label: 'Time Slots',
            backgroundColor: Colors.orange.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}