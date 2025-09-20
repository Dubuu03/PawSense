import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';
import 'package:pawsense/core/services/clinic/appointment_service.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class BookAppointmentPage extends StatefulWidget {
  final String? preselectedClinicId;
  final String? preselectedClinicName;

  const BookAppointmentPage({
    super.key,
    this.preselectedClinicId,
    this.preselectedClinicName,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String _selectedService = 'General Checkup';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String? _selectedPetId;
  String? _selectedClinicId;
  final TextEditingController _notesController = TextEditingController();
  
  bool _loading = true;
  List<Pet> _userPets = [];
  List<Map<String, dynamic>> _availableClinics = [];
  List<Map<String, dynamic>> _availableServices = [];

  final List<String> _defaultServices = [
    'General Checkup',
    'Vaccination',
    'Dental Cleaning',
    'Surgery Consultation',
    'Emergency Visit',
    'Grooming',
    'Behavioral Consultation',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      // Get current user and load their pets
      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final pets = await PetService.getUserPets(user.uid);
        setState(() {
          _userPets = pets;
          if (_userPets.isNotEmpty) {
            _selectedPetId = _userPets.first.id;
          }
        });
      }
      
      // Load available clinics
      final clinics = await ClinicListService.getAllActiveClinics();
      print('🏥 MOBILE DEBUG: Loaded ${clinics.length} available clinics');
      for (int i = 0; i < clinics.length && i < 3; i++) {
        final clinic = clinics[i];
        print('   Clinic ${i+1}: ID=${clinic['id']}, Name=${clinic['name']}');
      }
      
      setState(() {
        _availableClinics = clinics;
        
        // Use preselected clinic if provided and valid
        if (widget.preselectedClinicId != null) {
          // Check for clinic with matching ID in either 'id' or 'clinicId' field
          final matchingClinic = _availableClinics.firstWhere(
            (clinic) => clinic['id'] == widget.preselectedClinicId || 
                         clinic['clinicId'] == widget.preselectedClinicId,
            orElse: () => {},
          );
          
          if (matchingClinic.isNotEmpty) {
            _selectedClinicId = matchingClinic['id']; // Always use the 'id' field for consistency
          } else if (_availableClinics.isNotEmpty) {
            _selectedClinicId = _availableClinics.first['id'];
          }
        } else if (_availableClinics.isNotEmpty) {
          _selectedClinicId = _availableClinics.first['id'];
          print('🎯 MOBILE DEBUG: Auto-selected clinic ID: $_selectedClinicId');
        }
        
        _loading = false;
      });
      
      // Load services for the first clinic
      if (_selectedClinicId != null) {
        await _loadServicesForClinic(_selectedClinicId!);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Future<void> _loadServicesForClinic(String clinicId) async {
    try {
      // Fetch services for the selected clinic from Firestore
      final servicesQuery = await FirebaseFirestore.instance
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinicId)
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
      
      // If no services found, use default services
      if (services.isEmpty) {
        services = _defaultServices.map((service) => {
          'id': 'default-${service.toLowerCase().replaceAll(' ', '-')}',
          'serviceName': service,
          'serviceDescription': 'Professional veterinary $service',
          'estimatedPrice': '0.00',
          'duration': '30 mins',
          'category': 'consultation',
        }).toList();
      }
      
      setState(() {
        _availableServices = services;
        // Reset selected service when clinic changes
        if (_availableServices.isNotEmpty) {
          _selectedService = _availableServices.first['serviceName'];
        }
      });
    } catch (e) {
      print('Error loading services for clinic: $e');
      // Use default services as fallback
      setState(() {
        _availableServices = _defaultServices.map((service) => {
          'id': 'default-${service.toLowerCase().replaceAll(' ', '-')}',
          'serviceName': service,
          'serviceDescription': 'Professional veterinary $service',
          'estimatedPrice': '0.00',
          'duration': '30 mins',
          'category': 'consultation',
        }).toList();
        if (_availableServices.isNotEmpty) {
          _selectedService = _availableServices.first['serviceName'];
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _userPets.isEmpty && _availableClinics.isEmpty
              ? _buildErrorState()
              : SingleChildScrollView(
              padding: const EdgeInsets.all(kMobileMarginHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: kMobileSizedBoxLarge),
                  _buildAppointmentForm(),
                  const SizedBox(height: kMobileSizedBoxHuge),
                  _buildBookButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: kMobileBorderRadiusCardPreset,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Booking',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Schedule your pet\'s appointment with our qualified veterinarians',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentForm() {
    return Container(
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: kMobileTextStyleTitle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Clinic Selection
          _buildClinicDropdown(),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Pet Selection
          _buildPetDropdown(),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Service Selection
          _buildServiceDropdown(),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Date Selection
          _buildDateField(),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Time Selection
          _buildTimeField(),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Notes
          _buildNotesField(),
        ],
      ),
    );
  }

  Widget _buildClinicDropdown() {
    // If clinic is preselected (came from clinic details), show static display
    final isPreselected = widget.preselectedClinicId != null;
    final selectedClinic = _availableClinics.firstWhere(
      (clinic) => clinic['id'] == _selectedClinicId,
      orElse: () => {},
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPreselected ? 'Clinic' : 'Select Clinic',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
            color: isPreselected ? AppColors.background : Colors.white,
          ),
          child: isPreselected
              ? // Static display for preselected clinic
                Row(
                  children: [
                    Icon(Icons.local_hospital, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedClinic['name'] ?? widget.preselectedClinicName ?? 'Selected Clinic',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            selectedClinic['address'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : // Dropdown for manual selection
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClinicId,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    hint: const Text('Choose a clinic'),
                    items: _availableClinics.map((clinic) => DropdownMenuItem<String>(
                      value: clinic['id'],
                      child: Row(
                        children: [
                          Icon(Icons.local_hospital, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clinic['name'] ?? 'Unknown Clinic',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  clinic['address'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) {
                      setState(() => _selectedClinicId = value);
                      if (value != null) {
                        _loadServicesForClinic(value);
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPetDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Pet',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _userPets.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.pets, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No pets found. Add a pet first.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/add-pet'),
                        child: const Text('Add Pet'),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPetId,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    hint: const Text('Choose your pet'),
                    items: _userPets.map((pet) => DropdownMenuItem<String>(
                      value: pet.id,
                      child: Row(
                        children: [
                          // Pet profile picture
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.background,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      pet.imageUrl!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.pets,
                                          size: 20,
                                          color: AppColors.primary,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.pets,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.petName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${pet.petType} • ${pet.breed}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedPetId = value),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildServiceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Type',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _availableServices.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select a clinic first to see available services',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedService,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    hint: const Text('Choose a service'),
                    items: _availableServices.map((service) => DropdownMenuItem<String>(
                      value: service['serviceName'],
                      child: Row(
                        children: [
                          Icon(Icons.medical_services, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['serviceName'] ?? 'Unknown Service',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${service['estimatedPrice'] ?? '0.00'} • ${service['duration'] ?? '30 mins'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedService = value!),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Date',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Time',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (time != null) {
              setState(() => _selectedTime = time);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes (Optional)',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any specific concerns or requests...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    final bool canBook = _selectedClinicId != null && 
                        _selectedPetId != null &&
                        _userPets.isNotEmpty && 
                        _availableClinics.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canBook ? _bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canBook ? AppColors.primary : AppColors.textSecondary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          canBook ? 'Book Appointment' : 'Select Pet & Clinic',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kMobileMarginHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Unable to load data',
              style: kMobileTextStyleTitle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            Text(
              'Please check your connection and try again',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookAppointment() async {
    // Validation
    if (_selectedPetId == null || _userPets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pet first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedClinicId == null || _availableClinics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a clinic first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    if (_selectedService.isEmpty || _availableServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Format time for validation (HH:mm)
    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );

    try {
      // Validate if the appointment can be booked at the selected time
      final canBook = await AppointmentService.canBookAtTime(
        _selectedClinicId!,
        _selectedDate,
        formattedTime,
      );

      if (!canBook) {
        // Hide loading
        if (mounted) Navigator.of(context).pop();
        
        // Show schedule validation error
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Time Slot Unavailable'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('The selected time slot is not available. This could be because:'),
                  const SizedBox(height: 12),
                  const Text('• The clinic is closed at that time'),
                  const Text('• The time slot is during a break'),
                  const Text('• The time slot is already booked'),
                  const SizedBox(height: 16),
                  const Text('Would you like to see available time slots for this date?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _showAvailableTimeSlots();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Available Times'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Get selected pet and clinic for display
      final selectedPet = _userPets.firstWhere((pet) => pet.id == _selectedPetId);
      final selectedClinic = _availableClinics.firstWhere((clinic) => clinic['id'] == _selectedClinicId);
      
      // Get selected service details
      final selectedServiceData = _availableServices.firstWhere(
        (service) => service['serviceName'] == _selectedService,
        orElse: () => {
          'id': 'default-service',
          'serviceName': _selectedService,
          'estimatedPrice': '0.00',
          'duration': '30 mins',
        },
      );
      
      // Parse estimated price
      double? estimatedPrice;
      try {
        final priceStr = selectedServiceData['estimatedPrice']?.toString() ?? '0.00';
        estimatedPrice = double.parse(priceStr.replaceAll(RegExp(r'[^\d.]'), ''));
      } catch (e) {
        estimatedPrice = 0.00;
      }

      // Save appointment to Firebase
      final appointmentId = await AppointmentBookingService.bookAppointment(
        petId: _selectedPetId!,
        clinicId: _selectedClinicId!,
        serviceName: _selectedService,
        serviceId: selectedServiceData['id'] ?? 'default-service',
        appointmentDate: _selectedDate,
        appointmentTime: formattedTime,
        notes: _notesController.text.trim(),
        estimatedPrice: estimatedPrice,
        duration: selectedServiceData['duration']?.toString(),
      );

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      if (appointmentId != null) {
        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Appointment booked successfully for ${selectedPet.petName} at ${selectedClinic['name']} on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedTime.format(context)}',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
          context.pop();
        }
      } else {
        // Error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to book appointment. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showAvailableTimeSlots() async {
    if (_selectedClinicId == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );

    try {
      final availableSlots = await AppointmentService.getAvailableTimeSlots(
        _selectedClinicId!,
        _selectedDate,
      );

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      if (availableSlots.isEmpty) {
        // No available slots
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Available Times'),
              content: const Text('There are no available time slots for the selected date. Please choose a different date.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show available time slots
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Available Times - ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableSlots[index];
                  final timeParts = slot.split(':');
                  final timeOfDay = TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );
                  
                  return ListTile(
                    title: Text(timeOfDay.format(context)),
                    trailing: const Icon(Icons.access_time, color: AppColors.primary),
                    onTap: () {
                      setState(() {
                        _selectedTime = timeOfDay;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected time: ${timeOfDay.format(context)}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading available times: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}