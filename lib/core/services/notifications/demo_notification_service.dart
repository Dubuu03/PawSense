import 'package:pawsense/core/services/notifications/notification_service.dart';
import 'package:pawsense/core/models/notifications/notification_model.dart';

/// Demo/Test service to create sample notifications for testing the enhanced alerts page
class DemoNotificationService {
  /// Create sample appointment notifications for testing
  static Future<void> createSampleAppointmentNotifications(String userId) async {
    // Appointment request sent (pending)
    await NotificationService.createNotification(
      userId: userId,
      title: 'Appointment Request Sent',
      message: 'Your appointment request for Buddy at Sunny Pet Clinic has been submitted and is awaiting approval.',
      category: NotificationCategory.appointment,
      priority: NotificationPriority.medium,
      actionUrl: '/appointments/details/apt_122',
      actionLabel: 'View Details',
      metadata: {
        'appointmentId': 'apt_122',
        'clinicName': 'Sunny Pet Clinic',
        'petName': 'Buddy',
        'status': 'pending',
        'requestedDate': DateTime.now().add(Duration(days: 2)).toIso8601String(),
        'requestedTime': '3:00 PM',
      },
    );

    // Appointment confirmed
    await NotificationService.createNotification(
      userId: userId,
      title: 'Appointment Confirmed',
      message: 'Great news! Your appointment for Max at City Vet Clinic has been confirmed for tomorrow at 2:30 PM.',
      category: NotificationCategory.appointment,
      priority: NotificationPriority.high,
      actionUrl: '/book-appointment',
      actionLabel: 'View Details',
      metadata: {
        'appointmentId': 'apt_123',
        'clinicName': 'City Vet Clinic',
        'petName': 'Max',
        'appointmentTime': '2:30 PM',
        'appointmentDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'status': 'confirmed',
      },
    );

    // Appointment reminder (for confirmed appointments)
    await NotificationService.createNotification(
      userId: userId,
      title: 'Appointment Reminder',
      message: 'Don\'t forget! Your confirmed appointment for Luna is in 3 days at Pet Care Center.',
      category: NotificationCategory.appointment,
      priority: NotificationPriority.medium,
      actionUrl: '/book-appointment',
      actionLabel: 'View Details',
      metadata: {
        'appointmentId': 'apt_126',
        'clinicName': 'Pet Care Center',
        'petName': 'Luna',
        'status': 'confirmed',
        'daysUntil': 3,
        'appointmentDate': DateTime.now().add(Duration(days: 3)).toIso8601String(),
        'appointmentTime': '1:30 PM',
      },
    );

    // Recent booking confirmation (just changed from pending to confirmed)
    await NotificationService.createNotification(
      userId: userId,
      title: 'Appointment Status Updated',
      message: 'Your appointment request for Oscar has been approved and confirmed for next Friday at 9:00 AM.',
      category: NotificationCategory.appointment,
      priority: NotificationPriority.high,
      actionUrl: '/book-appointment',
      actionLabel: 'View Confirmation',
      metadata: {
        'appointmentId': 'apt_127',
        'clinicName': 'Westside Animal Hospital',
        'petName': 'Oscar',
        'status': 'confirmed',
        'oldStatus': 'pending',
        'appointmentDate': DateTime.now().add(Duration(days: 5)).toIso8601String(),
        'appointmentTime': '9:00 AM',
      },
    );

    // Another pending appointment (emergency)
    await NotificationService.createNotification(
      userId: userId,
      title: 'Emergency Appointment Request Submitted',
      message: 'Your emergency appointment request for Charlie has been submitted. The clinic will contact you shortly.',
      category: NotificationCategory.appointment,
      priority: NotificationPriority.high,
      actionUrl: '/book-appointment',
      actionLabel: 'View Request',
      metadata: {
        'appointmentId': 'apt_124_emergency',
        'clinicName': 'Emergency Animal Hospital',
        'petName': 'Charlie',
        'status': 'pending',
        'isEmergency': true,
        'symptoms': 'Difficulty breathing',
      },
    );

    // Appointment rescheduled
    await NotificationService.createNotification(
      userId: userId,
      title: 'Appointment Rescheduled',
      message: 'Your appointment for Bella has been moved to next Monday at 10:00 AM by Dr. Smith.',
      category: NotificationCategory.appointment,
      priority: NotificationPriority.high,
      actionUrl: '/book-appointment',
      actionLabel: 'View New Time',
      metadata: {
        'appointmentId': 'apt_125',
        'petName': 'Bella',
        'newTime': '10:00 AM',
        'newDate': 'Next Monday',
        'veterinarian': 'Dr. Smith',
        'status': 'rescheduled',
      },
    );
  }

  /// Create sample message notifications for testing
  static Future<void> createSampleMessageNotifications(String userId) async {
    // New message from clinic
    await NotificationService.createNotification(
      userId: userId,
      title: 'New Message from Sunny Pet Clinic',
      message: 'You have 2 unread messages: "Lab results are ready for pickup"',
      category: NotificationCategory.message,
      priority: NotificationPriority.medium,
      actionUrl: '/messaging',
      actionLabel: 'Read Messages',
      metadata: {
        'conversationId': 'conv_456',
        'clinicName': 'Sunny Pet Clinic',
        'unreadCount': 2,
        'lastMessage': 'Lab results are ready for pickup',
      },
    );

    // Urgent message
    await NotificationService.createNotification(
      userId: userId,
      title: 'Urgent Message from Emergency Vet',
      message: 'Please call immediately regarding Charlie\'s test results.',
      category: NotificationCategory.message,
      priority: NotificationPriority.urgent,
      actionUrl: '/messaging',
      actionLabel: 'Read Message',
      metadata: {
        'conversationId': 'conv_789',
        'clinicName': 'Emergency Vet',
        'isUrgent': true,
        'petName': 'Charlie',
      },
    );
  }

  /// Create sample task notifications for testing
  static Future<void> createSampleTaskNotifications(String userId) async {
    // New task assigned
    await NotificationService.createNotification(
      userId: userId,
      title: 'New Task Assigned',
      message: 'Dr. Johnson assigned you: "Update vaccination records for all patients"',
      category: NotificationCategory.task,
      priority: NotificationPriority.medium,
      actionUrl: '/home', // Tasks not implemented yet
      actionLabel: 'View Task',
      metadata: {
        'taskId': 'task_101',
        'taskTitle': 'Update vaccination records for all patients',
        'assignerName': 'Dr. Johnson',
        'deadline': DateTime.now().add(Duration(days: 5)).toIso8601String(),
      },
    );

    // Task due reminder
    await NotificationService.createNotification(
      userId: userId,
      title: 'Task Due Tomorrow',
      message: 'Reminder: "Complete monthly report" is due tomorrow.',
      category: NotificationCategory.task,
      priority: NotificationPriority.high,
      actionUrl: '/home',
      actionLabel: 'Complete Task',
      metadata: {
        'taskId': 'task_102',
        'taskTitle': 'Complete monthly report',
        'deadline': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'daysUntil': 1,
      },
    );

    // Overdue task
    await NotificationService.createNotification(
      userId: userId,
      title: 'Task Overdue',
      message: 'The task "Review patient files" is now overdue. Please complete it as soon as possible.',
      category: NotificationCategory.task,
      priority: NotificationPriority.urgent,
      actionUrl: '/home',
      actionLabel: 'Complete Now',
      metadata: {
        'taskId': 'task_103',
        'taskTitle': 'Review patient files',
        'isOverdue': true,
        'daysPastDue': 2,
      },
    );
  }

  /// Create sample system notifications for testing
  static Future<void> createSampleSystemNotifications(String userId) async {
    // System maintenance
    await NotificationService.createNotification(
      userId: userId,
      title: 'Scheduled Maintenance',
      message: 'PawSense will be undergoing maintenance tonight from 2:00 AM to 4:00 AM. Some features may be unavailable.',
      category: NotificationCategory.system,
      priority: NotificationPriority.medium,
      metadata: {
        'maintenanceStart': '2:00 AM',
        'maintenanceEnd': '4:00 AM',
        'affectedServices': ['Appointments', 'Messaging'],
      },
    );

    // App update
    await NotificationService.createNotification(
      userId: userId,
      title: 'App Update Available',
      message: 'Version 2.1.0 is available with improved skin analysis accuracy and bug fixes.',
      category: NotificationCategory.system,
      priority: NotificationPriority.low,
      actionLabel: 'Learn More',
      metadata: {
        'version': '2.1.0',
        'features': ['Improved skin analysis', 'Bug fixes', 'Performance improvements'],
      },
    );

    // Feature announcement
    await NotificationService.createNotification(
      userId: userId,
      title: 'New Feature: AI Health Insights',
      message: 'Discover our new AI-powered health insights feature for better pet care recommendations.',
      category: NotificationCategory.system,
      priority: NotificationPriority.medium,
      actionUrl: '/home',
      actionLabel: 'Try Now',
      metadata: {
        'feature': 'AI Health Insights',
        'isNewFeature': true,
      },
    );
  }

  /// Create comprehensive sample notifications for demo
  static Future<void> createAllSampleNotifications(String userId) async {
    await Future.wait([
      createSampleAppointmentNotifications(userId),
      createSampleMessageNotifications(userId),
      createSampleTaskNotifications(userId),
      createSampleSystemNotifications(userId),
    ]);

    print('✅ Created comprehensive sample notifications for user: $userId');
  }

  /// Clean up all notifications for a user (for testing purposes)
  static Future<void> clearAllNotifications(String userId) async {
    // Note: This would need to be implemented in NotificationService
    // For now, this is just a placeholder for the demo
    print('🧹 Clear notifications functionality would be implemented here for user: $userId');
  }
}