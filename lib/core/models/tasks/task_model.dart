import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  assigned,
  inProgress,
  completed,
  overdue,
  cancelled,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignerId; // Admin who assigned the task
  final String assignerName;
  final String assigneeId; // Faculty/Student who receives the task
  final String assigneeName;
  final String assigneeRole; // 'faculty' or 'student'
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime deadline;
  final DateTime? completedAt;
  final String? completionNotes;
  final Map<String, dynamic>? metadata; // Additional task data

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignerId,
    required this.assignerName,
    required this.assigneeId,
    required this.assigneeName,
    required this.assigneeRole,
    this.status = TaskStatus.assigned,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    required this.updatedAt,
    required this.deadline,
    this.completedAt,
    this.completionNotes,
    this.metadata,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel.fromMap(data, doc.id);
  }

  factory TaskModel.fromMap(Map<String, dynamic> data, String id) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignerId: data['assignerId'] ?? '',
      assignerName: data['assignerName'] ?? '',
      assigneeId: data['assigneeId'] ?? '',
      assigneeName: data['assigneeName'] ?? '',
      assigneeRole: data['assigneeRole'] ?? 'student',
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => TaskStatus.assigned,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deadline: (data['deadline'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      completionNotes: data['completionNotes'],
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignerId': assignerId,
      'assignerName': assignerName,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneeRole': assigneeRole,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deadline': Timestamp.fromDate(deadline),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completionNotes': completionNotes,
      'metadata': metadata,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignerId,
    String? assignerName,
    String? assigneeId,
    String? assigneeName,
    String? assigneeRole,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deadline,
    DateTime? completedAt,
    String? completionNotes,
    Map<String, dynamic>? metadata,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignerId: assignerId ?? this.assignerId,
      assignerName: assignerName ?? this.assignerName,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneeRole: assigneeRole ?? this.assigneeRole,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if task is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(deadline) && status != TaskStatus.completed;
  }

  /// Get days remaining until deadline
  int get daysUntilDeadline {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays;
  }

  /// Get hours remaining until deadline
  int get hoursUntilDeadline {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inHours;
  }

  /// Check if deadline is approaching (within 3 days)
  bool get isDeadlineApproaching {
    return daysUntilDeadline <= 3 && daysUntilDeadline >= 0;
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get priority display text
  String get priorityDisplayText {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}