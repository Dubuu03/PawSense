import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/schedule_header.dart';
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
            ScheduleHeader(
                  selectedView: selectedView,
                  onViewChanged: (view) {
                    setState(() {
                    selectedView = view;
                });
              },
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

