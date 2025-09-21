import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/messaging/conversation_model.dart';
import '../../models/messaging/message_model.dart';
import '../../guards/auth_guard.dart';

class MessagingWebService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all conversations for admin view (filtered by admin's clinic)
  Future<List<Conversation>> getAllConversations() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get admin's clinic ID first
      final clinicId = await _getCurrentAdminClinicId();
      if (clinicId == null) {
        print('❌ Admin has no clinic, returning empty conversations');
        return <Conversation>[];
      }

      print('🔍 MessagingService: Fetching conversations for clinic: $clinicId');
      final QuerySnapshot snapshot = await _firestore
          .collection('conversations')
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('lastMessageTime', descending: true)
          .get();

      print('🔍 MessagingService: Found ${snapshot.docs.length} conversations for clinic $clinicId');
      
      final conversations = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID to the data
        print('🔍 Conversation data: ${data.keys.toList()}');
        return Conversation.fromMap(data);
      }).toList();

      print('🔍 MessagingService: Parsed ${conversations.length} conversations');
      return conversations;
    } catch (e) {
      print('❌ Error in getAllConversations: $e');
      rethrow;
    }
  }

    // Get filtered conversations based on status (filtered by admin's clinic)
  Future<List<Conversation>> getFilteredConversations(String status) async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get admin's clinic ID first
      final clinicId = await _getCurrentAdminClinicId();
      if (clinicId == null) {
        print('❌ Admin has no clinic, returning empty conversations');
        return <Conversation>[];
      }

      Query query = _firestore
          .collection('conversations')
          .where('clinicId', isEqualTo: clinicId);
      
      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      
      query = query.orderBy('lastMessageTime', descending: true);
      
      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Conversation.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error in getFilteredConversations: $e');
      rethrow;
    }
  }

      // Get messages for a specific conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      print('🔍 MessagingService: Fetching messages for conversation: $conversationId');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false) // Changed to false for chronological order
          .get();

      print('🔍 MessagingService: Found ${snapshot.docs.length} message documents');
      
      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        print('🔍 Message data keys: ${data.keys.toList()}');
        return Message.fromMap(data);
      }).toList();

      print('🔍 MessagingService: Parsed ${messages.length} messages');
      return messages;
    } catch (e) {
      print('❌ Error in getMessages: $e');
      rethrow;
    }
  }

  // Send admin message
  Future<void> sendAdminMessage(String conversationId, String content) async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get conversation details to get recipient info
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }
      
      final conversationData = conversationDoc.data() as Map<String, dynamic>;
      
      final now = DateTime.now();
      final message = Message(
        id: '',
        conversationId: conversationId,
        senderId: user.uid,
        senderName: user.username,
        senderRole: 'admin',
        receiverId: conversationData['userId'] ?? '',
        receiverName: conversationData['userName'] ?? '',
        content: content,
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: now,
      );

      // Add message to the messages collection (not subcollection)
      final messageRef = await _firestore
          .collection('messages')
          .add(message.toMap());

      // Update conversation last message info
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessage': content,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageSenderId': user.uid,
        'updatedAt': Timestamp.fromDate(now),
      });

      print('Admin message sent successfully: ${messageRef.id}');
    } catch (e) {
      print('Error in sendAdminMessage: $e');
      rethrow;
    }
  }

  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'unreadCount': 0,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error in markConversationAsRead: $e');
      rethrow;
    }
  }

  // Update conversation status
  Future<void> updateConversationStatus(String conversationId, bool isActive) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error in updateConversationStatus: $e');
      rethrow;
    }
  }

  // Get conversation by ID
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID to the map
        return Conversation.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error in getConversationById: $e');
      rethrow;
    }
  }

  // Stream conversations for real-time updates (filtered by admin's clinic)
  Stream<List<Conversation>> getConversationsStream() {
    try {
      return Stream.fromFuture(_getCurrentAdminClinicId()).asyncExpand((clinicId) {
        if (clinicId == null) {
          print('❌ Admin has no clinic, returning empty conversation stream');
          return Stream.value(<Conversation>[]);
        }
        
        print('🏥 Filtering conversations for clinic: $clinicId');
        return _firestore
            .collection('conversations')
            .where('clinicId', isEqualTo: clinicId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots()
            .map((snapshot) {
          print('📝 Found ${snapshot.docs.length} conversations for clinic $clinicId');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID to the map
            return Conversation.fromMap(data);
          }).toList();
        });
      });
    } catch (e) {
      print('Error in getConversationsStream: $e');
      rethrow;
    }
  }

  // Helper method to get current admin's clinic ID
  Future<String?> _getCurrentAdminClinicId() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) {
        print('❌ No authenticated user found');
        return null;
      }
      
      print('👤 Current admin user: ${user.uid} (${user.username})');
      
      // For admin users, their UID should match their clinic ID
      // This is based on the clinic structure where clinic documents use the admin's UID as the document ID
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(user.uid)
          .get();
      
      if (clinicDoc.exists) {
        final clinicData = clinicDoc.data() as Map<String, dynamic>;
        final clinicId = clinicDoc.id;
        final clinicName = clinicData['clinicName'] ?? 'Unknown Clinic';
        print('🏥 Admin manages clinic: $clinicName (ID: $clinicId)');
        return clinicId;
      } else {
        print('❌ No clinic found for admin user: ${user.uid}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting admin clinic ID: $e');
      return null;
    }
  }

  // Stream messages for real-time updates
  Stream<List<Message>> getMessagesStream(String conversationId) {
    try {
      print('🔍 MessagingService: Starting messages stream for conversation: $conversationId');
      
      return _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false) // Changed to false for chronological order
          .snapshots()
          .map((snapshot) {
        print('🔍 MessagingService: Messages stream update - ${snapshot.docs.length} messages');
        
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Message.fromMap(data);
        }).toList();
      });
    } catch (e) {
      print('❌ Error in getMessagesStream: $e');
      rethrow;
    }
  }

  // Delete conversation (admin only)
  Future<void> deleteConversation(String conversationId) async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null || user.role != 'admin') {
        throw Exception('Unauthorized: Admin access required');
      }

      // Delete all messages in the conversation
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation document
      batch.delete(_firestore.collection('conversations').doc(conversationId));
      
      await batch.commit();
      print('Conversation deleted successfully: $conversationId');
    } catch (e) {
      print('Error in deleteConversation: $e');
      rethrow;
    }
  }

  // Get conversations count by status
  Future<Map<String, int>> getConversationsCount() async {
    try {
      final allSnapshot = await _firestore.collection('conversations').get();
      final activeSnapshot = await _firestore
          .collection('conversations')
          .where('isActive', isEqualTo: true)
          .get();
      final inactiveSnapshot = await _firestore
          .collection('conversations')
          .where('isActive', isEqualTo: false)
          .get();

      return {
        'all': allSnapshot.docs.length,
        'active': activeSnapshot.docs.length,
        'inactive': inactiveSnapshot.docs.length,
      };
    } catch (e) {
      print('Error in getConversationsCount: $e');
      return {'all': 0, 'active': 0, 'inactive': 0};
    }
  }
}