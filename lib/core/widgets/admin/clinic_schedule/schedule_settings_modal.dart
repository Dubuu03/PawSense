import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class ScheduleSettingsModal extends StatefulWidget {
  final void Function(Map<String, dynamic> settings)? onSave;

  const ScheduleSettingsModal({
    super.key,
    this.onSave,
  });

  @override
  State<ScheduleSettingsModal> createState() => _ScheduleSettingsModalState();
}

class _ScheduleSettingsModalState extends State<ScheduleSettingsModal> {
  final TextEditingController _startTimeController = TextEditingController(text: '09:00');
  final TextEditingController _endTimeController = TextEditingController(text: '17:00');
  
  // Working days
  final Map<String, bool> _workingDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': false,
    'Sunday': false,
  };

  // Appointment limits
  int _maxDailyAppointments = 28;
  int _maxPerTimeSlot = 4;

  // Blocked dates (holidays/closures)
  final List<DateTime> _blockedDates = [];
  final TextEditingController _blockDateController = TextEditingController();

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        } else {
          _endTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  Future<void> _selectBlockedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (!_blockedDates.contains(picked)) {
          _blockedDates.add(picked);
        }
      });
    }
  }

  void _removeBlockedDate(DateTime date) {
    setState(() {
      _blockedDates.remove(date);
    });
  }

  void _save() {
    final settings = {
      'clinicHours': {
        'start': _startTimeController.text,
        'end': _endTimeController.text,
      },
      'workingDays': _workingDays,
      'appointmentLimits': {
        'dailyMax': _maxDailyAppointments,
        'perTimeSlot': _maxPerTimeSlot,
      },
      'blockedDates': _blockedDates.map((date) => date.toIso8601String()).toList(),
    };

    widget.onSave?.call(settings);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width * 0.4;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: mq.size.height * 0.8),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFF3EEFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(Icons.settings, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clinic Schedule Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Configure working hours and availability',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clinic Hours Section
                      Text('Clinic Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Opening Time', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _startTimeController,
                                  readOnly: true,
                                  onTap: () => _selectTime(context, true),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "09:00",
                                    suffixIcon: Icon(Icons.access_time),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Closing Time', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _endTimeController,
                                  readOnly: true,
                                  onTap: () => _selectTime(context, false),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: "17:00",
                                    suffixIcon: Icon(Icons.access_time),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // Working Days Section
                      Text('Working Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _workingDays.entries.map((entry) {
                          return FilterChip(
                            selected: entry.value,
                            label: Text(entry.key),
                            onSelected: (bool selected) {
                              setState(() {
                                _workingDays[entry.key] = selected;
                              });
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                      // Appointment Limits Section
                      Text('Appointment Limits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Daily Maximum', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  value: _maxDailyAppointments,
                                  items: [20, 24, 28, 32, 36, 40].map((num) => 
                                    DropdownMenuItem(value: num, child: Text('$num appointments'))
                                  ).toList(),
                                  onChanged: (v) => setState(() => _maxDailyAppointments = v ?? 28),
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Per Time Slot', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<int>(
                                  value: _maxPerTimeSlot,
                                  items: [2, 3, 4, 5, 6].map((num) => 
                                    DropdownMenuItem(value: num, child: Text('$num appointments'))
                                  ).toList(),
                                  onChanged: (v) => setState(() => _maxPerTimeSlot = v ?? 4),
                                  decoration: const InputDecoration(border: OutlineInputBorder()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // Blocked Dates Section
                      Text('Blocked Dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Add holidays or emergency closure dates',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _blockDateController,
                              readOnly: true,
                              onTap: () => _selectBlockedDate(context),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Select date",
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _blockedDates.map((date) {
                          return Chip(
                            label: Text(
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 13),
                            ),
                            deleteIcon: Icon(Icons.close, size: 18),
                            onDeleted: () => _removeBlockedDate(date),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
