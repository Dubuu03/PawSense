// widgets/admin/appointments/appointment_completion_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_colors.dart';
import '../../../models/clinic/appointment_models.dart';

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
  
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAIAssessment();
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
      return;
    }

    setState(() => _isLoading = true);

    try {
      final assessmentDoc = await FirebaseFirestore.instance
          .collection('assessment_results')
          .doc(widget.appointment.assessmentResultId)
          .get();

      if (assessmentDoc.exists) {
        final data = assessmentDoc.data()!;
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
          
          // Initialize validation map
          for (var i = 0; i < _aiPredictions.length; i++) {
            _predictionValidation[i.toString()] = false;
          }
        });
      }
    } catch (e) {
      print('Error loading AI assessment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

    // Validate follow-up details if needed
    if (_needsFollowUp) {
      if (_followUpDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a follow-up date'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_followUpTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a follow-up time'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Validate AI assessment if available
    if (_hasAIAssessment && _aiAssessmentCorrect == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please indicate if the AI assessment was correct'),
          backgroundColor: AppColors.error,
        ),
      );
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
          },
          'updatedAt': Timestamp.now(),
        });

        // 3. Store validation data for model training
        if (_aiAssessmentCorrect != null) {
          final validationRef = FirebaseFirestore.instance
              .collection('model_training_data')
              .doc();
          
          batch.set(validationRef, {
            'appointmentId': widget.appointment.id,
            'assessmentResultId': widget.appointment.assessmentResultId,
            'petType': widget.appointment.pet.type,
            'petBreed': widget.appointment.pet.breed,
            'aiPredictions': validatedPredictions,
            'clinicDiagnosis': _diagnosisController.text.trim(),
            'overallCorrect': _aiAssessmentCorrect,
            'feedback': _aiAssessmentFeedback,
            'validatedAt': Timestamp.now(),
            'validatedBy': widget.appointment.clinicId,
            'canUseForTraining': _aiAssessmentCorrect == true, // Mark for retraining
          });
        }
      }

      // 4. Create follow-up appointment if needed
      if (_needsFollowUp && _followUpDate != null && _followUpTime != null) {
        final followUpRef = FirebaseFirestore.instance.collection('appointments').doc();
        
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete appointment: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                            // AI Assessment Validation Section (Compact)
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
                                              setState(() => _aiAssessmentCorrect = value);
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
                                              setState(() => _aiAssessmentCorrect = value);
                                            },
                                            activeColor: AppColors.error,
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Feedback (Optional)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: TextFormField(
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
                                            onChanged: (value) => _aiAssessmentFeedback = value,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Clinic Evaluation Section
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
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
                                    maxLines: 2,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Diagnosis is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Treatment
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Treatment Provided',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
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
                                    maxLines: 2,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Treatment information is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Prescription
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prescription',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
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
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Additional Notes
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Additional Notes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
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
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Follow-up Section (Compact)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.05),
                                border: Border.all(color: AppColors.border),
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
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const Text(
                                        'Schedule Follow-up Appointment',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_needsFollowUp) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _selectFollowUpDate,
                                            icon: const Icon(Icons.calendar_today, size: 16),
                                            label: Text(
                                              _followUpDate == null
                                                  ? 'Select Date'
                                                  : '${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _selectFollowUpTime,
                                            icon: const Icon(Icons.access_time, size: 16),
                                            label: Text(
                                              _followUpTime ?? 'Select Time',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
