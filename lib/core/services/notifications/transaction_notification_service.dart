import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Global transaction monitoring service
/// Monitors appointment bookings and creates real-time notifications
/// for status changes: confirmed, completed, rejected, rescheduled, etc.
class TransactionNotificationService {
  static final TransactionNotificationService _instance = TransactionNotificationService._internal();
  factory TransactionNotificationService() => _instance;
  TransactionNotificationService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream subscriptions for monitoring
  StreamSubscription<QuerySnapshot>? _appointmentSubscription;
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  
  // Track known transactions to detect changes
  Map<String, String> _knownAppointmentStatuses = {};
  Map<String, String> _knownMessageStatuses = {};
  
  String? _currentUserId;
  bool _isInitialized = false;

  /// Initialize transaction monitoring for a user
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      return; // Already initialized for this user
    }

    // Clean up previous user's listeners
    await dispose();
    
    _currentUserId = userId;
    
        // Setup real-time listeners for different transaction types
    _setupAppointmentListener(userId);
    _setupMessageListener(userId);
    // Assessment listener disabled by user request
    
    _isInitialized = true;
    debugPrint('🔔 Transaction notification service initialized for user: $userId');
  }

  /// Monitor appointment status changes
  void _setupAppointmentListener(String userId) {
    _appointmentSubscription = _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        _handleAppointmentChanges(snapshot, userId);
      },
      onError: (error) {
        debugPrint('❌ Appointment listener error: $error');
      },
    );
  }

  /// Monitor message/conversation changes
  void _setupMessageListener(String userId) {
    _messageSubscription = _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
      (snapshot) {
        _handleMessageChanges(snapshot, userId);
      },
      onError: (error) {
        debugPrint('❌ Message listener error: $error');
      },
    );
  }



  /// Handle appointment status changes
  void _handleAppointmentChanges(QuerySnapshot snapshot, String userId) {
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final appointmentId = doc.id;
      final status = data['status']?.toString() ?? 'unknown';
      final previousStatus = _knownAppointmentStatuses[appointmentId];
      
      // If this is a status change (not first load)
      if (previousStatus != null && previousStatus != status) {
        _createAppointmentNotification(appointmentId, status, data, userId);
      }
      
      // Update known status
      _knownAppointmentStatuses[appointmentId] = status;
    }
  }

  /// Handle message/conversation changes
  void _handleMessageChanges(QuerySnapshot snapshot, String userId) {
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final conversationId = doc.id;
      final lastMessageSenderId = data['lastMessageSenderId']?.toString();
      final updatedAt = data['updatedAt'] as Timestamp?;
      
      // Only create notification if message is from clinic (not from user)
      if (lastMessageSenderId != null && 
          lastMessageSenderId != userId && 
          updatedAt != null) {
        
        final statusKey = '${conversationId}_${updatedAt.millisecondsSinceEpoch}';
        final previousStatus = _knownMessageStatuses[conversationId];
        
        // If this is a new message (different timestamp)
        if (previousStatus != statusKey) {
          _createMessageNotification(conversationId, data, userId);
          _knownMessageStatuses[conversationId] = statusKey;
        }
      }
    }
  }



  /// Create notification for appointment status changes
  Future<void> _createAppointmentNotification(
    String appointmentId, 
    String status, 
    Map<String, dynamic> data,
    String userId
  ) async {
    try {
      String title = 'Appointment Update';
      String message = 'Your appointment status has been updated';
      String? actionUrl = '/appointments/details/$appointmentId';

      // Customize notification based on status
      switch (status.toLowerCase()) {
        case 'confirmed':
          title = 'Appointment Confirmed';
          message = 'Your appointment has been confirmed by the clinic';
          break;
        case 'completed':
          title = 'Appointment Completed';
          message = 'Your appointment has been completed';
          break;
        case 'rejected':
        case 'declined':
          title = 'Appointment Declined';
          message = 'Your appointment request has been declined';
          break;
        case 'rescheduled':
          title = 'Appointment Rescheduled';
          message = 'Your appointment has been rescheduled';
          break;
        case 'cancelled':
          title = 'Appointment Cancelled';
          message = 'Your appointment has been cancelled';
          break;
        default:
          title = 'Appointment Updated';
          message = 'Your appointment status: ${status.toUpperCase()}';
      }

      // Add pet name if available
      final petName = data['petName']?.toString();
      if (petName != null && petName.isNotEmpty) {
        message = message.replaceAll('Your', '$petName\'s');
      }

      // Create notification in Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'category': 'appointment',
        'priority': 'high',
        'isRead': false,
        'actionUrl': actionUrl,
        'actionLabel': 'View Details',
        'metadata': {
          'appointmentId': appointmentId,
          'status': status,
          'petName': petName,
          'type': 'appointment_status_change',
        },
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      });

      debugPrint('📋 Created appointment notification: $title');
    } catch (e) {
      debugPrint('❌ Error creating appointment notification: $e');
    }
  }

  /// Create notification for new messages
  Future<void> _createMessageNotification(
    String conversationId, 
    Map<String, dynamic> data,
    String userId
  ) async {
    try {
      final clinicName = data['clinicName']?.toString() ?? 'Clinic';
      
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'New Message',
        'message': 'New message from $clinicName',
        'category': 'message',
        'priority': 'medium',
        'isRead': false,
        'actionUrl': '/messaging',
        'actionLabel': 'View Message',
        'metadata': {
          'conversationId': conversationId,
          'clinicName': clinicName,
          'type': 'new_message',
        },
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      });

      debugPrint('💬 Created message notification from: $clinicName');
    } catch (e) {
      debugPrint('❌ Error creating message notification: $e');
    }
  }



  /// Dispose all listeners
  Future<void> dispose() async {
    await _appointmentSubscription?.cancel();
    await _messageSubscription?.cancel();
    
    _appointmentSubscription = null;
    _messageSubscription = null;
    
    _knownAppointmentStatuses.clear();
    _knownMessageStatuses.clear();
    
    _currentUserId = null;
    _isInitialized = false;
    
    debugPrint('🧹 Transaction notification service disposed');
  }

  /// Get current monitoring status
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
}