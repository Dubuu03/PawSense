import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';

class ScheduleSettingsModal extends StatefulWidget {
  final void Function(Map<String, dynamic> settings)? onSave;
  final String? clinicId;

  const ScheduleSettingsModal({
    super.key,
    this.onSave,
    this.clinicId,
  });

  @override
  State<ScheduleSettingsModal> createState() => _ScheduleSettingsModalState();
}

class _ScheduleSettingsModalState extends State<ScheduleSettingsModal> {
  late Future<WeeklySchedule> _weeklyScheduleFuture;
  final Map<String, bool> _isOpenMap = {};
  final Map<String, TimeOfDay?> _openTimeMap = {};
  final Map<String, TimeOfDay?> _closeTimeMap = {};
  final Map<String, List<BreakTime>> _breakTimesMap = {};
  final Map<String, TextEditingController> _notesControllers = {};
  
  // Holiday management
  final List<DateTime> _specialHolidays = [];
  
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSchedule();
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final day in WeeklySchedule.daysOfWeek) {
      _notesControllers[day] = TextEditingController();
      _breakTimesMap[day] = [];
    }
  }

  void _loadSchedule() {
    if (widget.clinicId == null) {
      _weeklyScheduleFuture = Future.value(WeeklySchedule(schedules: {}));
      return;
    }
    
    _weeklyScheduleFuture = ClinicScheduleService.getWeeklySchedule(widget.clinicId!);
    _weeklyScheduleFuture.then((schedule) {
      for (final day in WeeklySchedule.daysOfWeek) {
        final daySchedule = schedule.getScheduleForDay(day);
        if (daySchedule != null) {
          _isOpenMap[day] = daySchedule.isOpen;
          _openTimeMap[day] = daySchedule.openTime != null 
              ? _parseTimeString(daySchedule.openTime!) 
              : null;
          _closeTimeMap[day] = daySchedule.closeTime != null 
              ? _parseTimeString(daySchedule.closeTime!) 
              : null;
          _breakTimesMap[day] = List.from(daySchedule.breakTimes);
          _notesControllers[day]?.text = daySchedule.notes ?? '';
        } else {
          _isOpenMap[day] = day != 'Saturday' && day != 'Sunday';
          _openTimeMap[day] = const TimeOfDay(hour: 9, minute: 0);
          _closeTimeMap[day] = const TimeOfDay(hour: 17, minute: 0);
          _breakTimesMap[day] = [];
        }
      }
      setState(() {});
    });
  }

  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Validation functions
  bool _isOpenTimeBeforeCloseTime(String day) {
    final openTime = _openTimeMap[day];
    final closeTime = _closeTimeMap[day];
    
    if (openTime == null || closeTime == null) return true;
    
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;
    
    return openMinutes < closeMinutes;
  }

  bool _isBreakTimeValid(BreakTime breakTime) {
    final startParts = breakTime.startTime.split(':');
    final endParts = breakTime.endTime.split(':');
    
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    return startMinutes < endMinutes;
  }

  bool _isBreakTimeWithinOperatingHours(String day, BreakTime breakTime) {
    final openTime = _openTimeMap[day];
    final closeTime = _closeTimeMap[day];
    
    if (openTime == null || closeTime == null) return false;
    
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;
    
    final startParts = breakTime.startTime.split(':');
    final endParts = breakTime.endTime.split(':');
    
    final breakStartMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final breakEndMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    return breakStartMinutes >= openMinutes && breakEndMinutes <= closeMinutes;
  }

  String? _validateSchedule() {
    for (final day in WeeklySchedule.daysOfWeek) {
      if (_isOpenMap[day] == true) {
        if (_openTimeMap[day] == null || _closeTimeMap[day] == null) {
          return 'Please set both opening and closing times for $day';
        }
        
        if (!_isOpenTimeBeforeCloseTime(day)) {
          return 'Opening time must be before closing time for $day';
        }
        
        final breakTimes = _breakTimesMap[day] ?? [];
        for (final breakTime in breakTimes) {
          if (!_isBreakTimeValid(breakTime)) {
            return 'Break time start must be before end time for $day (${breakTime.label ?? 'Break'})';
          }
          
          if (!_isBreakTimeWithinOperatingHours(day, breakTime)) {
            return 'Break time must be within operating hours for $day (${breakTime.label ?? 'Break'})';
          }
        }
      }
    }
    return null;
  }

  Future<void> _selectHoliday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Holiday Date',
    );

    if (picked != null) {
      setState(() {
        if (!_specialHolidays.contains(picked)) {
          _specialHolidays.add(picked);
        }
      });
    }
  }

  void _removeHoliday(DateTime date) {
    setState(() {
      _specialHolidays.remove(date);
    });
  }

  // Updated save schedule with validation
  Future<void> _saveSchedule() async {
    // Validate schedule before saving
    final validationError = _validateSchedule();
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    if (widget.clinicId == null) {
      setState(() {
        _errorMessage = 'Clinic ID is required to save schedule';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final schedules = <ClinicScheduleModel>[];
      
      for (final day in WeeklySchedule.daysOfWeek) {
        final schedule = ClinicScheduleModel(
          id: '${widget.clinicId}_${day.toLowerCase()}',
          clinicId: widget.clinicId!,
          dayOfWeek: day,
          openTime: _openTimeMap[day] != null ? _formatTimeOfDay(_openTimeMap[day]!) : null,
          closeTime: _closeTimeMap[day] != null ? _formatTimeOfDay(_closeTimeMap[day]!) : null,
          isOpen: _isOpenMap[day] ?? false,
          breakTimes: _breakTimesMap[day] ?? [],
          notes: _notesControllers[day]?.text.trim().isEmpty == true 
              ? null 
              : _notesControllers[day]?.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        schedules.add(schedule);
      }
      
      final success = await ClinicScheduleService.saveWeeklySchedule(widget.clinicId!, schedules);
      
      if (success) {
        setState(() {
          _successMessage = 'Schedule saved successfully!';
        });
        
        // Call the onSave callback if provided
        widget.onSave?.call({
          'schedules': schedules.map((s) => s.toFirestore()).toList(),
          'holidays': _specialHolidays.map((d) => d.toIso8601String()).toList(),
        });
        
        // Close modal after short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to save schedule. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Operating Days Section with clickable chips
  Widget _buildOperatingDaysSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white,
            AppColors.bgsecond.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Operating Days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Select which days your clinic is open:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: WeeklySchedule.daysOfWeek.map((day) {
                final isOpen = _isOpenMap[day] ?? false;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _isOpenMap[day] = !isOpen;
                      if (!isOpen) {
                        // Clear times and breaks when day is closed
                        _openTimeMap[day] = null;
                        _closeTimeMap[day] = null;
                        _breakTimesMap[day] = [];
                        _notesControllers[day]?.clear();
                      } else {
                        // Set default times when day is opened
                        _openTimeMap[day] = const TimeOfDay(hour: 9, minute: 0);
                        _closeTimeMap[day] = const TimeOfDay(hour: 17, minute: 0);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isOpen 
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          )
                        : LinearGradient(
                            colors: [AppColors.white, AppColors.bgsecond.withOpacity(0.5)],
                          ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isOpen ? AppColors.primary : AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isOpen 
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.textSecondary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isOpen ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isOpen ? AppColors.white : AppColors.primary,
                            size: 18,
                            key: ValueKey(isOpen),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          day,
                          style: TextStyle(
                            color: isOpen ? AppColors.white : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Time Settings Section
  Widget _buildTimeSettingsSection() {
    final openDays = WeeklySchedule.daysOfWeek.where((day) => _isOpenMap[day] == true).toList();
    
    if (openDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withOpacity(0.1),
              AppColors.warning.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.white, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Please select at least one operating day to set opening hours.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white,
            AppColors.bgsecond.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.access_time, color: AppColors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Operating Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...openDays.map((day) => _buildDayTimeSettings(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTimeSettings(String day) {
    final openTime = _openTimeMap[day];
    final closeTime = _closeTimeMap[day];
    final breakTimes = _breakTimesMap[day] ?? [];
    final hasTimeError = !_isOpenTimeBeforeCloseTime(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white,
            AppColors.bgsecond.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasTimeError ? AppColors.error : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasTimeError 
              ? AppColors.error.withOpacity(0.1)
              : AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.today,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Time validation error
            if (hasTimeError)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withOpacity(0.1),
                      AppColors.error.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.error_outline, color: AppColors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Opening time must be before closing time',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Open and close time pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Open Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: openTime ?? const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _openTimeMap[day] = time;
                              _errorMessage = null; // Clear error when time is changed
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasTimeError ? AppColors.error : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                openTime?.format(context) ?? 'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: openTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                              Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Close Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: closeTime ?? const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _closeTimeMap[day] = time;
                              _errorMessage = null; // Clear error when time is changed
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasTimeError ? AppColors.error : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                closeTime?.format(context) ?? 'Select',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: closeTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                              Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Break times section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Break Times',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addBreakTime(day),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            
            if (breakTimes.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...breakTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final breakTime = entry.value;
                final isBreakValid = _isBreakTimeValid(breakTime);
                final isWithinHours = _isBreakTimeWithinOperatingHours(day, breakTime);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (!isBreakValid || !isWithinHours) 
                        ? AppColors.error.withOpacity(0.1) 
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (!isBreakValid || !isWithinHours) 
                          ? AppColors.error.withOpacity(0.3) 
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.coffee, color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${breakTime.startTime} - ${breakTime.endTime}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (breakTime.label != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    breakTime.label!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeBreakTime(day, index),
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 16,
                            color: AppColors.error,
                            tooltip: 'Remove break time',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          ),
                        ],
                      ),
                      // Break time validation errors
                      if (!isBreakValid || !isWithinHours) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                !isBreakValid 
                                    ? 'Break start time must be before end time'
                                    : 'Break time must be within operating hours',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Holiday Management Section
  Widget _buildHolidaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Holidays',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Add special holidays when your clinic will be closed:',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        
        // Add holiday button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _selectHoliday(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Holiday Date'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Holiday list
        if (_specialHolidays.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled Holidays:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._specialHolidays.map((date) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_busy, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => _removeHoliday(date),
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 16,
                          color: AppColors.error,
                          tooltip: 'Remove holiday',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'No special holidays added',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _addBreakTime(String day) {
    showDialog(
      context: context,
      builder: (context) => _AddBreakTimeDialog(
        day: day,
        openTime: _openTimeMap[day],
        closeTime: _closeTimeMap[day],
        onAdd: (breakTime) {
          // Validate break time before adding
          if (!_isBreakTimeValid(breakTime)) {
            setState(() {
              _errorMessage = 'Break start time must be before end time';
            });
            return;
          }
          
          if (!_isBreakTimeWithinOperatingHours(day, breakTime)) {
            setState(() {
              _errorMessage = 'Break time must be within operating hours';
            });
            return;
          }
          
          setState(() {
            _breakTimesMap[day]?.add(breakTime);
            _errorMessage = null;
          });
        },
      ),
    );
  }

  void _removeBreakTime(String day, int index) {
    setState(() {
      _breakTimesMap[day]?.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        height: 750,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.bgsecond.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with violet accent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.bgsecond.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clinic Schedule Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Configure your clinic operating hours and holidays',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.white.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Success/Error Messages
            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.1),
                      AppColors.success.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.check, color: AppColors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withOpacity(0.1),
                      AppColors.error.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.error_outline, color: AppColors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Schedule Settings
            Expanded(
              child: FutureBuilder<WeeklySchedule>(
                future: _weeklyScheduleFuture,
                builder: (context, snapshot) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Operating Days Section
                        _buildOperatingDaysSection(),
                        const SizedBox(height: 24),
                        
                        // Time Settings Section
                        _buildTimeSettingsSection(),
                        const SizedBox(height: 24),
                        
                        // Holiday Management Section
                        _buildHolidaySection(),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Action Buttons
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.bgsecond.withOpacity(0.3),
                    AppColors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.save, size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  'Save Schedule',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for adding break times with validation
class _AddBreakTimeDialog extends StatefulWidget {
  final String day;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final Function(BreakTime) onAdd;
  
  const _AddBreakTimeDialog({
    required this.day,
    required this.openTime,
    required this.closeTime,
    required this.onAdd,
  });

  @override
  State<_AddBreakTimeDialog> createState() => _AddBreakTimeDialogState();
}

class _AddBreakTimeDialogState extends State<_AddBreakTimeDialog> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _labelController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isValidBreakTime() {
    if (_startTime == null || _endTime == null) return false;
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    // Check if start is before end
    if (startMinutes >= endMinutes) {
      _errorMessage = 'Break start time must be before end time';
      return false;
    }
    
    // Check if within operating hours
    if (widget.openTime != null && widget.closeTime != null) {
      final operatingStartMinutes = widget.openTime!.hour * 60 + widget.openTime!.minute;
      final operatingEndMinutes = widget.closeTime!.hour * 60 + widget.closeTime!.minute;
      
      if (startMinutes < operatingStartMinutes || endMinutes > operatingEndMinutes) {
        _errorMessage = 'Break time must be within operating hours (${widget.openTime!.format(context)} - ${widget.closeTime!.format(context)})';
        return false;
      }
    }
    
    _errorMessage = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Row(
        children: [
          const Icon(Icons.coffee, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Add Break Time - ${widget.day}', style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // Operating hours info
          if (widget.openTime != null && widget.closeTime != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Operating hours: ${widget.openTime!.format(context)} - ${widget.closeTime!.format(context)}',
                      style: const TextStyle(color: AppColors.info, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          // Start time picker
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _startTime ?? widget.openTime ?? const TimeOfDay(hour: 12, minute: 0),
              );
              if (time != null) {
                setState(() {
                  _startTime = time;
                  _isValidBreakTime(); // Validate on change
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _startTime?.format(context) ?? 'Select start time',
                    style: TextStyle(
                      color: _startTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.access_time, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // End time picker
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _endTime ?? widget.closeTime ?? const TimeOfDay(hour: 13, minute: 0),
              );
              if (time != null) {
                setState(() {
                  _endTime = time;
                  _isValidBreakTime(); // Validate on change
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _endTime?.format(context) ?? 'Select end time',
                    style: TextStyle(
                      color: _endTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.access_time, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Label field
          TextField(
            controller: _labelController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Label (optional)',
              hintText: 'e.g., Lunch Break',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _startTime != null && _endTime != null && _isValidBreakTime()
              ? () {
                  final breakTime = BreakTime(
                    startTime: _formatTimeOfDay(_startTime!),
                    endTime: _formatTimeOfDay(_endTime!),
                    label: _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
                  );
                  widget.onAdd(breakTime);
                  Navigator.of(context).pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}