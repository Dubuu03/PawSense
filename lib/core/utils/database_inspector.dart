import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseInspector {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check conversations collection structure and data
  static Future<void> inspectConversationsCollection() async {
    try {
      print('\n=== CONVERSATIONS COLLECTION INSPECTION ===');
      
      final snapshot = await _firestore.collection('conversations').get();
      
      print('Total conversations: ${snapshot.docs.length}');
      print('\nConversation documents:');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('\n--- Conversation ID: ${doc.id} ---');
        print('Fields: ${data.keys.toList()}');
        print('Data: $data');
        
        // Check for key fields
        print('Key field analysis:');
        print('  - userId: ${data['userId']}');
        print('  - clinicId: ${data['clinicId']}');
        print('  - clinicName: ${data['clinicName']}');
        print('  - isActive: ${data['isActive']}');
        print('  - lastMessage: ${data['lastMessage']}');
        print('  - createdAt: ${data['createdAt']}');
      }
    } catch (e) {
      print('Error inspecting conversations: $e');
    }
  }

  /// Check messages collection structure and data
  static Future<void> inspectMessagesCollection() async {
    try {
      print('\n=== MESSAGES COLLECTION INSPECTION ===');
      
      final snapshot = await _firestore.collection('messages').get();
      
      print('Total messages: ${snapshot.docs.length}');
      print('\nMessage documents:');
      
      // Group messages by conversation
      Map<String, List<QueryDocumentSnapshot>> messagesByConversation = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final conversationId = data['conversationId'] ?? 'unknown';
        
        if (!messagesByConversation.containsKey(conversationId)) {
          messagesByConversation[conversationId] = [];
        }
        messagesByConversation[conversationId]!.add(doc);
      }
      
      print('\nMessages grouped by conversation:');
      for (var entry in messagesByConversation.entries) {
        print('\n--- Conversation ID: ${entry.key} ---');
        print('Message count: ${entry.value.length}');
        
        for (var doc in entry.value) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            print('\n  Message ID: ${doc.id}');
            print('  Fields: ${data.keys.toList()}');
            print('  Content: ${data['content'] ?? 'N/A'}');
            print('  Sender: ${data['senderId'] ?? 'N/A'} (${data['senderName'] ?? 'N/A'})');
            print('  Timestamp: ${data['timestamp'] ?? 'N/A'}');
          }
        }
      }
    } catch (e) {
      print('Error inspecting messages: $e');
    }
  }

  /// Check data consistency between collections
  static Future<void> checkDataConsistency() async {
    try {
      print('\n=== DATA CONSISTENCY CHECK ===');
      
      // Get all conversations
      final conversationsSnapshot = await _firestore.collection('conversations').get();
      final messagesSnapshot = await _firestore.collection('messages').get();
      
      print('Conversations: ${conversationsSnapshot.docs.length}');
      print('Messages: ${messagesSnapshot.docs.length}');
      
      // Check if all conversations have corresponding messages
      print('\nChecking conversation-message relationships:');
      
      for (var convDoc in conversationsSnapshot.docs) {
        final conversationId = convDoc.id;
        final convData = convDoc.data();
        
        // Count messages for this conversation
        final messageCount = messagesSnapshot.docs
            .where((msg) => msg.data()['conversationId'] == conversationId)
            .length;
        
        print('\nConversation: ${convData['clinicName']} (${conversationId})');
        print('  Message count: $messageCount');
        print('  Last message: ${convData['lastMessage']}');
        print('  Is active: ${convData['isActive']}');
        
        if (messageCount == 0 && convData['lastMessage'] != null) {
          print('  ⚠️  WARNING: Has lastMessage but no messages found');
        }
      }
      
      // Check orphaned messages
      print('\nChecking for orphaned messages:');
      final conversationIds = conversationsSnapshot.docs.map((doc) => doc.id).toSet();
      
      for (var msgDoc in messagesSnapshot.docs) {
        final msgData = msgDoc.data();
        final conversationId = msgData['conversationId'];
        
        if (!conversationIds.contains(conversationId)) {
          print('⚠️  Orphaned message: ${msgDoc.id} (conversation: $conversationId)');
        }
      }
      
    } catch (e) {
      print('Error checking data consistency: $e');
    }
  }

  /// Run full inspection
  static Future<void> runFullInspection() async {
    await inspectConversationsCollection();
    await inspectMessagesCollection();
    await checkDataConsistency();
  }
}