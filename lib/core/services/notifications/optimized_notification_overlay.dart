import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/user/alerts/alert_item.dart';
import 'realtime_notification_service.dart';

/// Optimized notification overlay manager
/// Shows popup notifications for real-time updates
/// Uses minimal resources and proper lifecycle management
class OptimizedNotificationOverlay {
  static final OptimizedNotificationOverlay _instance = OptimizedNotificationOverlay._internal();
  factory OptimizedNotificationOverlay() => _instance;
  OptimizedNotificationOverlay._internal();

  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;
  static String? _lastShownNotificationId;
  static bool _isInitialized = false;
  
  final RealTimeNotificationService _notificationService = RealTimeNotificationService();
  StreamSubscription<List<AlertData>>? _notificationSubscription;
  
  // Track known notifications to detect truly new ones
  Set<String> _knownNotificationIds = <String>{};
  
  // Track retry attempts to prevent infinite loops (reserved for future use)
  // Map<String, int> _retryAttempts = <String, int>{};

  /// Initialize overlay with real-time notification listening
  void initialize(BuildContext context) {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    // Clean up any existing state
    _dismissCurrentOverlay();
    
    // Listen to new notifications
    _notificationSubscription = _notificationService.notificationsStream
        .where((notifications) => notifications.isNotEmpty)
        .listen((notifications) {
      _handleNewNotifications(context, notifications);
    });
    
    debugPrint('🔔 Notification overlay initialized');
  }

  /// Handle new notifications and show popup for unread ones
  void _handleNewNotifications(BuildContext context, List<AlertData> notifications) {
    debugPrint('🔍 DEBUG: _handleNewNotifications called with ${notifications.length} notifications');
    
    if (!context.mounted) {
      debugPrint('⚠️ DEBUG: Context not mounted, returning');
      return;
    }
    
    // Find truly new notifications (not seen before)
    final newNotifications = notifications
        .where((n) => !n.isRead) // Only unread notifications
        .where((n) => !_knownNotificationIds.contains(n.id)) // Not seen before
        .where((n) => n.id != _lastShownNotificationId) // Not already shown
        .toList();
    
    debugPrint('🔍 DEBUG: Found ${newNotifications.length} truly new notifications');
    for (var notif in newNotifications) {
      debugPrint('🔍 DEBUG: New notification - ID: ${notif.id}, Title: ${notif.title}');
    }
    
    // Update known notifications set
    _knownNotificationIds.addAll(notifications.map((n) => n.id));
    
    if (newNotifications.isEmpty) {
      debugPrint('🔍 DEBUG: No new notifications to show');
      return;
    }
    
    // Get the most recent new notification
    final latestNotification = newNotifications.first;
    
    // Only show popup for recent notifications (last 300 seconds for testing)
    final now = DateTime.now();
    final notificationAge = now.difference(latestNotification.timestamp);
    
    debugPrint('🔍 DEBUG: Latest notification age: ${notificationAge.inSeconds} seconds');
    
    if (notificationAge.inSeconds <= 300) { // Increased to 5 minutes for testing
      debugPrint('🔔 Showing popup for new notification: ${latestNotification.title}');
      _showNotificationPopup(context, latestNotification);
      _lastShownNotificationId = latestNotification.id;
    } else {
      debugPrint('⏰ Notification too old to show popup: ${notificationAge.inSeconds}s old');
    }
  }

  /// Show notification popup overlay
  void _showNotificationPopup(BuildContext context, AlertData notification) {
    if (!context.mounted) {
      debugPrint('⚠️ Context not mounted, cannot show notification popup');
      return;
    }
    
    // Dismiss any existing overlay
    _dismissCurrentOverlay();
    
    try {
      // Check if Overlay is available
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        debugPrint('⚠️ No Overlay found, retrying in 1 second...');
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            _showNotificationPopup(context, notification);
          }
        });
        return;
      }
      
      _currentOverlay = OverlayEntry(
        builder: (context) => _NotificationPopupWidget(
          notification: notification,
          onTap: () => _handleNotificationTap(context, notification),
          onDismiss: _dismissCurrentOverlay,
        ),
      );
      
      if (overlay.mounted) {
        overlay.insert(_currentOverlay!);
        
        // Auto dismiss after 4 seconds
        _dismissTimer = Timer(const Duration(seconds: 4), _dismissCurrentOverlay);
        
        debugPrint('🔔 Successfully showing popup for: ${notification.title}');
      } else {
        debugPrint('⚠️ Overlay not mounted, cannot insert notification popup');
        _currentOverlay = null;
      }
    } catch (e) {
      debugPrint('❌ Error showing notification popup: $e');
      _currentOverlay = null;
      
      // Retry once after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          debugPrint('🔄 Retrying notification popup...');
          _showNotificationPopup(context, notification);
        }
      });
    }
  }

  /// Handle notification popup tap
  void _handleNotificationTap(BuildContext context, AlertData notification) {
    _dismissCurrentOverlay();
    
    // Mark as read
    if (context.mounted) {
      // Get current user ID (you'll need to adapt this to your auth system)
      final userId = getCurrentUserId(); // Implement this method
      if (userId != null) {
        _notificationService.markAsRead(notification.id, userId);
      }
      
      // Navigate to notification target
      if (notification.actionUrl != null) {
        context.push(notification.actionUrl!);
      }
    }
  }

  /// Dismiss current overlay
  static void _dismissCurrentOverlay() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    
    if (_currentOverlay != null) {
      try {
        _currentOverlay!.remove();
      } catch (e) {
        debugPrint('⚠️ Error removing overlay: $e');
      }
      _currentOverlay = null;
    }
  }

  /// Show notification manually (for testing or specific cases)
  void showNotification(BuildContext context, AlertData notification) {
    if (context.mounted) {
      debugPrint('🔔 Manually showing popup for: ${notification.title}');
      _showNotificationPopup(context, notification);
    }
  }

  /// Force show popup for newest unread notification (for testing)
  void showLatestNotification(BuildContext context) {
    if (!context.mounted) return;
    
    final notifications = _notificationService.cachedNotifications;
    final unreadNotifications = notifications.where((n) => !n.isRead).toList();
    
    if (unreadNotifications.isNotEmpty) {
      final latest = unreadNotifications.first;
      debugPrint('🔔 Force showing latest notification: ${latest.title}');
      _showNotificationPopup(context, latest);
    } else {
      debugPrint('📭 No unread notifications to show');
    }
  }



  /// Dispose overlay manager
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    
    _dismissCurrentOverlay();
    _isInitialized = false;
    _lastShownNotificationId = null;
    _knownNotificationIds.clear();
    
    debugPrint('🧹 Notification overlay disposed');
  }

  /// Get current user ID from Firebase Auth
  String? getCurrentUserId() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      debugPrint('❌ Error getting current user ID: $e');
      return null;
    }
  }
}

/// Notification popup widget
class _NotificationPopupWidget extends StatefulWidget {
  final AlertData notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationPopupWidget({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationPopupWidget> createState() => _NotificationPopupWidgetState();
}

class _NotificationPopupWidgetState extends State<_NotificationPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getNotificationColor(widget.notification.type),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Notification icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getNotificationColor(widget.notification.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getNotificationIcon(widget.notification.type),
                          color: _getNotificationColor(widget.notification.type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Notification content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.notification.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.notification.subtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Dismiss button
                      IconButton(
                        onPressed: widget.onDismiss,
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(24, 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(AlertType type) {
    switch (type) {
      case AlertType.appointment:
      case AlertType.appointmentPending:
        return Colors.blue;
      case AlertType.message:
        return Colors.green;
      case AlertType.task:
        return Colors.orange;
      case AlertType.reschedule:
        return Colors.amber;
      case AlertType.declined:
        return Colors.red;
      case AlertType.reappointment:
        return Colors.indigo;
      case AlertType.followUp:
        return const Color(0xFF3B82F6); // Blue color for follow-ups
      case AlertType.systemUpdate:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(AlertType type) {
    switch (type) {
      case AlertType.appointment:
      case AlertType.appointmentPending:
        return Icons.event;
      case AlertType.message:
        return Icons.message;
      case AlertType.task:
        return Icons.task_alt;
      case AlertType.reschedule:
        return Icons.schedule;
      case AlertType.declined:
        return Icons.cancel;
      case AlertType.reappointment:
        return Icons.event_repeat;
      case AlertType.followUp:
        return Icons.sync; // Sync icon for follow-ups
      case AlertType.systemUpdate:
        return Icons.info;
    }
  }
}