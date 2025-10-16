import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/services/clinic/patient_record_service.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/models/clinic/appointment_models.dart' as AppointmentModels;
import 'package:pawsense/core/services/user/pdf_generation_service.dart';
import 'package:pawsense/core/services/user/assessment_result_service.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/widgets/admin/appointments/appointment_completion_modal.dart';

class ImprovedPatientDetailsModal extends StatefulWidget {
  final PatientRecord patient;
  final String clinicId;

  const ImprovedPatientDetailsModal({
    super.key,
    required this.patient,
    required this.clinicId,
  });

  @override
  State<ImprovedPatientDetailsModal> createState() => _ImprovedPatientDetailsModalState();
}

class _ImprovedPatientDetailsModalState extends State<ImprovedPatientDetailsModal> {
  List<AppointmentBooking> _appointmentHistory = [];
  bool _isLoadingHistory = false;
  bool _showingAppointmentDetails = false;
  AppointmentModels.Appointment? _selectedAppointment;
  Map<String, dynamic>? _assessmentData;
  bool _isLoadingAssessment = false;
  
  // Previous appointment data for follow-ups
  AppointmentModels.Appointment? _previousAppointment;
  bool _isLoadingPreviousAppointment = false;

  @override
  void initState() {
    super.initState();
    _loadAppointmentHistory();
  }

  Future<void> _loadAppointmentHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final history = await PatientRecordService.getPatientHistory(
        clinicId: widget.clinicId,
        petId: widget.patient.petId,
      );

      if (mounted) {
        setState(() {
          _appointmentHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('❌ Error loading appointment history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _showAppointmentDetails(AppointmentBooking booking) async {
    // Convert to Appointment model
    final appointment = await _convertToAppointmentModel(booking);
    if (appointment != null && mounted) {
      setState(() {
        _showingAppointmentDetails = true;
        _selectedAppointment = appointment;
        _previousAppointment = null; // Reset previous appointment
      });
      
      // Load assessment data if available
      if (appointment.assessmentResultId != null && 
          appointment.assessmentResultId!.isNotEmpty) {
        _loadAssessmentData(appointment.assessmentResultId!);
      }
      
      // Load previous appointment if this is a follow-up
      if (appointment.isFollowUp == true && appointment.previousAppointmentId != null) {
        _loadPreviousAppointment(appointment.previousAppointmentId!);
      }
    }
  }

  Future<void> _loadPreviousAppointment(String previousAppointmentId) async {
    setState(() => _isLoadingPreviousAppointment = true);

    try {
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(previousAppointmentId)
          .get();
      
      if (appointmentDoc.exists && mounted) {
        final data = appointmentDoc.data()!;
        
        // Convert to Appointment model (handle both formats)
        AppointmentModels.Appointment? previousAppt;
        
        if (data['pet'] != null && data['pet'] is Map) {
          // New format with embedded data
          final petMap = data['pet'] as Map<String, dynamic>;
          final ownerMap = data['owner'] as Map<String, dynamic>;
          
          DateTime appointmentDate = DateTime.now();
          if (data['date'] != null) {
            try {
              final dateParts = (data['date'] as String).split('-');
              appointmentDate = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
            } catch (e) {
              print('⚠️ Error parsing previous appointment date: ${data['date']}');
            }
          }
          
          final statusString = data['status'] as String?;
          AppointmentModels.AppointmentStatus status = AppointmentModels.AppointmentStatus.pending;
          if (statusString != null) {
            switch (statusString) {
              case 'confirmed':
                status = AppointmentModels.AppointmentStatus.confirmed;
                break;
              case 'completed':
                status = AppointmentModels.AppointmentStatus.completed;
                break;
              case 'cancelled':
                status = AppointmentModels.AppointmentStatus.cancelled;
                break;
            }
          }
          
          previousAppt = AppointmentModels.Appointment(
            id: previousAppointmentId,
            clinicId: data['clinicId'] ?? '',
            date: data['date'] ?? '',
            time: data['time'] ?? '',
            timeSlot: data['timeSlot'] ?? '',
            pet: AppointmentModels.Pet.fromMap(petMap),
            diseaseReason: data['diseaseReason'] ?? '',
            owner: AppointmentModels.Owner.fromMap(ownerMap),
            status: status,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            notes: data['notes'],
            diagnosis: data['diagnosis'],
            treatment: data['treatment'],
            prescription: data['prescription'],
            clinicNotes: data['clinicNotes'],
            completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
          );
        } else {
          // Old format - convert from booking
          final booking = AppointmentBooking.fromMap(data, previousAppointmentId);
          previousAppt = await _convertToAppointmentModel(booking);
        }
        
        if (mounted && previousAppt != null) {
          setState(() {
            _previousAppointment = previousAppt;
            _isLoadingPreviousAppointment = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading previous appointment: $e');
      if (mounted) {
        setState(() => _isLoadingPreviousAppointment = false);
      }
    }
  }

  Future<void> _loadAssessmentData(String assessmentId) async {
    setState(() => _isLoadingAssessment = true);

    try {
      final assessmentDoc = await FirebaseFirestore.instance
          .collection('assessment_results')
          .doc(assessmentId)
          .get();
      
      if (assessmentDoc.exists && mounted) {
        setState(() {
          _assessmentData = assessmentDoc.data();
          _isLoadingAssessment = false;
        });
      }
    } catch (e) {
      print('❌ Error loading assessment data: $e');
      if (mounted) {
        setState(() => _isLoadingAssessment = false);
      }
    }
  }

  Future<void> _completeAppointment(AppointmentBooking booking) async {
    // Convert to Appointment model
    final appointment = await _convertToAppointmentModel(booking);
    if (appointment == null) return;

    if (!mounted) return;

    // Show the appointment completion modal
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppointmentCompletionModal(
        appointment: appointment,
        onCompleted: () {
          // Refresh the appointment history to show updated status
          _loadAppointmentHistory();
        },
      ),
    );
  }

  void _goBackToPatientDetails() {
    setState(() {
      _showingAppointmentDetails = false;
      _selectedAppointment = null;
      _assessmentData = null;
      _previousAppointment = null;
    });
  }

  Future<AppointmentModels.Appointment?> _convertToAppointmentModel(
      AppointmentBooking booking) async {
    try {
      // Get pet details
      final petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(booking.petId)
          .get();

      AppointmentModels.Pet pet;
      if (petDoc.exists) {
        final petData = petDoc.data()!;
        pet = AppointmentModels.Pet(
          id: booking.petId,
          name: petData['petName'] ?? 'Unknown',
          type: petData['petType'] ?? 'Unknown',
          emoji: _getPetEmoji(petData['petType'] ?? 'Unknown'),
          breed: petData['breed'],
          age: petData['age'] != null ? (petData['age'] as int) ~/ 12 : null,
          imageUrl: petData['imageUrl'],
        );
      } else {
        pet = AppointmentModels.Pet(
          id: booking.petId,
          name: widget.patient.petName,
          type: widget.patient.petType,
          emoji: widget.patient.petEmoji,
          breed: widget.patient.breed,
          age: widget.patient.age ~/ 12,
        );
      }

      // Get owner details
      final owner = AppointmentModels.Owner(
        id: booking.userId,
        name: widget.patient.ownerName,
        phone: widget.patient.ownerPhone,
        email: widget.patient.ownerEmail,
      );

      // Convert status
      AppointmentModels.AppointmentStatus status;
      switch (booking.status) {
        case AppointmentStatus.pending:
          status = AppointmentModels.AppointmentStatus.pending;
          break;
        case AppointmentStatus.confirmed:
          status = AppointmentModels.AppointmentStatus.confirmed;
          break;
        case AppointmentStatus.completed:
          status = AppointmentModels.AppointmentStatus.completed;
          break;
        case AppointmentStatus.cancelled:
          status = AppointmentModels.AppointmentStatus.cancelled;
          break;
        default:
          status = AppointmentModels.AppointmentStatus.pending;
      }

      // Format date
      final dateStr = '${booking.appointmentDate.year}-${booking.appointmentDate.month.toString().padLeft(2, '0')}-${booking.appointmentDate.day.toString().padLeft(2, '0')}';

      return AppointmentModels.Appointment(
        id: booking.id ?? '',
        clinicId: booking.clinicId,
        date: dateStr,
        time: booking.appointmentTime,
        timeSlot: '${booking.appointmentTime}-${booking.appointmentTime}',
        pet: pet,
        diseaseReason: booking.serviceName,
        owner: owner,
        status: status,
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
        notes: booking.notes,
        assessmentResultId: booking.assessmentResultId,
        cancelReason: booking.cancelReason,
        isFollowUp: booking.isFollowUp,
        previousAppointmentId: booking.previousAppointmentId,
      );
    } catch (e) {
      print('Error converting appointment: $e');
      return null;
    }
  }

  String _getPetEmoji(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐱';
      case 'bird':
        return '🐦';
      case 'rabbit':
        return '🐰';
      case 'hamster':
        return '🐹';
      default:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _showingAppointmentDetails ? 600 : 1000,
          maxHeight: 800,
        ),
        child: _showingAppointmentDetails && _selectedAppointment != null
            ? _buildAppointmentDetailsView()
            : _buildPatientDetailsView(),
      ),
    );
  }

  // ==================== PATIENT DETAILS VIEW ====================

  Widget _buildPatientDetailsView() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildPatientInfo(),
              ),
              VerticalDivider(
                width: 1,
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
              Expanded(
                flex: 3,
                child: _buildAppointmentHistory(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildPetAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patient.petName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.patient.petType} • ${widget.patient.breed}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildHealthStatusBadge(),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatar() {
    if (widget.patient.imageUrl != null && widget.patient.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(widget.patient.imageUrl!),
      );
    } else {
      return CircleAvatar(
        radius: 40,
        backgroundColor: _getPetTypeColor().withOpacity(0.2),
        child: Text(
          widget.patient.petEmoji,
          style: const TextStyle(fontSize: 40),
        ),
      );
    }
  }

  Widget _buildHealthStatusBadge() {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (widget.patient.healthStatus) {
      case PatientHealthStatus.healthy:
        badgeColor = Colors.green;
        badgeIcon = Icons.favorite;
        badgeText = 'Healthy';
        break;
      case PatientHealthStatus.treatment:
        badgeColor = Colors.orange;
        badgeIcon = Icons.medical_services;
        badgeText = 'Under Treatment';
        break;
      case PatientHealthStatus.scheduled:
        badgeColor = Colors.blue;
        badgeIcon = Icons.schedule;
        badgeText = 'Visit Scheduled';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help_outline;
        badgeText = 'Unknown Status';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 20,
            color: badgeColor,
          ),
          const SizedBox(width: 8),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 14,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          _buildInfoCard(
            title: 'Basic Details',
            children: [
              _buildInfoRow(Icons.pets, 'Name', widget.patient.petName),
              _buildInfoRow(Icons.category, 'Type', widget.patient.petType),
              _buildInfoRow(Icons.info_outline, 'Breed', widget.patient.breed),
              _buildInfoRow(Icons.cake, 'Age', widget.patient.ageString),
              _buildInfoRow(Icons.monitor_weight, 'Weight', widget.patient.weightString),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Owner Information',
            children: [
              _buildInfoRow(Icons.person, 'Name', widget.patient.ownerName),
              _buildInfoRow(Icons.phone, 'Phone', widget.patient.ownerPhone),
              _buildInfoRow(Icons.email, 'Email', widget.patient.ownerEmail),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Visit Statistics',
            children: [
              _buildInfoRow(
                Icons.event_note,
                'Total Visits',
                '${widget.patient.appointmentCount}',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Last Visit',
                _formatDate(widget.patient.lastVisit),
              ),
              _buildInfoRow(
                Icons.medical_information,
                'Last Diagnosis',
                widget.patient.lastDiagnosis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingHistory)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_appointmentHistory.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No appointment history found',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _appointmentHistory.length,
                itemBuilder: (context, index) {
                  final appointment = _appointmentHistory[index];
                  return _buildAppointmentCard(appointment);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentBooking appointment) {
    // Debug: Check if isFollowUp is being loaded
    print('📋 Appointment ${appointment.id}: isFollowUp = ${appointment.isFollowUp}, status = ${appointment.status}');
    
    final bool isFollowUp = appointment.isFollowUp == true;
    final Color followUpColor = const Color(0xFF3B82F6);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showAppointmentDetails(appointment),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Follow-up header banner (if applicable)
            if (isFollowUp) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: followUpColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: followUpColor.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 16, color: followUpColor),
                    const SizedBox(width: 6),
                    Text(
                      'Follow-up Appointment',
                      style: TextStyle(
                        color: followUpColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (appointment.previousAppointmentId != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_back, size: 12, color: followUpColor.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Text(
                        'Previous Visit',
                        style: TextStyle(
                          color: followUpColor.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(appointment.appointmentDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _buildAppointmentStatusBadge(appointment.status),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.appointmentTime,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.medical_information,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.serviceName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.notes,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Complete button for confirmed appointments
                if (appointment.status == AppointmentStatus.confirmed)
                  ElevatedButton.icon(
                    onPressed: () => _completeAppointment(appointment),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text(
                      'Complete',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                
                // View details indicator
                Row(
                  children: [
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildAppointmentStatusBadge(AppointmentStatus status) {
    Color badgeColor;
    String badgeText;

    switch (status) {
      case AppointmentStatus.confirmed:
        badgeColor = Colors.blue;
        badgeText = 'Confirmed';
        break;
      case AppointmentStatus.completed:
        badgeColor = Colors.green;
        badgeText = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        badgeColor = Colors.red;
        badgeText = 'Cancelled';
        break;
      case AppointmentStatus.pending:
        badgeColor = Colors.orange;
        badgeText = 'Pending';
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 11,
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==================== APPOINTMENT DETAILS VIEW ====================

  Widget _buildAppointmentDetailsView() {
    if (_selectedAppointment == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final appointment = _selectedAppointment!;
    final dateTime = DateTime.parse('${appointment.date} ${appointment.time}:00');
    final formattedDate = _formatDateFull(dateTime);
    final formattedTime = _formatTime(appointment.time);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _goBackToPatientDetails,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to patient details',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet Information
                  Row(
            children: [
              _buildAppointmentPetAvatar(appointment.pet),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.pet.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appointment.pet.type}${appointment.pet.breed != null ? ' • ${appointment.pet.breed}' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (appointment.pet.age != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${appointment.pet.age} years old',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildAppointmentModalStatusBadge(appointment.status),
            ],
          ),
          const SizedBox(height: 24),

          // Cancellation Reason (if cancelled)
          if (appointment.status == AppointmentModels.AppointmentStatus.cancelled && 
              appointment.cancelReason != null &&
              appointment.cancelReason!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cancel, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Cancellation Reason:',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appointment.cancelReason!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Follow-up Indicator with Previous Appointment Details
          if (appointment.isFollowUp == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync, size: 18, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      const Text(
                        'This is a Follow-up Appointment',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  // Previous Appointment Details
                  if (_isLoadingPreviousAppointment) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        ),
                      ),
                    ),
                  ] else if (_previousAppointment != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    
                    // Previous Visit Details Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.history, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Previous Visit Details:',
                                style: TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildPreviousAppointmentDetail('Date', _formatDate(DateTime.parse(_previousAppointment!.date))),
                              const SizedBox(height: 4),
                              _buildPreviousAppointmentDetail('Time', _previousAppointment!.time),
                              const SizedBox(height: 4),
                              _buildPreviousAppointmentDetail('Reason', _previousAppointment!.diseaseReason),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Clinic Evaluation Section
                    if (_previousAppointment!.diagnosis != null && _previousAppointment!.diagnosis!.isNotEmpty ||
                        _previousAppointment!.treatment != null && _previousAppointment!.treatment!.isNotEmpty ||
                        _previousAppointment!.prescription != null && _previousAppointment!.prescription!.isNotEmpty ||
                        _previousAppointment!.clinicNotes != null && _previousAppointment!.clinicNotes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.medical_services, size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clinic Evaluation:',
                                  style: TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_previousAppointment!.diagnosis != null && _previousAppointment!.diagnosis!.isNotEmpty) ...[
                                  _buildPreviousAppointmentDetail('Diagnosis', _previousAppointment!.diagnosis!),
                                  const SizedBox(height: 4),
                                ],
                                
                                if (_previousAppointment!.treatment != null && _previousAppointment!.treatment!.isNotEmpty) ...[
                                  _buildPreviousAppointmentDetail('Treatment', _previousAppointment!.treatment!),
                                  const SizedBox(height: 4),
                                ],
                                
                                if (_previousAppointment!.prescription != null && _previousAppointment!.prescription!.isNotEmpty) ...[
                                  _buildPreviousAppointmentDetail('Prescription', _previousAppointment!.prescription!),
                                  const SizedBox(height: 4),
                                ],
                                
                                if (_previousAppointment!.clinicNotes != null && _previousAppointment!.clinicNotes!.isNotEmpty) ...[
                                  _buildPreviousAppointmentDetail('Clinic Notes', _previousAppointment!.clinicNotes!),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Appointment Information
          _buildDetailInfoSection('Date & Time', '$formattedDate at $formattedTime'),
          const SizedBox(height: 16),
          _buildDetailInfoSection('Reason for Visit', appointment.diseaseReason),
          const SizedBox(height: 16),

          // Owner Information
          _buildDetailInfoSection(
            'Owner',
            '${appointment.owner.name}\n${appointment.owner.phone}${appointment.owner.email != null && appointment.owner.email!.isNotEmpty ? '\n${appointment.owner.email}' : ''}',
          ),

          // Notes (if available)
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailInfoSection('Notes', appointment.notes!),
          ],

          // AI Assessment Results
          if (_isLoadingAssessment)
            ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ]
          else if (_assessmentData != null)
            ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'AI Assessment Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 12),
              ..._buildAssessmentResults(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generatePDF,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download Assessment PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          
          // Complete Appointment Button (show for confirmed appointments, regardless of assessment data)
          if (appointment.status == AppointmentModels.AppointmentStatus.confirmed) ...[
            // Add spacing if assessment data was shown
            if (_assessmentData != null) const SizedBox(height: 12),
            // Add divider and spacing if no assessment data
            if (_assessmentData == null && !_isLoadingAssessment) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Convert back to AppointmentBooking to use existing method
                  final booking = _appointmentHistory.firstWhere(
                    (booking) => booking.id == appointment.id,
                    orElse: () => throw Exception('Booking not found'),
                  );
                  await _completeAppointment(booking);
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Complete Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentPetAvatar(AppointmentModels.Pet pet) {
    if (pet.imageUrl != null && pet.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          pet.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  pet.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            pet.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }
  }

  Widget _buildDetailInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentModalStatusBadge(AppointmentModels.AppointmentStatus status) {
    Color badgeColor;
    String badgeText;

    switch (status) {
      case AppointmentModels.AppointmentStatus.pending:
        badgeColor = Colors.orange;
        badgeText = 'Pending';
        break;
      case AppointmentModels.AppointmentStatus.confirmed:
        badgeColor = Colors.green;
        badgeText = 'Confirmed';
        break;
      case AppointmentModels.AppointmentStatus.completed:
        badgeColor = Colors.blue;
        badgeText = 'Completed';
        break;
      case AppointmentModels.AppointmentStatus.cancelled:
        badgeColor = Colors.red;
        badgeText = 'Cancelled';
        break;
      case AppointmentModels.AppointmentStatus.noShow:
        badgeColor = Colors.grey;
        badgeText = 'No Show';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor,
          width: 1,
        ),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildAssessmentResults() {
    if (_assessmentData == null) return [];
    
    final analysisResults = _assessmentData!['analysisResults'] as List?;
    
    if (analysisResults == null || analysisResults.isEmpty) {
      return [
        const Text(
          'No analysis results available',
          style: TextStyle(color: Colors.grey),
        ),
      ];
    }
    
    return analysisResults.map<Widget>((result) {
      if (result is! Map<String, dynamic>) return const SizedBox.shrink();
      
      final condition = result['condition'] as String?;
      final percentage = result['percentage'] as num?;
      final colorHex = result['colorHex'] as String?;
      
      if (condition == null || percentage == null) return const SizedBox.shrink();
      
      Color conditionColor = const Color(0xFF7C3AED);
      if (colorHex != null && colorHex.startsWith('#')) {
        try {
          conditionColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
        } catch (e) {
          // Use default color if parsing fails
        }
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: conditionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                condition,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: conditionColor,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _generatePDF() async {
    if (_selectedAppointment == null || 
        _selectedAppointment!.assessmentResultId == null ||
        _selectedAppointment!.assessmentResultId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assessment data available for this appointment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final assessmentService = AssessmentResultService();
      final assessmentResult = await assessmentService.getAssessmentResultById(
        _selectedAppointment!.assessmentResultId!
      );
      
      if (assessmentResult == null) {
        throw Exception('Assessment data not found');
      }

      final userModel = UserModel(
        uid: _selectedAppointment!.owner.id,
        username: _selectedAppointment!.owner.name,
        email: _selectedAppointment!.owner.email ?? '',
        contactNumber: _selectedAppointment!.owner.phone,
        createdAt: DateTime.now(),
        role: 'user',
      );

      final pdfBytes = await PDFGenerationService.generateAssessmentPDF(
        user: userModel,
        assessmentResult: assessmentResult,
      );

      final fileName = 'PawSense_Assessment_${_selectedAppointment!.pet.name}_${DateTime.now().millisecondsSinceEpoch}';
      await PDFGenerationService.saveWithSystemDialog(pdfBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('PDF downloaded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== HELPER METHODS ====================

  Color _getPetTypeColor() {
    switch (widget.patient.petType.toLowerCase()) {
      case 'dog':
        return Colors.brown;
      case 'cat':
        return Colors.orange;
      case 'bird':
        return Colors.blue;
      case 'rabbit':
        return Colors.pink;
      case 'hamster':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateFull(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildPreviousAppointmentDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
