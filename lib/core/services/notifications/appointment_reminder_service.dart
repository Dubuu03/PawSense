import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/notifications/notification_model.dart';

/// Service for scheduling and managing appointment reminder notifications
class AppointmentReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Timer? _reminderTimer;
  static bool _isRunning = false;

  /// Start the appointment reminder service
  /// This runs periodically to check for upcoming appointments and send reminders
  static void startReminderService() {
    if (_isRunning) {
      print('⏰ Appointment reminder service already running');
      return;
    }

    _isRunning = true;
    print('🚀 Starting appointment reminder service...');

    // Check for reminders every hour
    _reminderTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndSendReminders();
    });

    // Run immediate check on start
    _checkAndSendReminders();
  }

  /// Stop the appointment reminder service
  static void stopReminderService() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
    _isRunning = false;
    print('⏸️ Appointment reminder service stopped');
  }

  /// Check for upcoming appointments and send reminders
  static Future<void> _checkAndSendReminders() async {
    try {
      print('🔍 Checking for upcoming appointments...');
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfWeek = startOfDay.add(const Duration(days: 7));

      // Get confirmed appointments in the next 7 days
      final appointmentsSnapshot = await _firestore
          .collection('appointmentBookings')
          .where('status', isEqualTo: 'confirmed')
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .get();

      print('📅 Found ${appointmentsSnapshot.docs.length} confirmed appointments in next 7 days');

      for (final doc in appointmentsSnapshot.docs) {
        try {
          await _processAppointmentReminder(doc);
        } catch (e) {
          print('❌ Error processing appointment ${doc.id}: $e');
        }
      }

      print('✅ Appointment reminder check completed');
    } catch (e) {
      print('❌ Error checking appointment reminders: $e');
    }
  }

  /// Process individual appointment and send appropriate reminders
  static Future<void> _processAppointmentReminder(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentId = doc.id;
      final userId = data['userId'] as String?;
      final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
      final appointmentTime = data['appointmentTime'] as String?;
      final now = DateTime.now();

      if (userId == null) return;

      // Calculate days until appointment
      final daysUntil = appointmentDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      final hoursUntil = appointmentDate.difference(now).inHours;

      // Get pet and clinic info
      final petId = data['petId'] as String?;
      final clinicId = data['clinicId'] as String?;
      
      String petName = 'Your pet';
      if (petId != null) {
        try {
          final petDoc = await _firestore.collection('pets').doc(petId).get();
          if (petDoc.exists) {
            final petData = petDoc.data();
            petName = petData?['name'] ?? petData?['petName'] ?? 'Your pet';
          }
        } catch (e) {
          print('Error fetching pet name: $e');
          // Fall back to appointment data if available
          petName = data['petName'] ?? 'Your pet';
        }
      } else {
        // Fall back to appointment data if petId not available
        petName = data['petName'] ?? 'Your pet';
      }

      String clinicName = 'the clinic';
      if (clinicId != null) {
        try {
          final clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
          if (clinicDoc.exists) {
            final clinicData = clinicDoc.data();
            clinicName = clinicData?['clinicName'] ?? clinicData?['name'] ?? 'the clinic';
          }
        } catch (e) {
          print('Error fetching clinic name: $e');
          // Fall back to appointment data if available
          clinicName = data['clinicName'] ?? 'the clinic';
        }
      } else {
        // Fall back to appointment data if clinicId not available
        clinicName = data['clinicName'] ?? 'the clinic';
      }

      // Determine which reminder to send based on time until appointment
      ReminderType? reminderType;
      if (daysUntil == 7) {
        reminderType = ReminderType.sevenDays;
      } else if (daysUntil == 3) {
        reminderType = ReminderType.threeDays;
      } else if (daysUntil == 1) {
        reminderType = ReminderType.oneDay;
      } else if (daysUntil == 0 && hoursUntil > 2) {
        reminderType = ReminderType.today;
      } else if (daysUntil == 0 && hoursUntil <= 2 && hoursUntil > 0) {
        reminderType = ReminderType.twoHours;
      }

      if (reminderType == null) return;

      // Check if reminder was already sent
      final reminderId = 'appointment_reminder_${appointmentId}_${reminderType.name}';
      final existingNotification = await _firestore
          .collection('notifications')
          .doc(reminderId)
          .get();

      if (existingNotification.exists) {
        // Reminder already sent
        return;
      }

      // Send the reminder
      await _sendReminder(
        userId: userId,
        appointmentId: appointmentId,
        petName: petName,
        clinicName: clinicName,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        reminderType: reminderType,
        daysUntil: daysUntil,
        hoursUntil: hoursUntil,
      );

      print('✅ Sent ${reminderType.name} reminder for appointment $appointmentId');
    } catch (e) {
      print('❌ Error processing appointment reminder: $e');
    }
  }

  /// Send a reminder notification
  static Future<void> _sendReminder({
    required String userId,
    required String appointmentId,
    required String petName,
    required String clinicName,
    required DateTime appointmentDate,
    String? appointmentTime,
    required ReminderType reminderType,
    required int daysUntil,
    required int hoursUntil,
  }) async {
    String title;
    String message;
    NotificationPriority priority;

    final timeText = appointmentTime ?? 'your scheduled time';

    switch (reminderType) {
      case ReminderType.sevenDays:
        title = 'Appointment Reminder';
        message = 'Your appointment for $petName at $clinicName is coming up in 7 days.';
        priority = NotificationPriority.low;
        break;
      case ReminderType.threeDays:
        title = 'Appointment in 3 Days';
        message = 'Your appointment for $petName at $clinicName is in 3 days at $timeText.';
        priority = NotificationPriority.medium;
        break;
      case ReminderType.oneDay:
        title = 'Appointment Tomorrow';
        message = 'Reminder: Your appointment for $petName at $clinicName is tomorrow at $timeText.';
        priority = NotificationPriority.high;
        break;
      case ReminderType.today:
        title = 'Appointment Today';
        message = 'Your appointment for $petName at $clinicName is today at $timeText.';
        priority = NotificationPriority.urgent;
        break;
      case ReminderType.twoHours:
        title = 'Appointment Starting Soon';
        message = 'Your appointment for $petName at $clinicName starts in ${hoursUntil} hour(s). Please arrive early!';
        priority = NotificationPriority.urgent;
        break;
    }

    // Create notification with unique ID
    final reminderId = 'appointment_reminder_${appointmentId}_${reminderType.name}';
    
    await _firestore.collection('notifications').doc(reminderId).set({
      'userId': userId,
      'title': title,
      'message': message,
      'category': 'appointment',
      'priority': priority.name,
      'isRead': false,
      'actionUrl': '/book-appointment',
      'actionLabel': 'View Details',
      'metadata': {
        'appointmentId': appointmentId,
        'petName': petName,
        'clinicName': clinicName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'daysUntil': daysUntil,
        'status': 'confirmed',
        'reminderType': reminderType.name,
      },
      'createdAt': Timestamp.now(),
      'sentAt': Timestamp.now(),
    });
  }

  /// Manually trigger a reminder check (for testing)
  static Future<void> checkNow() async {
    print('🔄 Manual reminder check triggered');
    await _checkAndSendReminders();
  }

  /// Check if service is running
  static bool get isRunning => _isRunning;
}

enum ReminderType {
  sevenDays,
  threeDays,
  oneDay,
  today,
  twoHours,
}
