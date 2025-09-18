import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
}

enum MessageStatus {
  sent,
  delivered,
  read,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'user' or 'admin'
  final String receiverId;
  final String receiverName;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? imageUrl;
  final String? fileName;
  final bool isEdited;
  final DateTime? editedAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.receiverId,
    required this.receiverName,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.imageUrl,
    this.fileName,
    this.isEdited = false,
    this.editedAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'user',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${map['status']}',
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'],
      fileName: map['fileName'],
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null ? (map['editedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'fileName': fileName,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? receiverId,
    String? receiverName,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? imageUrl,
    String? fileName,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      fileName: fileName ?? this.fileName,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}