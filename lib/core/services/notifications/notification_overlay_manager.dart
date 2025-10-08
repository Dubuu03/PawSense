import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/user/notifications/notification_popup.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';

class NotificationOverlayManager {
  static OverlayEntry? _currentOverlay;
  static final List<AlertData> _pendingNotifications = [];
  static bool _isShowing = false;

  /// Show a notification popup
  static void showNotification(
    BuildContext context,
    AlertData alert, {
    String? userId,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Add to pending if one is already showing
    if (_isShowing) {
      _pendingNotifications.add(alert);
      return;
    }

    _isShowing = true;
    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: NotificationPopup(
          alert: alert,
          userId: userId,
          duration: duration,
          onTap: () {
            // Execute custom onTap if provided
            onTap?.call();
          },
          onDismiss: () {
            _dismissCurrent();
            _showNextPending(context);
          },
        ),
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  /// Dismiss the current notification
  static void _dismissCurrent() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _isShowing = false;
  }

  /// Show the next pending notification
  static void _showNextPending(BuildContext context) {
    if (_pendingNotifications.isNotEmpty) {
      final nextAlert = _pendingNotifications.removeAt(0);
      // Small delay before showing next notification
      Future.delayed(const Duration(milliseconds: 200), () {
        if (context.mounted) {
          showNotification(context, nextAlert);
        }
      });
    }
  }

  /// Clear all notifications
  static void clearAll() {
    _dismissCurrent();
    _pendingNotifications.clear();
  }

  /// Check if notification is currently showing
  static bool get isShowing => _isShowing;
  
  /// Get pending notifications count
  static int get pendingCount => _pendingNotifications.length;
}