import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';

class AppointmentHistoryDetailPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentHistoryDetailPage({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentHistoryDetailPage> createState() => _AppointmentHistoryDetailPageState();
}

class _AppointmentHistoryDetailPageState extends State<AppointmentHistoryDetailPage> {
  AppointmentBooking? _appointment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appointment = await AppointmentBookingService.getAppointmentById(widget.appointmentId);
      
      setState(() {
        _appointment = appointment;
        _loading = false;
      });
    } catch (e) {
      print('Error loading appointment data: $e');
      setState(() {
        _error = 'Failed to load appointment details: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home?tab=history');
            }
          },
        ),
        title: Text(
          'Appointment Details',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _appointment == null
                  ? _buildNotFoundState()
                  : _buildDetailContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Error Loading Appointment',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            _error!,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kMobilePaddingLarge),
          ElevatedButton(
            onPressed: _loadAppointmentData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Appointment Not Found',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'The appointment you\'re looking for could not be found.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    final appointment = _appointment!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: kMobileSizedBoxLarge),
          // Status Card
          _buildStatusCard(appointment),
          
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Appointment Info Card
          _buildAppointmentInfoCard(appointment),
          
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Service Info Card
          _buildServiceInfoCard(appointment),
          
          const SizedBox(height: kMobileSizedBoxLarge),
          
          // Notes Card (if available)
          if (appointment.notes.isNotEmpty)
            _buildNotesCard(appointment),
          
          if (appointment.notes.isNotEmpty)
            const SizedBox(height: kMobileSizedBoxLarge),
          
          // Cancellation/Reschedule Info (if applicable)
          if (appointment.status == AppointmentStatus.cancelled && appointment.cancelReason != null)
            _buildCancellationCard(appointment),
          
          if (appointment.status == AppointmentStatus.rescheduled && appointment.rescheduleReason != null)
            _buildRescheduleCard(appointment),
          
          if ((appointment.status == AppointmentStatus.cancelled && appointment.cancelReason != null) ||
              (appointment.status == AppointmentStatus.rescheduled && appointment.rescheduleReason != null))
            const SizedBox(height: kMobileSizedBoxLarge),
          
          // Timestamps Card
          _buildTimestampsCard(appointment),
          
          const SizedBox(height: kMobilePaddingLarge),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppointmentBooking appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              _getStatusIcon(appointment.status),
              color: _getStatusColor(appointment.status),
              size: 24,
            ),
          ),
          const SizedBox(width: kMobileSizedBoxLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(appointment.status),
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusSubtitle(appointment.status),
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
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
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildInfoRow('Date', _formatDate(appointment.appointmentDate)),
          _buildInfoRow('Time', appointment.appointmentTime),
          _buildInfoRow('Type', _formatAppointmentType(appointment.type)),
          if (appointment.duration != null)
            _buildInfoRow('Duration', appointment.duration!),
          if (appointment.estimatedPrice != null)
            _buildInfoRow('Estimated Price', '\$${appointment.estimatedPrice!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard(AppointmentBooking appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildInfoRow('Service', appointment.serviceName),
          _buildInfoRow('Service ID', appointment.serviceId),
          _buildInfoRow('Clinic ID', appointment.clinicId),
          _buildInfoRow('Pet ID', appointment.petId),
        ],
      ),
    );
  }

  Widget _buildNotesCard(AppointmentBooking appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationCard(AppointmentBooking appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cancellation Information',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          if (appointment.cancelledAt != null)
            _buildInfoRow('Cancelled On', _formatDateTime(appointment.cancelledAt!)),
          if (appointment.cancelReason != null)
            _buildInfoRow('Reason', appointment.cancelReason!),
        ],
      ),
    );
  }

  Widget _buildRescheduleCard(AppointmentBooking appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reschedule Information',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.warning,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          if (appointment.rescheduledAt != null)
            _buildInfoRow('Rescheduled On', _formatDateTime(appointment.rescheduledAt!)),
          if (appointment.rescheduleReason != null)
            _buildInfoRow('Reason', appointment.rescheduleReason!),
        ],
      ),
    );
  }

  Widget _buildTimestampsCard(AppointmentBooking appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
      padding: kMobilePaddingCard,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildInfoRow('Created', _formatDateTime(appointment.createdAt)),
          _buildInfoRow('Last Updated', _formatDateTime(appointment.updatedAt)),
          _buildInfoRow('Appointment ID', appointment.id ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.info;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.rescheduled:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.rescheduled:
        return Icons.update;
    }
  }

  String _getStatusTitle(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Pending Confirmation';
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

  String _getStatusSubtitle(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'Waiting for clinic confirmation';
      case AppointmentStatus.confirmed:
        return 'Your appointment is confirmed';
      case AppointmentStatus.completed:
        return 'Appointment has been completed';
      case AppointmentStatus.cancelled:
        return 'This appointment was cancelled';
      case AppointmentStatus.rescheduled:
        return 'This appointment was rescheduled';
    }
  }

  String _formatAppointmentType(AppointmentType type) {
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final date = '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }
}
