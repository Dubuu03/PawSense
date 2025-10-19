import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminNotificationType {
  appointment,
  message,
  transaction,
  system,
  emergency,
}

enum AdminNotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class AdminNotificationModel {
  final String id;
  final String title;
  final String message;
  final AdminNotificationType type;
  final AdminNotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final String? relatedId; // ID of appointment, message, etc.
  final String clinicId;

  AdminNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.metadata,
    this.relatedId,
    required this.clinicId,
  });

  // Convert from Firestore document
  factory AdminNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: AdminNotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => AdminNotificationType.system,
      ),
      priority: AdminNotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => AdminNotificationPriority.medium,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      actionUrl: data['actionUrl'],
      metadata: data['metadata']?.cast<String, dynamic>(),
      relatedId: data['relatedId'],
      clinicId: data['clinicId'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'metadata': metadata,
      'relatedId': relatedId,
      'clinicId': clinicId,
    };
  }

  // Create copy with updated fields
  AdminNotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    AdminNotificationType? type,
    AdminNotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    String? relatedId,
    String? clinicId,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      relatedId: relatedId ?? this.relatedId,
      clinicId: clinicId ?? this.clinicId,
    );
  }

  // Helper methods for UI
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case AdminNotificationType.appointment:
        return 'Appointment';
      case AdminNotificationType.message:
        return 'Message';
      case AdminNotificationType.transaction:
        return 'Transaction';
      case AdminNotificationType.system:
        return 'System';
      case AdminNotificationType.emergency:
        return 'Emergency';
    }
  }

  // Factory methods for different notification types
  static AdminNotificationModel createAppointmentNotification({
    required String id,
    required String title,
    required String message,
    required String clinicId,
    required String appointmentId,
    AdminNotificationPriority priority = AdminNotificationPriority.medium,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return AdminNotificationModel(
      id: id,
      title: title,
      message: message,
      type: AdminNotificationType.appointment,
      priority: priority,
      timestamp: DateTime.now(),
      clinicId: clinicId,
      relatedId: appointmentId,
      // Updated to navigate directly to appointment with ID
      actionUrl: actionUrl ?? '/admin/appointments?appointmentId=$appointmentId',
      metadata: metadata,
    );
  }

  static AdminNotificationModel createMessageNotification({
    required String id,
    required String title,
    required String message,
    required String clinicId,
    required String messageId,
    AdminNotificationPriority priority = AdminNotificationPriority.medium,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return AdminNotificationModel(
      id: id,
      title: title,
      message: message,
      type: AdminNotificationType.message,
      priority: priority,
      timestamp: DateTime.now(),
      clinicId: clinicId,
      relatedId: messageId,
      actionUrl: actionUrl ?? '/admin/messaging',
      metadata: metadata,
    );
  }

  static AdminNotificationModel createEmergencyNotification({
    required String id,
    required String title,
    required String message,
    required String clinicId,
    String? relatedId,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return AdminNotificationModel(
      id: id,
      title: title,
      message: message,
      type: AdminNotificationType.emergency,
      priority: AdminNotificationPriority.urgent,
      timestamp: DateTime.now(),
      clinicId: clinicId,
      relatedId: relatedId,
      actionUrl: actionUrl,
      metadata: metadata,
    );
  }
}