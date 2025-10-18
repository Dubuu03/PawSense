import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/widgets/shared/rating/rate_clinic_modal.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsPage({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  AppointmentBooking? _appointment;
  Pet? _pet;
  Map<String, dynamic>? _clinic;
  bool _loading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadAppointmentDetails() async {
    if (!_mounted) return;

    try {
      // Get appointment details
      final appointment = await _getAppointmentById(widget.appointmentId);
      
      if (!_mounted) return;
      
      if (appointment == null) {
        // Handle appointment not found
        if (_mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      // Get pet details
      final pet = await PetService.getPetById(appointment.petId);
      
      // Get clinic details
      final clinics = await ClinicListService.getAllActiveClinics();
      final clinic = clinics.firstWhere(
        (c) => c['id'] == appointment.clinicId,
        orElse: () => <String, dynamic>{},
      );

      if (_mounted) {
        setState(() {
          _appointment = appointment;
          _pet = pet;
          _clinic = clinic.isNotEmpty ? clinic : null;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading appointment details: $e');
      if (_mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<AppointmentBooking?> _getAppointmentById(String appointmentId) async {
    try {
      // Get current user
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        print('❌ User not authenticated when trying to get appointment: $appointmentId');
        return null;
      }

      final appointments = await AppointmentBookingService.getUserAppointments(
        currentUser.uid,
      );
      
      // Use try-catch with firstWhere to handle not found case gracefully
      AppointmentBooking? appointment;
      try {
        appointment = appointments.firstWhere((apt) => apt.id == appointmentId);
        print('✅ Found appointment: $appointmentId');
      } catch (e) {
        print('⚠️ Appointment not found: $appointmentId for user: ${currentUser.uid}');
        print('📋 Available appointments: ${appointments.map((a) => a.id).toList()}');
        appointment = null;
      }
      
      return appointment;
    } catch (e) {
      print('❌ Error getting appointment $appointmentId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Appointment Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _appointment == null
              ? _buildNotFoundView()
              : _buildAppointmentDetails(),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Padding(
        padding: kMobileMarginContainer,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Appointment Not Found',
              style: kMobileTextStyleTitle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
            Text(
              'This appointment may have been canceled or doesn\'t exist.',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    final appointment = _appointment!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Section (only show for non-cancelled appointments)
          if (appointment.status != AppointmentStatus.cancelled)
            _buildStatusSection(appointment),
          
          // Combined Cancellation Card (if cancelled)
          if (appointment.status == AppointmentStatus.cancelled && 
              appointment.cancelReason != null &&
              appointment.cancelReason!.isNotEmpty)
            _buildCancellationCard(appointment),
          
          const SizedBox(height: kMobileSizedBoxXLarge),
          
          // Pet Information
          if (_pet != null) ...[
            _buildPetInfoSection(_pet!),
            const SizedBox(height: kMobileSizedBoxXLarge),
          ],
          
          // Appointment Information
          _buildAppointmentInfoSection(appointment),
          
          const SizedBox(height: kMobileSizedBoxXLarge),
          
          // Clinic Information
          if (_clinic != null) ...[
            _buildClinicInfoSection(_clinic!),
            const SizedBox(height: kMobileSizedBoxXLarge),
          ],
          
          // Notes (if any)
          if (appointment.notes.isNotEmpty) ...[
            _buildNotesSection(appointment),
            const SizedBox(height: kMobileSizedBoxXLarge),
          ],
          
          // Clinic Evaluation (only for completed appointments)
          if (appointment.status == AppointmentStatus.completed) ...[
            _buildClinicEvaluationSection(appointment),
            const SizedBox(height: kMobileSizedBoxXLarge),
          ],
          
          // Rate Clinic button (only for completed appointments that haven't been rated)
          if (appointment.status == AppointmentStatus.completed && 
              appointment.hasRated != true) ...[
            _buildRateClinicButton(appointment),
            const SizedBox(height: kMobileSizedBoxXLarge),
          ],
          
          // Cancel button (only for pending/confirmed appointments)
          if (appointment.status == AppointmentStatus.pending ||
              appointment.status == AppointmentStatus.confirmed) ...[
            _buildCancelButton(appointment),
            const SizedBox(height: kMobileSizedBoxXLarge),
          ],
          
          // Additional spacing for safe area
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusSection(AppointmentBooking appointment) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(
          color: _getStatusColor(appointment.status).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(appointment.status),
              color: _getStatusColor(appointment.status),
              size: 20,
            ),
          ),
          const SizedBox(width: kMobileSizedBoxMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(appointment.status),
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(appointment.status),
                  ),
                ),
                Text(
                  _getStatusDescriptionDetailed(appointment.status),
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

  Widget _buildCancellationCard(AppointmentBooking appointment) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Cancelled Status Header
          Container(
            padding: const EdgeInsets.all(kMobilePaddingMedium),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kMobileBorderRadiusCard),
                topRight: Radius.circular(kMobileBorderRadiusCard),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 16,
                  ),
                ),
                const SizedBox(width: kMobileSizedBoxMedium),
                Text(
                  'Cancelled',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const Spacer(),
                Text(
                  'This appointment was cancelled',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Cancellation Reason Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kMobilePaddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cancellation Reason',
                      style: kMobileTextStyleTitle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kMobileSizedBoxMedium),
                Text(
                  appointment.cancelReason!,
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoSection(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pets,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Text(
                  'Pet Information',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildModalInfoRow('Pet Name', pet.petName),
          _buildModalInfoRow('Species', pet.petType),
          _buildModalInfoRow('Breed', pet.breed),
          _buildModalInfoRow('Age', pet.ageString),
          _buildModalInfoRow('Weight', '${pet.weight} kg'),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfoSection(AppointmentBooking appointment) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_note,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Text(
                  'Appointment Information',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildModalInfoRow('Service', appointment.serviceName),
          _buildModalInfoRow('Date', _formatDate(appointment.appointmentDate)),
          _buildModalInfoRow('Time', appointment.appointmentTime),
          _buildModalInfoRow('Type', _formatAppointmentType(appointment.type)),
          if (appointment.duration != null)
            _buildModalInfoRow('Duration', appointment.duration!),
          if (appointment.estimatedPrice != null)
            _buildModalInfoRow('Estimated Price', 'PHP ${appointment.estimatedPrice!.toStringAsFixed(2)}'),
          _buildModalInfoRow('Booked On', _formatDateTime(appointment.createdAt)),
        ],
      ),
    );
  }

  Widget _buildClinicInfoSection(Map<String, dynamic> clinic) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Text(
                  'Clinic Information',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildModalInfoRow('Clinic Name', clinic['name'] ?? 'Unknown Clinic'),
          if (clinic['address'] != null)
            _buildModalInfoRow('Address', clinic['address']),
          if (clinic['phone'] != null)
            _buildModalInfoRow('Phone', clinic['phone']),
          if (clinic['email'] != null)
            _buildModalInfoRow('Email', clinic['email']),
        ],
      ),
    );
  }

  Widget _buildNotesSection(AppointmentBooking appointment) {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.note_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Text(
                  'Notes',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              appointment.notes,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicEvaluationSection(AppointmentBooking appointment) {
    // Check if there's any evaluation data to display
    final hasEvaluation = (appointment.diagnosis?.isNotEmpty ?? false) ||
                         (appointment.treatment?.isNotEmpty ?? false) ||
                         (appointment.prescription?.isNotEmpty ?? false) ||
                         (appointment.clinicNotes?.isNotEmpty ?? false);

    if (!hasEvaluation) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medical_information_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: kMobileSizedBoxMedium),
              Expanded(
                child: Text(
                  'Clinic Evaluation',
                  style: kMobileTextStyleTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Diagnosis
          if (appointment.diagnosis?.isNotEmpty ?? false)
            _buildModalInfoRow('Diagnosis', appointment.diagnosis!),
          
          // Treatment
          if (appointment.treatment?.isNotEmpty ?? false)
            _buildModalInfoRow('Treatment', appointment.treatment!),
          
          // Prescription
          if (appointment.prescription?.isNotEmpty ?? false)
            _buildModalInfoRow('Prescription', appointment.prescription!),
          
          // Clinic Notes
          if (appointment.clinicNotes?.isNotEmpty ?? false)
            _buildModalInfoRow('Clinical Notes', appointment.clinicNotes!),
        ],
      ),
    );
  }

  Widget _buildCancelButton(AppointmentBooking appointment) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showCancelDialog(appointment),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
          ),
        ),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text(
          'Cancel Appointment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRateClinicButton(AppointmentBooking appointment) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showRateClinicModal(appointment),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
          ),
        ),
        icon: const Icon(Icons.star_outline),
        label: const Text(
          'Rate This Clinic',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _showRateClinicModal(AppointmentBooking appointment) async {
    // Get current user
    final currentUser = await AuthGuard.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please log in again.')),
        );
      }
      return;
    }

    // Get clinic name - fetch from Firestore if not available in state
    String clinicName = 'Unknown Clinic';
    if (_clinic != null && _clinic!['clinicName'] != null) {
      clinicName = _clinic!['clinicName'] as String;
    } else {
      try {
        // Fetch clinic name from Firestore
        final clinicDoc = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(appointment.clinicId)
            .get();
        if (clinicDoc.exists && clinicDoc.data()?['clinicName'] != null) {
          clinicName = clinicDoc.data()!['clinicName'] as String;
        }
      } catch (e) {
        print('Error fetching clinic name: $e');
      }
    }

    // Show rating modal
    final rated = await RateClinicModal.show(
      context: context,
      clinicId: appointment.clinicId,
      clinicName: clinicName,
      userId: currentUser.uid,
      appointmentId: appointment.id!,
    );

    // Refresh appointment if rating was submitted
    if (rated == true && mounted) {
      setState(() {
        _appointment = appointment.copyWith(hasRated: true);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for rating this clinic!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildModalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatAppointmentType(AppointmentType type) {
    switch (type) {
      case AppointmentType.general:
        return 'General Checkup';
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

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.completed:
        return AppColors.info;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.rescheduled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.rescheduled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusTitle(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending Approval';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  String _getStatusDescriptionDetailed(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Waiting for clinic confirmation';
      case AppointmentStatus.confirmed:
        return 'Your appointment is confirmed';
      case AppointmentStatus.completed:
        return 'This appointment has been completed';
      case AppointmentStatus.cancelled:
        return 'This appointment was cancelled';
      case AppointmentStatus.rescheduled:
        return 'This appointment was rescheduled';
    }
  }

  void _showCancelDialog(AppointmentBooking appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelAppointment(appointment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(AppointmentBooking appointment) async {
    try {
      final success = await AppointmentBookingService.cancelAppointment(
        appointment.id ?? '',
        'Cancelled by user',
      );

      if (!_mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh appointment details
        _loadAppointmentDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel appointment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!_mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}