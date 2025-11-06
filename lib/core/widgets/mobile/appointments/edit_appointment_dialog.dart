import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/services/clinic/appointment_service.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

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
  String? _selectedService;
  bool _isLoading = false;
  bool _loadingTimeSlots = false;
  bool _loadingServices = false;

  // Pet selection (only when no assessment is linked)
  List<Pet> _userPets = [];
  String? _selectedPetId;
  bool _loadingPets = false;

  // Dynamic data based on clinic
  List<String> _availableTimeSlots = [];
  List<Map<String, dynamic>> _availableServices = [];
  WeeklySchedule? _clinicSchedule;
  List<DateTime> _holidayDates = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadClinicData();
  }

  void _initializeForm() {
    _notesController.text = widget.appointment.notes;
    _serviceNameController.text = widget.appointment.serviceName;
    _selectedService = widget.appointment.serviceName;
    _selectedPetId = widget.appointment.petId;
    
    // Ensure we have a proper DateTime object (normalize to date only)
    _selectedDate = DateTime(
      widget.appointment.appointmentDate.year,
      widget.appointment.appointmentDate.month,
      widget.appointment.appointmentDate.day,
    );
    
    _selectedTime = widget.appointment.appointmentTime;
    
    print('🔧 Initialized form with:');
    print('   Service: ${widget.appointment.serviceName}');
    print('   Pet ID: ${widget.appointment.petId}');
    print('   Date: ${widget.appointment.appointmentDate} -> $_selectedDate');
    print('   Time: ${widget.appointment.appointmentTime}');
    print('   Assessment ID: ${widget.appointment.assessmentResultId}');
  }

  Future<void> _loadClinicData() async {
    setState(() {
      _loadingServices = true;
    });

    print('🔄 Loading clinic data for clinic: ${widget.appointment.clinicId}');
    await Future.wait([
      _loadClinicServices(),
      _loadClinicSchedule(),
      if (_canEditPet()) _loadUserPets(), // Load pets only if no assessment
    ]);

    print('✅ Clinic data loaded. Selected date: $_selectedDate, Selected time: $_selectedTime');
    // Load time slots for the currently selected date
    await _loadAvailableTimeSlots();
  }

  Future<void> _loadClinicServices() async {
    try {
      // Fetch services for the appointment's clinic from Firestore
      final servicesQuery = await FirebaseFirestore.instance
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: widget.appointment.clinicId)
          .limit(1)
          .get();
      
      List<Map<String, dynamic>> services = [];
      
      if (servicesQuery.docs.isNotEmpty) {
        final doc = servicesQuery.docs.first;
        final data = doc.data();
        final clinicServices = List<Map<String, dynamic>>.from(data['services'] ?? []);
        
        // Filter only active services
        services = clinicServices.where((service) => service['isActive'] == true).toList();
      }
      
      // If no services found, use default services as fallback
      if (services.isEmpty) {
        services = [
          {
            'id': 'default-general',
            'serviceName': 'General Consultation',
            'serviceDescription': 'Professional veterinary consultation',
            'estimatedPrice': '0.00',
            'duration': '30 mins',
            'category': 'consultation',
          },
          {
            'id': 'default-checkup',
            'serviceName': 'Health Checkup',
            'serviceDescription': 'Comprehensive health examination',
            'estimatedPrice': '0.00',
            'duration': '30 mins',
            'category': 'consultation',
          },
        ];
      }
      
      setState(() {
        _availableServices = services;
        
        // Set the service name controller to the current service name
        // or the first available service if current service is not found
        bool serviceFound = false;
        for (final service in services) {
          if (service['serviceName'] == widget.appointment.serviceName) {
            _serviceNameController.text = service['serviceName'];
            _selectedService = service['serviceName'];
            serviceFound = true;
            break;
          }
        }
        
        // If current service not found in clinic services, keep the current value
        if (!serviceFound) {
          _serviceNameController.text = widget.appointment.serviceName;
          _selectedService = widget.appointment.serviceName;
        }
        
        _loadingServices = false;
      });
    } catch (e) {
      print('Error loading clinic services: $e');
      setState(() {
        _loadingServices = false;
        // Use current service name as fallback
        _serviceNameController.text = widget.appointment.serviceName;
        _selectedService = widget.appointment.serviceName;
      });
    }
  }

  Future<void> _loadClinicSchedule() async {
    try {
      print('🔄 Loading clinic schedule for: ${widget.appointment.clinicId}');
      final schedule = await ClinicScheduleService.getWeeklySchedule(widget.appointment.clinicId);
      setState(() {
        _clinicSchedule = schedule;
      });
      print('✅ Clinic schedule loaded successfully');
    } catch (e) {
      print('❌ Error loading clinic schedule: $e');
    }
  }

  /// Check if the pet can be edited (no assessment linked)
  bool _canEditPet() {
    return widget.appointment.assessmentResultId == null || 
           widget.appointment.assessmentResultId!.isEmpty;
  }

  Future<void> _loadUserPets() async {
    setState(() {
      _loadingPets = true;
    });

    try {
      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final pets = await PetService.getUserPets(user.uid);
        setState(() {
          _userPets = pets;
          _loadingPets = false;
        });
        print('✅ Loaded ${pets.length} user pets');
      } else {
        setState(() {
          _loadingPets = false;
        });
        print('❌ No user found for pet loading');
      }
    } catch (e) {
      print('❌ Error loading user pets: $e');
      setState(() {
        _loadingPets = false;
      });
    }
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate == null || _clinicSchedule == null) {
      print('⚠️ Cannot load time slots: selectedDate=$_selectedDate, clinicSchedule=${_clinicSchedule != null}');
      setState(() {
        _availableTimeSlots = [];
        _loadingTimeSlots = false;
      });
      return;
    }

    print('🔄 Loading hourly time slots for date: $_selectedDate, clinic: ${widget.appointment.clinicId}');
    setState(() {
      _loadingTimeSlots = true;
    });

    try {
      // Get day name for schedule lookup
      const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = dayNames[_selectedDate!.weekday - 1];
      final daySchedule = _clinicSchedule!.schedules[dayName];
      
      if (daySchedule == null || !daySchedule.isOpen || daySchedule.openTime == null || daySchedule.closeTime == null) {
        setState(() {
          _availableTimeSlots = [];
          _loadingTimeSlots = false;
        });
        return;
      }
      
      // Generate hourly time slots (e.g., "09:00 - 10:00") matching booking page logic
      final slots = <String>[];
      final openParts = daySchedule.openTime!.split(':');
      final closeParts = daySchedule.closeTime!.split(':');
      final openHour = int.parse(openParts[0]);
      final closeHour = int.parse(closeParts[0]);
      
      // Generate 1-hour blocks
      for (int hour = openHour; hour < closeHour; hour++) {
        final startTime = '${hour.toString().padLeft(2, '0')}:00';
        final endHour = hour + 1;
        final endTime = '${endHour.toString().padLeft(2, '0')}:00';
        
        // Check if this hour block is during a break time
        bool isDuringBreak = false;
        for (final breakTime in daySchedule.breakTimes) {
          // Check if the entire hour block overlaps with break time
          if (_isHourBlockInBreak(startTime, endTime, breakTime.startTime, breakTime.endTime)) {
            isDuringBreak = true;
            break;
          }
        }
        
        if (!isDuringBreak) {
          // Check if at least one slot in this hour is available AND not full
          bool hasAvailableSlot = false;
          final slotsPerHour = daySchedule.slotsPerHour;
          final minutesPerSlot = 60 ~/ slotsPerHour;
          
          for (int slot = 0; slot < slotsPerHour; slot++) {
            final minute = slot * minutesPerSlot;
            final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
            
            // Check if slot is within operating hours and not during break
            final canBook = await AppointmentService.canBookAtTime(
              widget.appointment.clinicId,
              _selectedDate!,
              timeString,
            );
            
            if (!canBook) continue; // Skip if not within schedule
            
            // Check if slot is at full capacity
            final isFull = await AppointmentBookingService.isTimeSlotFull(
              clinicId: widget.appointment.clinicId,
              appointmentDate: _selectedDate!,
              appointmentTime: timeString,
            );
            
            if (!isFull) {
              hasAvailableSlot = true;
              break; // Found at least one available slot in this hour that's not full
            }
          }
          
          if (hasAvailableSlot) {
            // Store as "HH:00 - HH:00" format for display
            slots.add('$startTime - $endTime');
          }
        }
      }
      
      setState(() {
        _availableTimeSlots = slots;
        _loadingTimeSlots = false;
        
        // If current time is not available, reset selection
        if (_selectedTime != null && !slots.contains(_selectedTime)) {
          print('⚠️ Current time $_selectedTime not available, resetting selection');
          _selectedTime = null;
        }
      });
      
      print('✅ Loaded ${slots.length} hourly time slots');
    } catch (e) {
      print('❌ Error loading time slots: $e');
      setState(() {
        _loadingTimeSlots = false;
        _availableTimeSlots = [];
      });
    }
  }

  /// Check if an hour block overlaps with a break time
  bool _isHourBlockInBreak(String blockStart, String blockEnd, String breakStart, String breakEnd) {
    final blockStartMinutes = _timeToMinutes(blockStart);
    final blockEndMinutes = _timeToMinutes(blockEnd);
    final breakStartMinutes = _timeToMinutes(breakStart);
    final breakEndMinutes = _timeToMinutes(breakEnd);
    
    // Check if there's any overlap between the hour block and break time
    return !(blockEndMinutes <= breakStartMinutes || blockStartMinutes >= breakEndMinutes);
  }

  /// Convert time string to minutes for comparison
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool _isDateAvailable(DateTime date) {
    if (_clinicSchedule == null) return false;
    
    // Check if it's a holiday
    if (_holidayDates.any((holiday) => 
        holiday.year == date.year && 
        holiday.month == date.month && 
        holiday.day == date.day)) {
      return false;
    }
    
    // Check if clinic is open on this day
    const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = daysOfWeek[date.weekday - 1];
    final daySchedule = _clinicSchedule!.schedules[dayName];
    
    return daySchedule?.isOpen ?? false;
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
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600, // Add max height constraint
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildForm(),
              ),
            ),
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
          const SizedBox(height: 8), // Add space on top
          _buildServiceNameField(),
          const SizedBox(height: 16),
          if (_canEditPet()) ...[
            _buildPetSelectionField(),
            const SizedBox(height: 16),
          ],
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
    return _loadingServices
        ? Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : DropdownButtonFormField<String>(
            value: _availableServices.isNotEmpty && 
                   _availableServices.any((service) => service['serviceName'] == _selectedService)
                ? _selectedService
                : null,
            decoration: InputDecoration(
              labelText: 'Service Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                borderSide: BorderSide(color: AppColors.error),
              ),
              prefixIcon: Icon(Icons.medical_services, color: AppColors.primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            isExpanded: true,
            items: _availableServices.map((service) {
              return DropdownMenuItem<String>(
                value: service['serviceName'],
                child: Text(
                  service['serviceName'] ?? 'Unknown Service',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            menuMaxHeight: 300,
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedService = value;
                  _serviceNameController.text = value;
                });
                
                // Reload time slots when service changes
                if (_selectedDate != null) {
                  print('🔄 Service changed to: $value, reloading time slots for date: $_selectedDate');
                  _loadAvailableTimeSlots();
                }
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please select a service';
              }
              return null;
            },
          );
  }

  Widget _buildPetSelectionField() {
    if (_loadingPets) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_userPets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.error),
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          color: AppColors.error.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No pets found. Please add a pet first.',
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          DropdownButtonFormField<String>(
            value: _userPets.any((pet) => pet.id == _selectedPetId) ? _selectedPetId : null,
            decoration: InputDecoration(
              labelText: 'Select Pet',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                borderSide: BorderSide(color: AppColors.error),
              ),
              prefixIcon: Icon(Icons.pets, color: AppColors.primary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            isExpanded: true,
            selectedItemBuilder: (BuildContext context) {
              return _userPets.map((pet) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pet.petName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList();
            },
            items: _userPets.map((pet) {
              return DropdownMenuItem<String>(
                value: pet.id,
                child: Text(
                  pet.petName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedPetId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a pet';
              }
              return null;
            },
          ),
          if (_canEditPet())
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'You can edit the pet because no assessment is linked to this appointment.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _clinicSchedule != null ? _selectDate : null,
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
          suffixIcon: _clinicSchedule == null 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
        ),
        child: _clinicSchedule == null
            ? Text(
                'Loading clinic schedule...',
                style: TextStyle(color: AppColors.textSecondary),
              )
            : Text(
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
        labelText: 'Available Time Slots',
        prefixIcon: Icon(Icons.access_time, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
      isExpanded: true,
      hint: _loadingTimeSlots
          ? Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Loading available times...',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : _availableTimeSlots.isEmpty
              ? Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No available time slots',
                        style: TextStyle(fontSize: 14, color: AppColors.error),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Select a time slot',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
      items: _availableTimeSlots.map((String time) {
        return DropdownMenuItem<String>(
          value: time,
          child: Text(
            _formatTimeSlot(time),
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
      onChanged: _loadingTimeSlots || _availableTimeSlots.isEmpty 
          ? null 
          : (String? value) {
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
      selectableDayPredicate: (DateTime date) {
        // Don't allow past dates
        if (date.isBefore(DateTime(now.year, now.month, now.day))) {
          return false;
        }
        
        // Check if clinic is open on this day
        return _isDateAvailable(date);
      },
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

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedTime = null; // Reset time when date changes
      });
      
      // Load new time slots for the selected date
      await _loadAvailableTimeSlots();
    }
  }

  /// Format time slot for display (e.g., "09:00 - 10:00" -> "9:00 AM - 10:00 AM")
  String _formatTimeSlot(String timeRange) {
    // Handle new format "HH:mm - HH:mm"
    if (timeRange.contains(' - ')) {
      final parts = timeRange.split(' - ');
      final startTime = _formatSingleTime(parts[0]);
      final endTime = _formatSingleTime(parts[1]);
      return '$startTime - $endTime';
    }
    
    // Fallback for old format "HH:mm"
    return _formatSingleTime(timeRange);
  }
  
  /// Format a single time (e.g., "09:00" -> "9:00 AM")
  String _formatSingleTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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
        serviceName: _selectedService?.trim() ?? _serviceNameController.text.trim(),
        appointmentDate: _selectedDate,
        appointmentTime: _selectedTime,
        petId: _canEditPet() ? _selectedPetId : null, // Only update petId if allowed
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
}