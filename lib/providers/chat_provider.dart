import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/firestore_service.dart';

class ChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  FirestoreService getFirestoreService() => _firestoreService;

  Stream<List<ChatMessage>> getMessages(String currentUserId, String otherUserId) {
    return _firestoreService.getMessages(currentUserId, otherUserId);
  }

  Future<void> sendMessage(String currentUserId, String otherUserId, String message) async {
    await _firestoreService.sendMessage(currentUserId, otherUserId, message);
  }

  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestoreService.getUserChats(userId);
  }

  Future<void> saveUserToken(String userId, String token) async {
    await _firestoreService.saveUserToken(userId, token);
  }

  Future<void> markChatAsRead(String chatId, String userId) async {
    await _firestoreService.markChatAsRead(chatId, userId);
  }
}
