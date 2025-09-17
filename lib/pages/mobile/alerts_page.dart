import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_bottom_nav_bar.dart';
import 'package:pawsense/core/widgets/user/shared/modals/pet_assessment_modal.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_list.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  UserModel? _userModel;
  List<AlertData> _alerts = [];
  bool _loading = true;
  int _currentNavIndex = 2; // Set to 2 for alerts tab

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _loadAlerts();
  }

  Future<void> _fetchUser() async {
    try {
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null) {
        setState(() {
          _userModel = userModel;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Sample alert data - based on the image provided
    final sampleAlerts = [
      AlertData(
        title: 'Appointment Approved',
        subtitle: 'Tomorrow at 11:00 AM',
        type: AlertType.appointment,
        timestamp: DateTime.now(),
        isRead: false,
      ),
      AlertData(
        title: 'Reschedule',
        subtitle: 'Dr. Lee requested a new time',
        type: AlertType.reschedule,
        timestamp: DateTime.now(),
        isRead: false,
      ),
      AlertData(
        title: 'Appointment Declined',
        subtitle: 'Clinic fully booked',
        type: AlertType.declined,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: false,
      ),
      AlertData(
        title: 'Reappointment Needed',
        subtitle: 'Follow-up recommended',
        type: AlertType.reappointment,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isRead: false,
      ),
      AlertData(
        title: 'System Update',
        subtitle: 'Improved accuracy for dog dermatitis',
        type: AlertType.systemUpdate,
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        isRead: true,
      ),
    ];

    setState(() {
      _alerts = sampleAlerts;
      _loading = false;
    });
  }

  void _handleAlertTap(AlertData alert) {
    // Handle alert tap - navigate to relevant page or show details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${alert.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMarkAsRead(AlertData alert) {
    setState(() {
      final index = _alerts.indexOf(alert);
      if (index != -1) {
        _alerts[index] = AlertData(
          title: alert.title,
          subtitle: alert.subtitle,
          type: alert.type,
          timestamp: alert.timestamp,
          isRead: true,
        );
      }
    });
  }

  Future<void> _handleRefresh() async {
    await _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UserAppBar(
        user: _userModel,
        onUserUpdated: (updatedUser) {
          setState(() {
            _userModel = updatedUser;
          });
        },
      ),
      body: _loading 
          ? _buildLoadingState()
          : _buildAlertsContent(),
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) {
          if (index == 0) {
            // Navigate to home
            context.go('/home');
          } else if (index == 2) {
            // Already on alerts page, do nothing
          } else {
            setState(() {
              _currentNavIndex = index;
            });
          }
        },
        onCameraPressed: _showCameraDialog,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildAlertsContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: AlertList(
          alerts: _alerts,
          onAlertTap: _handleAlertTap,
          onMarkAsRead: _handleMarkAsRead,
        ),
      ),
    );
  }

  void _showCameraDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PetAssessmentModal(),
    );
  }
}
