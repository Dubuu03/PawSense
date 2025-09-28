import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationCategory {
  appointment,
  message,
  task,
  system,
}

enum NotificationPriority {
  low,
  medium, 
  high,
  urgent,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationCategory category;
  final NotificationPriority priority;
  final bool isRead;
  final String? actionUrl;
  final String? actionLabel;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.category,
    this.priority = NotificationPriority.medium,
    this.isRead = false,
    this.actionUrl,
    this.actionLabel,
    this.imageUrl,
    this.metadata,
    this.scheduledFor,
    this.sentAt,
    this.readAt,
    required this.createdAt,
    this.expiresAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data, doc.id);
  }

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      category: NotificationCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => NotificationCategory.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      isRead: data['isRead'] ?? false,
      actionUrl: data['actionUrl'],
      actionLabel: data['actionLabel'],
      imageUrl: data['imageUrl'],
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      scheduledFor: data['scheduledFor'] != null ? (data['scheduledFor'] as Timestamp).toDate() : null,
      sentAt: data['sentAt'] != null ? (data['sentAt'] as Timestamp).toDate() : null,
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'isRead': isRead,
      'actionUrl': actionUrl,
      'actionLabel': actionLabel,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationCategory? category,
    NotificationPriority? priority,
    bool? isRead,
    String? actionUrl,
    String? actionLabel,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Get time ago string (e.g., "2h ago", "3 days ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification should be shown (not expired and not deleted)
  bool get shouldShow {
    return !isExpired;
  }
}