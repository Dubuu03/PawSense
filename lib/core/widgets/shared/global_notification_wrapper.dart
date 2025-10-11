import 'package:flutter/material.dart';
import '../../services/notifications/global_notification_manager.dart';

/// Global notification wrapper widget
/// Wrap your entire app with this to enable notifications everywhere
class GlobalNotificationWrapper extends StatefulWidget {
  final Widget child;
  
  const GlobalNotificationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<GlobalNotificationWrapper> createState() => _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState extends State<GlobalNotificationWrapper> {
  final GlobalNotificationManager _notificationManager = GlobalNotificationManager();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationManager.initialize();
      debugPrint('🌍 Global notification wrapper initialized (overlay disabled)');
    } catch (e) {
      debugPrint('❌ Error initializing global notification wrapper: $e');
    }
  }

  @override
  void dispose() {
    // Don't dispose the global manager here as it should persist
    // It will be disposed when the app terminates
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Helper widget to display notification count badge
class NotificationBadgeWidget extends StatefulWidget {
  final Widget child;
  final bool showBadge;
  
  const NotificationBadgeWidget({
    super.key,
    required this.child,
    this.showBadge = true,
  });

  @override
  State<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends State<NotificationBadgeWidget> {
  final GlobalNotificationManager _notificationManager = GlobalNotificationManager();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    
    if (widget.showBadge) {
      // Listen to unread count changes
      _notificationManager.unreadCountStream.listen((count) {
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      });
      
      // Get initial count
      _unreadCount = _notificationManager.unreadCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showBadge || _unreadCount == 0) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              _unreadCount > 99 ? '99+' : _unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}