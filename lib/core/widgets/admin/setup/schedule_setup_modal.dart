import 'package:flutter/material.dart';
import '../../../models/clinic/clinic_model.dart';
import '../../../services/admin/schedule_setup_guard.dart';
import '../../../utils/app_colors.dart';
import '../clinic_schedule/schedule_settings_modal_new.dart';

class ScheduleSetupModal extends StatefulWidget {
  final Clinic clinic;
  final VoidCallback? onCompleted;

  const ScheduleSetupModal({
    Key? key,
    required this.clinic,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<ScheduleSetupModal> createState() => _ScheduleSetupModalState();
}

class _ScheduleSetupModalState extends State<ScheduleSetupModal> {
  bool _isLoading = false;
  bool _setupStarted = false;

  @override
  void initState() {
    super.initState();
    // Mark setup as in progress when modal opens
    _markSetupInProgress();
  }

  Future<void> _markSetupInProgress() async {
    await ScheduleSetupGuard.markScheduleSetupInProgress(widget.clinic.id);
  }

  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);

    try {
      final success = await ScheduleSetupGuard.completeScheduleSetup(widget.clinic.id);
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Clinic schedule setup completed! Your clinic is now visible to users.'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );

        // Close modal and refresh parent
        Navigator.of(context).pop();
        if (widget.onCompleted != null) {
          widget.onCompleted!();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete setup. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openScheduleSettings() {
    setState(() => _setupStarted = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScheduleSettingsModal(
        clinicId: widget.clinic.id,
        onSave: (scheduleData) {
          // Schedule settings saved, now complete the setup
          Navigator.of(context).pop(); // Close the schedule settings modal
          _completeSetup();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Your Clinic Setup',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.clinic.clinicName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.celebration, color: AppColors.info, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Congratulations! Your clinic has been approved.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Complete the final step to make your clinic visible to pet owners and start accepting appointments.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Setup steps
                    const Text(
                      'Setup Steps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 1 - Completed
                    _buildSetupStep(
                      stepNumber: 1,
                      title: 'Clinic Information',
                      description: 'Basic clinic details and verification',
                      isCompleted: true,
                      isActive: false,
                    ),
                    const SizedBox(height: 12),

                    // Step 2 - Completed
                    _buildSetupStep(
                      stepNumber: 2,
                      title: 'Application Review',
                      description: 'Super admin verification and approval',
                      isCompleted: true,
                      isActive: false,
                    ),
                    const SizedBox(height: 12),

                    // Step 3 - Current
                    _buildSetupStep(
                      stepNumber: 3,
                      title: 'Schedule Configuration',
                      description: 'Set your clinic hours and appointment availability',
                      isCompleted: false,
                      isActive: true,
                    ),

                    const SizedBox(height: 32),

                    // Benefits section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.05),
                        border: Border.all(color: AppColors.success.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'What happens after setup:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBenefitItem(Icons.visibility, 'Your clinic becomes visible to pet owners'),
                          const SizedBox(height: 8),
                          _buildBenefitItem(Icons.calendar_today, 'Users can book appointments with you'),
                          const SizedBox(height: 8),
                          _buildBenefitItem(Icons.notifications, 'Start receiving booking notifications'),
                          const SizedBox(height: 8),
                          _buildBenefitItem(Icons.trending_up, 'Begin growing your practice'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading || _setupStarted ? null : () {
                      // Ask for confirmation before closing
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Skip Setup?'),
                          content: const Text('You can complete the schedule setup later, but your clinic won\'t be visible to users until then.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Close modal
                              },
                              child: const Text('Skip for Now'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Skip for Now'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading || _setupStarted ? null : _openScheduleSettings,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.schedule, size: 20),
                    label: Text(_setupStarted ? 'Setting up...' : 'Set Up Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  Widget _buildSetupStep({
    required int stepNumber,
    required String title,
    required String description,
    required bool isCompleted,
    required bool isActive,
  }) {
    return Row(
      children: [
        // Step circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? AppColors.success 
                : isActive 
                    ? AppColors.primary 
                    : AppColors.border,
            border: Border.all(
              color: isCompleted 
                  ? AppColors.success 
                  : isActive 
                      ? AppColors.primary 
                      : AppColors.border,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color: isCompleted || isActive ? Colors.white : AppColors.textSecondary,
            size: isCompleted ? 24 : 8,
          ),
        ),
        const SizedBox(width: 16),
        
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isActive 
                      ? AppColors.textPrimary 
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.success, size: 16),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}