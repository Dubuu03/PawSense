import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/messaging/message_model.dart';
import '../../models/messaging/conversation_model.dart';
import '../clinic/clinic_list_service.dart';
import '../../guards/auth_guard.dart';

class MessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get approved clinics that users can message
  static Future<List<Map<String, dynamic>>> getApprovedClinics() async {
    try {
      return await ClinicListService.getAllActiveClinics();
    } catch (e) {
      print('Error getting approved clinics: $e');
      return [];
    }
  }

  /// Create or get existing conversation between user and clinic
  static Future<String?> createOrGetConversation(String clinicId, String clinicName) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return null;

      // Check if conversation already exists
      final existingConversation = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: currentUser.uid)
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Create new conversation
      final conversationRef = _firestore.collection('conversations').doc();
      final conversation = Conversation(
        id: conversationRef.id,
        userId: currentUser.uid,
        userName: '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim(),
        clinicId: clinicId,
        clinicName: clinicName,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await conversationRef.set(conversation.toMap());
      print('Created new conversation: ${conversationRef.id}');
      print('Conversation data: ${conversation.toMap()}');
      return conversationRef.id;
    } catch (e) {
      print('Error creating conversation: $e');
      return null;
    }
  }

  /// Get user's conversations
  static Stream<List<Conversation>> getUserConversations() async* {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) {
        print('No authenticated user found');
        yield [];
        return;
      }

      print('Getting conversations for user: ${user.uid}');

      // Simplified query without orderBy to avoid index issues
      yield* _firestore
          .collection('conversations')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            print('Received ${snapshot.docs.length} conversation documents');
            print('Raw conversation documents:');
            for (var doc in snapshot.docs) {
              print('Doc ID: ${doc.id}, Data: ${doc.data()}');
            }
            
            final conversations = snapshot.docs
                .map((doc) {
                  try {
                    final conv = Conversation.fromMap(doc.data());
                    print('Successfully parsed conversation: ${conv.clinicName}');
                    return conv;
                  } catch (e) {
                    print('Error parsing conversation ${doc.id}: $e');
                    return null;
                  }
                })
                .where((conv) => conv != null)
                .cast<Conversation>()
                .toList();
            
            print('Final conversations count: ${conversations.length}');
            
            // Sort in memory instead of in query
            conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            
            return conversations;
          })
          .handleError((error) {
            print('Error in getUserConversations stream: $error');
          });
    } catch (e) {
      print('Error setting up getUserConversations stream: $e');
      yield [];
    }
  }

  /// Get clinic's conversations (for admin use)
  static Stream<List<Conversation>> getClinicConversations(String clinicId) {
    return _firestore
        .collection('conversations')
        .where('clinicId', isEqualTo: clinicId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromMap(doc.data()))
            .toList());
  }

  /// Send a message
  static Future<bool> sendMessage({
    required String conversationId,
    required String receiverId,
    required String receiverName,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
    String? fileName,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;

      final messageRef = _firestore.collection('messages').doc();
      final message = Message(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: currentUser.uid,
        senderName: '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim(),
        senderRole: currentUser.role,
        receiverId: receiverId,
        receiverName: receiverName,
        content: content,
        type: type,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        fileName: fileName,
      );

      // Add message to messages collection
      await messageRef.set(message.toMap());

      // Update conversation with last message info
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': content,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
        'lastMessageSenderId': currentUser.uid,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Get messages for a conversation
  static Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to last 50 messages for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data()))
            .toList());
  }

  /// Get ALL messages for a conversation (no pagination)
  static Future<List<Message>> getAllMessages(String conversationId) async {
    try {
      print('=== MessagingService: Getting ALL messages ===');
      print('Conversation ID: $conversationId');
      
      final snapshot = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .get();
      
      print('Firestore query returned ${snapshot.docs.length} documents');
      
      final messages = snapshot.docs
          .map((doc) {
            try {
              final message = Message.fromMap(doc.data());
              print('Successfully parsed message: ${message.content}');
              return message;
            } catch (e) {
              print('Error parsing message ${doc.id}: $e');
              print('Document data: ${doc.data()}');
              return null;
            }
          })
          .where((msg) => msg != null)
          .cast<Message>()
          .toList();
      
      // Sort by timestamp (oldest first for display)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('=== Successfully loaded ${messages.length} total messages ===');
      return messages;
    } catch (e) {
      print('=== Error getting all messages: $e ===');
      return [];
    }
  }

  /// Stream to listen for real-time message updates
  static Stream<List<Message>> getMessagesStream(String conversationId) {
    print('=== Setting up messages stream for conversation: $conversationId ===');
    
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
          print('=== Messages stream update: ${snapshot.docs.length} documents ===');
          
          final messages = snapshot.docs
              .map((doc) {
                try {
                  return Message.fromMap(doc.data());
                } catch (e) {
                  print('Error parsing message in stream: $e');
                  return null;
                }
              })
              .where((msg) => msg != null)
              .cast<Message>()
              .toList();
          
          // Sort by timestamp (oldest first for display)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          print('=== Stream returning ${messages.length} messages ===');
          return messages;
        });
  }

  /// Get older messages for pagination
  static Future<List<Message>> getOlderMessages(String conversationId, DateTime lastMessageTimestamp, {int limit = 10}) async {
    try {
      print('Getting older messages for conversation: $conversationId before: $lastMessageTimestamp');
      
      final snapshot = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('timestamp', isLessThan: lastMessageTimestamp)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      final messages = snapshot.docs
          .map((doc) {
            try {
              return Message.fromMap(doc.data());
            } catch (e) {
              print('Error parsing older message ${doc.id}: $e');
              return null;
            }
          })
          .where((msg) => msg != null)
          .cast<Message>()
          .toList();
      
      print('Successfully loaded ${messages.length} older messages');
      return messages;
    } catch (e) {
      print('Error getting older messages: $e');
      return [];
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Get unread messages
      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: userId)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      // Mark them as read
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }

      // Update conversation unread count
      batch.update(
        _firestore.collection('conversations').doc(conversationId),
        {'unreadCount': 0},
      );

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Delete conversation and all its messages
  static Future<bool> deleteConversationAndMessages(String conversationId) async {
    try {
      print('=== Deleting conversation and messages: $conversationId ===');
      
      // Start a batch operation for atomic deletion
      final batch = _firestore.batch();
      
      // First, get all messages for this conversation
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .get();
      
      print('Found ${messagesSnapshot.docs.length} messages to delete');
      
      // Delete all messages
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }
      
      // Mark conversation as inactive (soft delete)
      batch.update(
        _firestore.collection('conversations').doc(conversationId),
        {
          'isActive': false,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
      
      // Commit the batch operation
      await batch.commit();
      
      print('=== Successfully deleted conversation and ${messagesSnapshot.docs.length} messages ===');
      return true;
    } catch (e) {
      print('Error deleting conversation and messages: $e');
      return false;
    }
  }

  /// Delete conversation
  static Future<bool> deleteConversation(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }
}