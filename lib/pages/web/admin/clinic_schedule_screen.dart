import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/schedule_header.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/schedule_settings_modal.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/schedule_stats.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/time_slot_list.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/week_days_grid.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/week_navigation.dart';


class ClinicScheduleScreen extends StatefulWidget {
  const ClinicScheduleScreen({super.key});

  @override
  _ClinicScheduleScreenState createState() => _ClinicScheduleScreenState();
}

class _ClinicScheduleScreenState extends State<ClinicScheduleScreen> {
  String selectedView = 'Timeline';
  DateTime selectedDate = DateTime.now();
  String selectedDay = 'Monday';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clinic Schedule',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ScheduleSettingsModal(
                        onSave: (settings) {
                          // TODO: Handle settings update
                          print('New settings: $settings');
                        },
                      ),
                    );
                  },
                  icon: Icon(Icons.settings, size: 18),
                  label: Text('Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: kSpacingLarge),

            Card(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    SizedBox(height: kSpacingLarge),
                    WeekNavigation(
                      selectedDate: selectedDate,
                      onDateChanged: (date) {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                    ),
                    SizedBox(height: kSpacingLarge),
                    WeekDaysGrid(
                      selectedDay: selectedDay,
                      onDaySelected: (day) {
                        setState(() {
                          selectedDay = day;
                        });
                      },
                    ),
                    SizedBox(height: kSpacingLarge),
                    ScheduleStatsWidget(),
                  ],
                ),
              ),
            ),
            SizedBox(height: kSpacingLarge),
            TimeSlotList(selectedDay: selectedDay),
          ],
        ),
      ),
    );
  }
}

