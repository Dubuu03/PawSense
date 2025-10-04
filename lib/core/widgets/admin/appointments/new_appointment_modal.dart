import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/validators.dart';

class NewAppointmentModal extends StatefulWidget {
  final void Function(Map<String, dynamic> appointment)? onSchedule;

  const NewAppointmentModal({super.key, this.onSchedule});

  @override
  State<NewAppointmentModal> createState() => _NewAppointmentModalState();
}

class _NewAppointmentModalState extends State<NewAppointmentModal> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientSearchController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  String _petType = 'Dog';
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _duration = '30 minutes';
  String _urgency = 'Routine';
  String? _reason;
  final TextEditingController _notesController = TextEditingController();
  String _reminder = 'Email';

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final appointment = {
        'patientSearch': _patientSearchController.text,
        'petName': _petNameController.text,
        'petType': _petType,
        'ownerName': _ownerNameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'date': _selectedDate?.toIso8601String(),
        'time': _selectedTime?.format(context),
        'duration': _duration,
        'urgency': _urgency,
        'reason': _reason,
        'notes': _notesController.text,
        'reminder': _reminder,
      };

      widget.onSchedule?.call(appointment);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width * 0.5; // modal width

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: mq.size.height * 0.9),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.event_available_outlined, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Schedule New Appointment',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Book a consultation for a patient', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final modalWidth = constraints.maxWidth;
                        final narrow = modalWidth < 600;

                        Widget twoColumn(Widget left, Widget right, {double rightWidth = 160}) {
                          if (narrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [left, const SizedBox(height: 8), right],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: left),
                              const SizedBox(width: 12),
                              SizedBox(width: rightWidth, child: right),
                            ],
                          );
                        }

                        // threeColumn helper removed (not needed for appointment form)

                        return Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Patient Search', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _patientSearchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search for existing patient or create new...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              twoColumn(
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Pet Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _petNameController,
                                    validator: (v) => requiredValidator(v, 'pet name'),
                                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter pet's name"),
                                  ),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Pet Type', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _petType,
                                    items: const [
                                      DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                                      DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                                    ],
                                    onChanged: (v) => setState(() => _petType = v ?? 'Dog'),
                                    decoration: const InputDecoration(border: OutlineInputBorder()),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 12),

                              const Text('Owner Name *', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _ownerNameController,
                                validator: (v) => requiredValidator(v, 'owner name'),
                                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter owner's name"),
                              ),
                              const SizedBox(height: 12),

                              twoColumn(
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(controller: _phoneController, validator: phoneValidator, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '+1 (555) 123-4567')),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(controller: _emailController, validator: emailValidator, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'owner@email.com')),
                                ]),
                              ),

                              const SizedBox(height: 18),

                              const Text('Appointment Details', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),

                              twoColumn(
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Date *', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickDate,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(border: OutlineInputBorder()),
                                      child: Text(_selectedDate == null ? 'dd/mm/yyyy' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                                    ),
                                  ),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Time *', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _pickTime,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(border: OutlineInputBorder()),
                                      child: Text(_selectedTime == null ? '--:-- --' : _selectedTime!.format(context)),
                                    ),
                                  ),
                                ]),
                              ),

                              const SizedBox(height: 12),

                              twoColumn(
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Duration (minutes)', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _duration,
                                    items: const [
                                      DropdownMenuItem(value: '30 minutes', child: Text('30 minutes')),
                                      DropdownMenuItem(value: '60 minutes', child: Text('60 minutes')),
                                      DropdownMenuItem(value: '90 minutes', child: Text('90 minutes')),
                                    ],
                                    onChanged: (v) => setState(() => _duration = v ?? '30 minutes'),
                                    decoration: const InputDecoration(border: OutlineInputBorder()),
                                  ),
                                ]),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Urgency Level', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _urgency,
                                    items: const [
                                      DropdownMenuItem(value: 'Routine', child: Text('Routine')),
                                      DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                                    ],
                                    onChanged: (v) => setState(() => _urgency = v ?? 'Routine'),
                                    decoration: const InputDecoration(border: OutlineInputBorder()),
                                  ),
                                ]),
                              ),

                              const SizedBox(height: 12),

                              const Text('Reason for Visit *', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _reason,
                                items: const [
                                  DropdownMenuItem(value: 'Consultation', child: Text('Consultation')),
                                  DropdownMenuItem(value: 'Vaccination', child: Text('Vaccination')),
                                  DropdownMenuItem(value: 'Dental', child: Text('Dental')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) => setState(() => _reason = v),
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                                validator: (v) => requiredValidator(v, 'reason'),
                              ),

                              const SizedBox(height: 12),

                              const Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _notesController,
                                maxLines: 4,
                                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Any specific symptoms, concerns, or instructions...'),
                              ),

                              const SizedBox(height: 12),

                              const Text('Reminder Preference', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _reminder,
                                items: const [
                                  DropdownMenuItem(value: 'Email', child: Text('Email')),
                                  DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                                  DropdownMenuItem(value: 'None', child: Text('None')),
                                ],
                                onChanged: (v) => setState(() => _reminder = v ?? 'Email'),
                                decoration: const InputDecoration(border: OutlineInputBorder()),
                              ),

                              const SizedBox(height: 20),

                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    child: const Text('Schedule Appointment'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
