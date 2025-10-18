import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/user/alerts/alert_item.dart';
import '../../../core/services/notifications/realtime_notification_service.dart';
import '../../../core/widgets/shared/ui/scroll_to_top_fab.dart';

/// Optimized alerts page with real-time updates
/// Uses the new RealTimeNotificationService for efficient data management
class OptimizedAlertsPage extends StatefulWidget {
  const OptimizedAlertsPage({super.key});

  @override
  State<OptimizedAlertsPage> createState() => _OptimizedAlertsPageState();
}

class _OptimizedAlertsPageState extends State<OptimizedAlertsPage> {
  final RealTimeNotificationService _notificationService = RealTimeNotificationService();
  final ScrollController _scrollController = ScrollController();
  
  StreamSubscription<List<AlertData>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  
  List<AlertData> _notifications = [];
  List<_AlertListItem> _groupedNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  /// Initialize notifications for current user
  Future<void> _initializeNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Initialize real-time service
      await _notificationService.initializeForUser(user.uid);
      
      // Subscribe to notifications stream
      _notificationsSubscription = _notificationService.notificationsStream.listen(
        (notifications) {
          if (mounted) {
            setState(() {
              _notifications = notifications;
              _groupNotifications(); // Group notifications by time periods
              _isLoading = false;
              _error = null;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = 'Failed to load notifications: $error';
              _isLoading = false;
            });
          }
        },
      );

      // Subscribe to unread count stream
      _unreadCountSubscription = _notificationService.unreadCountStream.listen(
        (count) {
          if (mounted) {
            setState(() {
              _unreadCount = count;
            });
          }
        },
      );

      // Load initial cached data
      final cachedNotifications = _notificationService.cachedNotifications;
      final cachedUnreadCount = _notificationService.unreadCount;
      
      if (cachedNotifications.isNotEmpty) {
        setState(() {
          _notifications = cachedNotifications;
          _groupNotifications(); // Group cached notifications
          _unreadCount = cachedUnreadCount;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize notifications: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Handle notification tap
  Future<void> _handleNotificationTap(AlertData notification) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🔍 DEBUG: Notification tapped - ID: ${notification.id}');
      print('🔍 DEBUG: Notification type: ${notification.type}');
      print('🔍 DEBUG: Notification metadata: ${notification.metadata}');

      // Mark as read if not already read
      if (!notification.isRead) {
        await _notificationService.markAsRead(notification.id, user.uid);
      }

      // Check if this is an appointment-related notification
      if (_isAppointmentNotification(notification)) {
        print('🔍 DEBUG: This is an appointment notification');
        // Try to get appointment ID from metadata
        final appointmentId = notification.metadata?['appointmentId'] as String?;
        
        print('🔍 DEBUG: Appointment ID from metadata: $appointmentId');
        
        if (appointmentId != null && mounted) {
          print('🔍 DEBUG: Navigating to appointment details: /appointments/details/$appointmentId');
          // Navigate directly to appointment details
          context.push('/appointments/details/$appointmentId');
          return;
        } else {
          print('⚠️ DEBUG: No appointmentId found in metadata, falling back to notification details');
        }
      } else {
        print('🔍 DEBUG: This is NOT an appointment notification');
      }

      // Navigate to notification target if available
      if (notification.actionUrl != null && mounted) {
        print('🔍 DEBUG: Using actionUrl: ${notification.actionUrl}');
        // Import go_router and use context.push
        context.push(notification.actionUrl!);
      } else {
        print('🔍 DEBUG: No actionUrl, navigating to notification details');
        // If no specific action URL, navigate to notification detail page
        context.push('/alerts/details/${notification.id}', extra: notification);
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Check if notification is appointment-related
  bool _isAppointmentNotification(AlertData notification) {
    return notification.type == AlertType.appointment ||
           notification.type == AlertType.appointmentPending ||
           notification.type == AlertType.reschedule ||
           notification.type == AlertType.reappointment;
  }

  /// Handle pull to refresh
  Future<void> _handleRefresh() async {
    try {
      await _notificationService.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      
      if (unreadNotifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No unread notifications')),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Mark all as read
      for (final notification in unreadNotifications) {
        await _notificationService.markAsRead(notification.id, user.uid);
        await Future.delayed(const Duration(milliseconds: 50)); // Small delay to prevent overwhelming
      }

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked ${unreadNotifications.length} notifications as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          // Unread count badge
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          
          // Mark all as read button
          IconButton(
            onPressed: _unreadCount > 0 ? _markAllAsRead : null,
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _notifications.isNotEmpty
          ? ScrollToTopFab(
              scrollController: _scrollController,
              showThreshold: 200.0,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading notifications...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeNotifications();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll see your notifications here when they arrive',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _groupedNotifications.length,
        itemBuilder: (context, index) {
          final item = _groupedNotifications[index];
          
          if (item.isHeader) {
            // Render section header
            return Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 0 : 24,
                bottom: 12,
              ),
              child: Text(
                item.headerText!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            );
          } else {
            // Render notification item
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AlertItem(
                alert: item.notification!,
                onTap: () => _handleNotificationTap(item.notification!),
              ),
            );
          }
        },
      ),
    );
  }

  /// Group notifications by time periods
  void _groupNotifications() {
    if (_notifications.isEmpty) {
      _groupedNotifications = [];
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));

    final List<AlertData> todayNotifications = [];
    final List<AlertData> yesterdayNotifications = [];
    final List<AlertData> thisWeekNotifications = [];
    final List<AlertData> earlierNotifications = [];

    for (final notification in _notifications) {
      final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day,
      );

      if (notificationDate.isAtSameMomentAs(today)) {
        todayNotifications.add(notification);
      } else if (notificationDate.isAtSameMomentAs(yesterday)) {
        yesterdayNotifications.add(notification);
      } else if (notificationDate.isAfter(thisWeekStart) && notificationDate.isBefore(yesterday)) {
        thisWeekNotifications.add(notification);
      } else {
        earlierNotifications.add(notification);
      }
    }

    // Build grouped list with headers
    _groupedNotifications = [];

    if (todayNotifications.isNotEmpty) {
      _groupedNotifications.add(_AlertListItem.header('TODAY'));
      _groupedNotifications.addAll(
        todayNotifications.map((n) => _AlertListItem.notification(n))
      );
    }

    if (yesterdayNotifications.isNotEmpty) {
      _groupedNotifications.add(_AlertListItem.header('YESTERDAY'));
      _groupedNotifications.addAll(
        yesterdayNotifications.map((n) => _AlertListItem.notification(n))
      );
    }

    if (thisWeekNotifications.isNotEmpty) {
      _groupedNotifications.add(_AlertListItem.header('THIS WEEK'));
      _groupedNotifications.addAll(
        thisWeekNotifications.map((n) => _AlertListItem.notification(n))
      );
    }

    if (earlierNotifications.isNotEmpty) {
      _groupedNotifications.add(_AlertListItem.header('EARLIER'));
      _groupedNotifications.addAll(
        earlierNotifications.map((n) => _AlertListItem.notification(n))
      );
    }
  }
}

/// Helper class for grouped notification list items
class _AlertListItem {
  final bool isHeader;
  final String? headerText;
  final AlertData? notification;

  _AlertListItem._({
    required this.isHeader,
    this.headerText,
    this.notification,
  });

  factory _AlertListItem.header(String text) {
    return _AlertListItem._(
      isHeader: true,
      headerText: text,
    );
  }

  factory _AlertListItem.notification(AlertData notification) {
    return _AlertListItem._(
      isHeader: false,
      notification: notification,
    );
  }
}