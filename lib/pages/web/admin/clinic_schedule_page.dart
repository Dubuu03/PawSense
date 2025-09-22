import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/schedule_settings_modal_new.dart' as new_modal;
import 'package:pawsense/core/widgets/admin/clinic_schedule/stats_card.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/appointment_time_slots.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/week_days_grid.dart';
import 'package:pawsense/core/widgets/admin/clinic_schedule/week_navigation.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class ClinicSchedulePage extends StatefulWidget {
  final String? clinicId;
  
  const ClinicSchedulePage({super.key, this.clinicId});

  @override
  _ClinicSchedulePageState createState() => _ClinicSchedulePageState();
}

class _ClinicSchedulePageState extends State<ClinicSchedulePage> {
  String selectedView = 'Timeline';
  DateTime selectedDate = DateTime.now();
  String selectedDay = 'Monday';
  String? _actualClinicId;
  int _scheduleRefreshKey = 0;
  
  // Statistics for the selected day
  Map<String, dynamic> _dayStats = {
    'totalAppointments': 0,
    'maxCapacity': 0,
    'utilization': 0,
    'availableSlots': 0,
  };
  
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _weekData = {};

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
        final currentUser = await AuthGuard.getCurrentUser();
        _actualClinicId = currentUser?.uid ?? 'default_clinic_id';
      }
      
      print('Loading clinic schedule for clinic ID: $_actualClinicId');
      await _loadWeekData();
      setState(() {});
    } catch (e) {
      print('Error loading clinic ID: $e');
      _actualClinicId = 'default_clinic_id';
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeekData() async {
    if (_actualClinicId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the Monday of the current selected week
      final weekday = selectedDate.weekday;
      final monday = selectedDate.subtract(Duration(days: weekday - 1));
      
      // Load weekly data with appointment availability
      _weekData = await ClinicScheduleService.getWeeklyScheduleWithAvailability(
        _actualClinicId!, 
        monday
      );
      
      // Set the selected day to match the current date
      final currentDayName = _getCurrentDayName();
      setState(() {
        selectedDay = currentDayName;
      });

      // Calculate statistics for the currently selected day
      _calculateDayStats();
      
    } catch (e) {
      print('Error loading week data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }  String _getCurrentDayName() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[selectedDate.weekday - 1];
  }

  void _calculateDayStats() {
    if (_weekData.isEmpty) {
      _dayStats = {
        'totalAppointments': 0,
        'maxCapacity': 0,
        'utilization': 0,
        'availableSlots': 0,
      };
      return;
    }

    // Get the current selected day's data
    final currentDayData = _weekData[selectedDay];
    
    if (currentDayData != null) {
      final bookedSlots = currentDayData['bookedSlots'] ?? 0;
      final totalSlots = currentDayData['totalSlots'] ?? 0;
      final availableSlots = currentDayData['availableSlots'] ?? 0;
      final utilization = currentDayData['utilization'] ?? 0;

      _dayStats = {
        'totalAppointments': bookedSlots,
        'maxCapacity': totalSlots,
        'utilization': utilization,
        'availableSlots': availableSlots,
      };
    } else {
      _dayStats = {
        'totalAppointments': 0,
        'maxCapacity': 0,
        'utilization': 0,
        'availableSlots': 0,
      };
    }
  }

  void _refreshSchedule() {
    setState(() {
      _scheduleRefreshKey++;
    });
    _loadWeekData();
  }

  Future<void> _onDateChanged(DateTime newDate) async {
    print('Date changed from ${selectedDate.toString().split(' ')[0]} to ${newDate.toString().split(' ')[0]}');
    setState(() {
      selectedDate = newDate;
    });
    await _loadWeekData();
  }

  void _onDaySelected(String day) {
    setState(() {
      selectedDay = day;
    });
    _calculateDayStats();
  }

  DateTime _getDateForSelectedDay() {
    // Get the Monday of the current selected week
    final weekday = selectedDate.weekday;
    final monday = selectedDate.subtract(Duration(days: weekday - 1));
    
    // Map day names to weekday numbers (1-7, Monday=1)
    const dayToWeekday = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    
    final targetWeekday = dayToWeekday[selectedDay] ?? 1;
    return monday.add(Duration(days: targetWeekday - 1));
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
                        clinicId: _actualClinicId!,
                        onSave: (settings) {
                          print('Schedule updated for clinic $_actualClinicId: $settings');
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
                    WeekNavigation(
                      selectedDate: selectedDate,
                      onDateChanged: _onDateChanged,
                    ),
                    SizedBox(height: kSpacingLarge),
                    WeekDaysGrid(
                      key: ValueKey('schedule_$_scheduleRefreshKey'),
                      selectedDay: selectedDay,
                      clinicId: _actualClinicId,
                      onDaySelected: _onDaySelected,
                      selectedDate: selectedDate, // Pass the selected date
                    ),
                    SizedBox(height: kSpacingLarge),
                    
                    // Dynamic Schedule Statistics
                    if (_isLoading) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading schedule data...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              icon: Icons.calendar_today,
                              iconColor: Colors.purple,
                              value: '${_dayStats['totalAppointments']}',
                              label: 'Total Appointments',
                              backgroundColor: Colors.purple.withOpacity(0.1),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              icon: Icons.people_outline,
                              iconColor: Colors.blue,
                              value: '${_dayStats['maxCapacity']}',
                              label: 'Max Capacity',
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              icon: Icons.check_circle_outline,
                              iconColor: Colors.green,
                              value: '${_dayStats['utilization']}%',
                              label: 'Utilization',
                              backgroundColor: Colors.green.withOpacity(0.1),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              icon: Icons.access_time,
                              iconColor: Colors.orange,
                              value: '${_dayStats['availableSlots']}',
                              label: 'Time Slots',
                              backgroundColor: Colors.orange.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: kSpacingLarge),
            
            // Only show appointments section when schedule data is loaded
            if (!_isLoading) ...[
              AppointmentTimeSlots(
                selectedDay: selectedDay,
                clinicId: _actualClinicId,
                selectedDate: _getDateForSelectedDay(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
