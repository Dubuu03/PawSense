import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/schedule_settings_modal_new.dart' as new_modal;
import 'package:pawsense/core/widgets/admin/clinic_schedule/schedule_stats.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/time_slot_list.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/week_days_grid.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/week_navigation.dart';

import 'package:pawsense/core/guards/auth_guard.dart';


class ClinicScheduleScreen extends StatefulWidget {
  final String? clinicId; // Add clinic ID parameter
  
  const ClinicScheduleScreen({super.key, this.clinicId});

  @override
  _ClinicScheduleScreenState createState() => _ClinicScheduleScreenState();
}

class _ClinicScheduleScreenState extends State<ClinicScheduleScreen> {
  String selectedView = 'Timeline';
  DateTime selectedDate = DateTime.now();
  String selectedDay = 'Monday';
  String? _actualClinicId;
  int _scheduleRefreshKey = 0; // Add refresh key

  @override
  void initState() {
    super.initState();
    _loadClinicId();
  }

  Future<void> _loadClinicId() async {
    try {
      if (widget.clinicId != null && widget.clinicId!.isNotEmpty) {
        _actualClinicId = widget.clinicId;
      } else {
        // Get clinic ID from current user's UID
        final currentUser = await AuthGuard.getCurrentUser();
        _actualClinicId = currentUser?.uid ?? 'default_clinic_id';
      }
      
      print('Loading clinic schedule for clinic ID: $_actualClinicId');
      setState(() {});
    } catch (e) {
      print('Error loading clinic ID: $e');
      _actualClinicId = 'default_clinic_id';
      setState(() {});
    }
  }

  void _refreshSchedule() {
    setState(() {
      _scheduleRefreshKey++; // Increment key to force rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if clinic ID is not yet loaded
    if (_actualClinicId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug widgets removed as requested
            
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
                      builder: (context) => new_modal.ScheduleSettingsModal(
                        clinicId: _actualClinicId!, // Pass actual clinic ID
                        onSave: (settings) {
                          // Handle settings update
                          print('Schedule updated for clinic $_actualClinicId: $settings');
                          // Refresh the schedule view
                          _refreshSchedule();
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
                      key: ValueKey('schedule_$_scheduleRefreshKey'), // Add refresh key
                      selectedDay: selectedDay,
                      clinicId: _actualClinicId, // Use actual clinic ID
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

