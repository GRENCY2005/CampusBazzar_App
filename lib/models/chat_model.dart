import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class ChatContact {
  final String contactId; // The ID of the person you are chatting with
  final String lastMessage;
  final DateTime timestamp;
  final String? contactName; // Optional, might need to fetch
  final String? contactImage;

  ChatContact({
    required this.contactId,
    required this.lastMessage,
    required this.timestamp,
    this.contactName,
    this.contactImage,
  });
}
