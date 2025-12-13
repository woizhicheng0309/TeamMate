import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.userId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Chat>>(
        stream: _chatService.getUserChats(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有聊天記錄',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '加入活動或私信其他用戶開始聊天',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // 分离置顶和未置顶的聊天
          final pinnedChats = chats.where((c) => c.isPinned ?? false).toList();
          final unpinnedChats = chats.where((c) => !(c.isPinned ?? false)).toList();
          
          // 合并：置顶在前
          final sortedChats = [...pinnedChats, ...unpinnedChats];

          return ListView.builder(
            itemCount: sortedChats.length,
            itemBuilder: (context, index) {
              final chat = sortedChats[index];
              return Dismissible(
                key: Key(chat.id),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.orange,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chat.isPinned ?? false ? Icons.push_pin_outlined : Icons.push_pin,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chat.isPinned ?? false ? '取消置頂' : '置頂',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '刪除',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    // 置頂/取消置頂
                    _togglePinChat(chat);
                  } else {
                    // 刪除
                    _deleteChat(chat);
                  }
                },
                child: _buildChatItem(chat, userId),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(Chat chat, String currentUserId) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: chat.type == 'group' ? Colors.blue : Colors.green,
        child: chat.avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  chat.avatarUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    chat.type == 'group' ? Icons.group : Icons.person,
                    color: Colors.white,
                  ),
                ),
              )
            : Icon(
                chat.type == 'group' ? Icons.group : Icons.person,
                color: Colors.white,
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.type == 'group')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '群組',
                style: TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
        ],
      ),
      subtitle: Text(
        chat.lastMessage ?? '開始聊天...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey,
          fontWeight:
              chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageTime != null)
            Text(
              _formatTime(chat.lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: chat.unreadCount > 0 ? Colors.blue : Colors.grey,
              ),
            ),
          const SizedBox(height: 4),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chat: chat),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  void _togglePinChat(Chat chat) {
    final newPinnedState = !(chat.isPinned ?? false);
    _chatService.updateChatPinned(chat.id, newPinnedState);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newPinnedState ? '聊天已置頂' : '聊天已取消置頂'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteChat(Chat chat) {
    _chatService.deleteChat(chat.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('聊天已刪除'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
