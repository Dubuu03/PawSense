import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_bottom_nav_bar.dart';
import 'package:pawsense/core/widgets/user/shared/modals/pet_assessment_modal.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/core/widgets/user/alerts/optimized_alert_list.dart';
import 'package:pawsense/core/services/notifications/notification_service.dart';
import 'package:pawsense/core/services/notifications/paginated_notification_service.dart';
import 'package:pawsense/core/services/notifications/demo_notification_service.dart';
import 'package:pawsense/core/widgets/shared/ui/scroll_to_top_fab.dart';


// GlobalKey for accessing AlertsPage methods
final GlobalKey<_AlertsPageState> alertsPageKey = GlobalKey<_AlertsPageState>();

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with WidgetsBindingObserver {
  UserModel? _userModel;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _currentNavIndex = 2; // Set to 2 for alerts tab
  List<AlertData> _notifications = [];
  late ScrollController _scrollController;
  
  // Local state for instant updates
  final Set<String> _locallyReadNotifications = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      // Debug scroll position
      if (_scrollController.hasClients) {
        final offset = _scrollController.offset;
        if (offset > 200 && offset < 220) {
          print('📊 Scroll position: $offset px - FAB should appear');
        }
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _fetchUser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted && _userModel != null) {
      // Refresh notifications when app is resumed
      print('🔄 App resumed, refreshing notifications...');
      _refreshNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    // Clear local state to prevent memory leaks
    _locallyReadNotifications.clear();
    // Stream will be automatically disposed when widget is disposed
    super.dispose();
  }

  Future<void> _fetchUser() async {
    try {
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null && mounted) {
        setState(() {
          _userModel = userModel;
        });
        
        // Load initial notifications
        await _loadInitialNotifications();
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

  /// Load initial notifications with cache-first strategy
  Future<void> _loadInitialNotifications() async {
    if (_userModel == null) return;
    
    try {
      setState(() {
        _loading = true;
      });
      
      print('📥 Loading notifications for user: ${_userModel!.uid}');
      final result = await PaginatedNotificationService.getNotificationsWithCache(_userModel!.uid);
      print('📥 Loaded ${result.notifications.length} notifications');
      
      if (mounted) {
        setState(() {
          _notifications = result.notifications;
          _hasMore = result.hasMore;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading initial notifications: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// Refresh notifications (pull-to-refresh)
  Future<void> _refreshNotifications() async {
    if (_userModel == null) return;
    
    try {
      final result = await PaginatedNotificationService.refreshNotifications(_userModel!.uid);
      
      if (mounted) {
        setState(() {
          _notifications = result.notifications;
          _hasMore = result.hasMore;
          _locallyReadNotifications.clear(); // Clear local cache
        });
      }
    } catch (e) {
      print('Error refreshing notifications: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh notifications'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Load more notifications for infinite scroll
  Future<void> _loadMoreNotifications() async {
    if (_userModel == null || _loadingMore || !_hasMore) return;
    
    try {
      setState(() {
        _loadingMore = true;
      });
      
      final result = await PaginatedNotificationService.loadMoreNotifications(_userModel!.uid);
      
      if (mounted) {
        setState(() {
          _notifications.addAll(result.notifications);
          _hasMore = result.hasMore;
          _loadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more notifications: $e');
      if (mounted) {
        setState(() {
          _loadingMore = false;
        });
      }
    }
  }



  void _handleAlertTap(AlertData alert) async {
    try {
      // Optimistically mark as read using the new service
      if (!alert.isRead && _userModel != null) {
        await PaginatedNotificationService.markAsReadOptimistic(alert.id, _userModel!.uid);
        
        // Update local UI immediately
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == alert.id);
          if (index != -1) {
            _notifications[index] = AlertData(
              id: alert.id,
              title: alert.title,
              subtitle: alert.subtitle,
              type: alert.type,
              timestamp: alert.timestamp,
              isRead: true, // Mark as read optimistically
              actionUrl: alert.actionUrl,
              actionLabel: alert.actionLabel,
              metadata: alert.metadata,
            );
          }
        });
      }
      
      // Check if this is an appointment-related notification
      if (_isAppointmentNotification(alert)) {
        // Try to get appointment ID from metadata
        final appointmentId = alert.metadata?['appointmentId'] as String?;
        
        if (appointmentId != null && mounted) {
          // Navigate directly to appointment details
          context.push('/appointments/details/$appointmentId');
          return;
        }
      }
      
      // Navigate to alert details page with notification data
      context.push(
        '/alerts/details/${alert.id}',
        extra: alert, // Pass the full alert data
      );
    } catch (e) {
      print('Error handling alert tap: $e');
      _showErrorMessage('Failed to open notification details');
    }
  }

  /// Check if notification is appointment-related
  bool _isAppointmentNotification(AlertData alert) {
    return alert.type == AlertType.appointment ||
           alert.type == AlertType.appointmentPending ||
           alert.type == AlertType.reschedule ||
           alert.type == AlertType.reappointment ||
           alert.type == AlertType.followUp;
  }

  Future<void> _handleMarkAsRead(AlertData alert) async {
    if (!mounted) return;
    
    // Optimistically mark as read locally for instant UI update
    setState(() {
      _locallyReadNotifications.add(alert.id);
    });
    
    try {
      await NotificationService.markAsRead(alert.id, userId: _userModel?.uid);
      
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
      
      // Revert local state on error
      if (mounted) {
        setState(() {
          _locallyReadNotifications.remove(alert.id);
        });
      }
    }
  }

  Future<void> _handleDelete(AlertData alert) async {
    if (!mounted) return;
    
    // Show confirmation dialog for message deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Optimistically remove from UI
    setState(() {
      _notifications.removeWhere((n) => n.id == alert.id);
    });

    try {
      await NotificationService.deleteNotification(alert.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
      _showErrorMessage('Failed to delete message');
      
      // Revert by refreshing
      if (mounted) {
        await _refreshNotifications();
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    // Debug: Check FAB visibility conditions
    final shouldShowFab = _userModel != null && _notifications.isNotEmpty;
    if (!shouldShowFab) {
      if (_userModel == null) {
        print('🔍 FAB Hidden: User not logged in');
      }
      if (_notifications.isEmpty) {
        print('🔍 FAB Hidden: No notifications (${_notifications.length})');
      }
    } else {
      print('✅ FAB Rendered: User logged in, ${_notifications.length} notifications');
    }
    
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
      floatingActionButton: _userModel != null && _notifications.isNotEmpty
          ? ScrollToTopFab(
              scrollController: _scrollController,
              showThreshold: 200.0,
            )
          : null,
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
      onRefresh: _refreshNotifications,
      color: AppColors.primary,
      child: _loading && _notifications.isEmpty
          ? _buildLoadingState()
          : _notifications.isEmpty
              ? _buildEmptyStateWithDemo()
              : OptimizedAlertList(
                  alerts: _notifications,
                  scrollController: _scrollController,
                  onAlertTap: _handleAlertTap,
                  onMarkAsRead: _handleMarkAsRead,
                  onDelete: _handleDelete,
                  onLoadMore: _loadMoreNotifications,
                  hasMore: _hasMore,
                  isLoading: _loading,
                  isLoadingMore: _loadingMore,
                ),
    );
  }

  Widget _buildEmptyStateWithDemo() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 100),
          
          // Demo button (for testing purposes - remove in production)
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () async {
                if (_userModel != null) {
                  setState(() {
                    _loading = true;
                  });
                  
                  await DemoNotificationService.createAllSampleNotifications(_userModel!.uid);
                  
                  // Refresh after creating demo notifications
                  await _refreshNotifications();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sample notifications created!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Generate Sample Notifications (Demo)'),
            ),
          ),
          
          _buildEmptyState(),
        ],
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
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (context) => const PetAssessmentModal(),
    );
  }
}
