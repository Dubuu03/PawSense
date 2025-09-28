import 'package:pawsense/core/models/notifications/notification_model.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';

class NotificationHelper {
  /// Convert NotificationModel to AlertData for display
  static AlertData fromNotificationModel(NotificationModel notification) {
    return AlertData(
      id: notification.id,
      title: notification.title,
      subtitle: notification.message,
      type: _mapCategoryToAlertType(notification.category, notification.metadata),
      timestamp: notification.createdAt,
      isRead: notification.isRead,
      actionUrl: notification.actionUrl,
      actionLabel: notification.actionLabel,
      metadata: notification.metadata,
    );
  }

  /// Map NotificationCategory to AlertType
  static AlertType _mapCategoryToAlertType(NotificationCategory category, [Map<String, dynamic>? metadata]) {
    switch (category) {
      case NotificationCategory.appointment:
        // Check if it's a pending appointment
        if (metadata != null && metadata['status'] == 'pending') {
          return AlertType.appointmentPending;
        }
        return AlertType.appointment;
      case NotificationCategory.message:
        return AlertType.message;
      case NotificationCategory.task:
        return AlertType.task;
      case NotificationCategory.system:
        return AlertType.systemUpdate;
    }
  }

  /// Get navigation route based on notification category and action URL
  static String getNavigationRoute(NotificationModel notification) {
    if (notification.actionUrl != null) {
      return notification.actionUrl!;
    }

    // Default routes based on category
    switch (notification.category) {
      case NotificationCategory.appointment:
        return '/book-appointment';  // Changed from /appointments to actual route
      case NotificationCategory.message:
        return '/messaging';  // Changed from /messages to actual route
      case NotificationCategory.task:
        return '/home';  // Tasks feature not implemented, redirect to home
      case NotificationCategory.system:
        return '/home';  // System notifications stay on home
    }
  }

  /// Check if notification requires immediate attention
  static bool requiresAttention(NotificationModel notification) {
    return !notification.isRead && 
           (notification.priority == NotificationPriority.high || 
            notification.priority == NotificationPriority.urgent);
  }

  /// Get priority color
  static String getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return '#E8F5E8';
      case NotificationPriority.medium:
        return '#FFF3E0';
      case NotificationPriority.high:
        return '#FFEBEE';
      case NotificationPriority.urgent:
        return '#FFCDD2';
    }
  }

  /// Get priority text
  static String getPriorityText(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
}