import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/notifications/notification_model.dart';
import 'package:pawsense/core/utils/app_logger.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';
  
  // Add a stream controller for immediate updates
  static final _updateController = StreamController<bool>.broadcast();
  
  // Static cache for read notifications to persist across page rebuilds
  static final Set<String> _localReadCache = <String>{};
  
  // Cache to track which appointments have real notifications (to reduce database queries)
  static final Map<String, bool> _appointmentNotificationCache = <String, bool>{};
  
  /// Trigger an immediate update of notification streams
  static void triggerUpdate() {
    _updateController.add(true);
    AppLogger.notification('Triggered notification update');
  }
  
  /// Add notification to local read cache
  static void _addToReadCache(String notificationId) {
    _localReadCache.add(notificationId);
    AppLogger.notification('Added to read cache: $notificationId');
  }
  
  /// Check if notification is in local read cache
  static bool _isInReadCache(String notificationId) {
    return _localReadCache.contains(notificationId);
  }

  /// Remove notification from local read cache
  static void _removeFromReadCache(String notificationId) {
    _localReadCache.remove(notificationId);
    AppLogger.notification('Removed from read cache: $notificationId');
  }

  /// Clear all read cache (useful for testing or when notifications are updated externally)
  static void clearReadCache() {
    _localReadCache.clear();
    AppLogger.notification('Cleared all read cache');
  }

  /// Update the appointment notification cache when real notifications are created/updated
  static void _updateAppointmentCache(String userId, String appointmentId, bool hasRealNotification) {
    final cacheKey = '${userId}_$appointmentId';
    _appointmentNotificationCache[cacheKey] = hasRealNotification;
  }

  /// Get user notifications stream
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to last 50 notifications
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .where((notification) => notification.shouldShow) // Filter expired notifications
            .toList());
  }

  /// Get unread notifications count
  static Stream<int> getUnreadNotificationsCount(String userId) {
    late StreamController<int> controller;
    late StreamSubscription periodicSub;
    late StreamSubscription triggerSub;
    
    controller = StreamController<int>(
      onListen: () {
        // Function to update count
        Future<void> updateCount() async {
          try {
            // Count regular notifications
            final regularSnapshot = await _firestore
                .collection(_collection)
                .where('userId', isEqualTo: userId)
                .where('isRead', isEqualTo: false)
                .get();

            final regularCount = regularSnapshot.docs
                .map((doc) => NotificationModel.fromFirestore(doc))
                .where((notification) => notification.shouldShow)
                .length;

            // Get virtual notification read states
            final readStatesDoc = await _firestore
                .collection('user_preferences')
                .doc('notification_read_states_$userId')
                .get();
            
            final readStates = readStatesDoc.exists ? readStatesDoc.data() ?? {} : <String, dynamic>{};

            // Count virtual notifications
            int virtualCount = 0;

            // Count appointment reminders
            await for (final appointmentNotifications in getAppointmentNotifications(userId).take(1)) {
              for (final notification in appointmentNotifications) {
                if (readStates[notification.id]?['isRead'] != true) {
                  virtualCount++;
                }
              }
              break;
            }

            // Count message notifications
            await for (final messageNotifications in getMessageNotifications(userId).take(1)) {
              for (final notification in messageNotifications) {
                if (readStates[notification.id]?['isRead'] != true) {
                  virtualCount++;
                }
              }
              break;
            }

            // Count task notifications
            await for (final taskNotifications in getTaskNotifications(userId).take(1)) {
              for (final notification in taskNotifications) {
                if (readStates[notification.id]?['isRead'] != true) {
                  virtualCount++;
                }
              }
              break;
            }

            final totalCount = regularCount + virtualCount;
            controller.add(totalCount);
          } catch (e) {
            print('Error counting unread notifications: $e');
            controller.add(0);
          }
        }
        
        // Initial update
        updateCount();
        
        // OPTIMIZED: Reduce frequency to 60 seconds to prevent database spam
        periodicSub = Stream.periodic(const Duration(seconds: 60))
            .listen((_) => updateCount());
        
        // Immediate updates when triggered
        triggerSub = _updateController.stream
            .listen((_) => updateCount());
      },
      onCancel: () {
        periodicSub.cancel();
        triggerSub.cancel();
      },
    );
    
    return controller.stream.distinct(); // Only emit when count actually changes
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId, {String? userId}) async {
    try {
      print('🔍 Attempting to mark notification as read: $notificationId (userId: $userId)');
      
      // Add to local cache immediately for instant updates
      _addToReadCache(notificationId);
      
      // Check if this is a virtual notification (appointment status, reminders, etc.)
      if (notificationId.startsWith('appointment_') && 
          (notificationId.endsWith('_reminder') || notificationId.endsWith('_status'))) {
        print('📱 Detected virtual appointment notification: $notificationId');
        
        // For appointment notifications, store the read state separately
        final docPath = userId != null ? 'notification_read_states_$userId' : 'notification_read_states';
        await _firestore.collection('user_preferences').doc(docPath).set({
          notificationId: {
            'isRead': true,
            'readAt': Timestamp.now(),
          }
        }, SetOptions(merge: true));
        print('✅ Marked virtual notification as read: $notificationId');
        
        // Trigger immediate update
        triggerUpdate();
        return;
      }
      
      if (notificationId.startsWith('message_') || notificationId.startsWith('task_')) {
        print('💬 Detected virtual message/task notification: $notificationId');
        
        // For message and task notifications, also store read state separately
        final docPath = userId != null ? 'notification_read_states_$userId' : 'notification_read_states';
        await _firestore.collection('user_preferences').doc(docPath).set({
          notificationId: {
            'isRead': true,
            'readAt': Timestamp.now(),
          }
        }, SetOptions(merge: true));
        print('✅ Marked virtual notification as read: $notificationId');
        
        // Trigger immediate update
        triggerUpdate();
        return;
      }

      // For regular notifications stored in Firestore
      print('📄 Detected regular notification, updating Firestore document: $notificationId');
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      print('✅ Marked notification as read: $notificationId');
      
      // Trigger immediate update
      triggerUpdate();
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      print('📋 NotificationId: $notificationId');
      print('👤 UserId: $userId');
      
      // Remove from cache on error
      _localReadCache.remove(notificationId);
    }
  }

  /// Check if a virtual notification is read
  static Future<bool> isVirtualNotificationRead(String notificationId, {String? userId}) async {
    try {
      final docPath = userId != null ? 'notification_read_states_$userId' : 'notification_read_states';
      final doc = await _firestore.collection('user_preferences').doc(docPath).get();
      if (!doc.exists) return false;
      
      final data = doc.data();
      return data?[notificationId]?['isRead'] == true;
    } catch (e) {
      print('Error checking virtual notification read state: $e');
      return false;
    }
  }

  /// Get notification by ID
  static Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(notificationId).get();
      if (doc.exists) {
        return NotificationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting notification by ID: $e');
      return null;
    }
  }

  /// Mark notification as read (alias for markAsRead)
  static Future<void> markNotificationAsRead(String notificationId) async {
    return markAsRead(notificationId);
  }

  /// Mark all notifications as read for user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final unreadNotifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Create a notification
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationCategory category,
    NotificationPriority priority = NotificationPriority.medium,
    String? actionUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
    DateTime? scheduledFor,
    DateTime? expiresAt,
  }) async {
    try {
      // DEBUG: Log stack trace for cancellation notifications
      if (title.contains('Cancelled') || title.contains('Cancel')) {
        print('🔍 createNotification called with cancellation title: "$title"');
        print('📍 Stack trace:');
        print(StackTrace.current);
      }
      
      // CRITICAL: Check for duplicate appointment notifications
      if (category == NotificationCategory.appointment && metadata?['appointmentId'] != null) {
        final appointmentId = metadata!['appointmentId'] as String;
        
        // Check if a notification for this appointment already exists
        final existingNotifications = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .where('metadata.appointmentId', isEqualTo: appointmentId)
            .where('category', isEqualTo: 'appointment')
            .get();
        
        if (existingNotifications.docs.isNotEmpty) {
          // Check if any of the existing notifications are for the same status/type
          for (final doc in existingNotifications.docs) {
            final existingData = doc.data();
            final existingTitle = existingData['title'] as String?;
            
            // Skip creating if an identical or more specific notification already exists
            if (existingTitle == title) {
              print('⏭️ Skipping duplicate notification creation for appointment $appointmentId');
              print('   Existing: "$existingTitle"');
              print('   Attempted: "$title"');
              return;
            }
            
            // Skip creating generic "Appointment Cancelled" if specific notification exists
            if (title == 'Appointment Cancelled' && 
                (existingTitle == 'Appointment Automatically Cancelled' || 
                 existingTitle == 'Appointment Marked as No Show')) {
              print('⏭️ Skipping generic cancellation notification - specific notification exists');
              print('   Existing: "$existingTitle"');
              return;
            }
            
            // If creating specific notification, delete any generic or other cancellation notifications
            if ((title == 'Appointment Automatically Cancelled' || title == 'Appointment Marked as No Show')) {
              if (existingTitle == 'Appointment Cancelled' || 
                  existingTitle == 'Appointment Automatically Cancelled' ||
                  existingTitle == 'Appointment Marked as No Show') {
                print('🗑️ Deleting existing notification before creating specific one');
                print('   Deleting: "$existingTitle"');
                print('   Creating: "$title"');
                await doc.reference.delete();
              }
            }
          }
        }
      }
      
      await _firestore.collection(_collection).add({
        'userId': userId,
        'title': title,
        'message': message,
        'category': category.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'isRead': false,
        'actionUrl': actionUrl,
        'actionLabel': actionLabel,
        'metadata': metadata,
        'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor) : null,
        'sentAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      });
      
      // Update appointment cache if this is an appointment notification
      if (category == NotificationCategory.appointment && metadata?['appointmentId'] != null) {
        _updateAppointmentCache(userId, metadata!['appointmentId'] as String, true);
      }
      
      print('✅ Notification created for user: $userId');
      print('   📋 Title: "$title"');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  /// Generate appointment notifications
  static Stream<List<NotificationModel>> getAppointmentNotifications(String userId) async* {
    try {
      // Get user's appointments (removed orderBy to avoid index requirement)
      await for (final appointmentsSnapshot in _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .limit(20)
          .snapshots()) {
        
        final notifications = <NotificationModel>[];
        final now = DateTime.now();

        for (final doc in appointmentsSnapshot.docs) {
          try {
            final appointmentData = doc.data();
            final appointmentId = doc.id;
            final status = appointmentData['status'] as String?;
            final appointmentDate = (appointmentData['appointmentDate'] as Timestamp?)?.toDate();
            final updatedAt = (appointmentData['updatedAt'] as Timestamp?)?.toDate() ?? now;

            // Get actual pet name and clinic name from their collections
            String petName = 'Your pet';
            String clinicName = 'Clinic';
            
            // Try to get pet name from pet ID
            final petId = appointmentData['petId'] as String?;
            if (petId != null) {
              try {
                final petDoc = await _firestore.collection('pets').doc(petId).get();
                if (petDoc.exists) {
                  final petData = petDoc.data();
                  petName = petData?['name'] ?? petData?['petName'] ?? 'Your pet';
                }
              } catch (e) {
                print('Error fetching pet name for ID $petId: $e');
                // Fall back to appointment data if available
                petName = appointmentData['petName'] ?? 'Your pet';
              }
            } else {
              // Fall back to appointment data if petId not available
              petName = appointmentData['petName'] ?? 'Your pet';
            }
            
            // Try to get clinic name from clinic ID
            final clinicId = appointmentData['clinicId'] as String?;
            if (clinicId != null) {
              try {
                final clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
                if (clinicDoc.exists) {
                  final clinicData = clinicDoc.data();
                  clinicName = clinicData?['clinicName'] ?? clinicData?['name'] ?? 'Clinic';
                }
              } catch (e) {
                print('Error fetching clinic name for ID $clinicId: $e');
                // Fall back to appointment data if available
                clinicName = appointmentData['clinicName'] ?? 'Clinic';
              }
            } else {
              // Fall back to appointment data if clinicId not available
              clinicName = appointmentData['clinicName'] ?? 'Clinic';
            }

            // Status change notifications
            String? title;
            String? message;
            NotificationPriority priority = NotificationPriority.medium;

            switch (status) {
              case 'pending':
                title = 'Appointment Request Sent';
                message = 'Your appointment request for $petName at $clinicName has been submitted and is awaiting approval.';
                priority = NotificationPriority.medium;
                break;
              case 'confirmed':
                title = 'Appointment Confirmed';
                message = 'Great news! Your appointment for $petName at $clinicName has been confirmed.';
                priority = NotificationPriority.high;
                break;
              case 'cancelled':
                // Check if this is auto-cancelled or no-show - these have their own specific real notifications
                final isAutoCancelled = appointmentData['autoCancelled'] == true;
                final isNoShow = appointmentData['isNoShow'] == true;
                
                if (isAutoCancelled || isNoShow) {
                  // Skip virtual notification - specific real notification already exists
                  print('⏭️ Skipping virtual notification for ${isNoShow ? "no-show" : "auto-cancelled"} appointment: $appointmentId');
                  title = null;
                  message = null;
                } else {
                  // Regular cancellation - create virtual notification
                  title = 'Appointment Cancelled';
                  message = 'Your appointment for $petName at $clinicName has been cancelled.';
                  priority = NotificationPriority.high;
                }
                break;
              case 'completed':
                title = 'Appointment Completed';
                message = 'Your appointment for $petName at $clinicName has been completed.';
                priority = NotificationPriority.medium;
                break;
            }

            if (title != null && message != null) {
              // Check cache first to avoid repeated database queries
              final cacheKey = '${userId}_$appointmentId';
              bool hasRealNotification = _appointmentNotificationCache[cacheKey] ?? false;
              
              // If not in cache, check database (but less frequently)
              if (!hasRealNotification) {
                final existingNotificationQuery = await _firestore
                    .collection(_collection)
                    .where('userId', isEqualTo: userId)
                    .where('metadata.appointmentId', isEqualTo: appointmentId)
                    .limit(1)
                    .get();
                
                hasRealNotification = existingNotificationQuery.docs.isNotEmpty;
                _appointmentNotificationCache[cacheKey] = hasRealNotification;
              }
              
              // Only create virtual notification if no real notification exists
              if (!hasRealNotification) {
                notifications.add(NotificationModel(
                  id: 'appointment_${appointmentId}_status',
                  userId: userId,
                  title: title,
                  message: message,
                  category: NotificationCategory.appointment,
                  priority: priority,
                  isRead: false,
                  actionUrl: '/appointments/details/${appointmentId}',
                  actionLabel: 'View Details',
                  createdAt: updatedAt,
                  metadata: {
                    'appointmentId': appointmentId,
                    'status': status,
                    'petName': petName,
                    'clinicName': clinicName,
                  },
                ));
              }
              // Remove the debug message since it's now cached and less frequent
            }

            // Reminder notifications (7 days before confirmed appointments)
            if (status == 'confirmed' && appointmentDate != null) {
              final daysUntil = appointmentDate.difference(now).inDays;
              
              if (daysUntil <= 7 && daysUntil > 0) {
                final timeText = daysUntil == 1 ? 'tomorrow' : 'in $daysUntil days';
                notifications.add(NotificationModel(
                  id: 'appointment_${appointmentId}_reminder',
                  userId: userId,
                  title: 'Appointment Reminder',
                  message: 'Your appointment for $petName at $clinicName is scheduled $timeText.',
                  category: NotificationCategory.appointment,
                  priority: NotificationPriority.medium,
                  isRead: false,
                  actionUrl: '/appointments/details/${appointmentId}',
                  actionLabel: 'View Details',
                  createdAt: now,
                  metadata: {
                    'appointmentId': appointmentId,
                    'appointmentDate': appointmentDate.toIso8601String(),
                    'daysUntil': daysUntil,
                    'petName': petName,
                    'clinicName': clinicName,
                  },
                ));
              }
            }
          } catch (e) {
            print('Error processing appointment notification: $e');
          }
        }

        yield notifications;
      }
    } catch (e) {
      print('Error getting appointment notifications: $e');
      yield [];
    }
  }

  /// Generate message notifications
  static Stream<List<NotificationModel>> getMessageNotifications(String userId) async* {
    try {
      // Get user's conversations with unread messages (removed orderBy to avoid index requirement)
      await for (final conversationsSnapshot in _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .where('unreadCount', isGreaterThan: 0)
          .snapshots()) {
        
        final notifications = <NotificationModel>[];

        for (final doc in conversationsSnapshot.docs) {
          try {
            final conversationData = doc.data();
            final conversationId = doc.id;
            final unreadCount = conversationData['unreadCount'] ?? 0;
            final clinicName = conversationData['clinicName'] ?? 'Clinic';
            final lastMessage = conversationData['lastMessage'] ?? '';
            final lastMessageTime = (conversationData['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();

            if (unreadCount > 0) {
              final messageText = unreadCount == 1 
                  ? 'You have 1 unread message'
                  : 'You have $unreadCount unread messages';

              notifications.add(NotificationModel(
                id: 'message_${conversationId}',
                userId: userId,
                title: 'New Messages from $clinicName',
                message: messageText + (lastMessage.isNotEmpty ? ': "$lastMessage"' : ''),
                category: NotificationCategory.message,
                priority: NotificationPriority.medium,
                isRead: false,
                actionUrl: '/messaging',
                actionLabel: 'Read Messages',
                createdAt: lastMessageTime,
                metadata: {
                  'conversationId': conversationId,
                  'unreadCount': unreadCount,
                  'clinicName': clinicName,
                  'lastMessage': lastMessage,
                },
              ));
            }
          } catch (e) {
            print('Error processing message notification: $e');
          }
        }

        yield notifications;
      }
    } catch (e) {
      print('Error getting message notifications: $e');
      yield [];
    }
  }

  /// Generate task notifications
  static Stream<List<NotificationModel>> getTaskNotifications(String userId) async* {
    try {
      // Get user's tasks (removed orderBy to avoid index requirement)
      await for (final tasksSnapshot in _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .limit(20)
          .snapshots()) {
        
        final notifications = <NotificationModel>[];
        final now = DateTime.now();

        for (final doc in tasksSnapshot.docs) {
          try {
            final taskData = doc.data();
            final taskId = doc.id;
            final title = taskData['title'] ?? 'Task';
            final status = taskData['status'] as String?;
            final priority = taskData['priority'] as String?;
            final deadline = (taskData['deadline'] as Timestamp?)?.toDate();
            final assignerName = taskData['assignerName'] ?? 'Admin';
            final updatedAt = (taskData['updatedAt'] as Timestamp?)?.toDate() ?? now;

            // New task assignment notification
            if (status == 'assigned') {
              notifications.add(NotificationModel(
                id: 'task_${taskId}_assigned',
                userId: userId,
                title: 'New Task Assigned',
                message: '$assignerName assigned you a task: "$title"',
                category: NotificationCategory.task,
                priority: priority == 'urgent' ? NotificationPriority.urgent : NotificationPriority.medium,
                isRead: false,
                actionUrl: '/tasks/${taskId}',
                actionLabel: 'View Task',
                createdAt: updatedAt,
                metadata: {
                  'taskId': taskId,
                  'taskTitle': title,
                  'assignerName': assignerName,
                  'priority': priority,
                },
              ));
            }

            // Deadline reminder notifications
            if (deadline != null && (status == 'assigned' || status == 'inProgress')) {
              final daysUntil = deadline.difference(now).inDays;
              final hoursUntil = deadline.difference(now).inHours;

              String? reminderTitle;
              String? reminderMessage;
              NotificationPriority reminderPriority = NotificationPriority.medium;

              if (daysUntil == 3) {
                reminderTitle = 'Task Deadline Reminder';
                reminderMessage = 'Task "$title" is due in 3 days.';
                reminderPriority = NotificationPriority.medium;
              } else if (daysUntil == 1) {
                reminderTitle = 'Task Due Tomorrow';
                reminderMessage = 'Task "$title" is due tomorrow.';
                reminderPriority = NotificationPriority.high;
              } else if (daysUntil == 0 && hoursUntil > 0) {
                reminderTitle = 'Task Due Today';
                reminderMessage = 'Task "$title" is due today.';
                reminderPriority = NotificationPriority.urgent;
              } else if (daysUntil < 0) {
                reminderTitle = 'Task Overdue';
                reminderMessage = 'Task "$title" is overdue.';
                reminderPriority = NotificationPriority.urgent;
              }

              if (reminderTitle != null && reminderMessage != null) {
                notifications.add(NotificationModel(
                  id: 'task_${taskId}_reminder',
                  userId: userId,
                  title: reminderTitle,
                  message: reminderMessage,
                  category: NotificationCategory.task,
                  priority: reminderPriority,
                  isRead: false,
                  actionUrl: '/tasks/${taskId}',
                  actionLabel: 'View Task',
                  createdAt: now,
                  metadata: {
                    'taskId': taskId,
                    'taskTitle': title,
                    'deadline': deadline.toIso8601String(),
                    'daysUntil': daysUntil,
                    'isOverdue': daysUntil < 0,
                  },
                ));
              }
            }
          } catch (e) {
            print('Error processing task notification: $e');
          }
        }

        yield notifications;
      }
    } catch (e) {
      print('Error getting task notifications: $e');
      yield [];
    }
  }

  /// Get comprehensive notifications (appointments + messages + tasks + regular notifications)
  static Stream<List<NotificationModel>> getAllUserNotifications(String userId) async* {
    try {
      // Create a combined stream controller for better responsiveness
      late StreamController<bool> combinedController;
      late StreamSubscription periodicSub;
      late StreamSubscription triggerSub;

      combinedController = StreamController<bool>(
        onListen: () {
          // OPTIMIZED: Start periodic updates less frequently
          periodicSub = Stream.periodic(const Duration(seconds: 60))
              .listen((_) => combinedController.add(true));
          
          // Listen to manual triggers
          triggerSub = _updateController.stream
              .listen((_) => combinedController.add(true));
          
          // Emit initial value
          combinedController.add(true);
        },
        onCancel: () {
          periodicSub.cancel();
          triggerSub.cancel();
        },
      );

      await for (final _ in combinedController.stream) {
        final allNotifications = <NotificationModel>[];

        // Get virtual notification read states
        final readStatesDoc = await _firestore
            .collection('user_preferences')
            .doc('notification_read_states_$userId')
            .get();
        
        final readStates = readStatesDoc.exists ? readStatesDoc.data() ?? {} : <String, dynamic>{};

        // Get regular notifications from database and apply cache states
        final regularNotifications = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();

        for (final doc in regularNotifications.docs) {
          final notification = NotificationModel.fromFirestore(doc);
          if (notification.shouldShow) {
            // Check if notification is in cache and update read state accordingly
            if (_isInReadCache(notification.id)) {
              final updatedNotification = NotificationModel(
                id: notification.id,
                userId: notification.userId,
                title: notification.title,
                message: notification.message,
                category: notification.category,
                priority: notification.priority,
                isRead: true, // Override with cache state
                actionUrl: notification.actionUrl,
                actionLabel: notification.actionLabel,
                createdAt: notification.createdAt,
                sentAt: notification.sentAt,
                readAt: notification.readAt,
                expiresAt: notification.expiresAt,
                metadata: notification.metadata,
              );
              allNotifications.add(updatedNotification);
            } else {
              allNotifications.add(notification);
            }
          }
        }

        // Get appointment notifications and apply read states (both database and cache)
        await for (final appointmentNotifications in getAppointmentNotifications(userId).take(1)) {
          for (final notification in appointmentNotifications) {
            final isDatabaseRead = readStates[notification.id]?['isRead'] == true;
            final isCacheRead = _isInReadCache(notification.id);
            final isRead = isDatabaseRead || isCacheRead; // Check both sources
            
            allNotifications.add(NotificationModel(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              category: notification.category,
              priority: notification.priority,
              isRead: isRead,
              actionUrl: notification.actionUrl,
              actionLabel: notification.actionLabel,
              createdAt: notification.createdAt,
              sentAt: notification.sentAt,
              readAt: notification.readAt,
              expiresAt: notification.expiresAt,
              metadata: notification.metadata,
            ));
          }
          break;
        }

        // Get message notifications and apply read states (both database and cache)
        await for (final messageNotifications in getMessageNotifications(userId).take(1)) {
          for (final notification in messageNotifications) {
            final isDatabaseRead = readStates[notification.id]?['isRead'] == true;
            final isCacheRead = _isInReadCache(notification.id);
            final isRead = isDatabaseRead || isCacheRead; // Check both sources
            
            allNotifications.add(NotificationModel(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              category: notification.category,
              priority: notification.priority,
              isRead: isRead,
              actionUrl: notification.actionUrl,
              actionLabel: notification.actionLabel,
              createdAt: notification.createdAt,
              sentAt: notification.sentAt,
              readAt: notification.readAt,
              expiresAt: notification.expiresAt,
              metadata: notification.metadata,
            ));
          }
          break;
        }

        // Get task notifications and apply read states (both database and cache)
        await for (final taskNotifications in getTaskNotifications(userId).take(1)) {
          for (final notification in taskNotifications) {
            final isDatabaseRead = readStates[notification.id]?['isRead'] == true;
            final isCacheRead = _isInReadCache(notification.id);
            final isRead = isDatabaseRead || isCacheRead; // Check both sources
            
            allNotifications.add(NotificationModel(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              category: notification.category,
              priority: notification.priority,
              isRead: isRead,
              actionUrl: notification.actionUrl,
              actionLabel: notification.actionLabel,
              createdAt: notification.createdAt,
              sentAt: notification.sentAt,
              readAt: notification.readAt,
              expiresAt: notification.expiresAt,
              metadata: notification.metadata,
            ));
          }
          break;
        }

        // Sort by creation time (newest first) and remove duplicates
        final uniqueNotifications = <String, NotificationModel>{};
        for (final notification in allNotifications) {
          uniqueNotifications[notification.id] = notification;
        }

        final sortedNotifications = uniqueNotifications.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        yield sortedNotifications.take(30).toList(); // Limit to 30 most recent
        break; // Only emit once per periodic tick
      }
    } catch (e) {
      print('Error getting all user notifications: $e');
      yield [];
    }
  }

  /// Create a pending appointment notification when user books an appointment
  static Future<void> createPendingAppointmentNotification({
    required String userId,
    required String petName,
    required String clinicName,
    required DateTime requestedDate,
    required String requestedTime,
    String? appointmentId,
    bool isEmergency = false,
  }) async {
    try {
      final title = isEmergency 
          ? 'Emergency Appointment Request Submitted'
          : 'Appointment Request Sent';
      
      final message = isEmergency
          ? 'Your emergency appointment request for $petName has been submitted. $clinicName will contact you shortly.'
          : 'Your appointment request for $petName at $clinicName has been submitted and is awaiting approval.';

      // Determine the action URL and label based on whether we have an appointmentId
      final actionUrl = appointmentId != null 
          ? '/appointments/details/$appointmentId'
          : '/book-appointment';
      final actionLabel = appointmentId != null 
          ? 'View Details'
          : 'View Status';

      await createNotification(
        userId: userId,
        title: title,
        message: message,
        category: NotificationCategory.appointment,
        priority: isEmergency ? NotificationPriority.high : NotificationPriority.medium,
        actionUrl: actionUrl,
        actionLabel: actionLabel,
        metadata: {
          'appointmentId': appointmentId ?? 'pending_${DateTime.now().millisecondsSinceEpoch}',
          'clinicName': clinicName,
          'petName': petName,
          'status': 'pending',
          'isEmergency': isEmergency,
          'requestedDate': requestedDate.toIso8601String(),
          'requestedTime': requestedTime,
        },
      );

      print('✅ Created pending appointment notification for $petName at $clinicName');
    } catch (e) {
      print('❌ Error creating pending appointment notification: $e');
    }
  }

  /// Update existing appointment notification when status changes
  static Future<void> updateAppointmentStatusNotification({
    required String userId,
    required String appointmentId,
    required String petName,
    required String clinicName,
    required String oldStatus,
    required String newStatus,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? reason,
  }) async {
    try {
      print('🔄 updateAppointmentStatusNotification called:');
      print('   📍 AppointmentId: $appointmentId');
      print('   📊 Status: $oldStatus → $newStatus');
      
      // IMPORTANT: Check if this is a no-show or auto-cancelled appointment
      // These have their own specific notifications and should not be updated here
      if (newStatus == 'cancelled') {
        try {
          final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
          if (appointmentDoc.exists) {
            final appointmentData = appointmentDoc.data();
            final isNoShow = appointmentData?['isNoShow'] == true;
            final isAutoCancelled = appointmentData?['autoCancelled'] == true;
            
            if (isNoShow) {
              print('🚫 Skipping generic notification update for no-show appointment: $appointmentId');
              print('   ✅ Specific no-show notification should handle this');
              return; // Don't update - specific no-show notification already created
            }
            
            if (isAutoCancelled) {
              print('⏰ Skipping generic notification update for auto-cancelled appointment: $appointmentId');
              print('   ✅ Specific auto-cancel notification should handle this');
              return; // Don't update - specific auto-cancel notification already created
            }
            
            print('   ℹ️ Regular cancellation - proceeding with generic notification');
          }
        } catch (e) {
          print('⚠️ Could not check appointment flags: $e');
          // Continue with generic notification if check fails
        }
      }
      
      String title;
      String message;
      NotificationPriority priority = NotificationPriority.medium;

      switch (newStatus) {
        case 'confirmed':
          title = 'Appointment Confirmed';
          message = appointmentDate != null && appointmentTime != null
              ? 'Great news! Your appointment for $petName at $clinicName has been confirmed for ${_formatDate(appointmentDate)} at $appointmentTime.'
              : 'Great news! Your appointment for $petName at $clinicName has been confirmed.';
          priority = NotificationPriority.high;
          break;
        case 'cancelled':
          title = 'Appointment Cancelled';
          message = reason != null
              ? 'Your appointment for $petName at $clinicName has been cancelled. Reason: $reason'
              : 'Your appointment for $petName at $clinicName has been cancelled.';
          priority = NotificationPriority.high;
          break;
        case 'rescheduled':
          title = 'Appointment Rescheduled';
          message = appointmentDate != null && appointmentTime != null
              ? 'Your appointment for $petName has been rescheduled to ${_formatDate(appointmentDate)} at $appointmentTime.'
              : 'Your appointment for $petName has been rescheduled by $clinicName.';
          priority = NotificationPriority.high;
          break;
        case 'completed':
          title = 'Appointment Completed';
          message = 'Your appointment for $petName at $clinicName has been completed. Thank you for choosing us!';
          priority = NotificationPriority.medium;
          break;
        default:
          print('ℹ️ Unknown appointment status: $newStatus - skipping notification update');
          return; // Unknown status, don't update notification
      }

      // First, try to find and update existing notification
      final existingNotificationQuery = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('metadata.appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      if (existingNotificationQuery.docs.isNotEmpty) {
        // Update existing notification
        final notificationDoc = existingNotificationQuery.docs.first;
        final updatedMetadata = {
          'appointmentId': appointmentId,
          'clinicName': clinicName,
          'petName': petName,
          'oldStatus': oldStatus,
          'status': newStatus,
          'appointmentDate': appointmentDate?.toIso8601String(),
          'appointmentTime': appointmentTime,
          'reason': reason,
        };

        await notificationDoc.reference.update({
          'title': title,
          'message': message,
          'priority': priority.toString().split('.').last,
          'isRead': false, // Mark as unread so user sees the update
          'readAt': null, // Clear read timestamp
          'metadata': updatedMetadata,
          'updatedAt': Timestamp.now(),
        });

        // Remove from local read cache if it was there
        _removeFromReadCache(notificationDoc.id);
        
        // Update appointment cache to indicate this appointment has a real notification
        _updateAppointmentCache(userId, appointmentId, true);

        // Trigger update to refresh UI
        triggerUpdate();

        print('✅ Updated existing notification ${notificationDoc.id}: $oldStatus → $newStatus');
        print('   📋 New Title: "$title"');
        print('   📝 New Message: "${message.substring(0, message.length > 50 ? 50 : message.length)}..."');
      } else {
        // No existing notification found, create a new one
        print('ℹ️ No existing notification found for appointment $appointmentId, creating new one');
        print('   📋 Title: "$title"');
        await createNotification(
          userId: userId,
          title: title,
          message: message,
          category: NotificationCategory.appointment,
          priority: priority,
          actionUrl: '/appointments/details/$appointmentId',
          actionLabel: 'View Details',
          metadata: {
            'appointmentId': appointmentId,
            'clinicName': clinicName,
            'petName': petName,
            'oldStatus': oldStatus,
            'status': newStatus,
            'appointmentDate': appointmentDate?.toIso8601String(),
            'appointmentTime': appointmentTime,
            'reason': reason,
            'notificationSource': 'updateAppointmentStatusNotification',  // DEBUG: Track source
          },
        );
      }
    } catch (e) {
      print('❌ Error updating appointment status notification: $e');
      print('📋 AppointmentId: $appointmentId, Status: $oldStatus → $newStatus');
    }
  }

  /// Create appointment status change notification (deprecated - use updateAppointmentStatusNotification instead)
  @deprecated
  static Future<void> createAppointmentStatusNotification({
    required String userId,
    required String appointmentId,
    required String petName,
    required String clinicName,
    required String oldStatus,
    required String newStatus,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? reason,
  }) async {
    // Redirect to the new update method
    return updateAppointmentStatusNotification(
      userId: userId,
      appointmentId: appointmentId,
      petName: petName,
      clinicName: clinicName,
      oldStatus: oldStatus,
      newStatus: newStatus,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      reason: reason,
    );
  }

  /// Format date for notifications
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'tomorrow';
    } else if (difference == -1) {
      return 'yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Migration function to update old "Received" notifications to "Sent"
  static Future<void> migrateOldNotificationText(String userId) async {
    try {
      print('🔄 Starting migration of old notification text for user: $userId');
      
      // Find all notifications with the old text
      final oldNotificationsQuery = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: 'Appointment Request Received')
          .get();
      
      final batch = _firestore.batch();
      int updateCount = 0;
      
      for (final doc in oldNotificationsQuery.docs) {
        // Update the title to the new text
        batch.update(doc.reference, {
          'title': 'Appointment Request Sent',
          'updatedAt': Timestamp.now(),
        });
        updateCount++;
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('✅ Migrated $updateCount notifications from "Received" to "Sent"');
      } else {
        print('ℹ️ No notifications found with old text to migrate');
      }
      
    } catch (e) {
      print('❌ Error during notification migration: $e');
    }
  }

  /// Migration function to update action URLs for appointment notifications
  static Future<void> migrateAppointmentActionUrls(String userId) async {
    try {
      print('🔄 Starting migration of appointment action URLs for user: $userId');
      
      // Find appointment notifications with old action URL
      final oldActionUrlQuery = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('actionUrl', isEqualTo: '/book-appointment')
          .where('category', isEqualTo: 'appointment')
          .get();
      
      final batch = _firestore.batch();
      int updateCount = 0;
      
      for (final doc in oldActionUrlQuery.docs) {
        final data = doc.data();
        final appointmentId = data['metadata']?['appointmentId'] as String?;
        
        if (appointmentId != null && appointmentId != 'pending_${DateTime.now().millisecondsSinceEpoch}') {
          // Update to use appointment details URL
          batch.update(doc.reference, {
            'actionUrl': '/appointments/details/$appointmentId',
            'actionLabel': 'View Details',
            'updatedAt': Timestamp.now(),
          });
          updateCount++;
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('✅ Migrated $updateCount appointment notification URLs');
      } else {
        print('ℹ️ No appointment notifications found with old URLs to migrate');
      }
      
    } catch (e) {
      print('❌ Error during URL migration: $e');
    }
  }

  /// Clean up duplicate cancelled appointment notifications
  static Future<void> cleanupDuplicateCancelledNotifications(String userId) async {
    try {
      print('🧹 Cleaning up duplicate cancelled notifications for user: $userId');
      
      // Get all cancelled appointment notifications for this user
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: 'appointment')
          .where('title', isEqualTo: 'Appointment Cancelled')
          .get();
      
      if (snapshot.docs.isEmpty) {
        print('ℹ️ No cancelled notifications found to clean up');
        return;
      }
      
      // Group notifications by appointment ID
      final Map<String, List<QueryDocumentSnapshot>> notificationGroups = {};
      for (final doc in snapshot.docs) {
        final metadata = doc.data();
        final appointmentId = metadata['metadata']?['appointmentId'] as String?;
        
        if (appointmentId != null) {
          notificationGroups.putIfAbsent(appointmentId, () => []).add(doc);
        }
      }
      
      int deletedCount = 0;
      final batch = _firestore.batch();
      
      // For each appointment, keep only the most recent notification and delete duplicates
      for (final group in notificationGroups.values) {
        if (group.length > 1) {
          // Sort by creation time (most recent first)
          group.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = aData?['createdAt'] as Timestamp?;
            final bTime = bData?['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          
          // Delete all but the most recent (first in sorted list)
          for (int i = 1; i < group.length; i++) {
            batch.delete(group[i].reference);
            deletedCount++;
          }
        }
      }
      
      if (deletedCount > 0) {
        await batch.commit();
        print('✅ Cleaned up $deletedCount duplicate cancelled notifications');
      } else {
        print('ℹ️ No duplicate cancelled notifications found');
      }
      
    } catch (e) {
      print('❌ Error cleaning up duplicate notifications: $e');
    }
  }

  /// Complete migration for a user (call this once to fix existing notifications)
  static Future<void> migrateUserNotifications(String userId) async {
    print('🚀 Starting complete notification migration for user: $userId');
    await migrateOldNotificationText(userId);
    await migrateAppointmentActionUrls(userId);
    await cleanupDuplicateCancelledNotifications(userId);
    print('✅ Notification migration completed for user: $userId');
  }
}