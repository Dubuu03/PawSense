import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class AddTimeSlotModal extends StatefulWidget {
  final void Function(Map<String, dynamic> timeSlot)? onCreate;
  final String selectedDay;

  const AddTimeSlotModal({
    super.key, 
    this.onCreate,
    required this.selectedDay,
  });

  @override
  State<AddTimeSlotModal> createState() => _AddTimeSlotModalState();
}

class _AddTimeSlotModalState extends State<AddTimeSlotModal> {
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  String _slotType = 'Consultation';
  int _capacity = 4;

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

  void _save() {
    if (_startTimeController.text.isNotEmpty && _endTimeController.text.isNotEmpty) {
      final timeSlot = {
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
        'type': _slotType,
        'capacity': _capacity,
        'day': widget.selectedDay,
      };

      widget.onCreate?.call(timeSlot);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width * 0.35;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: mq.size.height * 0.7),
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
                          child: Icon(Icons.schedule, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Time Slot',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            widget.selectedDay,
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
              
              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _startTimeController,
                          readOnly: true,
                          onTap: () => _selectTime(context, true),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "00:00",
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
                        const Text('End Time *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _endTimeController,
                          readOnly: true,
                          onTap: () => _selectTime(context, false),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "00:00",
                            suffixIcon: Icon(Icons.access_time),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slot Type
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Slot Type *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _slotType,
                    items: const [
                      DropdownMenuItem(value: 'Consultation', child: Text('Consultation')),
                      DropdownMenuItem(value: 'Surgery', child: Text('Surgery')),
                      DropdownMenuItem(value: 'Emergency', child: Text('Emergency')),
                    ],
                    onChanged: (v) => setState(() => _slotType = v ?? 'Consultation'),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Capacity
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Capacity *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _capacity,
                    items: List.generate(5, (i) => i + 1).map((num) => 
                      DropdownMenuItem(value: num, child: Text('$num appointments'))
                    ).toList(),
                    onChanged: (v) => setState(() => _capacity = v ?? 4),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
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
                    child: const Text('Create Time Slot'),
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
