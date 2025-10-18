import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';
import 'package:pawsense/core/services/clinic/appointment_service.dart';
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/notifications/appointment_booking_integration.dart';
import 'package:pawsense/core/services/user/assessment_result_service.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';
import 'package:pawsense/core/utils/data_cache.dart';
import 'dart:async';

/// Cache entry for clinic schedule with real-time invalidation support
class _CachedSchedule {
  final WeeklySchedule schedule;
  final DateTime cachedAt;
  final DateTime? lastModified;
  
  _CachedSchedule(this.schedule, this.cachedAt, this.lastModified);
  
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(cachedAt) > const Duration(minutes: 30); // Extended cache time since we have real-time updates
  }
  
  bool isNewerThan(DateTime? otherModified) {
    if (lastModified == null || otherModified == null) return false;
    return lastModified!.isAfter(otherModified) || lastModified!.isAtSameMomentAs(otherModified);
  }
}

class BookAppointmentPage extends StatefulWidget {
  final String? preselectedClinicId;
  final String? preselectedClinicName;
  final String? assessmentResultId;
  final bool skipServiceSelection;

  const BookAppointmentPage({
    super.key,
    this.preselectedClinicId,
    this.preselectedClinicName,
    this.assessmentResultId,
    this.skipServiceSelection = false,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  String _selectedService = 'General Checkup';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot; // New: selected time slot as string
  String? _selectedPetId;
  String? _selectedClinicId;
  final TextEditingController _notesController = TextEditingController();
  
  bool _loading = true;
  bool _isBooking = false; // Prevent duplicate submission
  List<Pet> _userPets = [];
  List<Map<String, dynamic>> _availableClinics = [];
  List<Map<String, dynamic>> _availableServices = [];
  AssessmentResult? _assessmentResult;
  bool _petAutoRegistered = false;
  
  // New: Clinic schedule data
  WeeklySchedule? _clinicSchedule;
  List<String> _availableTimeSlots = [];
  bool _loadingTimeSlots = false;
  
  // Holiday dates for the selected clinic
  List<DateTime> _holidayDates = [];
  
  // Real-time listener management
  StreamSubscription<DocumentSnapshot>? _scheduleListener;
  
  // Static cache for clinic schedules (shared across all instances)
  static final Map<String, _CachedSchedule> _scheduleCache = {};
  
  // Static real-time listeners (shared across all instances)
  static final Map<String, StreamSubscription<DocumentSnapshot>> _scheduleListeners = {};

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
    
    // Set default service based on context
    if (widget.skipServiceSelection) {
      _selectedService = 'Consultation Service';
    }
    
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      // Load assessment result if coming from assessment
      if (widget.assessmentResultId != null) {
        final assessmentService = AssessmentResultService();
        _assessmentResult = await assessmentService.getAssessmentResultById(widget.assessmentResultId!);
      }
      
      // Get current user and load their pets
      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final pets = await PetService.getUserPets(user.uid);
        
        // Auto-register pet from assessment if not already registered
        if (_assessmentResult != null) {
          await _autoRegisterPetFromAssessment(user.uid, pets);
          // Reload pets after potential registration
          final updatedPets = await PetService.getUserPets(user.uid);
          setState(() {
            _userPets = updatedPets;
            // Select the assessment pet if found
            final assessmentPet = _userPets.firstWhere(
              (pet) => pet.petName.toLowerCase() == _assessmentResult!.petName.toLowerCase(),
              orElse: () => _userPets.isNotEmpty ? _userPets.first : _userPets.first,
            );
            if (assessmentPet.id != null && assessmentPet.id!.isNotEmpty) {
              _selectedPetId = assessmentPet.id;
            }
          });
        } else {
          setState(() {
            _userPets = pets;
            if (_userPets.isNotEmpty) {
              _selectedPetId = _userPets.first.id;
            }
          });
        }
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
      
      // Load clinic schedule after loading services
      await _loadClinicSchedule(clinicId);
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
  
  /// Load clinic schedule with real-time updates and smart caching
  Future<void> _loadClinicSchedule(String clinicId) async {
    try {
      print('📅 Loading clinic schedule for clinic: $clinicId');
      
      // Setup real-time listener if not already exists
      await _setupScheduleListener(clinicId);
      
      // Load holidays for this clinic
      await _loadHolidays(clinicId);
      
      // Check cache first
      final cachedEntry = _scheduleCache[clinicId];
      if (cachedEntry != null && !cachedEntry.isExpired) {
        print('✅ Using cached schedule for clinic: $clinicId');
        setState(() {
          _clinicSchedule = cachedEntry.schedule;
          
          // Always validate and update the selected date when schedule loads
          final newDate = _findNextAvailableDate(_selectedDate);
          if (newDate != _selectedDate) {
            _selectedDate = newDate;
            print('⚠️ Initial date was not available, updated to: $_selectedDate');
          }
        });
        
        // Load available time slots for the selected date
        await _loadAvailableTimeSlots();
        return;
      }
      
      // Fetch from Firestore if not in cache or expired
      print('🔄 Fetching fresh schedule from Firestore...');
      await _fetchAndCacheSchedule(clinicId);
      
    } catch (e) {
      print('❌ Error loading clinic schedule: $e');
      // Don't block user from booking, just log the error
    }
  }
  
  /// Load holidays for a clinic
  Future<void> _loadHolidays(String clinicId) async {
    try {
      final holidays = await ClinicScheduleService.getHolidays(clinicId);
      setState(() {
        _holidayDates = holidays;
      });
      print('✅ Loaded ${holidays.length} holidays for clinic: $clinicId');
    } catch (e) {
      print('❌ Error loading holidays: $e');
      setState(() {
        _holidayDates = [];
      });
    }
  }
  
  /// Setup real-time listener for clinic schedule changes
  Future<void> _setupScheduleListener(String clinicId) async {
    // Cancel existing listener for this clinic if any
    _scheduleListeners[clinicId]?.cancel();
    
    // Set up new listener
    _scheduleListeners[clinicId] = FirebaseFirestore.instance
        .collection('clinicSchedules')
        .doc(clinicId)
        .snapshots()
        .listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists && mounted) {
          _handleScheduleUpdate(clinicId, snapshot);
        }
      },
      onError: (error) {
        print('❌ Error in schedule listener for clinic $clinicId: $error');
      },
    );
    
    print('🎧 Real-time listener setup for clinic schedule: $clinicId');
  }
  
  /// Handle real-time schedule updates
  void _handleScheduleUpdate(String clinicId, DocumentSnapshot snapshot) async {
    try {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      final lastModified = (data['updatedAt'] as Timestamp?)?.toDate() ?? 
                          (data['lastModified'] as Timestamp?)?.toDate();
      
      // Check if we need to update the cache
      final cachedEntry = _scheduleCache[clinicId];
      if (cachedEntry != null && cachedEntry.isNewerThan(lastModified)) {
        return; // Cache is already up to date
      }
      
      print('🔄 Schedule updated for clinic $clinicId, refreshing cache...');
      
      // Parse the updated schedule from document data
      final daysData = data['days'] as Map<String, dynamic>? ?? {};
      final Map<String, ClinicScheduleModel> schedules = {};
      
      for (final dayName in WeeklySchedule.daysOfWeek) {
        final dayKey = dayName.toLowerCase();
        if (daysData.containsKey(dayKey)) {
          final dayData = daysData[dayKey] as Map<String, dynamic>;
          schedules[dayName] = ClinicScheduleModel(
            id: '${clinicId}_$dayKey',
            clinicId: clinicId,
            dayOfWeek: dayData['dayOfWeek'] ?? dayName,
            openTime: dayData['openTime'],
            closeTime: dayData['closeTime'],
            isOpen: dayData['isOpen'] ?? false,
            breakTimes: (dayData['breakTimes'] as List<dynamic>?)
                ?.map((bt) => BreakTime.fromMap(bt))
                .toList() ?? [],
            notes: dayData['notes'],
            slotsPerHour: dayData['slotsPerHour'] ?? 3,
            slotDurationMinutes: dayData['slotDurationMinutes'] ?? 20,
            createdAt: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (dayData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isActive: dayData['isActive'] ?? true,
          );
        } else {
          // Create default closed schedule for missing days
          schedules[dayName] = ClinicScheduleModel(
            id: '${clinicId}_$dayKey',
            clinicId: clinicId,
            dayOfWeek: dayName,
            openTime: null,
            closeTime: null,
            isOpen: false,
            breakTimes: [],
            notes: null,
            slotsPerHour: 3,
            slotDurationMinutes: 20,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          );
        }
      }
      
      final schedule = WeeklySchedule(schedules: schedules);
      
      // Update cache with new data
      _scheduleCache[clinicId] = _CachedSchedule(
        schedule, 
        DateTime.now(), 
        lastModified,
      );
      
      // Update UI if this is the currently selected clinic
      if (_selectedClinicId == clinicId && mounted) {
        // Reload holidays when schedule updates
        await _loadHolidays(clinicId);
        
        setState(() {
          _clinicSchedule = schedule;
          
          // Revalidate selected date
          final newDate = _findNextAvailableDate(_selectedDate);
          if (newDate != _selectedDate) {
            _selectedDate = newDate;
            print('⚠️ Selected date updated due to schedule change: $_selectedDate');
          }
        });
        
        // Reload available time slots
        await _loadAvailableTimeSlots();
        
        // Show notification to user about schedule update
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Clinic schedule updated'),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      
      print('✅ Schedule cache updated for clinic: $clinicId');
    } catch (e) {
      print('❌ Error handling schedule update for clinic $clinicId: $e');
    }
  }
  
  /// Fetch and cache schedule from Firestore
  Future<void> _fetchAndCacheSchedule(String clinicId) async {
    final schedule = await ClinicScheduleService.getWeeklySchedule(clinicId);
    
    // Get the document to check last modified time
    final doc = await FirebaseFirestore.instance
        .collection('clinicSchedules')
        .doc(clinicId)
        .get();
    
    DateTime? lastModified;
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      lastModified = (data['updatedAt'] as Timestamp?)?.toDate() ?? 
                     (data['lastModified'] as Timestamp?)?.toDate();
    }
    
      // Store in cache with last modified timestamp
      _scheduleCache[clinicId] = _CachedSchedule(schedule, DateTime.now(), lastModified);    setState(() {
      _clinicSchedule = schedule;
      
      // Always validate and update the selected date when schedule loads
      final newDate = _findNextAvailableDate(_selectedDate);
      if (newDate != _selectedDate) {
        _selectedDate = newDate;
        print('⚠️ Initial date was not available, updated to: $_selectedDate');
      }
    });
    
    // Load available time slots for the selected date
    await _loadAvailableTimeSlots();
    
    print('✅ Clinic schedule fetched and cached successfully');
  }
  
  /// Load available time slots for the selected date
  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedClinicId == null || _clinicSchedule == null) {
      setState(() {
        _availableTimeSlots = [];
        _selectedTimeSlot = null;
      });
      return;
    }
    
    setState(() => _loadingTimeSlots = true);
    
    try {
      // Get day name from selected date
      const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = daysOfWeek[_selectedDate.weekday - 1];
      
      // Get schedule for this day
      final daySchedule = _clinicSchedule!.schedules[dayName];
      
      if (daySchedule == null || !daySchedule.isOpen || daySchedule.openTime == null || daySchedule.closeTime == null) {
        setState(() {
          _availableTimeSlots = [];
          _selectedTimeSlot = null;
          _loadingTimeSlots = false;
        });
        return;
      }
      
      // Generate hourly time slots (e.g., "09:00 - 10:00")
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
              _selectedClinicId!,
              _selectedDate,
              timeString,
            );
            
            if (!canBook) continue; // Skip if not within schedule
            
            // Check if slot is at full capacity
            final isFull = await AppointmentBookingService.isTimeSlotFull(
              clinicId: _selectedClinicId!,
              appointmentDate: _selectedDate,
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
        // Auto-select first available slot if current selection is not available
        if (_selectedTimeSlot == null || !slots.contains(_selectedTimeSlot)) {
          _selectedTimeSlot = slots.isNotEmpty ? slots.first : null;
        }
        _loadingTimeSlots = false;
      });
      
      print('✅ Loaded ${slots.length} hourly time slots for ${dayName}');
    } catch (e) {
      print('❌ Error loading time slots: $e');
      setState(() {
        _availableTimeSlots = [];
        _selectedTimeSlot = null;
        _loadingTimeSlots = false;
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
  
  /// Convert time string (HH:mm) to minutes since midnight
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
  
  /// Check if a date should be enabled (clinic is open on this day)
  bool _isDateEnabled(DateTime date) {
    if (_clinicSchedule == null) return true; // Allow all dates if schedule not loaded
    
    // First check if date is a holiday (compare date-only)
    final dateOnly = DateTime(date.year, date.month, date.day);
    final isHoliday = _holidayDates.any((holiday) {
      final holidayOnly = DateTime(holiday.year, holiday.month, holiday.day);
      return holidayOnly == dateOnly;
    });
    
    if (isHoliday) {
      return false; // Holidays are closed
    }
    
    // Then check regular schedule
    const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = daysOfWeek[date.weekday - 1];
    final daySchedule = _clinicSchedule!.schedules[dayName];
    
    return daySchedule != null && daySchedule.isOpen;
  }
  
  /// Find the next available date starting from the given date
  DateTime _findNextAvailableDate(DateTime startDate) {
    // If clinic schedule is not loaded yet, return tomorrow as default
    if (_clinicSchedule == null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return startDate.isBefore(tomorrow) ? tomorrow : startDate;
    }
    
    DateTime checkDate = startDate;
    final maxDate = DateTime.now().add(const Duration(days: 365));
    
    // Ensure we don't go back in time - start from today if startDate is in the past
    final today = DateTime.now();
    if (checkDate.isBefore(DateTime(today.year, today.month, today.day))) {
      checkDate = DateTime(today.year, today.month, today.day);
    }
    
    // Check up to 30 days ahead to find an available date
    for (int i = 0; i < 30; i++) {
      if (checkDate.isAfter(maxDate)) break;
      
      if (_isDateEnabled(checkDate)) {
        return checkDate;
      }
      
      checkDate = checkDate.add(const Duration(days: 1));
    }
    
    // Fallback to tomorrow if no available date found
    return DateTime.now().add(const Duration(days: 1));
  }
  


  @override
  void dispose() {
    _notesController.dispose();
    _scheduleListener?.cancel();
    super.dispose();
  }
  
  /// Clean up real-time listeners for a specific clinic
  static void _cleanupListenerForClinic(String clinicId) {
    _scheduleListeners[clinicId]?.cancel();
    _scheduleListeners.remove(clinicId);
    print('🧹 Cleaned up listener for clinic: $clinicId');
  }

  
  /// Force refresh schedule for a specific clinic (useful for admin operations)


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
          onPressed: () => _handleBackNavigation(),
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
        color: (_petAutoRegistered ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
        borderRadius: kMobileBorderRadiusCardPreset,
        border: Border.all(color: (_petAutoRegistered ? AppColors.success : AppColors.primary).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            _petAutoRegistered ? Icons.pets : Icons.info_outline,
            color: _petAutoRegistered ? AppColors.success : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _petAutoRegistered ? 'Pet Auto-Registered' : 'Quick Booking',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _petAutoRegistered ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _petAutoRegistered 
                      ? 'Your pet from the assessment has been automatically registered'
                      : 'Schedule your pet\'s appointment with our qualified veterinarians',
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
                    // Circular clinic logo for preselected
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(3), // Add padding to make image smaller inside circle
                      child: ClipOval(
                        child: selectedClinic['logoUrl'] != null && selectedClinic['logoUrl'].toString().isNotEmpty
                            ? Image.network(
                                selectedClinic['logoUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.local_hospital, size: 16, color: AppColors.primary);
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              )
                            : Icon(Icons.local_hospital, size: 16, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          // Circular clinic logo in dropdown
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(3), // Add padding to make image smaller inside circle
                            child: ClipOval(
                              child: clinic['logoUrl'] != null && clinic['logoUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      clinic['logoUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.local_hospital, size: 16, color: AppColors.primary);
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    )
                                  : Icon(Icons.local_hospital, size: 16, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                      // Cleanup previous clinic listener if switching clinics
                      if (_selectedClinicId != null && _selectedClinicId != value) {
                        _cleanupListenerForClinic(_selectedClinicId!);
                      }
                      
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
              : (widget.skipServiceSelection && _assessmentResult != null)
                  ? // Locked pet selection (from assessment)
                    Container(
                      padding: const EdgeInsets.all(12),
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
                            child: _userPets.isNotEmpty && _selectedPetId != null
                                ? (() {
                                    final selectedPet = _userPets.firstWhere(
                                      (pet) => pet.id == _selectedPetId,
                                      orElse: () => _userPets.first,
                                    );
                                    return selectedPet.imageUrl != null && selectedPet.imageUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              selectedPet.imageUrl!,
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
                                          );
                                  })()
                                : Icon(
                                    Icons.pets,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _userPets.isNotEmpty && _selectedPetId != null
                                ? (() {
                                    final selectedPet = _userPets.firstWhere(
                                      (pet) => pet.id == _selectedPetId,
                                      orElse: () => _userPets.first,
                                    );
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              selectedPet.petName,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'ASSESSED PET',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${selectedPet.petType} • ${selectedPet.breed}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    );
                                  })()
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _assessmentResult?.petName ?? 'Assessment Pet',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        '${_assessmentResult?.petType ?? 'Unknown'} • Auto-selected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          Icon(
                            Icons.lock,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    )
                  : // Normal dropdown for manual selection
                    DropdownButtonHideUnderline(
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
    // Show assessment results if coming from assessment
    if (widget.skipServiceSelection && _assessmentResult != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assessment Results',
            style: kMobileTextStyleTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Assessment Detection',
                        style: kMobileTextStyleSubtitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'AUTO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_assessmentResult!.analysisResults.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...(_assessmentResult!.analysisResults.take(3).map((analysis) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(int.parse(analysis.colorHex.substring(1), radix: 16) + 0xFF000000),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              analysis.condition,
                              style: kMobileTextStyleSubtitle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${analysis.percentage.toStringAsFixed(1)}%',
                            style: kMobileTextStyleSubtitle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),
                ],
                const SizedBox(height: 8),
                Text(
                  'Consultation recommended for accurate diagnosis',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Hide service selection if coming from assessment but no assessment data
    if (widget.skipServiceSelection) {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.medical_services, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consultation Service',
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.lock_outline, size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
        ],
      );
    }
    
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
    // Check if selected date is a holiday
    final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isSelectedDateHoliday = _holidayDates.any((holiday) {
      final holidayOnly = DateTime(holiday.year, holiday.month, holiday.day);
      return holidayOnly == dateOnly;
    });
    
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
            // Ensure we have a valid initial date before opening the picker
            DateTime initialDate = _selectedDate;
            if (!_isDateEnabled(initialDate)) {
              initialDate = _findNextAvailableDate(DateTime.now());
              // Update the selected date to the valid initial date
              setState(() {
                _selectedDate = initialDate;
              });
            }
            
            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              helpText: 'Select Appointment Date',
              selectableDayPredicate: (DateTime date) {
                // Disable dates where clinic is closed or it's a holiday
                return _isDateEnabled(date);
              },
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: AppColors.textPrimary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _selectedDate = date);
              // Reload available time slots when date changes
              await _loadAvailableTimeSlots();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: isSelectedDateHoliday ? AppColors.error : AppColors.border),
              borderRadius: BorderRadius.circular(8),
              color: isSelectedDateHoliday ? AppColors.error.withOpacity(0.05) : Colors.white,
            ),
            child: Row(
              children: [
                Icon(
                  isSelectedDateHoliday ? Icons.event_busy : Icons.calendar_today, 
                  size: 18, 
                  color: isSelectedDateHoliday ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelectedDateHoliday ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (isSelectedDateHoliday) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                'Clinic is closed on this date (Holiday)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ] else if (_holidayDates.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Gray dates are closed or holidays',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Time Slots',
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingTimeSlots)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
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
                Text(
                  'Loading available times...',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else if (_availableTimeSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.error),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.error.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No available time slots for this date',
                    style: TextStyle(fontSize: 14, color: AppColors.error),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeSlot,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                items: _availableTimeSlots.map((String time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeSlot(time),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeSlot = newValue;
                    });
                  }
                },
              ),
            ),
          ),
      ],
    );
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
          maxLength: 300,
          inputFormatters: [
            LengthLimitingTextInputFormatter(300),
          ],
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
                        _availableClinics.isNotEmpty &&
                        !_isBooking; // Disable during booking
    
    return SizedBox(
      width: double.infinity,
      height: 55,
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
        child: _isBooking 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Text(
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
    // Prevent duplicate submission
    if (_isBooking) {
      print('🚫 Booking already in progress, ignoring duplicate request');
      return;
    }
    
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
    
    // Validate time slot selection
    if (_selectedTimeSlot == null || _selectedTimeSlot!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available time slot'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    // Set booking flag to prevent duplicate submissions
    setState(() => _isBooking = true);

    // Extract start time from hour block format "HH:mm - HH:mm"
    String formattedTime;
    if (_selectedTimeSlot!.contains(' - ')) {
      // New format: take the start time of the hour block
      formattedTime = _selectedTimeSlot!.split(' - ')[0];
    } else {
      // Fallback for old format
      formattedTime = _selectedTimeSlot!;
    }

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

      // Save appointment to Firebase with duplicate prevention
      final bookingResult = await AppointmentBookingService.bookAppointment(
        petId: _selectedPetId!,
        clinicId: _selectedClinicId!,
        serviceName: _selectedService,
        serviceId: selectedServiceData['id'] ?? 'default-service',
        appointmentDate: _selectedDate,
        appointmentTime: formattedTime,
        notes: _notesController.text.trim(),
        estimatedPrice: estimatedPrice,
        duration: selectedServiceData['duration']?.toString(),
        assessmentResultId: widget.assessmentResultId,
      );

      // Hide loading
      if (mounted) Navigator.of(context).pop();
      
      // Reset booking flag
      if (mounted) setState(() => _isBooking = false);

      final success = bookingResult['success'] as bool;
      final message = bookingResult['message'] as String;
      final appointmentId = bookingResult['appointmentId'] as String?;

      if (success && appointmentId != null) {
        // Create pending appointment notification immediately
        try {
          final currentUser = await AuthGuard.getCurrentUser();
          if (currentUser != null) {
            await AppointmentBookingIntegration.onAppointmentBooked(
              userId: currentUser.uid,
              petName: selectedPet.petName,
              clinicName: selectedClinic['name'],
              requestedDate: _selectedDate,
              requestedTime: formattedTime,
              appointmentId: appointmentId,
              isEmergency: _selectedService.toLowerCase().contains('emergency'),
              symptoms: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            );
          }
        } catch (notificationError) {
          print('⚠️ Failed to create pending notification: $notificationError');
          // Don't block the success flow if notification fails
        }
        
        // Invalidate appointment history cache after successful booking
        await _invalidateAppointmentHistoryCache();
        
        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment submitted successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate back with refresh parameter to trigger appointment history refresh
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              // Add timestamp to ensure cache invalidation
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              context.go('/home?tab=history&refresh_appointments=$timestamp');
            }
          });
        }
      } else {
        // Handle different error cases
        String errorMessage = message;
        
        if (bookingResult['rateLimitExceeded'] == true) {
          errorMessage = 'Too many booking attempts. Please wait a few minutes before trying again.';
        } else if (bookingResult['isDuplicate'] == true) {
          errorMessage = 'You already have an appointment for this pet at this time. Please choose a different time.';
        } else if (bookingResult['slotFull'] == true) {
          errorMessage = 'This time slot was just booked. Please select a different time.';
          // Refresh time slots to show updated availability
          await _loadAvailableTimeSlots();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Reset booking flag on error
      if (mounted) setState(() => _isBooking = false);
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
                        _selectedTimeSlot = slot;
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

  // Auto-register pet from assessment if not already exists
  Future<void> _autoRegisterPetFromAssessment(String userId, List<Pet> existingPets) async {
    if (_assessmentResult == null) return;

    // Check if pet already exists by name
    final existingPet = existingPets.firstWhere(
      (pet) => pet.petName.toLowerCase() == _assessmentResult!.petName.toLowerCase(),
      orElse: () => Pet(
        userId: '',
        petName: '',
        petType: '',
        age: 0,
        weight: 0.0,
        breed: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // If pet doesn't exist, register it
    if (existingPet.petName.isEmpty) {
      try {
        final newPet = Pet(
          userId: userId,
          petName: _assessmentResult!.petName,
          petType: _assessmentResult!.petType,
          age: _assessmentResult!.petAge,
          weight: _assessmentResult!.petWeight,
          breed: _assessmentResult!.petBreed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await PetService.addPet(newPet);
        
        setState(() {
          _petAutoRegistered = true;
        });

        print('✅ Auto-registered pet: ${_assessmentResult!.petName}');
      } catch (e) {
        print('❌ Error auto-registering pet: $e');
      }
    } else {
      print('✅ Pet already exists: ${existingPet.petName}');
    }
  }

  void _handleBackNavigation() {
    // Check if we came from history via query parameter or assessment result ID
    final fromHistory = widget.assessmentResultId != null && widget.assessmentResultId!.isNotEmpty;
    
    if (fromHistory) {
      // Navigate back to assessment history
      context.go('/home?tab=history');
    } else {
      // Try to pop, or fallback to home if can't pop
      if (Navigator.canPop(context)) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  // Cache invalidation method
  Future<void> _invalidateAppointmentHistoryCache() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user != null) {
        final cache = DataCache();
        
        // Invalidate appointment history cache using the same pattern as home_page.dart
        final appointmentCacheKey = 'user_appointments_${user.uid}';
        cache.invalidate(appointmentCacheKey);
        
        print('DEBUG: Appointment history cache invalidated after booking for user: ${user.uid}');
      }
    } catch (e) {
      print('DEBUG: Error invalidating appointment history cache: $e');
    }
  }
}