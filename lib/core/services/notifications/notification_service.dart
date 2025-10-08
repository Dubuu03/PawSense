import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/notifications/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';
  
  // Add a stream controller for immediate updates
  static final _updateController = StreamController<bool>.broadcast();
  
  // Static cache for read notifications to persist across page rebuilds
  static final Set<String> _localReadCache = <String>{};
  
  /// Trigger an immediate update of notification streams
  static void triggerUpdate() {
    _updateController.add(true);
    print('🚀 Triggered notification update');
  }
  
  /// Add notification to local read cache
  static void _addToReadCache(String notificationId) {
    _localReadCache.add(notificationId);
    print('📝 Added to read cache: $notificationId');
  }
  
  /// Check if notification is in local read cache
  static bool _isInReadCache(String notificationId) {
    return _localReadCache.contains(notificationId);
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
        
        // Periodic updates every 500ms
        periodicSub = Stream.periodic(const Duration(milliseconds: 500))
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
      print('✅ Notification created for user: $userId');
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
            final petName = appointmentData['petName'] ?? 'Your pet';
            final clinicName = appointmentData['clinicName'] ?? 'Clinic';
            final updatedAt = (appointmentData['updatedAt'] as Timestamp?)?.toDate() ?? now;

            // Status change notifications
            String? title;
            String? message;
            NotificationPriority priority = NotificationPriority.medium;

            switch (status) {
              case 'pending':
                title = 'Appointment Request Received';
                message = 'Your appointment request for $petName at $clinicName has been submitted and is awaiting approval.';
                priority = NotificationPriority.medium;
                break;
              case 'confirmed':
                title = 'Appointment Confirmed';
                message = 'Great news! Your appointment for $petName at $clinicName has been confirmed.';
                priority = NotificationPriority.high;
                break;
              case 'cancelled':
                title = 'Appointment Cancelled';
                message = 'Your appointment for $petName at $clinicName has been cancelled.';
                priority = NotificationPriority.high;
                break;
              case 'completed':
                title = 'Appointment Completed';
                message = 'Your appointment for $petName at $clinicName has been completed.';
                priority = NotificationPriority.medium;
                break;
            }

            if (title != null && message != null) {
              notifications.add(NotificationModel(
                id: 'appointment_${appointmentId}_status',
                userId: userId,
                title: title,
                message: message,
                category: NotificationCategory.appointment,
                priority: priority,
                isRead: false,
                actionUrl: '/appointments/${appointmentId}',
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
                  actionUrl: '/appointments/${appointmentId}',
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
                actionUrl: '/messages/${conversationId}',
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
      // Combine all notification streams with faster updates
      await for (final _ in Stream.periodic(const Duration(milliseconds: 500))) {
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
          : 'Appointment Request Received';
      
      final message = isEmergency
          ? 'Your emergency appointment request for $petName has been submitted. $clinicName will contact you shortly.'
          : 'Your appointment request for $petName at $clinicName has been submitted and is awaiting approval.';

      await createNotification(
        userId: userId,
        title: title,
        message: message,
        category: NotificationCategory.appointment,
        priority: isEmergency ? NotificationPriority.high : NotificationPriority.medium,
        actionUrl: '/book-appointment',
        actionLabel: 'View Status',
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

  /// Create appointment status change notification
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
    try {
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
          return; // Unknown status, don't create notification
      }

      await createNotification(
        userId: userId,
        title: title,
        message: message,
        category: NotificationCategory.appointment,
        priority: priority,
        actionUrl: '/book-appointment',
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
        },
      );

      print('✅ Created $newStatus appointment notification for $petName');
    } catch (e) {
      print('❌ Error creating appointment status notification: $e');
    }
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
}