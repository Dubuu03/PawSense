import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/admin/admin_notification_service.dart';
import 'package:pawsense/core/models/admin/admin_notification_model.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/utils/app_logger.dart';

/// Integration service to create admin notifications for appointment events
class AdminAppointmentNotificationIntegrator {
  static final AdminNotificationService _notificationService = AdminNotificationService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track processed appointments to prevent duplicates
  static final Set<String> _processedAppointments = {};
  static final Set<String> _initialLoadAppointments = {}; // NEW: Track initial load appointments
  static bool _isInitialLoad = true;
  static bool _isListenerInitialized = false; // Prevent multiple listener initialization
  
  // Track specific notification events to prevent duplicate notifications
  // Key format: "appointmentId_eventType" (e.g., "appt123_created", "appt123_cancelled")
  static final Set<String> _notifiedEvents = {};

  /// Initialize appointment listeners for admin notifications
  static void initializeAppointmentListeners() {
    // Prevent multiple listener initialization
    if (_isListenerInitialized) {
      print('⚠️ Appointment notification listener already initialized, skipping');
      return;
    }
    
    _isListenerInitialized = true;
    print('🔔 Initializing appointment notification listener (ONCE)');
    
    // Listen for new appointments
    _firestore.collection('appointments').snapshots().listen((snapshot) {
      print('📡 Appointment snapshot received: ${snapshot.docs.length} docs, ${snapshot.docChanges.length} changes');
      // On first load, just mark all existing appointments as processed
      // This prevents creating notifications for historical data
      if (_isInitialLoad) {
        for (final doc in snapshot.docs) {
          final docId = doc.id;
          
          _processedAppointments.add(docId);
          _initialLoadAppointments.add(docId); // Track as initial load
          
          // Mark all possible notification events as already handled
          // This prevents notifications for existing appointments
          _notifiedEvents.add('${docId}_created');
          _notifiedEvents.add('${docId}_cancelled');
          // Note: Rescheduled events have dynamic timestamps, blocked via _initialLoadAppointments
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
            // Only process if not already processed AND not already notified
            final eventKey = '${docId}_created';
            if (!_processedAppointments.contains(docId) && !_notifiedEvents.contains(eventKey)) {
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
      final data = doc.data();
      if (data == null || data is! Map<String, dynamic>) {
        AppLogger.error('Invalid document data for new appointment: ${doc.id}', tag: 'AdminAppointmentNotificationIntegrator');
        return;
      }
      
      final appointment = AppointmentBooking.fromMap(data, doc.id);
      final docId = doc.id;
      
      // Create unique event key to prevent duplicate notifications
      final eventKey = '${docId}_created';
      
      // Check if we already notified for this event
      if (_notifiedEvents.contains(eventKey)) {
        print('⚠️ Already notified for appointment creation: $docId');
        return;
      }
      
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
              ? 'Emergency Appointment Request'
              : 'New Appointment Request',
          message: '$ownerName requested an appointment for $petName on $appointmentTime for ${appointment.serviceName}',
          priority: priority,
          notificationSubtype: 'created', // Deterministic ID for duplicate prevention
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
        
        // Mark this event as notified
        _notifiedEvents.add(eventKey);
        
        print('✅ Created admin notification for new appointment: ${doc.id}');
      }
    } catch (e) {
      AppLogger.error('Error handling new appointment notification: $e', tag: 'AdminAppointmentNotificationIntegrator');
    }
  }

  /// Handle appointment status updates
  static Future<void> _handleAppointmentUpdate(DocumentSnapshot doc) async {
    try {
      final data = doc.data();
      if (data == null || data is! Map<String, dynamic>) {
        AppLogger.error('Invalid document data for appointment update: ${doc.id}', tag: 'AdminAppointmentNotificationIntegrator');
        return;
      }
      
      final appointment = AppointmentBooking.fromMap(data, doc.id);
      final docId = doc.id;
      
      // Get pet and user details (common to all status updates)
      final petData = await _getPetData(appointment.petId);
      final userData = await _getUserData(appointment.userId);
      
      String petName = petData?['name'] ?? petData?['petName'] ?? 'Pet';
      String ownerName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
      if (ownerName.isEmpty) {
        ownerName = userData?['username'] ?? 'Pet Owner';
      }
      
      final appointmentTime = '${_formatDate(appointment.appointmentDate)} at ${appointment.appointmentTime}';
      
      // Handle different status updates with appropriate notifications
      
      if (appointment.status == AppointmentStatus.cancelled && appointment.cancelReason != null) {
        // Create unique event key to prevent duplicate notifications
        final eventKey = '${docId}_cancelled';
        
        // Check if we already notified for this event
        if (_notifiedEvents.contains(eventKey)) {
          print('⚠️ Already notified for appointment cancellation: $docId');
          return;
        }
        
        print('🔔 Processing appointment cancellation: $docId - ${appointment.cancelReason}');
        
        // Determine if this was cancelled by admin or user
        // Check for admin cancellation indicators in the data
        final cancelledAt = data['cancelledAt'] as Timestamp?;
        
        String actionBy = 'user'; // Default assumption
        
        // Check if cancellation reason suggests admin action
        final reason = appointment.cancelReason?.toLowerCase() ?? '';
        if (reason.contains('admin') || 
            reason.contains('clinic') || 
            reason.contains('management') ||
            reason.contains('staff') ||
            reason.contains('system') ||
            reason.contains('rejected by')) {
          actionBy = 'admin';
        }
        
        await _createAppointmentStatusNotification(
          appointmentId: appointment.id ?? doc.id,
          status: AppointmentStatus.cancelled,
          petName: petName,
          ownerName: ownerName,
          appointmentTime: appointmentTime,
          serviceName: appointment.serviceName,
          reason: appointment.cancelReason,
          actionBy: actionBy,
          additionalMetadata: {
            'petId': appointment.petId,
            'appointmentDate': appointment.appointmentDate.toIso8601String(),
            'cancelledAt': cancelledAt?.toDate().toIso8601String(),
          },
        );
        
        // Create transaction notification for cancellation
        // Check if there's a cancellation fee or refund
        final paymentAmount = data['paymentAmount'] as num?;
        final refundAmount = data['refundAmount'] as num?;
        final cancellationFee = data['cancellationFee'] as num?;
        
        if (paymentAmount != null && paymentAmount > 0) {
          String transactionMessage;
          String transactionTitle;
          
          if (refundAmount != null && refundAmount > 0) {
            transactionTitle = 'Refund Processed';
            transactionMessage = 'Refund of ₱${refundAmount.toStringAsFixed(2)} processed for $ownerName\'s cancelled appointment for $petName';
            if (cancellationFee != null && cancellationFee > 0) {
              transactionMessage += ' (Cancellation fee: ₱${cancellationFee.toStringAsFixed(2)})';
            }
          } else if (cancellationFee != null && cancellationFee > 0) {
            transactionTitle = 'Cancellation Fee Applied';
            transactionMessage = 'Cancellation fee of ₱${cancellationFee.toStringAsFixed(2)} applied to $ownerName\'s cancelled appointment for $petName';
          } else {
            transactionTitle = 'Payment Cancelled';
            transactionMessage = 'Payment of ₱${paymentAmount.toStringAsFixed(2)} cancelled for $ownerName\'s appointment for $petName';
          }
          
          await _notificationService.createTransactionNotification(
            transactionId: 'cancel_${appointment.id ?? doc.id}',
            title: transactionTitle,
            message: transactionMessage,
            priority: AdminNotificationPriority.medium,
            metadata: {
              'appointmentId': appointment.id ?? doc.id,
              'petName': petName,
              'ownerName': ownerName,
              'originalAmount': paymentAmount,
              'refundAmount': refundAmount,
              'cancellationFee': cancellationFee,
              'transactionType': 'cancellation',
              'userId': appointment.userId,
            },
          );
        }
        
        // Mark this event as notified
        _notifiedEvents.add(eventKey);
        
        print('✅ Created admin notification for cancelled appointment: ${doc.id}');
      }
      
      // Handle appointment confirmation
      if (appointment.status == AppointmentStatus.confirmed) {
        // Create unique event key to prevent duplicate notifications
        final eventKey = '${docId}_confirmed';
        
        // Check if we already notified for this event
        if (_notifiedEvents.contains(eventKey)) {
          print('⚠️ Already notified for appointment confirmation: $docId');
          return;
        }
        
        // Get pet and user details
        final petData = await _getPetData(appointment.petId);
        final userData = await _getUserData(appointment.userId);
        
        String petName = petData?['name'] ?? petData?['petName'] ?? 'Pet';
        String ownerName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
        if (ownerName.isEmpty) {
          ownerName = userData?['username'] ?? 'Pet Owner';
        }
        
        final appointmentTime = '${_formatDate(appointment.appointmentDate)} at ${appointment.appointmentTime}';
        
        await _createAppointmentStatusNotification(
          appointmentId: appointment.id ?? doc.id,
          status: AppointmentStatus.confirmed,
          petName: petName,
          ownerName: ownerName,
          appointmentTime: appointmentTime,
          serviceName: appointment.serviceName,
          actionBy: 'admin',
          additionalMetadata: {
            'petId': appointment.petId,
            'appointmentDate': appointment.appointmentDate.toIso8601String(),
            'confirmedAt': DateTime.now().toIso8601String(),
          },
        );
        
        // Mark this event as notified
        _notifiedEvents.add(eventKey);
        
        print('✅ Created admin notification for confirmed appointment: ${doc.id}');
      }

      // Handle appointment completion
      if (appointment.status == AppointmentStatus.completed) {
        // Create unique event key to prevent duplicate notifications
        final eventKey = '${docId}_completed';
        
        // Check if we already notified for this event
        if (_notifiedEvents.contains(eventKey)) {
          print('⚠️ Already notified for appointment completion: $docId');
          return;
        }
        
        await _createAppointmentStatusNotification(
          appointmentId: appointment.id ?? doc.id,
          status: AppointmentStatus.completed,
          petName: petName,
          ownerName: ownerName,
          appointmentTime: appointmentTime,
          serviceName: appointment.serviceName,
          actionBy: 'admin',
          additionalMetadata: {
            'petId': appointment.petId,
            'appointmentDate': appointment.appointmentDate.toIso8601String(),
            'completedAt': DateTime.now().toIso8601String(),
          },
        );
        
        // Mark this event as notified
        _notifiedEvents.add(eventKey);
        
        print('✅ Created admin notification for completed appointment: ${doc.id}');
      }
      
      if (appointment.status == AppointmentStatus.rescheduled && appointment.rescheduleReason != null) {
        // Skip notifications for appointments that existed during initial load
        // These are historical data that user already knows about
        if (_initialLoadAppointments.contains(docId)) {
          print('⚠️ Skipping notification for initial load appointment reschedule: $docId');
          return;
        }
        
        // Create unique event key to prevent duplicate notifications
        final eventKey = '${docId}_rescheduled_${appointment.appointmentDate.millisecondsSinceEpoch}';
        
        // Check if we already notified for this event
        if (_notifiedEvents.contains(eventKey)) {
          print('⚠️ Already notified for appointment reschedule: $docId');
          return;
        }
        
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
          title: 'Appointment Rescheduled',
          message: '$ownerName rescheduled the appointment for $petName to $appointmentTime. Reason: ${appointment.rescheduleReason}',
          priority: AdminNotificationPriority.medium,
          notificationSubtype: 'rescheduled_${appointment.appointmentDate.millisecondsSinceEpoch}', // Include date for multiple reschedules
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
        
        // Create transaction notification if there's a reschedule fee
        final rescheduleFee = data['rescheduleFee'] as num?;
        
        if (rescheduleFee != null && rescheduleFee > 0) {
          await _notificationService.createTransactionNotification(
            transactionId: 'reschedule_${appointment.id ?? doc.id}',
            title: 'Reschedule Fee Applied',
            message: 'Reschedule fee of ₱${rescheduleFee.toStringAsFixed(2)} applied to $ownerName\'s appointment for $petName',
            priority: AdminNotificationPriority.low,
            metadata: {
              'appointmentId': appointment.id ?? doc.id,
              'petName': petName,
              'ownerName': ownerName,
              'rescheduleFee': rescheduleFee,
              'newAppointmentDate': appointment.appointmentDate.toIso8601String(),
              'newAppointmentTime': appointment.appointmentTime,
              'transactionType': 'reschedule_fee',
              'userId': appointment.userId,
            },
          );
        }
        
        // Mark this event as notified
        _notifiedEvents.add(eventKey);
        
        print('✅ Created admin notification for rescheduled appointment: ${doc.id}');
      }
    } catch (e) {
      AppLogger.error('Error handling appointment update notification: $e', tag: 'AdminAppointmentNotificationIntegrator');
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

  /// Helper method to create comprehensive appointment status notifications
  static Future<void> _createAppointmentStatusNotification({
    required String appointmentId,
    required AppointmentStatus status,
    required String petName,
    required String ownerName,
    required String appointmentTime,
    required String serviceName,
    String? reason,
    String? actionBy = 'user',
    Map<String, dynamic>? additionalMetadata,
  }) async {
    String title;
    String message;
    String notificationSubtype;
    AdminNotificationPriority priority = AdminNotificationPriority.medium;

    switch (status) {
      case AppointmentStatus.confirmed:
        title = 'Appointment Confirmed';
        message = actionBy == 'admin' 
            ? 'You confirmed the appointment for $petName (owner: $ownerName) scheduled for $appointmentTime'
            : 'Appointment for $petName (owner: $ownerName) has been confirmed for $appointmentTime';
        notificationSubtype = actionBy == 'admin' ? 'admin_confirmed' : 'confirmed';
        break;
      case AppointmentStatus.cancelled:
        if (actionBy == 'admin') {
          title = 'Appointment Cancelled by Admin';
          message = 'You cancelled the appointment for $petName (owner: $ownerName) scheduled for $appointmentTime';
        } else {
          title = 'Appointment Cancelled by User'; 
          message = '$ownerName cancelled their appointment for $petName scheduled for $appointmentTime';
        }
        if (reason != null) {
          message += '. Reason: $reason';
        }
        notificationSubtype = actionBy == 'admin' ? 'admin_cancelled' : 'user_cancelled';
        break;
      case AppointmentStatus.completed:
        title = 'Appointment Completed';
        message = 'Appointment for $petName (owner: $ownerName) scheduled for $appointmentTime has been completed';
        notificationSubtype = 'completed';
        priority = AdminNotificationPriority.low;
        break;
      case AppointmentStatus.rescheduled:
        title = 'Appointment Rescheduled';
        message = '$ownerName rescheduled the appointment for $petName to $appointmentTime';
        if (reason != null) {
          message += '. Reason: $reason';
        }
        notificationSubtype = 'rescheduled';
        break;
      default:
        return; // Don't create notifications for other statuses
    }

    final metadata = <String, dynamic>{
      'petName': petName,
      'ownerName': ownerName,
      'appointmentTime': appointmentTime,
      'serviceName': serviceName,
      'status': status.name,
      'actionBy': actionBy,
      'actionType': notificationSubtype,
      'reason': reason,
      'actionAt': DateTime.now().toIso8601String(),
      ...(additionalMetadata ?? {}),
    };

    await _notificationService.createAppointmentNotification(
      appointmentId: appointmentId,
      title: title,
      message: message,
      priority: priority,
      notificationSubtype: notificationSubtype,
      metadata: metadata,
    );
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
      title: 'Appointment Confirmed by Admin',
      message: 'You confirmed the appointment for $petName (owner: $ownerName) scheduled for $appointmentTimeStr - $serviceName',
      priority: AdminNotificationPriority.medium,
      notificationSubtype: 'admin_confirmed',
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'serviceName': serviceName,
        'status': 'confirmed',
        'actionType': 'admin_confirmed',
        'actionBy': 'admin',
        'actionAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Create notification when admin rejects an appointment
  static Future<void> notifyAppointmentRejected({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String serviceName,
    required String rejectionReason,
  }) async {
    final appointmentTimeStr = '${_formatDate(appointmentDate)} at $appointmentTime';
    
    await _notificationService.createAppointmentNotification(
      appointmentId: appointmentId,
      title: 'Appointment Rejected by Admin',
      message: 'You rejected the appointment for $petName (owner: $ownerName) scheduled for $appointmentTimeStr. Reason: $rejectionReason',
      priority: AdminNotificationPriority.medium,
      notificationSubtype: 'admin_rejected',
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'serviceName': serviceName,
        'status': 'rejected',
        'actionType': 'admin_rejected',
        'actionBy': 'admin',
        'rejectionReason': rejectionReason,
        'actionAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Create notification when admin cancels an appointment
  static Future<void> notifyAppointmentCancelledByAdmin({
    required String appointmentId,
    required String petName,
    required String ownerName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String serviceName,
    String? cancellationReason,
  }) async {
    final appointmentTimeStr = '${_formatDate(appointmentDate)} at $appointmentTime';
    String reasonText = cancellationReason != null ? '. Reason: $cancellationReason' : '';
    
    await _notificationService.createAppointmentNotification(
      appointmentId: appointmentId,
      title: '🚫 Appointment Cancelled by Admin',
      message: 'You cancelled the appointment for $petName (owner: $ownerName) scheduled for $appointmentTimeStr$reasonText',
      priority: AdminNotificationPriority.medium,
      notificationSubtype: 'admin_cancelled',
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        'serviceName': serviceName,
        'status': 'cancelled',
        'actionType': 'admin_cancelled',
        'actionBy': 'admin',
        'cancellationReason': cancellationReason,
        'actionAt': DateTime.now().toIso8601String(),
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
      title = 'Appointment Starting Soon';
      message = 'Appointment for $petName (owner: $ownerName) starts in $hoursUntil hour(s) - $serviceName';
      priority = AdminNotificationPriority.high;
    } else if (hoursUntil <= 24) {
      title = 'Appointment Tomorrow';
      message = 'Reminder: Appointment for $petName (owner: $ownerName) is scheduled for tomorrow at $appointmentTime - $serviceName';
      priority = AdminNotificationPriority.medium;
    } else {
      title = 'Upcoming Appointment';
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
      title: 'Missed Appointment',
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