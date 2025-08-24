import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/time_slot.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/time_slot_item.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/add_time_slot_modal.dart';

class TimeSlotList extends StatelessWidget {
  final String selectedDay;

  const TimeSlotList({
    super.key,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final timeSlots = _getTimeSlots();
    final dayInfo = _getDayInfo(selectedDay);

    return Card(
      elevation: 2,
       color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dayInfo['dayName']} Schedule',
                      style: TextStyle(
                        fontSize: kFontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      dayInfo['date'] ?? '',
                      style: TextStyle(
                        fontSize: kFontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddTimeSlotModal(
                        selectedDay: selectedDay,
                        onCreate: (timeSlot) {
                          // TODO: Handle time slot creation
                          print('New time slot: $timeSlot');
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add Time Slot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: kSpacingSmall),
            // Divider between header and list
            Divider(
              color: AppColors.textSecondary.withOpacity(0.2),
              thickness: 1,
            ),

            SizedBox(height: kSpacingLarge),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: timeSlots.length,
              separatorBuilder: (context, index) => SizedBox(height: kSpacingSmall),
              itemBuilder: (context, index) {
                return TimeSlotItem(timeSlot: timeSlots[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getDayInfo(String selectedDay) {
    final Map<String, Map<String, String>> dayData = {
      'Monday': {
        'dayName': 'Monday',
        'date': '2025-01-20',
      },
      'Tuesday': {
        'dayName': 'Tuesday', 
        'date': '2025-01-21',
      },
      'Wednesday': {
        'dayName': 'Wednesday',
        'date': '2025-01-22',
      },
      'Thursday': {
        'dayName': 'Thursday',
        'date': '2025-01-23',
      },
      'Friday': {
        'dayName': 'Friday',
        'date': '2025-01-24',
      },
      'Saturday': {
        'dayName': 'Saturday',
        'date': '2025-01-25',
      },
      'Sunday': {
        'dayName': 'Sunday',
        'date': '2025-01-26',
      },
    };

    return dayData[selectedDay] ?? dayData['Monday']!;
  }

  List<TimeSlot> _getTimeSlots() {
    // Generate different time slots based on the selected day
    final baseTimeSlots = [
      {
        'startTime': '08:00',
        'endTime': '09:00',
        'type': 'Consultation',
        'currentAppointments': 2,
        'maxAppointments': 4,
      },
      {
        'startTime': '09:00',
        'endTime': '10:00',
        'type': 'Consultation',
        'currentAppointments': 4,
        'maxAppointments': 4,
      },
      {
        'startTime': '10:00',
        'endTime': '11:00',
        'type': 'Surgery',
        'currentAppointments': 1,
        'maxAppointments': 2,
      },
      {
        'startTime': '11:00',
        'endTime': '12:00',
        'type': 'Consultation',
        'currentAppointments': 3,
        'maxAppointments': 4,
      },
      {
        'startTime': '14:00',
        'endTime': '15:00',
        'type': 'Emergency',
        'currentAppointments': 0,
        'maxAppointments': 2,
      },
      {
        'startTime': '15:00',
        'endTime': '16:00',
        'type': 'Consultation',
        'currentAppointments': 1,
        'maxAppointments': 4,
      },
    ];

    return baseTimeSlots.map((slot) {
      final current = slot['currentAppointments'] as int;
      final max = slot['maxAppointments'] as int;
      final utilization = (current / max * 100).toDouble();
      
      Color progressColor;
      if (utilization >= 90) {
        progressColor = AppColors.error;
      } else if (utilization >= 70) {
        progressColor = AppColors.warning;
      } else {
        progressColor = AppColors.success;
      }

      return TimeSlot(
        startTime: slot['startTime'] as String,
        endTime: slot['endTime'] as String,
        type: slot['type'] as String,
        currentAppointments: current,
        maxAppointments: max,
        utilizationPercentage: utilization,
        progressColor: progressColor,
      );
    }).toList();
  }
}