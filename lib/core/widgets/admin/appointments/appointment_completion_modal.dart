// widgets/admin/appointments/appointment_completion_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_colors.dart';
import '../../../models/clinic/appointment_models.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../models/notifications/notification_model.dart';

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
  
  // AI Assessment Validation
  bool _hasAIAssessment = false;
  bool? _aiAssessmentCorrect;
  String _aiAssessmentFeedback = '';
  List<Map<String, dynamic>> _aiPredictions = [];
  Map<String, bool> _predictionValidation = {};
  String? _selectedCorrectDisease; // For when AI assessment is incorrect
  
  // Disease name lists loaded from Firestore
  Map<String, List<String>> _diseasesByPetType = {};
  bool _isLoadingDiseases = false;
  
  // Image Assessment Data for Training
  List<Map<String, dynamic>> _assessmentImages = [];
  String? _originalImageUrl;
  String? _annotatedImageUrl;
  Map<String, dynamic>? _assessmentMetadata;
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAIAssessment();
    _loadDiseasesFromFirestore();
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
          
          // Load metadata
          _assessmentMetadata = data['metadata'] as Map<String, dynamic>?;
          
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
          
          // Initialize validation map
          for (var i = 0; i < _aiPredictions.length; i++) {
            _predictionValidation[i.toString()] = false;
          }
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
    setState(() => _isLoadingDiseases = true);

    try {
      final diseasesSnapshot = await FirebaseFirestore.instance
          .collection('skinDiseases')
          .get();

      final Map<String, List<String>> diseasesByType = {
        'Dogs': <String>[],
        'Cats': <String>[],
      };

      for (var doc in diseasesSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        final species = data['species'] as List<dynamic>? ?? [];

        if (name.isNotEmpty) {
          // Add the disease to appropriate species lists
          for (var specie in species) {
            final specieStr = specie.toString();
            if (diseasesByType.containsKey(specieStr)) {
              diseasesByType[specieStr]!.add(name);
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
        // Map from plural to singular for compatibility with existing pet types
        _diseasesByPetType = {
          'Dog': diseasesByType['Dogs'] ?? [],
          'Cat': diseasesByType['Cats'] ?? [],
        };
        _isLoadingDiseases = false;
      });

      print('Loaded diseases: $_diseasesByPetType');
    } catch (e) {
      print('Error loading diseases: $e');
      setState(() {
        // Fallback to basic list if loading fails
        _diseasesByPetType = {
          'Dog': ['Contact Dermatitis', 'Allergic Dermatitis', 'Bacterial Infection', 'Fungal Infection', 'Other'],
          'Cat': ['Contact Dermatitis', 'Allergic Dermatitis', 'Bacterial Infection', 'Fungal Infection', 'Other'],
        };
        _isLoadingDiseases = false;
      });
    }
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
    
    // Use the selected correct disease if available, otherwise use the AI prediction or diagnosis
    String diseaseForFilename = diseaseName ?? _selectedCorrectDisease ?? _diagnosisController.text.trim();
    
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

  Future<void> _selectFollowUpDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
      setState(() => _followUpDate = selectedDate);
    }
  }

  Future<void> _selectFollowUpTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    if (selectedTime != null) {
      setState(() {
        _followUpTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveCompletion() async {
    if (!_formKey.currentState!.validate()) return;

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

    // Validate AI assessment if available
    if (_hasAIAssessment && _aiAssessmentCorrect == null) {
      setState(() => _errorMessage = 'Please indicate if the AI assessment was correct');
      return;
    }

    // Validate correct disease selection if AI assessment is marked as incorrect
    if (_hasAIAssessment && _aiAssessmentCorrect == false && (_selectedCorrectDisease == null || _selectedCorrectDisease!.isEmpty)) {
      setState(() => _errorMessage = 'Please select the correct disease when marking AI assessment as incorrect');
      return;
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

      // 2. If AI assessment exists, save validation feedback
      if (_hasAIAssessment && widget.appointment.assessmentResultId != null) {
        final assessmentRef = FirebaseFirestore.instance
            .collection('assessment_results')
            .doc(widget.appointment.assessmentResultId);
        
        // Collect individual prediction validations
        final validatedPredictions = _aiPredictions.asMap().entries.map((entry) {
          return {
            'condition': entry.value['condition'],
            'percentage': entry.value['percentage'],
            'colorHex': entry.value['colorHex'],
            'isCorrect': _predictionValidation[entry.key.toString()] ?? false,
          };
        }).toList();

        batch.update(assessmentRef, {
          'clinicValidation': {
            'isValidated': true,
            'validatedAt': Timestamp.now(),
            'validatedBy': widget.appointment.clinicId,
            'overallCorrect': _aiAssessmentCorrect,
            'feedback': _aiAssessmentFeedback,
            'predictionsValidation': validatedPredictions,
            'clinicDiagnosis': _diagnosisController.text.trim(),
            'clinicTreatment': _treatmentController.text.trim(),
            'correctDisease': _aiAssessmentCorrect == false ? _selectedCorrectDisease : null,
          },
          'updatedAt': Timestamp.now(),
        });

        // 3. Store validation data for model training
        if (_aiAssessmentCorrect != null) {
          final validationRef = FirebaseFirestore.instance
              .collection('model_training_data')
              .doc();
          
          // Prepare image data for training with unique filename
          Map<String, dynamic> imageTrainingData = {};
          if (_originalImageUrl != null || _assessmentImages.isNotEmpty) {
            // Generate unique filename based on the disease
            final uniqueFilename = _generateUniqueFilename(
              diseaseName: _aiAssessmentCorrect == false ? _selectedCorrectDisease : null
            );
            
            if (_originalImageUrl != null) {
              imageTrainingData['originalImageUrl'] = _originalImageUrl;
            }
            if (_annotatedImageUrl != null) {
              imageTrainingData['annotatedImageUrl'] = _annotatedImageUrl;
            }
            if (_assessmentImages.isNotEmpty) {
              imageTrainingData['assessmentImages'] = _assessmentImages;
            }
            if (_assessmentMetadata != null) {
              imageTrainingData['assessmentMetadata'] = _assessmentMetadata;
            }
            
            // Add unique filename for file storage/organization
            imageTrainingData['uniqueFilename'] = uniqueFilename;
            imageTrainingData['diseaseLabel'] = _aiAssessmentCorrect == false 
                ? _selectedCorrectDisease 
                : (_aiPredictions.isNotEmpty ? _aiPredictions.first['condition'] : _diagnosisController.text.trim());
            imageTrainingData['petType'] = widget.appointment.pet.type;
            imageTrainingData['correctionType'] = _aiAssessmentCorrect == false ? 'manual_correction' : 'validation';
          }
          
          batch.set(validationRef, {
            'appointmentId': widget.appointment.id,
            'assessmentResultId': widget.appointment.assessmentResultId,
            'petType': widget.appointment.pet.type,
            'petBreed': widget.appointment.pet.breed,
            'aiPredictions': validatedPredictions,
            'clinicDiagnosis': _diagnosisController.text.trim(),
            'overallCorrect': _aiAssessmentCorrect,
            'feedback': _aiAssessmentFeedback,
            'correctDisease': _aiAssessmentCorrect == false ? _selectedCorrectDisease : null,
            'validatedAt': Timestamp.now(),
            'validatedBy': widget.appointment.clinicId,
            'canUseForTraining': _aiAssessmentCorrect == true, // Mark for retraining
            'canUseForRetraining': _aiAssessmentCorrect == false && _selectedCorrectDisease != null, // Mark for correction training
            'imageData': imageTrainingData.isNotEmpty ? imageTrainingData : null,
            'hasImageAssessment': (_originalImageUrl != null || _assessmentImages.isNotEmpty),
            'trainingDataType': _originalImageUrl != null ? 'image_assessment' : 'text_assessment',
          });
        }
      }

      // 4. Create follow-up appointment if needed
      String? followUpAppointmentId;
      if (_needsFollowUp && _followUpDate != null && _followUpTime != null) {
        final followUpRef = FirebaseFirestore.instance.collection('appointments').doc();
        followUpAppointmentId = followUpRef.id;
        
        final followUpTimeSlot = '$_followUpTime-${_addMinutes(_followUpTime!, 20)}';
        
        batch.set(followUpRef, {
          'clinicId': widget.appointment.clinicId,
          'date': '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}',
          'time': _followUpTime,
          'timeSlot': followUpTimeSlot,
          'pet': widget.appointment.pet.toMap(),
          'diseaseReason': 'Follow-up for: ${widget.appointment.diseaseReason}',
          'owner': widget.appointment.owner.toMap(),
          'status': 'confirmed',
          'notes': 'Follow-up appointment from previous visit',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'isFollowUp': true,
          'previousAppointmentId': widget.appointment.id,
        });
      }

      await batch.commit();

      // 5. Create notification for follow-up appointment
      if (_needsFollowUp && followUpAppointmentId != null && _followUpDate != null && _followUpTime != null) {
        try {
          // Build a comprehensive message about the follow-up need
          final diagnosisText = _diagnosisController.text.trim();
          final messageText = diagnosisText.isNotEmpty 
              ? 'Based on the diagnosis "${diagnosisText}", a follow-up appointment for ${widget.appointment.pet.name} has been scheduled for ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year} at $_followUpTime. Tap to view details and previous evaluation.'
              : 'A follow-up appointment for ${widget.appointment.pet.name} has been scheduled for ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year} at $_followUpTime. Tap to view details and previous evaluation.';
          
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
              'followUpTime': _followUpTime,
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
        width: 650,
        constraints: const BoxConstraints(maxHeight: 750),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (Compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.task_alt, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Appointment',
                          style: TextStyle(
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
                    : Form(
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
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Date',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              InkWell(
                                                onTap: _selectFollowUpDate,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    _followUpDate != null
                                                        ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                                                        : 'Select Date',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: _followUpDate != null ? Colors.black : Colors.grey,
                                                    ),
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
                                                'Time',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              InkWell(
                                                onTap: _selectFollowUpTime,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    _followUpTime ?? 'Select Time',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: _followUpTime != null ? Colors.black : Colors.grey,
                                                    ),
                                                  ),
                                                ),
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

                            // AI Assessment Validation Section (After Clinic Evaluation)
                            if (_hasAIAssessment) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
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
                                        Icon(Icons.smart_toy, color: AppColors.primary, size: 18),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'AI Assessment Validation',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Display predictions in compact list
                                    ..._aiPredictions.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final prediction = entry.value;
                                      
                                      // Parse color from hex
                                      Color conditionColor = AppColors.primary;
                                      final colorHex = prediction['colorHex'] as String?;
                                      if (colorHex != null && colorHex.startsWith('#')) {
                                        try {
                                          conditionColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
                                        } catch (e) {
                                          // Use default if parsing fails
                                        }
                                      }
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Checkbox(
                                                value: _predictionValidation[index.toString()] ?? false,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _predictionValidation[index.toString()] = value ?? false;
                                                  });
                                                },
                                                activeColor: AppColors.success,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                prediction['condition'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${(prediction['percentage'] as num).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: conditionColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),

                                    const Divider(height: 24),
                                    
                                    // Overall assessment - compact radio buttons
                                    const Text(
                                      'Overall Assessment:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<bool>(
                                            title: const Text('Correct', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
                                            value: true,
                                            groupValue: _aiAssessmentCorrect,
                                            onChanged: (value) {
                                              setState(() {
                                                _aiAssessmentCorrect = value;
                                                if (value == true) {
                                                  _selectedCorrectDisease = null; // Reset when switching to correct
                                                }
                                              });
                                            },
                                            activeColor: AppColors.success,
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<bool>(
                                            title: const Text('Incorrect', style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600)),
                                            value: false,
                                            groupValue: _aiAssessmentCorrect,
                                            onChanged: (value) {
                                              setState(() {
                                                _aiAssessmentCorrect = value;
                                                if (value == true) {
                                                  _selectedCorrectDisease = null; // Reset when switching to correct
                                                }
                                              });
                                            },
                                            activeColor: AppColors.error,
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Disease Selection Dropdown (when AI is incorrect)
                                    if (_aiAssessmentCorrect == false) ...[
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Select Correct Disease *',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.border),
                                              borderRadius: BorderRadius.circular(8),
                                              color: AppColors.white,
                                            ),
                                            child: _isLoadingDiseases 
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                                                          'Loading diseases...',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : DropdownButtonFormField<String>(
                                                    value: _selectedCorrectDisease,
                                                    decoration: InputDecoration(
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      border: InputBorder.none,
                                                      hintText: _getDiseasesForPetType().isEmpty 
                                                          ? 'No diseases available' 
                                                          : 'Select the correct disease',
                                                      hintStyle: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                    items: _getDiseasesForPetType().map((disease) {
                                                      return DropdownMenuItem<String>(
                                                        value: disease,
                                                        child: Text(
                                                          disease,
                                                          style: const TextStyle(fontSize: 13),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: _getDiseasesForPetType().isEmpty ? null : (value) {
                                                      setState(() {
                                                        _selectedCorrectDisease = value;
                                                      });
                                                    },
                                                    validator: (value) {
                                                      if (_aiAssessmentCorrect == false && (value == null || value.isEmpty)) {
                                                        return 'Please select the correct disease';
                                                      }
                                                      return null;
                                                    },
                                                    isExpanded: true,
                                                    dropdownColor: AppColors.white,
                                                    iconEnabledColor: AppColors.primary,
                                                  ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'This will help improve our AI model accuracy for ${widget.appointment.pet.type.toLowerCase()} diseases.',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Feedback (Optional)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                            decoration: const InputDecoration(
                                              hintText: 'Additional comments...',
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
                                            onChanged: (value) => _aiAssessmentFeedback = value,
                                          ),
                                      ],
                                    ),
                                    
                                    // Image Assessment Validation for Model Training
                                    if (_hasAIAssessment) ...[
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),
                                      
                                      Row(
                                        children: [
                                          Icon(Icons.image, color: AppColors.primary, size: 18),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Image Assessment for Model Training',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Display assessment images (always show container)
                                      InkWell(
                                        onTap: _originalImageUrl != null && _originalImageUrl!.isNotEmpty
                                            ? () => _showImageZoomDialog(_originalImageUrl!)
                                            : null,
                                        child: Container(
                                          width: double.infinity,
                                          height: 300,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: _originalImageUrl != null && _originalImageUrl!.isNotEmpty
                                                    ? Image.network(
                                                        _originalImageUrl!,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return const Center(
                                                            child: CircularProgressIndicator(),
                                                          );
                                                        },
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            color: Colors.grey.withOpacity(0.1),
                                                            child: const Center(
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                                  Text('Image not available', style: TextStyle(color: Colors.grey)),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      )
                                                    : Container(
                                                        color: Colors.grey.withOpacity(0.1),
                                                        child: const Center(
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.image, size: 40, color: Colors.grey),
                                                              Text('No assessment image available', style: TextStyle(color: Colors.grey)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                              // Zoom icon overlay when image is available
                                              if (_originalImageUrl != null && _originalImageUrl!.isNotEmpty)
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.6),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Icon(
                                                      Icons.zoom_in,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Original Assessment Image',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Image validation confirmation
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withOpacity(0.05),
                                          border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Training Data Validation',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'By confirming the AI assessment as correct, this image and assessment data will be used to improve our AI model. Please verify the accuracy before confirming.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (_assessmentMetadata != null) ...[
                                              Text(
                                                'Assessment Date: ${(_assessmentMetadata!['timestamp'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'Unknown'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              if (_assessmentMetadata!['confidence'] != null)
                                                Text(
                                                  'AI Confidence: ${(_assessmentMetadata!['confidence'] as num).toStringAsFixed(1)}%',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
              ),
            ),

            // Footer Actions (Compact)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
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
            ),
          ],
        ),
      ),
    );
  }
}
