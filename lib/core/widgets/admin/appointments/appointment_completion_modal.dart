// widgets/admin/appointments/appointment_completion_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_colors.dart';
import '../../../models/clinic/appointment_models.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../models/notifications/notification_model.dart';
import '../../../services/clinic/clinic_schedule_service.dart';
import '../../../models/clinic/clinic_schedule_model.dart';

/// Class to track training data validation for each image
class ImageTrainingValidation {
  final String imageUrl;
  final String imageType; // 'original', 'annotated', 'detection'
  bool? isCorrect;
  String? correctDisease;
  String feedback;
  List<Map<String, dynamic>> aiPredictions;
  Map<String, bool> predictionValidation;

  ImageTrainingValidation({
    required this.imageUrl,
    required this.imageType,
    this.isCorrect,
    this.correctDisease,
    this.feedback = '',
    required this.aiPredictions,
    required this.predictionValidation,
  });
}

class AppointmentCompletionModal extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onCompleted;

  const AppointmentCompletionModal({
    Key? key,
    required this.appointment,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<AppointmentCompletionModal> createState() => _AppointmentCompletionModalState();
}

class _AppointmentCompletionModalState extends State<AppointmentCompletionModal> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNotesController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  
  bool _needsFollowUp = false;
  DateTime? _followUpDate;
  String? _followUpTime;
  
  // Clinic schedule data
  List<DateTime> _holidayDates = [];
  Map<String, ClinicScheduleModel> _weeklySchedule = {};
  List<String> _availableTimeSlots = [];
  bool _isLoadingSchedule = false;
  
  // AI Assessment Validation
  bool _hasAIAssessment = false;
  List<Map<String, dynamic>> _aiPredictions = [];
  
  // Disease name lists loaded from Firestore
  Map<String, List<String>> _diseasesByPetType = {};
  
  // Image Assessment Data for Training (Multiple Images Support)
  List<Map<String, dynamic>> _assessmentImages = [];
  String? _originalImageUrl;
  String? _annotatedImageUrl;
  
  // Multi-image training data validation
  List<ImageTrainingValidation> _imageValidations = [];
  
  // Two-step modal state
  int _currentStep = 1; // 1 = Clinic Evaluation, 2 = Training Data Validation
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAIAssessment();
    _loadDiseasesFromFirestore();
    _loadHolidays();
    _loadClinicSchedule();
  }

  @override
  void dispose() {
    _clinicNotesController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAIAssessment() async {
    if (widget.appointment.assessmentResultId == null || 
        widget.appointment.assessmentResultId!.isEmpty) {
      print('No assessment result ID found for appointment ${widget.appointment.id}');
      return;
    }
    print('Loading AI assessment for appointment ${widget.appointment.id} with result ID ${widget.appointment.assessmentResultId}');

    setState(() => _isLoading = true);

    try {
      final assessmentDoc = await FirebaseFirestore.instance
          .collection('assessment_results')
          .doc(widget.appointment.assessmentResultId)
          .get();

      if (assessmentDoc.exists) {
        final data = assessmentDoc.data()!;
        print('📄 Assessment document fields: ${data.keys.toList()}');
        
        final analysisResults = data['analysisResults'] as List<dynamic>? ?? [];
        
        setState(() {
          _hasAIAssessment = analysisResults.isNotEmpty;
          _aiPredictions = analysisResults.map((result) {
            return {
              'condition': result['condition'] ?? 'Unknown',
              'percentage': (result['percentage'] ?? 0.0).toDouble(),
              'colorHex': result['colorHex'] ?? '#7C3AED',
            };
          }).toList();
          
          // Load image assessment data from multiple possible sources
          // Priority: 1. Direct URL fields, 2. detectionResults, 3. imageUrls array
          
          // Try direct URL fields first
          _originalImageUrl = data['originalImageUrl'] as String?;
          _annotatedImageUrl = data['annotatedImageUrl'] as String?;
          
          // If not found, check detectionResults array for images with bounding boxes
          if (_originalImageUrl == null || _originalImageUrl!.isEmpty) {
            final detectionResults = data['detectionResults'] as List<dynamic>? ?? [];
            if (detectionResults.isNotEmpty) {
              final firstDetection = detectionResults[0] as Map<String, dynamic>?;
              if (firstDetection != null) {
                _originalImageUrl = firstDetection['imageUrl'] as String?;
                print('📸 Found image in detectionResults: $_originalImageUrl');
              }
            }
          }
          
          // If still not found, check imageUrls array
          if (_originalImageUrl == null || _originalImageUrl!.isEmpty) {
            final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
            if (imageUrls.isNotEmpty) {
              _originalImageUrl = imageUrls[0] as String?;
              print('📸 Found image in imageUrls array: $_originalImageUrl');
            }
          }
          
          print('✅ AI Assessment loaded: hasAssessment=$_hasAIAssessment, predictions=${_aiPredictions.length}');
          print('🖼️ Image URLs - Original: $_originalImageUrl, Annotated: $_annotatedImageUrl');
          
          // Load assessment images if available from 'images' array
          final images = data['images'] as List<dynamic>? ?? [];
          _assessmentImages = images.map((img) {
            return {
              'url': img['url'] ?? '',
              'type': img['type'] ?? 'original', // original, annotated, processed
              'timestamp': img['timestamp'] ?? Timestamp.now(),
              'description': img['description'] ?? '',
            };
          }).toList();
          
          // Also add images from detectionResults to _assessmentImages if available
          final detectionResults = data['detectionResults'] as List<dynamic>? ?? [];
          for (var detection in detectionResults) {
            final imageUrl = detection['imageUrl'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              _assessmentImages.add({
                'url': imageUrl,
                'type': 'detection',
                'timestamp': Timestamp.now(),
                'description': 'Image with detections',
              });
            }
          }
          
          print('📦 Total assessment images: ${_assessmentImages.length}');
          
          // Initialize image validations for each image
          _imageValidations = [];
          
          // Add original image if available
          if (_originalImageUrl != null && _originalImageUrl!.isNotEmpty) {
            _imageValidations.add(ImageTrainingValidation(
              imageUrl: _originalImageUrl!,
              imageType: 'original',
              aiPredictions: List.from(_aiPredictions),
              predictionValidation: {},
            ));
          }
          
          // Add other assessment images
          for (var img in _assessmentImages) {
            final url = img['url'] as String?;
            final type = img['type'] as String? ?? 'detection';
            if (url != null && url.isNotEmpty && url != _originalImageUrl) {
              _imageValidations.add(ImageTrainingValidation(
                imageUrl: url,
                imageType: type,
                aiPredictions: List.from(_aiPredictions),
                predictionValidation: {},
              ));
            }
          }
          
          print('✅ Initialized ${_imageValidations.length} image validations');
        });
      } else {
        print('❌ Assessment document does not exist');
      }
    } catch (e) {
      print('❌ Error loading AI assessment: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDiseasesFromFirestore() async {
    try {
      final diseasesSnapshot = await FirebaseFirestore.instance
          .collection('skinDiseases')
          .get();

      final Map<String, List<String>> diseasesByType = {
        'Dog': <String>[],
        'Cat': <String>[],
      };

      for (var doc in diseasesSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        final species = data['species'] as List<dynamic>? ?? [];

        if (name.isNotEmpty) {
          // Clean the disease name (remove parentheses if content matches)
          final cleanedName = _cleanDiseaseName(name);
          
          // Add the disease to appropriate species lists based on species field
          for (var specie in species) {
            final specieStr = specie.toString().toLowerCase();
            
            // Match species to pet type (Dog or Cat)
            if (specieStr.contains('dog') && !diseasesByType['Dog']!.contains(cleanedName)) {
              diseasesByType['Dog']!.add(cleanedName);
            }
            if (specieStr.contains('cat') && !diseasesByType['Cat']!.contains(cleanedName)) {
              diseasesByType['Cat']!.add(cleanedName);
            }
            // Handle "both" species
            if (specieStr == 'both') {
              if (!diseasesByType['Dog']!.contains(cleanedName)) {
                diseasesByType['Dog']!.add(cleanedName);
              }
              if (!diseasesByType['Cat']!.contains(cleanedName)) {
                diseasesByType['Cat']!.add(cleanedName);
              }
            }
          }
        }
      }

      // Sort the lists alphabetically and add "Other" option at the end
      for (var key in diseasesByType.keys) {
        diseasesByType[key]!.sort();
        diseasesByType[key]!.add('Other');
      }

      setState(() {
        _diseasesByPetType = diseasesByType;
      });

      print('Loaded diseases for Dog: ${_diseasesByPetType['Dog']?.length ?? 0}');
      print('Loaded diseases for Cat: ${_diseasesByPetType['Cat']?.length ?? 0}');
    } catch (e) {
      print('Error loading diseases: $e');
      setState(() {
        // Fallback to basic list if loading fails
        _diseasesByPetType = {
          'Dog': ['Contact Dermatitis', 'Allergic Dermatitis', 'Bacterial Infection', 'Fungal Infection', 'Other'],
          'Cat': ['Contact Dermatitis', 'Allergic Dermatitis', 'Bacterial Infection', 'Fungal Infection', 'Other'],
        };
      });
    }
  }
  
  /// Clean disease name by removing parentheses if the content inside matches
  /// E.g., "Alopecia (Alopecia)" -> "Alopecia"
  /// E.g., "Alopecia (Hair Loss)" -> "Alopecia (Hair Loss)" (keeps it if different)
  String _cleanDiseaseName(String name) {
    final regex = RegExp(r'^(.+?)\s*\((.+?)\)$');
    final match = regex.firstMatch(name);
    
    if (match != null) {
      final mainName = match.group(1)?.trim() ?? '';
      final parenthesesContent = match.group(2)?.trim() ?? '';
      
      // If the content in parentheses is the same as the main name, remove it
      if (mainName.toLowerCase() == parenthesesContent.toLowerCase()) {
        return mainName;
      }
    }
    
    return name;
  }

  List<String> _getDiseasesForPetType() {
    final petType = widget.appointment.pet.type;
    return _diseasesByPetType[petType] ?? _diseasesByPetType['Dog'] ?? [];
  }

  String _generateUniqueFilename({String? diseaseName}) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final petType = widget.appointment.pet.type.toLowerCase();
    final appointmentId = widget.appointment.id.substring(0, 8); // First 8 chars of appointment ID
    
    // Use the provided disease name, otherwise use diagnosis
    String diseaseForFilename = diseaseName ?? _diagnosisController.text.trim();
    
    if (diseaseForFilename.isEmpty && _aiPredictions.isNotEmpty) {
      diseaseForFilename = _aiPredictions.first['condition'] ?? 'unknown';
    }
    
    if (diseaseForFilename.isEmpty) {
      diseaseForFilename = 'diagnosis';
    }
    
    // Clean disease name for filename (remove special characters, spaces)
    diseaseForFilename = diseaseForFilename
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    
    return '${petType}_${diseaseForFilename}_${appointmentId}_${timestamp}';
  }

  /// Load holidays for the clinic
  Future<void> _loadHolidays() async {
    try {
      final holidays = await ClinicScheduleService.getHolidays(widget.appointment.clinicId);
      if (mounted) {
        setState(() {
          _holidayDates = holidays;
        });
      }
      print('✅ Loaded ${holidays.length} holidays for appointment completion');
    } catch (e) {
      print('❌ Error loading holidays: $e');
      if (mounted) {
        setState(() {
          _holidayDates = [];
        });
      }
    }
  }

  /// Load clinic weekly schedule
  Future<void> _loadClinicSchedule() async {
    try {
      setState(() => _isLoadingSchedule = true);
      
      final weeklySchedule = await ClinicScheduleService.getWeeklySchedule(widget.appointment.clinicId);
      
      if (mounted) {
        setState(() {
          _weeklySchedule = weeklySchedule.schedules;
          _isLoadingSchedule = false;
        });
      }
      print('✅ Loaded weekly schedule for clinic');
    } catch (e) {
      print('❌ Error loading clinic schedule: $e');
      if (mounted) {
        setState(() {
          _weeklySchedule = {};
          _isLoadingSchedule = false;
        });
      }
    }
  }

  /// Load available time slots for a specific date
  Future<void> _loadAvailableTimeSlotsForDate(DateTime date) async {
    try {
      setState(() => _isLoadingSchedule = true);
      
      // Get day name from selected date
      const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = daysOfWeek[date.weekday - 1];
      
      // Get schedule for this day
      final daySchedule = _weeklySchedule[dayName];
      
      if (daySchedule == null || !daySchedule.isOpen || daySchedule.openTime == null || daySchedule.closeTime == null) {
        if (mounted) {
          setState(() {
            _availableTimeSlots = [];
            _isLoadingSchedule = false;
          });
        }
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
          if (_isHourBlockInBreak(startTime, endTime, breakTime.startTime, breakTime.endTime)) {
            isDuringBreak = true;
            break;
          }
        }
        
        if (!isDuringBreak) {
          // Store as "HH:00 - HH:00" format for display
          slots.add('$startTime - $endTime');
        }
      }
      
      if (mounted) {
        setState(() {
          _availableTimeSlots = slots;
          // Auto-select first available slot if current selection is not available
          if (_followUpTime == null || !slots.contains(_followUpTime)) {
            _followUpTime = slots.isNotEmpty ? slots.first : null;
          }
          _isLoadingSchedule = false;
        });
      }
      
      print('✅ Loaded ${slots.length} hourly time slots for $dayName');
    } catch (e) {
      print('❌ Error loading time slots: $e');
      if (mounted) {
        setState(() {
          _availableTimeSlots = [];
          _isLoadingSchedule = false;
        });
      }
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

  /// Check if a date should be selectable for follow-up
  bool _isDateSelectableForFollowUp(DateTime date) {
    // Parse the appointment date (format: "YYYY-MM-DD")
    final appointmentDateParts = widget.appointment.date.split('-');
    final appointmentDate = DateTime(
      int.parse(appointmentDateParts[0]),
      int.parse(appointmentDateParts[1]),
      int.parse(appointmentDateParts[2]),
    );
    
    // Normalize dates to compare only year, month, day (ignore time)
    final dateOnly = DateTime(date.year, date.month, date.day);
    final appointmentDateOnly = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );
    
    // Disable if date is before or equal to appointment date
    if (dateOnly.isBefore(appointmentDateOnly) || dateOnly.isAtSameMomentAs(appointmentDateOnly)) {
      return false;
    }
    
    // Disable if date is a holiday
    final isHoliday = _holidayDates.any((holiday) {
      final holidayOnly = DateTime(holiday.year, holiday.month, holiday.day);
      return dateOnly.isAtSameMomentAs(holidayOnly);
    });
    
    if (isHoliday) {
      return false;
    }
    
    // Check if clinic is open on this day of the week
    final dayOfWeek = _getDayOfWeek(date.weekday);
    final daySchedule = _weeklySchedule[dayOfWeek];
    
    if (daySchedule == null || !daySchedule.isOpen) {
      return false;
    }
    
    return true;
  }

  /// Get day of week name from weekday number (1 = Monday, 7 = Sunday)
  String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Format time slot for display (e.g., "09:00 - 10:00" -> "9:00 AM - 10:00 AM")
  String _formatTimeSlotWithRange(String timeRange) {
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

  Future<void> _selectFollowUpDate() async {
    // Parse the appointment date
    final appointmentDateParts = widget.appointment.date.split('-');
    final appointmentDate = DateTime(
      int.parse(appointmentDateParts[0]),
      int.parse(appointmentDateParts[1]),
      int.parse(appointmentDateParts[2]),
    );
    
    // Start from day after appointment
    final firstSelectableDate = appointmentDate.add(const Duration(days: 1));
    final now = DateTime.now();
    
    // Use the later of tomorrow or day after appointment
    final initialDate = firstSelectableDate.isAfter(now) 
        ? firstSelectableDate.add(const Duration(days: 6)) // 7 days after appointment
        : now.add(const Duration(days: 7)); // 7 days from now
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstSelectableDate.isAfter(now) ? firstSelectableDate : now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      selectableDayPredicate: _isDateSelectableForFollowUp,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _followUpDate = selectedDate;
        _followUpTime = null; // Reset time when date changes
      });
      
      // Load available time slots for the selected date
      await _loadAvailableTimeSlotsForDate(selectedDate);
    }
  }

  Future<void> _saveCompletion() async {
    // Only validate the clinic evaluation form if it's currently mounted.
    // When the user is on Step 2 the Form from Step 1 is not in the widget
    // tree, so _formKey.currentState will be null — avoid calling validate()
    // in that case to prevent exceptions and allow completing from Step 2.
    if (_formKey.currentState != null) {
      if (!_formKey.currentState!.validate()) return;
    }

    // Clear previous error
    setState(() => _errorMessage = null);

    // Validate follow-up details if needed
    if (_needsFollowUp) {
      if (_followUpDate == null) {
        setState(() => _errorMessage = 'Please select a follow-up date');
        return;
      }
      if (_followUpTime == null) {
        setState(() => _errorMessage = 'Please select a follow-up time');
        return;
      }
    }

    // Validate AI assessment if available - check all images are validated
    // Only validate if we're on step 2 or have gone through step 2
    if (_currentStep == 2 && _hasAIAssessment && _imageValidations.isNotEmpty) {
      for (var i = 0; i < _imageValidations.length; i++) {
        if (_imageValidations[i].isCorrect == null) {
          setState(() => _errorMessage = 'Please validate all images (Image ${i + 1} is not validated)');
          return;
        }
        if (_imageValidations[i].isCorrect == false) {
          final correctDisease = _imageValidations[i].correctDisease;
          if (correctDisease == null || correctDisease.isEmpty) {
            setState(() => _errorMessage = 'Please select correct disease for Image ${i + 1}');
            return;
          }
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Update appointment with completion data
      final appointmentRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id);
      
      batch.update(appointmentRef, {
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'clinicNotes': _clinicNotesController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'treatment': _treatmentController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'needsFollowUp': _needsFollowUp,
        'followUpDate': _needsFollowUp && _followUpDate != null 
            ? '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}'
            : null,
        'followUpTime': _needsFollowUp ? _followUpTime : null,
        'updatedAt': Timestamp.now(),
      });

      // 2. If AI assessment exists AND user went through Step 2, save validation feedback and create training data entries
      if (_hasAIAssessment && widget.appointment.assessmentResultId != null && _currentStep == 2) {
        // Count how many images were actually validated
        final validatedCount = _imageValidations.where((v) => v.isCorrect != null).length;
        
        // Only update assessment if at least one image was validated
        if (validatedCount > 0) {
          final assessmentRef = FirebaseFirestore.instance
              .collection('assessment_results')
              .doc(widget.appointment.assessmentResultId);
          
          batch.update(assessmentRef, {
            'clinicValidation': {
              'isValidated': true,
              'validatedAt': Timestamp.now(),
              'validatedBy': widget.appointment.clinicId,
              'clinicDiagnosis': _diagnosisController.text.trim(),
              'clinicTreatment': _treatmentController.text.trim(),
              'totalImagesValidated': validatedCount,
            },
            'updatedAt': Timestamp.now(),
          });

          // 3. Create individual training data entries for each validated image
          for (var i = 0; i < _imageValidations.length; i++) {
            final validation = _imageValidations[i];
            
            if (validation.isCorrect != null) {
            final validationRef = FirebaseFirestore.instance
                .collection('model_training_data')
                .doc();
            
            // Determine the disease label
            final rawDiseaseLabel = validation.isCorrect == false 
                ? validation.correctDisease 
                : (_aiPredictions.isNotEmpty ? _aiPredictions.first['condition'] : _diagnosisController.text.trim());
            final cleanedDiseaseLabel = rawDiseaseLabel != null ? _cleanDiseaseName(rawDiseaseLabel) : '';
            
            // Generate unique filename based on the disease
            final uniqueFilename = _generateUniqueFilename(
              diseaseName: validation.isCorrect == false ? validation.correctDisease : null
            );
            
            batch.set(validationRef, {
              'appointmentId': widget.appointment.id,
              'assessmentResultId': widget.appointment.assessmentResultId,
              'petType': widget.appointment.pet.type,
              'petBreed': widget.appointment.pet.breed,
              'imageUrl': validation.imageUrl,
              'imageType': validation.imageType,
              'aiPredictions': validation.aiPredictions,
              'clinicDiagnosis': _diagnosisController.text.trim(),
              'isCorrect': validation.isCorrect,
              'correctDisease': validation.isCorrect == false ? _cleanDiseaseName(validation.correctDisease!) : null,
              'diseaseLabel': cleanedDiseaseLabel,
              'uniqueFilename': uniqueFilename,
              'validatedAt': Timestamp.now(),
              'validatedBy': widget.appointment.clinicId,
              'canUseForTraining': validation.isCorrect == true,
              'canUseForRetraining': validation.isCorrect == false && validation.correctDisease != null,
              'hasImageAssessment': true,
              'trainingDataType': 'image_assessment',
              'correctionType': validation.isCorrect == false ? 'manual_correction' : 'validation',
            });
          }
        }
        }
      }

      // 4. Create follow-up appointment if needed
      String? followUpAppointmentId;
      if (_needsFollowUp && _followUpDate != null && _followUpTime != null) {
        final followUpRef = FirebaseFirestore.instance.collection('appointments').doc();
        followUpAppointmentId = followUpRef.id;
        
        // Extract start time from hour block format "HH:mm - HH:mm"
        String formattedTime;
        if (_followUpTime!.contains(' - ')) {
          formattedTime = _followUpTime!.split(' - ')[0]; // Get start time only
        } else {
          formattedTime = _followUpTime!;
        }
        
        final followUpTimeSlot = '$formattedTime-${_addMinutes(formattedTime, 20)}';
        
        batch.set(followUpRef, {
          // Required fields for AppointmentBooking model (mobile compatibility)
          'userId': widget.appointment.owner.id,
          'petId': widget.appointment.pet.id,
          'clinicId': widget.appointment.clinicId,
          'serviceName': widget.appointment.serviceType ?? widget.appointment.diseaseReason,
          'serviceId': widget.appointment.serviceType ?? 'general',
          'appointmentDate': Timestamp.fromDate(DateTime(
            _followUpDate!.year,
            _followUpDate!.month,
            _followUpDate!.day,
          )),
          'appointmentTime': formattedTime,
          'notes': 'Follow-up appointment from previous visit',
          'status': 'confirmed',
          'type': 'followUp',
          'estimatedPrice': 0.0,
          'duration': '${widget.appointment.estimatedDuration?.toInt() ?? 20} minutes',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          
          // Legacy fields (for backward compatibility with admin)
          'date': '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}',
          'time': formattedTime,
          'timeSlot': followUpTimeSlot,
          'pet': widget.appointment.pet.toMap(),
          'diseaseReason': 'Follow-up for: ${widget.appointment.diseaseReason}',
          'owner': widget.appointment.owner.toMap(),
          'serviceType': widget.appointment.serviceType,
          'estimatedDuration': widget.appointment.estimatedDuration,
          
          // Follow-up specific fields
          'isFollowUp': true,
          'previousAppointmentId': widget.appointment.id,
        });
      }

      await batch.commit();

      // 5. Create notification for follow-up appointment
      if (_needsFollowUp && followUpAppointmentId != null && _followUpDate != null && _followUpTime != null) {
        try {
          // Extract start time from hour block format "HH:mm - HH:mm" for notification
          String displayTime;
          if (_followUpTime!.contains(' - ')) {
            displayTime = _followUpTime!.split(' - ')[0];
          } else {
            displayTime = _followUpTime!;
          }
          
          // Build a comprehensive message about the follow-up need
          final diagnosisText = _diagnosisController.text.trim();
          final messageText = diagnosisText.isNotEmpty 
              ? 'Based on the diagnosis "${diagnosisText}", a follow-up appointment for ${widget.appointment.pet.name} has been scheduled for ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year} at $displayTime. Tap to view details and previous evaluation.'
              : 'A follow-up appointment for ${widget.appointment.pet.name} has been scheduled for ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year} at $displayTime. Tap to view details and previous evaluation.';
          
          await NotificationService.createNotification(
            userId: widget.appointment.owner.id,
            title: 'Follow-up Required - ${widget.appointment.pet.name}',
            message: messageText,
            category: NotificationCategory.appointment,
            priority: NotificationPriority.high,
            actionUrl: '/appointments/details/${widget.appointment.id}',
            actionLabel: 'View Evaluation',
            metadata: {
              'appointmentId': widget.appointment.id, // Link to previous/completed appointment
              'petId': widget.appointment.pet.id,
              'petName': widget.appointment.pet.name,
              'clinicId': widget.appointment.clinicId,
              'date': widget.appointment.date, // Use completed appointment date
              'time': widget.appointment.time, // Use completed appointment time
              'followUpAppointmentId': followUpAppointmentId,
              'followUpDate': '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}',
              'followUpTime': displayTime,
              'diseaseReason': 'Follow-up for: ${widget.appointment.diseaseReason}',
              'isFollowUp': true,
              'notificationType': 'followUp',
              'needsFollowUp': true,
              // Include clinic evaluation in metadata
              'previousDiagnosis': diagnosisText,
              'previousTreatment': _treatmentController.text.trim(),
              'previousPrescription': _prescriptionController.text.trim(),
              'previousClinicNotes': _clinicNotesController.text.trim(),
            },
          );
          print('✅ Follow-up notification created for user ${widget.appointment.owner.id}');
        } catch (e) {
          print('⚠️ Error creating follow-up notification: $e');
          // Don't fail the entire operation if notification fails
        }
      }

      if (!mounted) return;
      
      Navigator.of(context).pop();
      widget.onCompleted();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _needsFollowUp 
                      ? 'Appointment completed and follow-up scheduled!'
                      : 'Appointment completed successfully!',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error saving completion: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to complete appointment: ${e.toString()}';
        _isSaving = false;
      });
    }
  }

  String _addMinutes(String time, int minutesToAdd) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final totalMinutes = hour * 60 + minute + minutesToAdd;
    final newHour = (totalMinutes ~/ 60) % 24;
    final newMinute = totalMinutes % 60;
    return '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}';
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isActive ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showImageZoomDialog(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow closing by tapping outside
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(), // Close on tap anywhere
        child: Dialog(
          backgroundColor: Colors.black87,
          insetPadding: EdgeInsets.zero, // Remove all padding for full screen
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.transparent,
            child: Stack(
              children: [
                // Image - Full screen (prevents closing when tapped)
                Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping on image
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.black87,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.black87,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 80, color: Colors.white),
                                    SizedBox(height: 16),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Hint text at bottom
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text(
                        'Pinch to zoom • Drag to pan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Step Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.task_alt, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hasAIAssessment && _imageValidations.isNotEmpty
                                  ? (_currentStep == 1 
                                      ? 'Step 1: Complete Appointment' 
                                      : 'Step 2: Validate Training Data')
                                  : 'Complete Appointment',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.appointment.pet.name} - ${widget.appointment.date}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Step Progress Indicator (only show if there's AI assessment with images)
                  if (_hasAIAssessment && _imageValidations.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIndicator(1, 'Clinic Evaluation'),
                        // shorter connector and reduced horizontal spacing
                        SizedBox(
                          width: 120,
                          child: Container(
                            height: 2,
                            color: _currentStep >= 2 ? Colors.white : Colors.white.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                        _buildStepIndicator(2, 'Training Data'),
                      ],
                    ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )
                    : _currentStep == 1
                        ? _buildStep1ClinicEvaluation()
                        : _buildStep2TrainingDataValidation(),
              ),
            ),

            // Footer Actions
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1ClinicEvaluation() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                            // Error Banner
                            if (_errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => setState(() => _errorMessage = null),
                                    ),
                                  ],
                                ),
                              ),

                            // Clinic Evaluation Section (First)
                            const Text(
                              'Clinic Evaluation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Diagnosis
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Diagnosis',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                    controller: _diagnosisController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter the final diagnosis',
                                      hintStyle: TextStyle(fontSize: 13),
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter a diagnosis';
                                      }
                                      return null;
                                    },
                                    maxLines: 2,
                                    maxLength: 300,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Treatment Provided
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Treatment Provided',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                    controller: _treatmentController,
                                    decoration: const InputDecoration(
                                      hintText: 'Describe the treatment',
                                      hintStyle: TextStyle(fontSize: 13),
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please describe the treatment';
                                      }
                                      return null;
                                    },
                                    maxLines: 2,
                                    maxLength: 300,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Prescription
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prescription',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                    controller: _prescriptionController,
                                    decoration: const InputDecoration(
                                      hintText: 'Medications and dosage',
                                      hintStyle: TextStyle(fontSize: 13),
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 2,
                                    maxLength: 300,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Additional Notes
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Additional Notes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                    controller: _clinicNotesController,
                                    decoration: const InputDecoration(
                                      hintText: 'Other observations',
                                      hintStyle: TextStyle(fontSize: 13),
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      isDense: true,
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 3,
                                    maxLength: 300,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Follow-up Section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.05),
                                border: Border.all(color: AppColors.info.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _needsFollowUp,
                                        onChanged: (value) {
                                          setState(() => _needsFollowUp = value ?? false);
                                        },
                                        activeColor: AppColors.primary,
                                      ),
                                      const Expanded(
                                        child: Text(
                                          'Schedule Follow-up Appointment',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_needsFollowUp) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Select a date and time for the follow-up appointment. Only dates when the clinic is open are available.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    'Follow-up Date',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              InkWell(
                                                onTap: _selectFollowUpDate,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color: _followUpDate != null 
                                                          ? AppColors.primary 
                                                          : AppColors.border,
                                                      width: _followUpDate != null ? 2 : 1,
                                                    ),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        _followUpDate != null
                                                            ? '${_followUpDate!.day.toString().padLeft(2, '0')}/${_followUpDate!.month.toString().padLeft(2, '0')}/${_followUpDate!.year}'
                                                            : 'Select Date',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: _followUpDate != null 
                                                              ? AppColors.textPrimary 
                                                              : AppColors.textSecondary,
                                                          fontWeight: _followUpDate != null 
                                                              ? FontWeight.w500 
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.calendar_month,
                                                        size: 18,
                                                        color: _followUpDate != null 
                                                            ? AppColors.primary 
                                                            : AppColors.textSecondary,
                                                      ),
                                                    ],
                                                  ),
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
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Text(
                                                    'Follow-up Time',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              _followUpDate == null
                                                  ? Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade100,
                                                        border: Border.all(color: AppColors.border),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Select date first',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppColors.textSecondary,
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons.lock_outline,
                                                            size: 18,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : _isLoadingSchedule
                                                      ? Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            border: Border.all(color: AppColors.border),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              SizedBox(
                                                                width: 14,
                                                                height: 14,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                                    AppColors.primary,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Text(
                                                                'Loading slots...',
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: AppColors.textSecondary,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      : _availableTimeSlots.isEmpty
                                                          ? Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                                              decoration: BoxDecoration(
                                                                color: Colors.orange.shade50,
                                                                border: Border.all(color: Colors.orange.shade200),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      'No slots available',
                                                                      style: TextStyle(
                                                                        fontSize: 13,
                                                                        color: Colors.orange.shade900,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Icon(
                                                                    Icons.warning_amber,
                                                                    size: 18,
                                                                    color: Colors.orange.shade900,
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : DropdownButtonFormField<String>(
                                                              value: _followUpTime,
                                                              decoration: InputDecoration(
                                                                contentPadding: const EdgeInsets.symmetric(
                                                                  horizontal: 12,
                                                                  vertical: 14,
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  borderSide: BorderSide(color: AppColors.border),
                                                                ),
                                                                enabledBorder: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  borderSide: BorderSide(color: AppColors.border),
                                                                ),
                                                                focusedBorder: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  borderSide: BorderSide(
                                                                    color: AppColors.primary,
                                                                    width: 2,
                                                                  ),
                                                                ),
                                                                filled: true,
                                                                fillColor: Colors.white,
                                                              ),
                                                              hint: Text(
                                                                'Select Time',
                                                                style: TextStyle(
                                                                  fontSize: 13,
                                                                  color: AppColors.textSecondary,
                                                                ),
                                                              ),
                                                              icon: Icon(
                                                                Icons.arrow_drop_down,
                                                                color: AppColors.primary,
                                                              ),
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: AppColors.textPrimary,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              dropdownColor: Colors.white,
                                                              items: _availableTimeSlots.map((time) {
                                                                return DropdownMenuItem<String>(
                                                                  value: time,
                                                                  child: Text(
                                                                    _formatTimeSlotWithRange(time),
                                                                    style: const TextStyle(fontSize: 13),
                                                                  ),
                                                                );
                                                              }).toList(),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _followUpTime = value;
                                                                });
                                                              },
                                                              isExpanded: true,
                                                              menuMaxHeight: 250,
                                                            ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                        ],
                      ),
    );
  }

  Widget _buildStep2TrainingDataValidation() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Training Data Validation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Validate each assessment image for AI model training. Review the images below and mark whether the AI prediction is correct.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          if (_imageValidations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: const [
                    Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No assessment images available for validation',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _imageValidations.asMap().entries.map((entry) {
                final index = entry.key;
                final validation = entry.value;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.05),
                    border: Border.all(
                      color: validation.isCorrect == null 
                          ? AppColors.info.withOpacity(0.2)
                          : validation.isCorrect! 
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.error.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: validation.isCorrect == null
                                  ? AppColors.info
                                  : validation.isCorrect!
                                      ? AppColors.success
                                      : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Image ${index + 1} - ${validation.imageType}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Image
                      InkWell(
                        onTap: () => _showImageZoomDialog(validation.imageUrl),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              validation.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // AI Prediction (highest confidence only)
                      if (_aiPredictions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.smart_toy, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  () {
                                    var highest = _aiPredictions.first;
                                    for (var prediction in _aiPredictions) {
                                      if ((prediction['percentage'] as num) > (highest['percentage'] as num)) {
                                        highest = prediction;
                                      }
                                    }
                                    return 'AI Prediction: ${highest['condition']} (${(highest['percentage'] as num).toStringAsFixed(1)}%)';
                                  }(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Validation controls
                      const Text(
                        'Is the AI prediction correct for this image?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Correct', style: TextStyle(fontSize: 13)),
                              value: true,
                              groupValue: validation.isCorrect,
                              onChanged: (value) {
                                setState(() {
                                  validation.isCorrect = value;
                                  if (value == true) {
                                    validation.correctDisease = null;
                                  }
                                });
                              },
                              activeColor: AppColors.success,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Incorrect', style: TextStyle(fontSize: 13)),
                              value: false,
                              groupValue: validation.isCorrect,
                              onChanged: (value) {
                                setState(() {
                                  validation.isCorrect = value;
                                });
                              },
                              activeColor: AppColors.error,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      
                      // Disease dropdown when incorrect
                      if (validation.isCorrect == false) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Select Correct Disease *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: validation.correctDisease,
                          decoration: const InputDecoration(
                            hintText: 'Select the correct disease',
                            hintStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          items: _getDiseasesForPetType().map((disease) {
                            return DropdownMenuItem(
                              value: disease,
                              child: Text(disease),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              validation.correctDisease = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep == 2)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Evaluation'),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep == 1 && _hasAIAssessment && _imageValidations.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _validateStep1AndProceed,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Next: Training Data', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveCompletion,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                _isSaving ? 'Saving...' : 'Complete Appointment',
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _validateStep1AndProceed() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    if (_needsFollowUp) {
      if (_followUpDate == null) {
        setState(() => _errorMessage = 'Please select a follow-up date');
        return;
      }
      if (_followUpTime == null) {
        setState(() => _errorMessage = 'Please select a follow-up time');
        return;
      }
    }

    setState(() {
      _currentStep = 2;
    });
  }
}
