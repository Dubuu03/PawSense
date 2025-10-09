import 'package:flutter/material.dart';
import '../../../models/clinic/appointment_models.dart';
import '../../../services/clinic/appointment_service.dart';
import '../../../utils/app_colors.dart';
import 'appointment_completion_modal.dart';

class AppointmentEditModal extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onUpdate;

  const AppointmentEditModal({
    super.key,
    required this.appointment,
    required this.onUpdate,
  });

  @override
  State<AppointmentEditModal> createState() => _AppointmentEditModalState();
}

class _AppointmentEditModalState extends State<AppointmentEditModal> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Appointment',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pet and Owner Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Pet profile picture or emoji
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: widget.appointment.pet.imageUrl != null && widget.appointment.pet.imageUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              widget.appointment.pet.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    widget.appointment.pet.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              widget.appointment.pet.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appointment.pet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.appointment.owner.name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${widget.appointment.date} at ${widget.appointment.time}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current Status
            Row(
              children: [
                const Text(
                  'Current Status: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getStatusColor(widget.appointment.status)),
                  ),
                  child: Text(
                    widget.appointment.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(widget.appointment.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Text(
              'Available Actions:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            if (widget.appointment.status == AppointmentStatus.confirmed) ...[
              _buildActionButton(
                icon: Icons.task_alt,
                label: 'Mark as Completed',
                color: AppColors.success,
                onPressed: _markAsCompleted,
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.cancel,
                label: 'Reject Appointment',
                color: AppColors.error,
                onPressed: () => _showRejectDialog(),
              ),
            ] else if (widget.appointment.status == AppointmentStatus.cancelled) ...[
              _buildActionButton(
                icon: Icons.check_circle,
                label: 'Re-accept Appointment',
                color: AppColors.success,
                onPressed: () => _reAcceptAppointment(),
              ),
            ],

            const SizedBox(height: 24),
            
            // Cancel reason display for cancelled appointments
            if (widget.appointment.status == AppointmentStatus.cancelled && 
                widget.appointment.cancelReason != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cancellation Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.appointment.cancelReason!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.textSecondary;
    }
  }

  void _markAsCompleted() {
    // Close the edit modal first
    Navigator.of(context).pop();
    
    // Show the appointment completion modal
    showDialog(
      context: context,
      builder: (context) => AppointmentCompletionModal(
        appointment: widget.appointment,
        onCompleted: widget.onUpdate,
      ),
    );
  }

  Future<void> _reAcceptAppointment() async {
    setState(() => _isLoading = true);
    
    final success = await AppointmentService.reAcceptAppointment(widget.appointment.id);
    
    setState(() => _isLoading = false);
    
    if (success) {
      widget.onUpdate();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-accepted ${widget.appointment.pet.name}\'s appointment')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to re-accept appointment')),
      );
    }
  }

  Future<void> _showRejectDialog() async {
    _reasonController.clear();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting appointment for ${widget.appointment.pet.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
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
              if (_reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(_reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isLoading = true);
      
      final success = await AppointmentService.rejectAppointment(widget.appointment.id, reason);
      
      setState(() => _isLoading = false);
      
      if (success) {
        widget.onUpdate();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejected ${widget.appointment.pet.name}\'s appointment')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject appointment')),
        );
      }
    }
  }
}