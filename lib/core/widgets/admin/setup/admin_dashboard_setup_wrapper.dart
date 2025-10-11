import 'package:flutter/material.dart';
import '../../../models/clinic/clinic_model.dart';
import '../../../services/admin/schedule_setup_guard.dart';
import '../../../utils/app_colors.dart';
import 'schedule_setup_components.dart';

/// Wrapper widget that automatically checks clinic schedule setup status
/// and shows setup UI if needed, or the main dashboard content if setup is complete
class AdminDashboardWithSetupCheck extends StatefulWidget {
  final Widget dashboardContent;
  final Clinic? clinic;
  final VoidCallback? onSetupCompleted;

  const AdminDashboardWithSetupCheck({
    Key? key,
    required this.dashboardContent,
    this.clinic,
    this.onSetupCompleted,
  }) : super(key: key);

  @override
  State<AdminDashboardWithSetupCheck> createState() => _AdminDashboardWithSetupCheckState();
}

class _AdminDashboardWithSetupCheckState extends State<AdminDashboardWithSetupCheck> {
  ScheduleSetupStatus? _setupStatus;
  Clinic? _clinic;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  @override
  void didUpdateWidget(AdminDashboardWithSetupCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh if clinic changes
    if (oldWidget.clinic?.id != widget.clinic?.id) {
      _checkSetupStatus();
    }
  }

  Future<void> _checkSetupStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final status = await ScheduleSetupGuard.checkScheduleSetupStatus(widget.clinic?.id);
      
      if (mounted) {
        setState(() {
          _setupStatus = status;
          _clinic = status.clinic ?? widget.clinic;
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkSetupStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_setupStatus == null || _clinic == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No clinic data available',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // If setup is needed, show the setup prompt as the main content
    if (_setupStatus!.needsSetup && !_setupStatus!.inProgress) {
      return Scaffold(
        body: ScheduleSetupPrompt(
          clinic: _clinic!,
          onSetupStarted: _onSetupCompleted,
        ),
      );
    }

    // If setup is complete or in progress, show dashboard with optional banner
    return Scaffold(
      body: ScheduleSetupCheckWidget(
        clinic: _clinic!,
        onSetupCompleted: _onSetupCompleted,
        child: widget.dashboardContent,
      ),
    );
  }
}

/// Simple loading wrapper for when clinic data is being fetched
class AdminDashboardLoader extends StatelessWidget {
  final Future<Clinic?> clinicFuture;
  final Widget Function(Clinic clinic) dashboardBuilder;
  final VoidCallback? onSetupCompleted;

  const AdminDashboardLoader({
    Key? key,
    required this.clinicFuture,
    required this.dashboardBuilder,
    this.onSetupCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Clinic?>(
      future: clinicFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading clinic data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final clinic = snapshot.data;
        if (clinic == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'No clinic found',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return AdminDashboardWithSetupCheck(
          clinic: clinic,
          onSetupCompleted: onSetupCompleted,
          dashboardContent: dashboardBuilder(clinic),
        );
      },
    );
  }
}