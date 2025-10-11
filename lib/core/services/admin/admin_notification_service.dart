import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/admin/admin_notification_model.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';
import 'package:pawsense/core/utils/app_logger.dart';

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
  
  // Debouncing and deduplication
  Timer? _emissionDebounceTimer;
  String? _lastEmittedDataHash;
  DateTime? _lastEmissionTime;
  static const Duration _minEmissionInterval = Duration(seconds: 1);

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
    AppLogger.notification('AdminNotificationService.initialize() called');
    
    // Skip if already initialized
    if (_notificationSubscription != null && _currentClinicId != null) {
      AppLogger.notification('AdminNotificationService already initialized with clinicId: $_currentClinicId');
      return;
    }
    
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        AppLogger.warning('No current user found during initialization', tag: 'AdminNotificationService');
        return;
      }

      // Get clinic ID for admin users
      if (currentUser.role == 'admin') {
        _currentClinicId = currentUser.uid; // For admin users, their UID is their clinic ID
        AppLogger.info('Got clinic ID for admin: $_currentClinicId');
        
        // Start listening for notifications
        await _startListeningToNotifications();
      } else if (currentUser.role == 'super_admin') {
        // For testing - super admin can access all clinics, use a default
        _currentClinicId = 'super_admin_test_clinic'; 
        AppLogger.info('Super admin mode - clinic ID set to: $_currentClinicId');
        
        // Start listening for notifications
        await _startListeningToNotifications();
      } else {
        // For non-admin users, we don't start the notification service
        AppLogger.warning('No clinic ID found - cannot start listening', tag: 'AdminNotificationService');
        return;
      }
      
    } catch (e) {
      AppLogger.error('Error initializing AdminNotificationService', error: e, tag: 'AdminNotificationService');
    }
  }

  /// Start listening to real-time notifications
  Future<void> _startListeningToNotifications() async {
    if (_currentClinicId == null) {
      AppLogger.warning('Cannot start listening: _currentClinicId is null', tag: 'AdminNotificationService');
      return;
    }

    try {
      AppLogger.notification('Starting notification listener for clinicId: $_currentClinicId');
      
      // Use only clinicId filter without limit to avoid composite index requirement
      // Real-time listener: Only ONE active connection to Firestore
      // This is the most efficient way - no polling, no multiple queries
      Query query = _firestore
          .collection('admin_notifications')
          .where('clinicId', isEqualTo: _currentClinicId);

      _notificationSubscription = query.snapshots().listen(
        (snapshot) {
          // Only log if there are actual changes
          if (snapshot.docChanges.isNotEmpty) {
            AppLogger.notification('Processing ${snapshot.docChanges.length} notification changes');
            
            bool hasActualChanges = false;
            
            for (var change in snapshot.docChanges) {
              final notification = AdminNotificationModel.fromFirestore(change.doc);
              
              switch (change.type) {
                case DocumentChangeType.added:
                case DocumentChangeType.modified:
                  // Check if this is actually a new/changed notification
                  final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
                  if (existingIndex == -1 || 
                      _notifications[existingIndex].isRead != notification.isRead ||
                      _notifications[existingIndex].title != notification.title) {
                    _notifications.removeWhere((n) => n.id == notification.id);
                    _notifications.add(notification);
                    hasActualChanges = true;
                  }
                  break;
                case DocumentChangeType.removed:
                  final originalLength = _notifications.length;
                  _notifications.removeWhere((n) => n.id == notification.id);
                  if (_notifications.length < originalLength) {
                    hasActualChanges = true;
                  }
                  break;
              }
            }
            
            // Only emit if there were actual changes
            if (hasActualChanges) {
              // Sort by timestamp descending (most recent first)
              _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              
              // Keep last 100 for performance
              if (_notifications.length > 100) {
                _notifications = _notifications.take(100).toList();
              }
              
              // Use debounced emission to prevent spam
              _debouncedEmit();
            } else {
              AppLogger.notification('No actual changes detected - skipping emission');
            }
          }
        },
        onError: (error) {
          AppLogger.error('Error listening to notifications', error: error, tag: 'AdminNotificationService');
        },
      );
    } catch (e) {
      AppLogger.error('Error starting notification listener', error: e, tag: 'AdminNotificationService');
    }
  }
  
  /// Debounced emission to prevent spam
  void _debouncedEmit() {
    // Cancel previous timer
    _emissionDebounceTimer?.cancel();
    
    // Set up debounced emission
    _emissionDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _emitIfChanged();
    });
  }
  
  /// Emit notifications only if data has changed and rate limit respected
  void _emitIfChanged() {
    final now = DateTime.now();
    
    // Generate hash of current data
    final currentDataHash = _notifications.map((n) => '${n.id}_${n.isRead}').join(',');
    
    // Skip if data hasn't changed
    if (currentDataHash == _lastEmittedDataHash) {
      AppLogger.notification('Skipping emission - data unchanged');
      return;
    }
    
    // Rate limiting - don't emit more than once per second
    if (_lastEmissionTime != null && 
        now.difference(_lastEmissionTime!) < _minEmissionInterval) {
      AppLogger.notification('Rate limiting emission');
      return;
    }
    
    // Emit the data
    _lastEmittedDataHash = currentDataHash;
    _lastEmissionTime = now;
    
    AppLogger.notification('Emitting ${_notifications.length} notifications to stream');
    _controller.add(_notifications);
    AppLogger.info('Updated notifications: ${_notifications.length} total, ${unreadCount} unread');
  }

  /// Create a new notification (prevents duplicates)
  Future<void> createNotification(AdminNotificationModel notification) async {
    try {
      // Check if notification already exists to prevent duplicates
      final docRef = _firestore.collection('admin_notifications').doc(notification.id);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        AppLogger.warning('Notification already exists: ${notification.id}', tag: 'AdminNotificationService');
        return;
      }
      
      await docRef.set(notification.toFirestore());
      AppLogger.success('Created notification: ${notification.title}');
    } catch (e) {
      AppLogger.error('Error creating notification', error: e, tag: 'AdminNotificationService');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      AppLogger.success('Marked notification as read: $notificationId');
    } catch (e) {
      AppLogger.error('Error marking notification as read', error: e, tag: 'AdminNotificationService');
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
    String? notificationSubtype, // e.g., 'created', 'cancelled', 'rescheduled'
  }) async {
    if (_currentClinicId == null) {
      print('⚠️ Cannot create notification: _currentClinicId is null');
      return;
    }

    // Create deterministic ID based on appointment and event type
    // This prevents duplicates even if called multiple times
    String notificationId;
    if (notificationSubtype != null) {
      // For specific events, use subtype in ID (no timestamp)
      notificationId = 'appt_${appointmentId}_$notificationSubtype';
    } else {
      // For generic notifications, include timestamp
      notificationId = 'appt_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}';
    }

    final notification = AdminNotificationModel.createAppointmentNotification(
      id: notificationId,
      title: title,
      message: message,
      clinicId: _currentClinicId!,
      appointmentId: appointmentId,
      priority: priority,
      metadata: metadata,
    );

    print('📝 Creating notification with ID: $notificationId and clinicId: $_currentClinicId');
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

  /// Create transaction-related notifications
  Future<void> createTransactionNotification({
    required String transactionId,
    required String title,
    required String message,
    AdminNotificationPriority priority = AdminNotificationPriority.medium,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentClinicId == null) {
      print('⚠️ Cannot create transaction notification: _currentClinicId is null');
      return;
    }

    final notification = AdminNotificationModel(
      id: 'txn_${transactionId}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: AdminNotificationType.transaction,
      priority: priority,
      timestamp: DateTime.now(),
      clinicId: _currentClinicId!,
      relatedId: transactionId,
      metadata: metadata,
    );

    print('💳 Creating transaction notification: $title');
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
    AppLogger.info('Disposing AdminNotificationService');
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _emissionDebounceTimer?.cancel();
    _emissionDebounceTimer = null;
    if (_notificationsController != null && !_notificationsController!.isClosed) {
      _notificationsController!.close();
      _notificationsController = null;
    }
    _notifications.clear();
    _currentClinicId = null;
    _lastEmittedDataHash = null;
    _lastEmissionTime = null;
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