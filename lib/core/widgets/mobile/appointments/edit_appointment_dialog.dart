import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';

class EditAppointmentDialog extends StatefulWidget {
  final AppointmentBooking appointment;
  final VoidCallback? onUpdated;

  const EditAppointmentDialog({
    super.key,
    required this.appointment,
    this.onUpdated,
  });

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _serviceNameController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedTime;
  AppointmentType _selectedType = AppointmentType.general;
  bool _isLoading = false;

  // Available time slots (could be fetched from clinic service in real implementation)
  final List<String> _timeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _notesController.text = widget.appointment.notes;
    _serviceNameController.text = widget.appointment.serviceName;
    _selectedDate = widget.appointment.appointmentDate;
    _selectedTime = widget.appointment.appointmentTime;
    _selectedType = widget.appointment.type;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _serviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildForm(),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.edit,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Edit Appointment',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServiceNameField(),
          const SizedBox(height: 16),
          _buildAppointmentTypeField(),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 16),
          _buildTimeField(),
          const SizedBox(height: 16),
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildServiceNameField() {
    return TextFormField(
      controller: _serviceNameController,
      decoration: InputDecoration(
        labelText: 'Service Name',
        hintText: 'Enter service name...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.medical_services, color: AppColors.primary),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Service name is required';
        }
        return null;
      },
    );
  }

  Widget _buildAppointmentTypeField() {
    return DropdownButtonFormField<AppointmentType>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Appointment Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.category, color: AppColors.primary),
      ),
      items: AppointmentType.values.map((type) {
        return DropdownMenuItem<AppointmentType>(
          value: type,
          child: Text(_getAppointmentTypeDisplayName(type)),
        );
      }).toList(),
      onChanged: (AppointmentType? value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Appointment Date',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
          suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
        ),
        child: Text(
          _selectedDate != null
              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
              : 'Select date...',
          style: TextStyle(
            color: _selectedDate != null ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return DropdownButtonFormField<String>(
      value: _selectedTime,
      decoration: InputDecoration(
        labelText: 'Appointment Time',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.access_time, color: AppColors.primary),
      ),
      items: _timeSlots.map((time) {
        return DropdownMenuItem<String>(
          value: time,
          child: Text(time),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedTime = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an appointment time';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional notes...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        prefixIcon: Icon(Icons.notes, color: AppColors.primary),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  void _selectDate() async {
    final now = DateTime.now();
    final firstDate = now; // Can't select past dates
    final lastDate = now.add(const Duration(days: 90)); // 90 days in advance

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an appointment date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AppointmentBookingService.updateUserAppointmentDetails(
        widget.appointment.id!,
        notes: _notesController.text.trim(),
        serviceName: _serviceNameController.text.trim(),
        appointmentDate: _selectedDate,
        appointmentTime: _selectedTime,
        type: _selectedType,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
          widget.onUpdated?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update appointment. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAppointmentTypeDisplayName(AppointmentType type) {
    switch (type) {
      case AppointmentType.general:
        return 'General Consultation';
      case AppointmentType.emergency:
        return 'Emergency';
      case AppointmentType.followUp:
        return 'Follow-up';
      case AppointmentType.vaccination:
        return 'Vaccination';
      case AppointmentType.surgery:
        return 'Surgery';
      case AppointmentType.consultation:
        return 'Consultation';
    }
  }
}