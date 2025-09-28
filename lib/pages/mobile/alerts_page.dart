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
import 'package:pawsense/core/services/notifications/notification_service.dart';
import 'package:pawsense/core/services/notifications/demo_notification_service.dart';
import 'package:pawsense/core/utils/notification_helper.dart';

// GlobalKey for accessing AlertsPage methods
final GlobalKey<_AlertsPageState> alertsPageKey = GlobalKey<_AlertsPageState>();

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  UserModel? _userModel;
  bool _loading = true;
  int _currentNavIndex = 2; // Set to 2 for alerts tab
  Stream<List<AlertData>>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    // Stream will be automatically disposed when widget is disposed
    super.dispose();
  }

  Future<void> _fetchUser() async {
    try {
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null && mounted) {
        setState(() {
          _userModel = userModel;
          _notificationsStream = _getNotificationsStream();
        });
      }
    } catch (e) {
      // Handle error silently
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Stream of notifications from Firebase
  Stream<List<AlertData>> _getNotificationsStream() async* {
    if (_userModel == null) {
      yield [];
      return;
    }

    try {
      await for (final notifications in NotificationService.getAllUserNotifications(_userModel!.uid)) {
        if (!mounted) return; // Stop if widget is disposed
        
        final alertData = notifications
            .map((notification) => NotificationHelper.fromNotificationModel(notification))
            .toList();
        
        // Update loading state
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        
        yield alertData;
      }
    } catch (e) {
      print('Error getting all user notifications: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      yield [];
    }
  }

  void _handleAlertTap(AlertData alert) async {
    try {
      // Navigate to alert details page
      context.push('/alerts/details/${alert.id}');
    } catch (e) {
      print('Error handling alert tap: $e');
      _showErrorMessage('Failed to open notification details');
    }
  }

  Future<void> _handleMarkAsRead(AlertData alert) async {
    if (!mounted) return;
    
    try {
      await NotificationService.markAsRead(alert.id);
      
      // Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked "${alert.title}" as read'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error marking alert as read: $e');
      _showErrorMessage('Failed to mark notification as read');
    }
  }

  Future<void> _handleRefresh() async {
    // Firebase streams handle real-time updates automatically
    // Just show a brief loading indicator
    setState(() {
      _loading = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
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
      body: _userModel == null 
          ? _buildLoadingState()
          : _buildNotificationsContent(),
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

  Widget _buildNotificationsContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      child: StreamBuilder<List<AlertData>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _loading) {
            return _buildLoadingState();
          }
          
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          
          final alerts = snapshot.data ?? [];
          
          if (alerts.isEmpty) {
            return _buildEmptyState();
          }
          
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Demo button (for testing purposes - remove in production)
                if (alerts.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_userModel != null) {
                          await DemoNotificationService.createAllSampleNotifications(_userModel!.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sample notifications created!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Generate Sample Notifications (Demo)'),
                    ),
                  ),
                
                // Notifications list
                AlertList(
                  alerts: alerts,
                  onAlertTap: _handleAlertTap,
                  onMarkAsRead: _handleMarkAsRead,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loading = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All caught up! You\'ll see new notifications here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
