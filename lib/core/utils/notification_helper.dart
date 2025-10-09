import 'package:pawsense/core/models/notifications/notification_model.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';

class NotificationHelper {
  /// Convert NotificationModel to AlertData for display
  static AlertData fromNotificationModel(NotificationModel notification) {
    // Runtime fix for old notification text (temporary migration helper)
    String title = notification.title;
    String message = notification.message;
    String? actionUrl = notification.actionUrl;
    String? actionLabel = notification.actionLabel;
    
    // Fix old "Received" text to "Sent"
    if (title == 'Appointment Request Received') {
      title = 'Appointment Request Sent';
    }
    
    // Replace placeholder text with actual names from metadata
    if (notification.metadata != null) {
      final metadata = notification.metadata!;
      
      // Replace pet name placeholders
      final actualPetName = metadata['petName'] as String?;
      if (actualPetName != null && actualPetName.isNotEmpty && actualPetName != 'Your pet') {
        message = message.replaceAll('Your pet', actualPetName);
        message = message.replaceAll('your pet', actualPetName);
        title = title.replaceAll('Your pet', actualPetName);
        title = title.replaceAll('your pet', actualPetName);
      }
      
      // Replace clinic name placeholders
      final actualClinicName = metadata['clinicName'] as String?;
      if (actualClinicName != null && actualClinicName.isNotEmpty && 
          actualClinicName != 'Clinic' && actualClinicName != 'the clinic') {
        message = message.replaceAll('Clinic', actualClinicName);
        message = message.replaceAll('clinic', actualClinicName);
        message = message.replaceAll('the clinic', actualClinicName);
        title = title.replaceAll('Clinic', actualClinicName);
        title = title.replaceAll('clinic', actualClinicName);
        title = title.replaceAll('the clinic', actualClinicName);
      }
    }
    
    // Fix old action URLs and labels for appointment notifications
    if (notification.category == NotificationCategory.appointment) {
      final appointmentId = notification.metadata?['appointmentId'] as String?;
      
      // If we have appointment ID and old action URL, update it
      if (appointmentId != null && 
          actionUrl == '/book-appointment' && 
          !appointmentId.startsWith('pending_')) {
        actionUrl = '/appointments/details/$appointmentId';
        actionLabel = 'View Details';
      }
    }
    
    return AlertData(
      id: notification.id,
      title: title,
      subtitle: message,
      type: _mapCategoryToAlertType(notification.category, notification.metadata),
      timestamp: notification.createdAt,
      isRead: notification.isRead,
      actionUrl: actionUrl,
      actionLabel: actionLabel,
      metadata: notification.metadata,
    );
  }

  /// Convert AlertData back to NotificationModel
  static NotificationModel toNotificationModel(AlertData alert) {
    return NotificationModel(
      id: alert.id,
      userId: '', // Will be populated from context if needed
      title: alert.title,
      message: alert.subtitle,
      category: _mapAlertTypeToCategory(alert.type),
      priority: _determinePriorityFromMetadata(alert.metadata),
      isRead: alert.isRead,
      actionUrl: alert.actionUrl,
      actionLabel: alert.actionLabel,
      metadata: alert.metadata,
      createdAt: alert.timestamp,
    );
  }

  /// Map AlertType to NotificationCategory
  static NotificationCategory _mapAlertTypeToCategory(AlertType type) {
    switch (type) {
      case AlertType.appointment:
      case AlertType.appointmentPending:
        return NotificationCategory.appointment;
      case AlertType.message:
        return NotificationCategory.message;
      case AlertType.task:
      case AlertType.reschedule:
      case AlertType.declined:
      case AlertType.reappointment:
        return NotificationCategory.task;
      case AlertType.systemUpdate:
        return NotificationCategory.system;
    }
  }

  /// Determine priority from metadata
  static NotificationPriority _determinePriorityFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return NotificationPriority.medium;
    
    final priorityStr = metadata['priority'] as String?;
    if (priorityStr != null) {
      switch (priorityStr.toLowerCase()) {
        case 'low':
          return NotificationPriority.low;
        case 'high':
          return NotificationPriority.high;
        case 'urgent':
          return NotificationPriority.urgent;
        default:
          return NotificationPriority.medium;
      }
    }
    
    // Check for urgent indicators
    final daysUntil = metadata['daysUntil'] as int?;
    if (daysUntil != null && daysUntil <= 1) {
      return NotificationPriority.urgent;
    } else if (daysUntil != null && daysUntil <= 3) {
      return NotificationPriority.high;
    }
    
    return NotificationPriority.medium;
  }

  /// Map NotificationCategory to AlertType
  static AlertType _mapCategoryToAlertType(NotificationCategory category, [Map<String, dynamic>? metadata]) {
    switch (category) {
      case NotificationCategory.appointment:
        // Check appointment status to determine the correct alert type
        if (metadata != null) {
          final status = metadata['status'] as String?;
          switch (status) {
            case 'pending':
              return AlertType.appointmentPending;
            case 'cancelled':
              return AlertType.declined; // Use declined type for red color
            case 'confirmed':
            case 'completed':
              return AlertType.appointment;
            default:
              return AlertType.appointment;
          }
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

    // Smart default routes based on category and metadata
    switch (notification.category) {
      case NotificationCategory.appointment:
        // Try to get appointment ID from metadata to create proper details route
        if (notification.metadata?['appointmentId'] != null) {
          final appointmentId = notification.metadata!['appointmentId'] as String;
          return '/appointments/details/$appointmentId';
        }
        // Fallback to booking page only if no appointment ID available
        return '/book-appointment';
      case NotificationCategory.message:
        return '/messaging';
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