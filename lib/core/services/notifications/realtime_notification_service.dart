import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/notifications/notification_model.dart';
import '../../widgets/user/alerts/alert_item.dart';
import '../../utils/notification_helper.dart';

/// Real-time notification service with minimal database reads
/// Uses Firestore real-time listeners for instant updates
/// Implements best practices for performance and battery life
class RealTimeNotificationService {
  static final RealTimeNotificationService _instance = RealTimeNotificationService._internal();
  factory RealTimeNotificationService() => _instance;
  RealTimeNotificationService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  // Single stream controller for all notification updates
  final StreamController<List<AlertData>> _notificationsController = 
      StreamController<List<AlertData>>.broadcast();
  
  final StreamController<int> _unreadCountController = 
      StreamController<int>.broadcast();

  // Cache for current user's notifications
  List<AlertData> _cachedNotifications = [];
  int _cachedUnreadCount = 0;
  String? _currentUserId;
  
  // Firestore listeners
  StreamSubscription<QuerySnapshot>? _notificationsListener;
  StreamSubscription<QuerySnapshot>? _readStatesListener;
  
  // Read states cache to minimize reads
  Map<String, bool> _readStatesCache = {};

  /// Initialize real-time notifications for a user
  Future<void> initializeForUser(String userId) async {
    if (_currentUserId == userId && _notificationsListener != null) {
      return; // Already initialized for this user
    }

    // Clean up previous user's listeners
    await dispose();
    
    _currentUserId = userId;
    
    // Setup real-time listeners
    _setupNotificationsListener(userId);
    _setupReadStatesListener(userId);
    
    debugPrint('🔔 Real-time notifications initialized for user: $userId');
  }

  /// Setup real-time listener for notifications
  void _setupNotificationsListener(String userId) {
    _notificationsListener = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Reasonable limit
        .snapshots()
        .listen(
      (snapshot) {
        _handleNotificationsUpdate(snapshot);
      },
      onError: (error) {
        debugPrint('❌ Notifications listener error: $error');
      },
    );
  }

  /// Setup real-time listener for read states
  void _setupReadStatesListener(String userId) {
    _readStatesListener = _firestore
        .collection('user_preferences')
        .where(FieldPath.documentId, isEqualTo: 'notification_read_states_$userId')
        .snapshots()
        .listen(
      (snapshot) {
        _handleReadStatesUpdate(snapshot);
      },
      onError: (error) {
        debugPrint('❌ Read states listener error: $error');
      },
    );
  }

  /// Handle notifications update from Firestore
  void _handleNotificationsUpdate(QuerySnapshot snapshot) {
    try {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .where((notification) => notification.shouldShow)
          .map((notification) => NotificationHelper.fromNotificationModel(notification))
          .toList();

      // Merge with virtual notifications (appointments, messages, etc.)
      _mergeWithVirtualNotifications(notifications);
      
    } catch (e) {
      debugPrint('❌ Error handling notifications update: $e');
    }
  }

  /// Handle read states update from Firestore
  void _handleReadStatesUpdate(QuerySnapshot snapshot) {
    try {
      if (snapshot.docs.isNotEmpty) {
        final readStatesDoc = snapshot.docs.first;
        final readStates = readStatesDoc.data() as Map<String, dynamic>? ?? {};
        
        // Update read states cache
        _readStatesCache = readStates.map((key, value) => 
            MapEntry(key, value['isRead'] == true));
        
        // Recalculate unread count and update UI
        _updateNotificationsWithReadStates();
      }
    } catch (e) {
      debugPrint('❌ Error handling read states update: $e');
    }
  }

  /// Merge regular notifications with virtual notifications
  void _mergeWithVirtualNotifications(List<AlertData> regularNotifications) async {
    if (_currentUserId == null) return;
    
    try {
      // Get virtual notifications (appointments, messages, tasks)
      final virtualNotifications = await _getVirtualNotifications(_currentUserId!);
      
      // Combine all notifications
      final allNotifications = [...regularNotifications, ...virtualNotifications];
      
      // Sort by timestamp
      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Update cache
      _cachedNotifications = allNotifications;
      
      // Apply read states and emit updates
      _updateNotificationsWithReadStates();
      
    } catch (e) {
      debugPrint('❌ Error merging virtual notifications: $e');
    }
  }

  /// Get virtual notifications (appointments, messages, tasks)
  Future<List<AlertData>> _getVirtualNotifications(String userId) async {
    final virtualNotifications = <AlertData>[];
    
    try {
      // Get appointment notifications (only if needed)
      final appointmentNotifications = await _getAppointmentNotifications(userId);
      virtualNotifications.addAll(appointmentNotifications);
      
      // Get message notifications (only if needed)
      final messageNotifications = await _getMessageNotifications(userId);
      virtualNotifications.addAll(messageNotifications);
      
      // Add more virtual notification types as needed
      
    } catch (e) {
      debugPrint('❌ Error getting virtual notifications: $e');
    }
    
    return virtualNotifications;
  }

  /// Get appointment-related notifications
  Future<List<AlertData>> _getAppointmentNotifications(String userId) async {
    // This should be optimized to only fetch recent appointments
    // and only when appointment status changes
    try {
      final upcomingAppointments = await FirebaseFirestore.instance
          .collection('appointmentBookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed') // Only send reminders for confirmed appointments
          .where('appointmentDate', isGreaterThan: Timestamp.now())
          .limit(10) // Only recent upcoming appointments
          .get();

      final notifications = <AlertData>[];
      
      for (final doc in upcomingAppointments.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
        final now = DateTime.now();
        
        // Only create notifications for appointments within 24 hours
        if (appointmentDate.difference(now).inHours <= 24 && 
            appointmentDate.difference(now).inHours > 0) {
          
          notifications.add(AlertData(
            id: 'appointment_${doc.id}_reminder',
            title: 'Appointment Reminder',
            subtitle: 'You have an upcoming appointment',
            type: AlertType.appointment,
            timestamp: appointmentDate.subtract(const Duration(hours: 1)),
            isRead: _readStatesCache['appointment_${doc.id}_reminder'] ?? false,
            actionUrl: '/appointments/${doc.id}',
            actionLabel: 'View Details',
            metadata: {'appointmentId': doc.id},
          ));
        }
      }
      
      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting appointment notifications: $e');
      return [];
    }
  }

  /// Get message-related notifications
  Future<List<AlertData>> _getMessageNotifications(String userId) async {
    try {
      debugPrint('🔍 Fetching message notifications for user: $userId');
      
      final recentMessages = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .where('lastMessageSenderId', isNotEqualTo: userId)
          .where('unreadCount', isGreaterThan: 0)  // ✅ FIX: Only show if unread
          .where('updatedAt', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7))
          ))
          .limit(5) // Only recent messages
          .get();

      debugPrint('📊 Found ${recentMessages.docs.length} conversations with unread messages');
      
      final notifications = <AlertData>[];
      
      for (final doc in recentMessages.docs) {
        final data = doc.data();
        final conversationId = doc.id;
        final unreadCount = data['unreadCount'] ?? 0;
        final clinicName = data['clinicName'] ?? 'Unknown';
        
        debugPrint('💬 Conversation: $clinicName (ID: $conversationId)');
        debugPrint('   - Unread count: $unreadCount');
        debugPrint('   - Last sender: ${data['lastMessageSenderId']}');
        debugPrint('   - Updated: ${(data['updatedAt'] as Timestamp).toDate()}');
        
        // ✅ FIX: Double-check unread count before adding notification
        if (unreadCount > 0) {
          notifications.add(AlertData(
            id: 'message_${conversationId}',
            title: 'New Message',
            subtitle: 'You have a new message from $clinicName',
            type: AlertType.message,
            timestamp: (data['updatedAt'] as Timestamp).toDate(),
            isRead: _readStatesCache['message_$conversationId'] ?? false,
            actionUrl: '/messaging',
            actionLabel: 'View Message',
            metadata: {
              'conversationId': conversationId,
              'unreadCount': unreadCount,
            },
          ));
          
          debugPrint('   ✅ Added to notifications');
        } else {
          debugPrint('   ❌ Skipped (unreadCount = 0)');
        }
      }
      
      debugPrint('✅ Returning ${notifications.length} message notifications');
      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting message notifications: $e');
      return [];
    }
  }

  /// Update notifications with read states and emit changes
  void _updateNotificationsWithReadStates() {
    // Apply read states to cached notifications
    final updatedNotifications = _cachedNotifications.map((notification) {
      final isRead = _readStatesCache[notification.id] ?? notification.isRead;
      return AlertData(
        id: notification.id,
        title: notification.title,
        subtitle: notification.subtitle,
        type: notification.type,
        timestamp: notification.timestamp,
        isRead: isRead,
        actionUrl: notification.actionUrl,
        actionLabel: notification.actionLabel,
        metadata: notification.metadata,
      );
    }).toList();

    _cachedNotifications = updatedNotifications;
    
    // Calculate unread count
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    // Emit updates only if data changed
    if (_cachedUnreadCount != unreadCount) {
      _cachedUnreadCount = unreadCount;
      _unreadCountController.add(unreadCount);
    }
    
    _notificationsController.add(updatedNotifications);
  }

  /// Mark notification as read with optimistic update
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      // Optimistic update
      _readStatesCache[notificationId] = true;
      _updateNotificationsWithReadStates();
      
      // Update Firestore
      await _firestore
          .collection('user_preferences')
          .doc('notification_read_states_$userId')
          .set({
        notificationId: {
          'isRead': true,
          'readAt': Timestamp.now(),
        }
      }, SetOptions(merge: true));
      
    } catch (e) {
      // Revert optimistic update on error
      _readStatesCache[notificationId] = false;
      _updateNotificationsWithReadStates();
      
      debugPrint('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Get real-time notifications stream
  Stream<List<AlertData>> get notificationsStream => _notificationsController.stream;

  /// Get real-time unread count stream
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Get current cached notifications
  List<AlertData> get cachedNotifications => List.from(_cachedNotifications);

  /// Get current unread count
  int get unreadCount => _cachedUnreadCount;

  /// Dispose all listeners and controllers
  Future<void> dispose() async {
    await _notificationsListener?.cancel();
    await _readStatesListener?.cancel();
    
    _notificationsListener = null;
    _readStatesListener = null;
    _currentUserId = null;
    
    // Clear cache
    _cachedNotifications.clear();
    _readStatesCache.clear();
    _cachedUnreadCount = 0;
    
    debugPrint('🧹 Real-time notifications disposed');
  }

  /// Force refresh (useful for pull-to-refresh)
  Future<void> refresh() async {
    if (_currentUserId != null) {
      // Re-fetch virtual notifications
      final virtualNotifications = await _getVirtualNotifications(_currentUserId!);
      
      // Merge and update
      final regularNotifications = _cachedNotifications
          .where((n) => !n.id.startsWith('appointment_') && !n.id.startsWith('message_'))
          .toList();
      
      final allNotifications = [...regularNotifications, ...virtualNotifications];
      allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _cachedNotifications = allNotifications;
      _updateNotificationsWithReadStates();
    }
  }
}