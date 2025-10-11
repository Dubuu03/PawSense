import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/admin/admin_notification_service.dart';
import 'package:pawsense/core/models/admin/admin_notification_model.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';

/// Integration service to create admin notifications for appointment events
class AdminAppointmentNotificationIntegrator {
  static final AdminNotificationService _notificationService = AdminNotificationService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track processed appointments to prevent duplicates
  static final Set<String> _processedAppointments = {};
  static bool _isInitialLoad = true;

  /// Initialize appointment listeners for admin notifications
  static void initializeAppointmentListeners() {
    // Listen for new appointments
    _firestore.collection('appointments').snapshots().listen((snapshot) {
      // On first load, just mark all existing appointments as processed
      // This prevents creating notifications for historical data
      if (_isInitialLoad) {
        for (final doc in snapshot.docs) {
          _processedAppointments.add(doc.id);
        }
        _isInitialLoad = false;
        print('🔄 Initial load: Marked ${_processedAppointments.length} existing appointments as processed');
        return;
      }
      
      // Process only new changes after initial load
      for (final change in snapshot.docChanges) {
        final docId = change.doc.id;
        
        switch (change.type) {
          case DocumentChangeType.added:
            // Only process if not already processed
            if (!_processedAppointments.contains(docId)) {
              _handleNewAppointment(change.doc);
              _processedAppointments.add(docId);
            }
            break;
          case DocumentChangeType.modified:
            _handleAppointmentUpdate(change.doc);
            break;
          case DocumentChangeType.removed:
            _handleAppointmentCancellation(change.doc);
            _processedAppointments.remove(docId);
            break;
        }
      }
    });
  }

  /// Handle new appointment booking
  static Future<void> _handleNewAppointment(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final appointment = AppointmentBooking.fromMap(data, doc.id);
      
      if (appointment.status == AppointmentStatus.pending) {
        // Get pet and user details
        final petData = await _getPetData(appointment.petId);
        final userData = await _getUserData(appointment.userId);
        
        String petName = petData?['name'] ?? petData?['petName'] ?? 'Pet';
        String ownerName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
        if (ownerName.isEmpty) {
          ownerName = userData?['username'] ?? 'Pet Owner';
        }
        
        final appointmentTime = '${_formatDate(appointment.appointmentDate)} at ${appointment.appointmentTime}';
        
        // Determine priority based on appointment type and service
        AdminNotificationPriority priority = AdminNotificationPriority.medium;
        if (appointment.type == AppointmentType.emergency || 
            appointment.serviceName.toLowerCase().contains('emergency')) {
          priority = AdminNotificationPriority.urgent;
        }
        
        await _notificationService.createAppointmentNotification(
          appointmentId: appointment.id ?? doc.id,
          title: priority == AdminNotificationPriority.urgent 
              ? '🚨 Emergency Appointment Request'
              : 'New Appointment Request',
          message: '$ownerName requested an appointment for $petName on $appointmentTime for ${appointment.serviceName}',
          priority: priority,
          metadata: {
            'petId': appointment.petId,
            'petName': petName,
            'ownerName': ownerName,
            'appointmentDate': appointment.appointmentDate.toIso8601String(),
            'appointmentTime': appointment.appointmentTime,
            'serviceName': appointment.serviceName,
            'notes': appointment.notes,
            'isEmergency': priority == AdminNotificationPriority.urgent,
          },
        );
        
        print('✅ Created admin notification for new appointment: ${doc.id}');
      }
    } catch (e) {
      print('❌ Error handling new appointment notification: $e');
    }
  }

  /// Handle appointment status updates
  static Future<void> _handleAppointmentUpdate(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final appointment = AppointmentBooking.fromMap(data, doc.id);
      
      // Check if this is a status change from pending to confirmed/cancelled
      // We can't easily track old vs new status without additional logic,
      // so we'll create notifications for specific status changes
      
      if (appointment.status == AppointmentStatus.cancelled && appointment.cancelReason != null) {
        // Get pet and user details
        final petData = await _getPetData(appointment.petId);
        final userData = await _getUserData(appointment.userId);
        
        String petName = petData?['name'] ?? petData?['petName'] ?? 'Pet';
        String ownerName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
        if (ownerName.isEmpty) {
          ownerName = userData?['username'] ?? 'Pet Owner';
        }
        
        final appointmentTime = '${_formatDate(appointment.appointmentDate)} at ${appointment.appointmentTime}';
        
        await _notificationService.createAppointmentNotification(
          appointmentId: appointment.id ?? doc.id,
          title: '❌ Appointment Cancelled',
          message: '$ownerName cancelled the appointment for $petName on $appointmentTime. Reason: ${appointment.cancelReason}',
          priority: AdminNotificationPriority.medium,
          metadata: {
            'petId': appointment.petId,
            'petName': petName,
            'ownerName': ownerName,
            'appointmentDate': appointment.appointmentDate.toIso8601String(),
            'appointmentTime': appointment.appointmentTime,
            'serviceName': appointment.serviceName,
            'cancelReason': appointment.cancelReason,
            'status': 'cancelled',
          },
        );
        
        print('✅ Created admin notification for cancelled appointment: ${doc.id}');
      }
      
      if (appointment.status == AppointmentStatus.rescheduled && appointment.rescheduleReason != null) {
        // Get pet and user details
        final petData = await _getPetData(appointment.petId);
        final userData = await _getUserData(appointment.userId);
        
        String petName = petData?['name'] ?? petData?['petName'] ?? 'Pet';
        String ownerName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
        if (ownerName.isEmpty) {
          ownerName = userData?['username'] ?? 'Pet Owner';
        }
        
        final appointmentTime = '${_formatDate(appointment.appointmentDate)} at ${appointment.appointmentTime}';
        
        await _notificationService.createAppointmentNotification(
          appointmentId: appointment.id ?? doc.id,
          title: '🔄 Appointment Rescheduled',
          message: '$ownerName rescheduled the appointment for $petName to $appointmentTime. Reason: ${appointment.rescheduleReason}',
          priority: AdminNotificationPriority.medium,
          metadata: {
            'petId': appointment.petId,
            'petName': petName,
            'ownerName': ownerName,
            'appointmentDate': appointment.appointmentDate.toIso8601String(),
            'appointmentTime': appointment.appointmentTime,
            'serviceName': appointment.serviceName,
            'rescheduleReason': appointment.rescheduleReason,
            'status': 'rescheduled',
          },
        );
        
        print('✅ Created admin notification for rescheduled appointment: ${doc.id}');
      }
    } catch (e) {
      print('❌ Error handling appointment update notification: $e');
    }
  }

  /// Handle appointment deletion (less common, but included for completeness)
  static Future<void> _handleAppointmentCancellation(DocumentSnapshot doc) async {
    try {
      // Create a system notification about deleted appointment
      await _notificationService.createSystemNotification(
        title: 'Appointment Record Deleted',
        message: 'An appointment record was permanently deleted from the system.',
        priority: AdminNotificationPriority.low,
        metadata: {
          'deletedAppointmentId': doc.id,
          'deletedAt': DateTime.now().toIso8601String(),
        },
      );
      
      print('✅ Created admin notification for deleted appointment: ${doc.id}');
    } catch (e) {
      print('❌ Error handling appointment deletion notification: $e');
    }
  }

  /// Helper to get pet data
  static Future<Map<String, dynamic>?> _getPetData(String petId) async {
    try {
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      return petDoc.exists ? petDoc.data() : null;
    } catch (e) {
      print('Error fetching pet data: $e');
      return null;
    }
  }

  /// Helper to get user data
  static Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  /// Helper to format date
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Manual notification creation methods for specific scenarios
  
  /// Create notification when admin accepts an appointment
  static Future<void> notifyAppointmentAccepted({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String serviceName,
  }) async {
    final appointmentTimeStr = '${_formatDate(appointmentDate)} at $appointmentTime';
    
    await _notificationService.createAppointmentNotification(
      appointmentId: appointmentId,
      title: '✅ Appointment Confirmed',
      message: 'Appointment for $petName (owner: $ownerName) has been confirmed for $appointmentTimeStr - $serviceName',
      priority: AdminNotificationPriority.medium,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'serviceName': serviceName,
        'status': 'confirmed',
        'actionType': 'admin_confirmed',
      },
    );
  }

  /// Create notification for appointment reminders (24h, 2h before)
  static Future<void> notifyUpcomingAppointment({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String serviceName,
    required int hoursUntil,
  }) async {
    String title;
    String message;
    AdminNotificationPriority priority;
    
    if (hoursUntil <= 2) {
      title = '⏰ Appointment Starting Soon';
      message = 'Appointment for $petName (owner: $ownerName) starts in $hoursUntil hour(s) - $serviceName';
      priority = AdminNotificationPriority.high;
    } else if (hoursUntil <= 24) {
      title = '📅 Appointment Tomorrow';
      message = 'Reminder: Appointment for $petName (owner: $ownerName) is scheduled for tomorrow at $appointmentTime - $serviceName';
      priority = AdminNotificationPriority.medium;
    } else {
      title = '📅 Upcoming Appointment';
      message = 'Reminder: Appointment for $petName (owner: $ownerName) is scheduled for ${_formatDate(appointmentDate)} at $appointmentTime - $serviceName';
      priority = AdminNotificationPriority.low;
    }
    
    await _notificationService.createAppointmentNotification(
      appointmentId: appointmentId,
      title: title,
      message: message,
      priority: priority,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'serviceName': serviceName,
        'hoursUntil': hoursUntil,
        'reminderType': hoursUntil <= 2 ? 'immediate' : hoursUntil <= 24 ? 'tomorrow' : 'upcoming',
      },
    );
  }

  /// Create notification for missed appointments
  static Future<void> notifyMissedAppointment({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String serviceName,
  }) async {
    final appointmentTimeStr = '${_formatDate(appointmentDate)} at $appointmentTime';
    
    await _notificationService.createAppointmentNotification(
      appointmentId: appointmentId,
      title: '⚠️ Missed Appointment',
      message: '$ownerName did not show up for the appointment for $petName scheduled for $appointmentTimeStr - $serviceName',
      priority: AdminNotificationPriority.medium,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'serviceName': serviceName,
        'status': 'missed',
        'missedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Create notification for completed appointments
  static Future<void> notifyAppointmentCompleted({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String serviceName,
    String? diagnosis,
    String? treatment,
  }) async {
    final appointmentTimeStr = '${_formatDate(appointmentDate)} at $appointmentTime';
    
    String message = 'Appointment for $petName (owner: $ownerName) scheduled for $appointmentTimeStr has been completed - $serviceName';
    if (diagnosis != null) {
      message += '. Diagnosis: $diagnosis';
    }
    
    await _notificationService.createAppointmentNotification(
      appointmentId: appointmentId,
      title: '✅ Appointment Completed',
      message: message,
      priority: AdminNotificationPriority.low,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'serviceName': serviceName,
        'status': 'completed',
        'diagnosis': diagnosis,
        'treatment': treatment,
        'completedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}