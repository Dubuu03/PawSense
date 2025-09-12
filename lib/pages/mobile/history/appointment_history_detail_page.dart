import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/home/appointment_history_list.dart';

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
  AppointmentHistoryData? _appointmentData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  Future<void> _loadAppointmentData() async {
    setState(() {
      _loading = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock data based on ID - in real app, fetch from API/database
    final mockData = _getMockAppointmentData(widget.appointmentId);

    setState(() {
      _appointmentData = mockData;
      _loading = false;
    });
  }

  AppointmentHistoryData? _getMockAppointmentData(String id) {
    // Mock data - replace with actual API call
    final mockDataMap = {
      '1': AppointmentHistoryData(
        id: '1',
        title: 'Routine Checkup',
        subtitle: 'Dr. Sarah Johnson - Scheduled for tomorrow',
        status: AppointmentStatus.confirmed,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        clinicName: 'PawCare Veterinary Clinic',
      ),
      '2': AppointmentHistoryData(
        id: '2',
        title: 'Skin Treatment Follow-up',
        subtitle: 'Dr. Michael Lee - Reschedule requested',
        status: AppointmentStatus.pending,
        timestamp: DateTime.now().add(const Duration(days: 3)),
        clinicName: 'VetCare Animal Hospital',
      ),
      '3': AppointmentHistoryData(
        id: '3',
        title: 'Emergency Visit',
        subtitle: 'Dr. Emily Chen - Completed last week',
        status: AppointmentStatus.completed,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        clinicName: 'City Pet Emergency Clinic',
      ),
      '4': AppointmentHistoryData(
        id: '4',
        title: 'Vaccination Appointment',
        subtitle: 'Dr. Robert Kim - Cancelled due to availability',
        status: AppointmentStatus.cancelled,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        clinicName: 'Happy Paws Veterinary Center',
      ),
    };

    return mockDataMap[id];
  }

  Color _getStatusColor() {
    if (_appointmentData == null) return AppColors.primary;
    
    switch (_appointmentData!.status) {
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.completed:
        return AppColors.info;
      case AppointmentStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon() {
    if (_appointmentData == null) return Icons.event;
    
    switch (_appointmentData!.status) {
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusLabel() {
    if (_appointmentData == null) return '';
    
    switch (_appointmentData!.status) {
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getStatusDescription() {
    if (_appointmentData == null) return '';
    
    switch (_appointmentData!.status) {
      case AppointmentStatus.confirmed:
        return 'Your appointment has been confirmed. Please arrive 15 minutes early for check-in.';
      case AppointmentStatus.pending:
        return 'Your appointment is pending confirmation. The clinic will contact you soon with details.';
      case AppointmentStatus.completed:
        return 'This appointment has been completed. You can view any follow-up recommendations below.';
      case AppointmentStatus.cancelled:
        return 'This appointment was cancelled. You can reschedule or book a new appointment if needed.';
    }
  }

  List<String> _getAvailableActions() {
    if (_appointmentData == null) return [];
    
    switch (_appointmentData!.status) {
      case AppointmentStatus.confirmed:
        return ['Reschedule', 'Cancel', 'Get Directions'];
      case AppointmentStatus.pending:
        return ['Cancel Request', 'Contact Clinic'];
      case AppointmentStatus.completed:
        return ['Book Follow-up', 'View Records', 'Leave Review'];
      case AppointmentStatus.cancelled:
        return ['Reschedule', 'Book New Appointment'];
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
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/home?tab=history'),
        ),
        title: Text(
          'Appointment Details',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: _loading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildContent() {
    if (_appointmentData == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppointmentHeader(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildStatusSection(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildClinicInformation(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildAppointmentDetails(),
          const SizedBox(height: kMobileSizedBoxLarge),
          _buildActionsSection(),
        ],
      ),
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
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Appointment Not Found',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            'The requested appointment could not be loaded.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentHeader() {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimestamp(_appointmentData!.timestamp),
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            _appointmentData!.title,
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxSmall),
          Text(
            _appointmentData!.subtitle,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            _getStatusDescription(),
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInformation() {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinic Information',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildInfoRow(Icons.local_hospital, 'Clinic', _appointmentData!.clinicName ?? 'Not specified'),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildInfoRow(Icons.location_on, 'Address', '123 Pet Care Street, City, State 12345'),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildInfoRow(Icons.phone, 'Phone', '+1 (555) 123-4567'),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildInfoRow(Icons.access_time, 'Hours', 'Mon-Fri: 8AM-6PM, Sat: 9AM-4PM'),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    return Container(
      padding: const EdgeInsets.all(kMobilePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildInfoRow(Icons.pets, 'Pet', 'Max - German Shepherd'),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(_appointmentData!.timestamp)),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildInfoRow(Icons.schedule, 'Time', _formatTime(_appointmentData!.timestamp)),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildInfoRow(Icons.notes, 'Reason', _appointmentData!.title),
          if (_appointmentData!.status == AppointmentStatus.completed) ...[
            const SizedBox(height: kMobileSizedBoxSmall),
            _buildInfoRow(Icons.assignment, 'Notes', 'Pet responded well to treatment. Follow-up recommended in 2 weeks.'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: kMobileSizedBoxMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    final actions = _getAvailableActions();
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Actions',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: kMobileSizedBoxMedium),
        ...actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final isLastItem = index == actions.length - 1;
          
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: index == 0 
                    ? ElevatedButton(
                        onPressed: () => _handleAction(action),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
                          ),
                        ),
                        child: Text(
                          action,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => _handleAction(action),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
                          ),
                        ),
                        child: Text(
                          action,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              if (!isLastItem) const SizedBox(height: kMobileSizedBoxMedium),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _handleAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action functionality coming soon')),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = timestamp.difference(now);

    if (difference.isNegative) {
      final pastDifference = now.difference(timestamp);
      if (pastDifference.inDays > 0) {
        return '${pastDifference.inDays} day${pastDifference.inDays == 1 ? '' : 's'} ago';
      } else if (pastDifference.inHours > 0) {
        return '${pastDifference.inHours} hour${pastDifference.inHours == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } else {
      if (difference.inDays > 0) {
        return 'In ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
      } else if (difference.inHours > 0) {
        return 'In ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
      } else {
        return 'Soon';
      }
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
