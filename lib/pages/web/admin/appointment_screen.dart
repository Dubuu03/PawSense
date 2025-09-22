// screens/appointment_management_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/models/clinic/appointment_models.dart' as AppointmentModels;
import '../../../core/services/clinic/appointment_service.dart';
import '../../../core/widgets/admin/appointments/appointment_header.dart';
import '../../../core/widgets/admin/appointments/appointment_filters.dart';
import '../../../core/widgets/admin/appointments/appointment_table.dart';
import '../../../core/widgets/admin/appointments/appointment_summary.dart';
import '../../../core/widgets/admin/appointments/appointment_edit_modal.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> {
  String searchQuery = '';
  String selectedStatus = 'All Status';
  List<AppointmentModels.Appointment> appointments = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      // First, find the clinic document for this user
      print('👤 DEBUG: Current admin user UID: ${user.uid}');
      
      final clinicQuery = await FirebaseFirestore.instance
          .collection('clinics')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      print('🏥 DEBUG: Found ${clinicQuery.docs.length} approved clinics for user ${user.uid}');

      if (clinicQuery.docs.isEmpty) {
        print('❌ DEBUG: No approved clinic found for user ${user.uid}');
        // Let's also check if there are any clinics for this user regardless of status
        final anyClinicQuery = await FirebaseFirestore.instance
            .collection('clinics')
            .where('userId', isEqualTo: user.uid)
            .get();
        print('🔍 DEBUG: Found ${anyClinicQuery.docs.length} clinics (any status) for user ${user.uid}');
        for (var doc in anyClinicQuery.docs) {
          print('   - Clinic ${doc.id}: status = ${doc.data()['status']}');
        }
        
        setState(() {
          error = 'No approved clinic found for this user';
          isLoading = false;
        });
        return;
      }

      final clinicId = clinicQuery.docs.first.id;
      final clinicData = clinicQuery.docs.first.data();
      print('🎯 DEBUG: Using clinic ID: $clinicId');
      print('🏥 DEBUG: Clinic name: ${clinicData['clinicName']}');
      print('📧 DEBUG: Clinic status: ${clinicData['status']}');

      // Load appointments for this clinic using the clinic document ID
      final loadedAppointments = await AppointmentService.getClinicAppointments(
        clinicId,
        // Temporarily remove date filters for debugging
        // startDate: DateTime.now().subtract(const Duration(days: 30)), // Last 30 days
        // endDate: DateTime.now().add(const Duration(days: 30)), // Next 30 days
      );

      setState(() {
        appointments = loadedAppointments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load appointments: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshAppointments() async {
    await _loadAppointments();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const AppointmentHeader(),
              const SizedBox(height: 24),

              // Loading state
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Loading appointments...', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              // Error state
              else if (error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(error!, style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshAppointments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // Content
              else ...[
                // Summary
                AppointmentSummary(appointments: appointments),
                const SizedBox(height: 24),

                // Filters
                AppointmentFilters(
                  searchQuery: searchQuery,
                  selectedStatus: selectedStatus,
                  onSearchChanged: (query) => setState(() => searchQuery = query),
                  onStatusChanged: (status) => setState(() => selectedStatus = status),
                ),

                const SizedBox(height: 16),

                // Table
                Builder(
                  builder: (context) {
                    // Filter appointments for the table
                    List<AppointmentModels.Appointment> filteredAppointments = appointments.where((appointment) {
                      // Status filter
                      bool statusMatch = selectedStatus == 'All Status' ||
                          appointment.status.name.toLowerCase() == selectedStatus.toLowerCase();
                      
                      // Search filter
                      bool searchMatch = searchQuery.isEmpty ||
                          appointment.pet.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          appointment.owner.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                          appointment.diseaseReason.toLowerCase().contains(searchQuery.toLowerCase());
                      
                      return statusMatch && searchMatch;
                    }).toList();

                    if (filteredAppointments.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.calendar_today, size: 48, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'No appointments found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or create a new appointment',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return AppointmentTable(
                      appointments: filteredAppointments,
                      onAccept: (appointment) async {
                        final result = await AppointmentService.acceptAppointment(appointment.id);
                        
                        if (result['success']) {
                          _refreshAppointments();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Accepted appointment for ${appointment.pet.name}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4), // Longer duration for error messages
                            ),
                          );
                        }
                      },
                      onMarkDone: (appointment) async {
                        final success = await AppointmentService.markAppointmentCompleted(appointment.id);
                        
                        if (success) {
                          _refreshAppointments();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Marked ${appointment.pet.name}\'s appointment as completed')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to mark appointment as completed')),
                          );
                        }
                      },
                      onReject: (appointment) async {
                        final TextEditingController reasonController = TextEditingController();
                        
                        final reason = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reject Appointment'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rejecting appointment for ${appointment.pet.name}'),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: reasonController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reason for rejection',
                                    hintText: 'Please provide a reason for rejecting this appointment',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (reasonController.text.trim().isNotEmpty) {
                                    Navigator.of(context).pop(reasonController.text.trim());
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                child: const Text('Reject', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (reason != null && reason.isNotEmpty) {
                          final success = await AppointmentService.rejectAppointment(appointment.id, reason);
                          
                          if (success) {
                            _refreshAppointments();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Rejected appointment for ${appointment.pet.name}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to reject appointment')),
                            );
                          }
                        }
                      },
                      onEdit: (appointment) {
                        showDialog(
                          context: context,
                          builder: (context) => AppointmentEditModal(
                            appointment: appointment,
                            onUpdate: _refreshAppointments,
                          ),
                        );
                      },
                      onDelete: (appointment) async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Appointment'),
                            content: Text('Are you sure you want to delete the appointment for ${appointment.pet.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                child: const Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          // Update status to cancelled instead of deleting
                          final success = await AppointmentService.updateAppointmentStatus(
                            appointment.id,
                            AppointmentModels.AppointmentStatus.cancelled,
                          );
                          
                          if (success) {
                            _refreshAppointments();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cancelled appointment for ${appointment.pet.name}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to cancel appointment')),
                            );
                          }
                        }
                      },
                      onView: (appointment) {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Container(
                              width: 500,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Pet profile picture or emoji fallback
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.border, width: 2),
                                        ),
                                        child: appointment.pet.imageUrl != null && appointment.pet.imageUrl!.isNotEmpty
                                            ? ClipOval(
                                                child: Image.network(
                                                  appointment.pet.imageUrl!,
                                                  width: 64,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Center(
                                                      child: Text(
                                                        appointment.pet.emoji,
                                                        style: const TextStyle(fontSize: 32),
                                                      ),
                                                    );
                                                  },
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return const Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  appointment.pet.emoji,
                                                  style: const TextStyle(fontSize: 32),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              appointment.pet.name,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${appointment.pet.type} • ${appointment.pet.breed}',
                                              style: const TextStyle(color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildDetailRow('Date', appointment.date),
                                  _buildDetailRow('Time', appointment.timeSlot),
                                  _buildDetailRow('Reason', appointment.diseaseReason),
                                  _buildDetailRow('Owner', appointment.owner.name),
                                  _buildDetailRow('Phone', appointment.owner.phone),
                                  if (appointment.owner.email != null)
                                    _buildDetailRow('Email', appointment.owner.email!),
                                  _buildDetailRow('Status', appointment.status.name.toUpperCase()),
                                  if (appointment.status == AppointmentModels.AppointmentStatus.cancelled) ...[
                                    if (appointment.cancelReason != null)
                                      _buildDetailRow('Cancel Reason', appointment.cancelReason!),
                                    if (appointment.cancelledAt != null)
                                      _buildDetailRow('Cancelled At', 
                                        '${appointment.cancelledAt!.day}/${appointment.cancelledAt!.month}/${appointment.cancelledAt!.year} ${appointment.cancelledAt!.hour}:${appointment.cancelledAt!.minute.toString().padLeft(2, '0')}'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}