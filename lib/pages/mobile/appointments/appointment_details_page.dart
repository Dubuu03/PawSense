import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';
import 'package:pawsense/core/services/user/pet_service.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

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
      padding: kMobileMarginContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header Card
          _buildStatusHeader(appointment),
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Appointment Info Card
          _buildAppointmentInfoCard(appointment),
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Pet Info Card
          if (_pet != null) ...[
            _buildPetInfoCard(_pet!),
            const SizedBox(height: kMobileSizedBoxLarge),
          ],
          
          // Clinic Info Card
          if (_clinic != null) ...[
            _buildClinicInfoCard(_clinic!),
            const SizedBox(height: kMobileSizedBoxLarge),
          ],
          
          // Service Details Card
          _buildServiceDetailsCard(appointment),
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Notes Card (if any)
          if (appointment.notes.isNotEmpty) ...[
            _buildNotesCard(appointment),
            const SizedBox(height: kMobileSizedBoxLarge),
          ],
          
          // Action Buttons
          _buildActionButtons(appointment),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(AppointmentBooking appointment) {
    final status = appointment.status;
    Color statusColor;
    Color backgroundColor;
    IconData statusIcon;
    
    switch (status) {
      case AppointmentStatus.pending:
        statusColor = AppColors.warning;
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        statusIcon = Icons.schedule;
        break;
      case AppointmentStatus.confirmed:
        statusColor = AppColors.success;
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        statusIcon = Icons.check_circle;
        break;
      case AppointmentStatus.completed:
        statusColor = AppColors.info;
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        statusIcon = Icons.task_alt;
        break;
      case AppointmentStatus.cancelled:
        statusColor = AppColors.error;
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.textSecondary;
        backgroundColor = AppColors.textSecondary.withValues(alpha: 0.1);
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      width: double.infinity,
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: kMobileBorderRadiusCardPreset,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${status.name.toUpperCase()}',
                  style: kMobileTextStyleTitle.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusDescription(status),
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: statusColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentInfoCard(AppointmentBooking appointment) {
    return Container(
      width: double.infinity,
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
            'Appointment Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Time',
            value: appointment.appointmentTime,
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          
          _buildInfoRow(
            icon: Icons.schedule,
            label: 'Created',
            value: _formatDateTime(appointment.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoCard(Pet pet) {
    return Container(
      width: double.infinity,
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
            'Pet Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          Row(
            children: [
              // Pet avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          pet.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.pets,
                              color: AppColors.primary,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.pets,
                        color: AppColors.primary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.petName,
                      style: kMobileTextStyleTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${pet.petType} • ${pet.breed}',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${pet.age} years old',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInfoCard(Map<String, dynamic> clinic) {
    return Container(
      width: double.infinity,
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
            'Clinic Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          _buildInfoRow(
            icon: Icons.local_hospital,
            label: 'Name',
            value: clinic['name'] ?? 'Unknown Clinic',
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          
          if (clinic['address'] != null) ...[
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Address',
              value: clinic['address'],
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
          ],
          
          if (clinic['phone'] != null) ...[
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: clinic['phone'],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard(AppointmentBooking appointment) {
    return Container(
      width: double.infinity,
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
            'Service Details',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          
          _buildInfoRow(
            icon: Icons.medical_services,
            label: 'Service',
            value: appointment.serviceName,
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          
          if (appointment.duration != null) ...[
            _buildInfoRow(
              icon: Icons.timer,
              label: 'Duration',
              value: appointment.duration!,
            ),
            const SizedBox(height: kMobileSizedBoxSmall),
          ],
          
          if (appointment.estimatedPrice != null) ...[
            _buildInfoRow(
              icon: Icons.attach_money,
              label: 'Estimated Price',
              value: '\$${appointment.estimatedPrice!.toStringAsFixed(2)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard(AppointmentBooking appointment) {
    return Container(
      width: double.infinity,
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
            'Additional Notes',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            appointment.notes,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppointmentBooking appointment) {
    return Column(
      children: [
        // Cancel button (only for pending/confirmed appointments)
        if (appointment.status == AppointmentStatus.pending ||
            appointment.status == AppointmentStatus.confirmed) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(appointment),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
        ],
        
        // Back to appointments button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home?tab=history'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Appointments'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: kMobileTextStyleSubtitle.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusDescription(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Your appointment is being reviewed';
      case AppointmentStatus.confirmed:
        return 'Your appointment is confirmed';
      case AppointmentStatus.completed:
        return 'This appointment has been completed';
      case AppointmentStatus.cancelled:
        return 'This appointment was cancelled';
      default:
        return 'Status unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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