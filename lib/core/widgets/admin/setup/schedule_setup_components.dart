import 'package:flutter/material.dart';
import '../../../models/clinic/clinic_model.dart';
import '../../../services/admin/schedule_setup_guard.dart';
import '../../../utils/app_colors.dart';
import '../setup/schedule_setup_modal.dart';

class ScheduleSetupBanner extends StatefulWidget {
  final Clinic clinic;
  final VoidCallback? onSetupCompleted;

  const ScheduleSetupBanner({
    Key? key,
    required this.clinic,
    this.onSetupCompleted,
  }) : super(key: key);

  @override
  State<ScheduleSetupBanner> createState() => _ScheduleSetupBannerState();
}

class _ScheduleSetupBannerState extends State<ScheduleSetupBanner> {
  bool _showBanner = false;
  ScheduleSetupStatus? _setupStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    try {
      final status = await ScheduleSetupGuard.checkScheduleSetupStatus(widget.clinic.id);
      if (mounted) {
        setState(() {
          _setupStatus = status;
          _showBanner = status.needsSetup || status.inProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showBanner = false;
        });
      }
    }
  }

  void _openSetupModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScheduleSetupModal(
        clinic: widget.clinic,
        onCompleted: () {
          // Refresh status after setup completion
          _checkSetupStatus();
          if (widget.onSetupCompleted != null) {
            widget.onSetupCompleted!();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_showBanner || _setupStatus == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _setupStatus!.inProgress
              ? [AppColors.warning.withOpacity(0.1), AppColors.warning.withOpacity(0.05)]
              : [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _setupStatus!.inProgress
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _setupStatus!.inProgress
                  ? AppColors.warning.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              _setupStatus!.inProgress ? Icons.schedule : Icons.settings,
              color: _setupStatus!.inProgress ? AppColors.warning : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _setupStatus!.inProgress
                      ? 'Complete Your Schedule Setup'
                      : 'Schedule Setup Required',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _setupStatus!.inProgress
                      ? 'You started setting up your clinic schedule. Complete it to become visible to users.'
                      : 'Your clinic has been approved! Set up your schedule to start accepting appointments.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Action Button
          ElevatedButton.icon(
            onPressed: _openSetupModal,
            icon: Icon(
              _setupStatus!.inProgress ? Icons.play_arrow : Icons.schedule,
              size: 18,
            ),
            label: Text(
              _setupStatus!.inProgress ? 'Continue Setup' : 'Set Up Now',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _setupStatus!.inProgress ? AppColors.warning : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleSetupCheckWidget extends StatelessWidget {
  final Clinic clinic;
  final Widget child;
  final VoidCallback? onSetupCompleted;

  const ScheduleSetupCheckWidget({
    Key? key,
    required this.clinic,
    required this.child,
    this.onSetupCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show banner if setup is needed
        ScheduleSetupBanner(
          clinic: clinic,
          onSetupCompleted: onSetupCompleted,
        ),
        // Show the main content
        Expanded(child: child),
      ],
    );
  }
}

class ScheduleSetupPrompt extends StatelessWidget {
  final Clinic clinic;
  final VoidCallback? onSetupStarted;

  const ScheduleSetupPrompt({
    Key? key,
    required this.clinic,
    this.onSetupStarted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.schedule,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Welcome to PawSense!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Your clinic has been approved. Complete the setup to start accepting appointments from pet owners.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Setup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (onSetupStarted != null) {
                    onSetupStarted!();
                  }
                  
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => ScheduleSetupModal(
                      clinic: clinic,
                      onCompleted: () {
                        // Refresh parent or navigate
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.schedule, size: 20),
                label: const Text('Complete Setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Skip option
            TextButton(
              onPressed: () {
                // Allow skip but show warning
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Skip Setup?'),
                    content: const Text(
                      'You can skip the setup for now, but your clinic won\'t be visible to users until you complete it. You can always complete the setup later from your dashboard.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          // Navigate or handle skip
                        },
                        child: const Text('Skip for Now'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Skip for Now'),
            ),
          ],
        ),
      ),
    );
  }
}