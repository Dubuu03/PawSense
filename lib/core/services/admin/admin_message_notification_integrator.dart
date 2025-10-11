import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/admin/admin_notification_service.dart';

/// Integration service to create admin notifications for messaging events
class AdminMessageNotificationIntegrator {
  static final AdminNotificationService _notificationService = AdminNotificationService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track processed messages to prevent duplicates
  static final Set<String> _processedConversations = {};
  static final Set<String> _processedMessages = {};
  static bool _isInitialLoad = true;

  /// Initialize message listeners for admin notifications
  static void initializeMessageListeners() {
    // Listen for new messages in conversations
    _firestore.collection('conversations').snapshots().listen((snapshot) {
      // On first load, just mark all existing conversations as processed
      if (_isInitialLoad) {
        for (final doc in snapshot.docs) {
          _processedConversations.add(doc.id);
        }
        print('🔄 Initial load: Marked ${_processedConversations.length} existing conversations as processed');
      }
      
      for (final change in snapshot.docChanges) {
        final docId = change.doc.id;
        
        if (change.type == DocumentChangeType.added) {
          if (!_processedConversations.contains(docId)) {
            _handleNewConversation(change.doc);
            _processedConversations.add(docId);
          }
        } else if (change.type == DocumentChangeType.modified) {
          _handleConversationUpdate(change.doc);
        }
      }
    });

    // Listen for new messages
    _firestore.collection('messages').snapshots().listen((snapshot) {
      // On first load, just mark all existing messages as processed
      if (_isInitialLoad) {
        for (final doc in snapshot.docs) {
          _processedMessages.add(doc.id);
        }
        _isInitialLoad = false; // Set to false after processing both collections
        print('🔄 Initial load: Marked ${_processedMessages.length} existing messages as processed');
      }
      
      for (final change in snapshot.docChanges) {
        final docId = change.doc.id;
        
        if (change.type == DocumentChangeType.added) {
          if (!_processedMessages.contains(docId)) {
            _handleNewMessage(change.doc);
            _processedMessages.add(docId);
          }
        }
      }
    });
  }

  /// Handle new conversation creation
  static Future<void> _handleNewConversation(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      final lastMessage = data['lastMessage'] as String?;
      final lastMessageSender = data['lastMessageSender'] as String?;
      
      // Check if this is a user-to-clinic conversation (not admin-to-admin)
      if (participants.length == 2 && lastMessageSender != null) {
        final userData = await _getUserData(lastMessageSender);
        final userRole = userData?['role'] ?? '';
        
        // Only create notifications for messages from non-admin users
        if (userRole != 'admin' && userRole != 'super_admin') {
          String userName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
          if (userName.isEmpty) {
            userName = userData?['username'] ?? 'User';
          }
          
          await _notificationService.createMessageNotification(
            messageId: doc.id,
            title: '💬 New Conversation Started',
            message: '$userName started a new conversation: "${lastMessage ?? 'New message'}"',
            conversationId: doc.id,
            senderId: lastMessageSender,
            senderName: userName,
          );
          
          print('✅ Created admin notification for new conversation: ${doc.id}');
        }
      }
    } catch (e) {
      print('❌ Error handling new conversation notification: $e');
    }
  }

  /// Handle conversation updates (new messages)
  static Future<void> _handleConversationUpdate(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final lastMessage = data['lastMessage'] as String?;
      final lastMessageSender = data['lastMessageSender'] as String?;
      final lastMessageTime = data['lastMessageTime'] as Timestamp?;
      
      if (lastMessage != null && lastMessageSender != null && lastMessageTime != null) {
        // Check if message is recent (within last 5 minutes to avoid spam)
        final messageTime = lastMessageTime.toDate();
        final now = DateTime.now();
        final timeDiff = now.difference(messageTime).inMinutes;
        
        if (timeDiff <= 5) {
          final userData = await _getUserData(lastMessageSender);
          final userRole = userData?['role'] ?? '';
          
          // Only create notifications for messages from non-admin users
          if (userRole != 'admin' && userRole != 'super_admin') {
            String userName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
            if (userName.isEmpty) {
              userName = userData?['username'] ?? 'User';
            }
            
            // Truncate long messages
            String messagePreview = lastMessage;
            if (messagePreview.length > 100) {
              messagePreview = '${messagePreview.substring(0, 100)}...';
            }
            
            await _notificationService.createMessageNotification(
              messageId: '${doc.id}_${messageTime.millisecondsSinceEpoch}',
              title: '💬 New Message from $userName',
              message: messagePreview,
              conversationId: doc.id,
              senderId: lastMessageSender,
              senderName: userName,
            );
            
            print('✅ Created admin notification for new message in conversation: ${doc.id}');
          }
        }
      }
    } catch (e) {
      print('❌ Error handling conversation update notification: $e');
    }
  }

  /// Handle individual new messages (alternative approach)
  static Future<void> _handleNewMessage(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = data['senderId'] as String?;
      final conversationId = data['conversationId'] as String?;
      final content = data['content'] as String?;
      final timestamp = data['timestamp'] as Timestamp?;
      
      if (senderId != null && conversationId != null && content != null && timestamp != null) {
        // Check if message is recent (within last 2 minutes)
        final messageTime = timestamp.toDate();
        final now = DateTime.now();
        final timeDiff = now.difference(messageTime).inMinutes;
        
        if (timeDiff <= 2) {
          final userData = await _getUserData(senderId);
          final userRole = userData?['role'] ?? '';
          
          // Only create notifications for messages from non-admin users
          if (userRole != 'admin' && userRole != 'super_admin') {
            String userName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();
            if (userName.isEmpty) {
              userName = userData?['username'] ?? 'User';
            }
            
            // Truncate long messages
            String messagePreview = content;
            if (messagePreview.length > 100) {
              messagePreview = '${messagePreview.substring(0, 100)}...';
            }
            
            await _notificationService.createMessageNotification(
              messageId: doc.id,
              title: '💬 New Message from $userName',
              message: messagePreview,
              conversationId: conversationId,
              senderId: senderId,
              senderName: userName,
            );
            
            print('✅ Created admin notification for message: ${doc.id}');
          }
        }
      }
    } catch (e) {
      print('❌ Error handling new message notification: $e');
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

  /// Manual notification methods for specific scenarios

  /// Create notification for urgent/priority messages
  static Future<void> notifyUrgentMessage({
    required String messageId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String content,
    String? petName,
    bool isEmergency = false,
  }) async {
    String title = isEmergency ? '🚨 Emergency Message' : '⚡ Urgent Message';
    
    String message = '$senderName sent ${isEmergency ? 'an emergency' : 'an urgent'} message';
    if (petName != null) {
      message += ' about $petName';
    }
    message += ': "$content"';
    
    await _notificationService.createMessageNotification(
      messageId: messageId,
      title: title,
      message: message,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Create notification for support requests
  static Future<void> notifySupportRequest({
    required String messageId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String subject,
    required String content,
  }) async {
    await _notificationService.createMessageNotification(
      messageId: messageId,
      title: '🆘 Support Request from $senderName',
      message: 'Subject: $subject - $content',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Create notification for appointment-related messages
  static Future<void> notifyAppointmentMessage({
    required String messageId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String content,
    required String appointmentId,
    String? petName,
  }) async {
    String message = '$senderName sent a message about appointment';
    if (petName != null) {
      message += ' for $petName';
    }
    message += ': "$content"';
    
    await _notificationService.createMessageNotification(
      messageId: messageId,
      title: '📅 Appointment Message from $senderName',
      message: message,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Create notification for follow-up messages
  static Future<void> notifyFollowUpMessage({
    required String messageId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String content,
    String? petName,
    String? previousAppointmentId,
  }) async {
    String message = '$senderName sent a follow-up message';
    if (petName != null) {
      message += ' about $petName';
    }
    message += ': "$content"';
    
    await _notificationService.createMessageNotification(
      messageId: messageId,
      title: '🔄 Follow-up Message from $senderName',
      message: message,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Create notification for complaint messages
  static Future<void> notifyComplaintMessage({
    required String messageId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String content,
  }) async {
    await _notificationService.createMessageNotification(
      messageId: messageId,
      title: '⚠️ Complaint from $senderName',
      message: 'Customer complaint: "$content"',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Create notification for feedback messages
  static Future<void> notifyFeedbackMessage({
    required String messageId,
    required String senderId,
    required String senderName,
    required String conversationId,
    required String content,
    int? rating,
  }) async {
    String message = '$senderName left feedback';
    if (rating != null) {
      message += ' (Rating: $rating/5)';
    }
    message += ': "$content"';
    
    await _notificationService.createMessageNotification(
      messageId: messageId,
      title: '⭐ Feedback from $senderName',
      message: message,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Batch notification for multiple unread messages
  static Future<void> notifyUnreadMessagesSummary({
    required String clinicId,
    required int unreadCount,
    required List<String> senderNames,
  }) async {
    String title = '💬 $unreadCount Unread Messages';
    String message;
    
    if (senderNames.length == 1) {
      message = 'You have $unreadCount unread messages from ${senderNames.first}';
    } else if (senderNames.length <= 3) {
      message = 'You have $unreadCount unread messages from ${senderNames.join(', ')}';
    } else {
      message = 'You have $unreadCount unread messages from ${senderNames.take(2).join(', ')} and ${senderNames.length - 2} others';
    }
    
    await _notificationService.createMessageNotification(
      messageId: 'unread_summary_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
    );
  }
}