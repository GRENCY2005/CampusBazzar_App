import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text('Please login to see messages'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatProvider.getUserChats(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final users = List<String>.from(chat['users'] ?? []);
              final otherUserId = users.firstWhere((uid) => uid != user.uid, orElse: () => '');
              
              if (otherUserId.isEmpty) return const SizedBox.shrink();

              // We need to fetch other user's name/details. 
              // Since we don't have a user stream here, we can display a placeholder or fetch it.
              // For now, let's just show "User" or enhance this by storing user names in the chat doc.
              // Ideally, FirestoreService.sendMessage should store {userId: userName} map in chat doc 
              // or we fetch user profile. 
              // Given the constraints, let's use a FutureBuilder to fetch the name or just generic.
              // Actually, best practice is to store participants' basic info in the chat doc.
              // Since we didn't do that yet, let's fetch it on the fly or just use "Chat".
              
              return UserChatTile(
                chatId: chat['id'] ?? '',
                otherUserId: otherUserId,
                lastMessage: chat['lastMessage'] ?? '',
                timestamp: chat['timestamp'] != null ? (chat['timestamp'] as dynamic).toDate() : DateTime.now(),
                unreadCount: (chat['unreadCount']?[user.uid] ?? 0) as int,
              );
            },
          );
        },
      ),
    );
  }
}

class UserChatTile extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  const UserChatTile({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We can use a FutureBuilder to get the name, or just show "User"
    // Ideally we'd have a UserProvider or similar.
    // Let's just use "Chat with User" for now or try to get name from Firestore.
    // But that might be too many reads.
    // Let's assume we can fetch it.
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<ChatProvider>(context, listen: false).getFirestoreService().getUserDetails(otherUserId),
      builder: (context, snapshot) {
         final userData = snapshot.data;
         final name = userData?['displayName'] ?? 'User';
         final photoUrl = userData?['photoUrl'];

         return ListTile(
            leading: CircleAvatar(
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(name),
            subtitle: Text(
              lastMessage, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('hh:mm a').format(timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Mark as read when tapping
              final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
              if (currentUser != null) {
                Provider.of<ChatProvider>(context, listen: false).markChatAsRead(chatId, currentUser.uid);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUserId: otherUserId,
                    otherUserName: name,
                  ),
                ),
              );
            },
         );
      },
    );
  }
}
