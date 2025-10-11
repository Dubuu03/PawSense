import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/admin/admin_notification_model.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  StreamController<List<AdminNotificationModel>>? _notificationsController;
  
  List<AdminNotificationModel> _notifications = [];
  String? _currentClinicId;

  // Getter for notifications controller (creates if null)
  StreamController<List<AdminNotificationModel>> get _controller {
    _notificationsController ??= StreamController<List<AdminNotificationModel>>.broadcast();
    return _notificationsController!;
  }

  // Stream for notifications
  Stream<List<AdminNotificationModel>> get notificationsStream => _controller.stream;
  
  // Get current notifications list
  List<AdminNotificationModel> get notifications => List.unmodifiable(_notifications);
  
  // Get unread count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  // Get recent notifications (last 24 hours)
  List<AdminNotificationModel> get recentNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((n) => n.timestamp.isAfter(yesterday)).toList();
  }

  /// Initialize the service and start listening for notifications
  Future<void> initialize() async {
    print('🔄 AdminNotificationService.initialize() called');
    
    // Skip if already initialized
    if (_notificationSubscription != null && _currentClinicId != null) {
      print('✅ AdminNotificationService already initialized with clinicId: $_currentClinicId');
      return;
    }
    
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('⚠️ No current user found during initialization');
        return;
      }

      // Get clinic ID for admin users
      if (currentUser.role == 'admin') {
        final clinic = await _authService.getUserClinic();
        _currentClinicId = clinic?.id;
        print('🏥 Got clinic ID for admin: $_currentClinicId');
      } else if (currentUser.role == 'super_admin') {
        // Super admin can see all notifications or handle differently
        _currentClinicId = 'all';
        print('👑 Super admin mode - clinic ID set to: $_currentClinicId');
      }

      if (_currentClinicId != null) {
        await _startListeningToNotifications();
      } else {
        print('⚠️ No clinic ID found - cannot start listening');
      }
    } catch (e) {
      print('❌ Error initializing AdminNotificationService: $e');
    }
  }

  /// Start listening to real-time notifications
  Future<void> _startListeningToNotifications() async {
    if (_currentClinicId == null) {
      print('⚠️ Cannot start listening: _currentClinicId is null');
      return;
    }

    try {
      print('🔍 Starting notification listener for clinicId: $_currentClinicId');
      
      // Use only clinicId filter without limit to avoid composite index requirement
      // Real-time listener: Only ONE active connection to Firestore
      // This is the most efficient way - no polling, no multiple queries
      Query query = _firestore
          .collection('admin_notifications')
          .where('clinicId', isEqualTo: _currentClinicId);

      _notificationSubscription = query.snapshots().listen(
        (snapshot) {
          print('📡 Received ${snapshot.docs.length} notification documents from Firestore');
          
          // Parse only if needed (use document changes for efficiency)
          // Only process added/modified/removed documents
          if (snapshot.docChanges.isNotEmpty) {
            for (var change in snapshot.docChanges) {
              final notification = AdminNotificationModel.fromFirestore(change.doc);
              
              switch (change.type) {
                case DocumentChangeType.added:
                case DocumentChangeType.modified:
                  // Update or add notification
                  _notifications.removeWhere((n) => n.id == notification.id);
                  _notifications.add(notification);
                  break;
                case DocumentChangeType.removed:
                  // Remove notification
                  _notifications.removeWhere((n) => n.id == notification.id);
                  break;
              }
            }
            
            // Sort by timestamp descending (most recent first)
            _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            // Keep last 100 for performance (reduced from unlimited)
            if (_notifications.length > 100) {
              _notifications = _notifications.take(100).toList();
            }
            
            print('🚀 Emitting ${_notifications.length} notifications to stream');
            _controller.add(_notifications);
            print('📱 Updated notifications: ${_notifications.length} total, ${unreadCount} unread');
            
            // Debug: Print first few notification titles
            if (_notifications.isNotEmpty) {
              print('📋 First few notifications:');
              for (int i = 0; i < _notifications.length && i < 3; i++) {
                print('  - ${_notifications[i].title} (read: ${_notifications[i].isRead})');
              }
            } else {
              print('📋 No notifications found');
            }
          }
        },
        onError: (error) {
          print('❌ Error listening to notifications: $error');
        },
      );
    } catch (e) {
      print('❌ Error starting notification listener: $e');
    }
  }

  /// Create a new notification (prevents duplicates)
  Future<void> createNotification(AdminNotificationModel notification) async {
    try {
      // Check if notification already exists to prevent duplicates
      final docRef = _firestore.collection('admin_notifications').doc(notification.id);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        print('⚠️ Notification already exists: ${notification.id}');
        return;
      }
      
      await docRef.set(notification.toFirestore());
      print('✅ Created notification: ${notification.title}');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      print('✅ Marked notification as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentClinicId == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead);

      for (final notification in unreadNotifications) {
        final docRef = _firestore.collection('admin_notifications').doc(notification.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();
      print('✅ Marked all notifications as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .delete();
      
      print('✅ Deleted notification: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Clear old notifications (older than 30 days)
  Future<void> clearOldNotifications() async {
    if (_currentClinicId == null) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final query = await _firestore
          .collection('admin_notifications')
          .where('clinicId', isEqualTo: _currentClinicId)
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Cleared ${query.docs.length} old notifications');
    } catch (e) {
      print('❌ Error clearing old notifications: $e');
    }
  }

  /// Create appointment-related notifications
  Future<void> createAppointmentNotification({
    required String appointmentId,
    required String title,
    required String message,
    AdminNotificationPriority priority = AdminNotificationPriority.medium,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentClinicId == null) {
      print('⚠️ Cannot create notification: _currentClinicId is null');
      return;
    }

    final notification = AdminNotificationModel.createAppointmentNotification(
      id: 'appt_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      clinicId: _currentClinicId!,
      appointmentId: appointmentId,
      priority: priority,
      metadata: metadata,
    );

    print('📝 Creating notification with clinicId: $_currentClinicId');
    await createNotification(notification);
  }

  /// Create message-related notifications
  Future<void> createMessageNotification({
    required String messageId,
    required String title,
    required String message,
    String? conversationId,
    String? senderId,
    String? senderName,
  }) async {
    if (_currentClinicId == null) return;

    final notification = AdminNotificationModel.createMessageNotification(
      id: 'msg_${messageId}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      clinicId: _currentClinicId!,
      messageId: messageId,
      priority: AdminNotificationPriority.medium,
      metadata: {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
      },
    );

    await createNotification(notification);
  }

  /// Create emergency notifications
  Future<void> createEmergencyNotification({
    required String title,
    required String message,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentClinicId == null) return;

    final notification = AdminNotificationModel.createEmergencyNotification(
      id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      clinicId: _currentClinicId!,
      relatedId: relatedId,
      metadata: metadata,
    );

    await createNotification(notification);
  }

  /// Create system notifications
  Future<void> createSystemNotification({
    required String title,
    required String message,
    AdminNotificationPriority priority = AdminNotificationPriority.low,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentClinicId == null) return;

    final notification = AdminNotificationModel(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: AdminNotificationType.system,
      priority: priority,
      timestamp: DateTime.now(),
      clinicId: _currentClinicId!,
      metadata: metadata,
    );

    await createNotification(notification);
  }

  /// Get notifications by type
  List<AdminNotificationModel> getNotificationsByType(AdminNotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get notifications by priority
  List<AdminNotificationModel> getNotificationsByPriority(AdminNotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).toList();
  }

  /// Get urgent notifications
  List<AdminNotificationModel> get urgentNotifications {
    return getNotificationsByPriority(AdminNotificationPriority.urgent);
  }

  /// Reset the service (for testing or cleanup)
  void reset() {
    print('🔄 Resetting AdminNotificationService');
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notifications.clear();
    _currentClinicId = null;
  }

  /// Dispose the service (should only be called on app shutdown)
  void dispose() {
    print('🧹 Disposing AdminNotificationService');
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    if (_notificationsController != null && !_notificationsController!.isClosed) {
      _notificationsController!.close();
      _notificationsController = null;
    }
    _notifications.clear();
    _currentClinicId = null;
  }

  /// Quick notification helpers for common scenarios
  
  /// New appointment booked
  Future<void> notifyNewAppointment(String appointmentId, String petName, String ownerName, String appointmentTime) async {
    await createAppointmentNotification(
      appointmentId: appointmentId,
      title: 'New Appointment Booked',
      message: '$ownerName booked an appointment for $petName at $appointmentTime',
      priority: AdminNotificationPriority.medium,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentTime': appointmentTime,
      },
    );
  }

  /// Appointment cancelled
  Future<void> notifyAppointmentCancelled(String appointmentId, String petName, String ownerName, String appointmentTime) async {
    await createAppointmentNotification(
      appointmentId: appointmentId,
      title: 'Appointment Cancelled',
      message: '$ownerName cancelled the appointment for $petName scheduled at $appointmentTime',
      priority: AdminNotificationPriority.medium,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'appointmentTime': appointmentTime,
        'status': 'cancelled',
      },
    );
  }

  /// Emergency appointment request
  Future<void> notifyEmergencyAppointment(String appointmentId, String petName, String ownerName, String issue) async {
    await createAppointmentNotification(
      appointmentId: appointmentId,
      title: 'Emergency Appointment Request',
      message: '$ownerName requested emergency care for $petName: $issue',
      priority: AdminNotificationPriority.urgent,
      metadata: {
        'petName': petName,
        'ownerName': ownerName,
        'issue': issue,
        'isEmergency': true,
      },
    );
  }

  /// New message received
  Future<void> notifyNewMessage(String messageId, String senderName, String messagePreview, {String? conversationId}) async {
    await createMessageNotification(
      messageId: messageId,
      title: 'New Message',
      message: '$senderName: $messagePreview',
      conversationId: conversationId,
      senderName: senderName,
    );
  }
}