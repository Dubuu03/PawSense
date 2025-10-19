import 'package:flutter/material.dart';
import '../models/clinic/clinic_model.dart';
import '../services/admin/schedule_setup_guard.dart' as SetupService;
import '../services/auth/auth_service.dart';
import '../widgets/admin/setup/schedule_setup_components.dart';

/// Navigation guard that enforces schedule setup before accessing admin pages
/// 
/// Usage:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return ScheduleSetupNavigationGuard(
///     child: YourAdminPage(),
///   );
/// }
/// ```
class ScheduleSetupNavigationGuard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSetupCompleted;

  const ScheduleSetupNavigationGuard({
    Key? key,
    required this.child,
    this.onSetupCompleted,
  }) : super(key: key);

  @override
  State<ScheduleSetupNavigationGuard> createState() => _ScheduleSetupNavigationGuardState();
}

class _ScheduleSetupNavigationGuardState extends State<ScheduleSetupNavigationGuard> {
  Clinic? _clinic;
  SetupService.ScheduleSetupStatus? _setupStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get clinic data
      _clinic = await AuthService().getUserClinic();
      
      if (_clinic == null) {
        setState(() {
          _error = 'No clinic found for current user';
          _isLoading = false;
        });
        return;
      }

      // Check setup status
      final status = await SetupService.ScheduleSetupGuard.checkScheduleSetupStatus(_clinic!.id);
      
      if (mounted) {
        setState(() {
          _setupStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSetupCompleted() {
    // Refresh the status after setup completion
    _checkSetupStatus();
    
    // Call parent callback
    if (widget.onSetupCompleted != null) {
      widget.onSetupCompleted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading page',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkSetupStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_clinic == null || _setupStatus == null) {
      return const Scaffold(
        body: Center(
          child: Text('No clinic data available'),
        ),
      );
    }

    // If setup is needed (pending and not started), show blocking prompt
    if (_setupStatus!.needsSetup && !_setupStatus!.inProgress) {
      return Scaffold(
        body: ScheduleSetupPrompt(
          clinic: _clinic!,
          onSetupStarted: _onSetupCompleted,
        ),
      );
    }

    // If setup is in progress or completed, show the actual page with optional banner
    if (_setupStatus!.inProgress) {
      return Scaffold(
        body: Column(
          children: [
            ScheduleSetupBanner(
              clinic: _clinic!,
              onSetupCompleted: _onSetupCompleted,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Setup completed - show normal page
    return widget.child;
  }
}
