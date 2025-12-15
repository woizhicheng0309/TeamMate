import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
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
  final DatabaseService _db = DatabaseService();
  String _category = 'stranger'; // 保留（若需狀態外用）
  int _refreshKey = 0; // 用於強制刷新流
  bool _isOperating = false; // 禁用操作時的 Dismissible
  final Map<String, String?> _avatarCache = {}; // Cache for user avatars

  @override
  Widget build(BuildContext context) {
    final userId = _authService.userId;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('聊天'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _refreshKey++);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '陌生人'),
              Tab(text: '好友'),
              Tab(text: '群組'),
            ],
          ),
        ),
        body: StreamBuilder<List<Chat>>(
          key: ValueKey(_refreshKey),
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
              return const TabBarView(
                children: [
                  Center(child: Text('沒有聊天')),
                  Center(child: Text('沒有聊天')),
                  Center(child: Text('沒有聊天')),
                ],
              );
            }

            final pinnedChats = chats
                .where((c) => c.isPinned ?? false)
                .toList();
            final unpinnedChats = chats
                .where((c) => !(c.isPinned ?? false))
                .toList();
            final sorted = [...pinnedChats, ...unpinnedChats];

            final groupChats = sorted.where((c) => c.type == 'group').toList();
            final privateChats = sorted
                .where((c) => c.type != 'group')
                .toList();
            final friendChats = <Chat>[];

            List<Widget> buildChildren(List<Chat> items) {
              // Preload avatars for private chats
              for (final chat in items) {
                if (chat.type == 'private') {
                  _getPrivateChatAvatar(chat, userId);
                }
              }
              
              return items.map((chat) {
                return Dismissible(
                  key: Key(chat.id),
                  direction: DismissDirection.horizontal,
                  background: _pinBackground(chat),
                  secondaryBackground: _deleteBackground(),
                  onDismissed: _isOperating
                      ? null
                      : (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            _togglePinChat(chat);
                          } else {
                            _deleteChat(chat);
                          }
                        },
                  child: _buildChatItem(chat, userId),
                );
              }).toList();
            }

            return TabBarView(
              children: [
                ListView(children: buildChildren(privateChats)),
                ListView(children: buildChildren(friendChats)),
                ListView(children: buildChildren(groupChats)),
              ],
            );
          },
        ),
      ),
    );
  }

  // 已移除分段標題，改用上方 ChoiceChips 切換分類

  Widget _pinBackground(Chat chat) {
    return Container(
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
    );
  }

  Widget _deleteBackground() {
    return Container(
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat, String currentUserId) {
    return ListTile(
      leading: GestureDetector(
        onTap: () async {
          if (chat.type == 'group') return; // 群組不顯示個人資料
          final otherId = chat.participants.firstWhere(
            (p) => p != currentUserId,
            orElse: () => '',
          );
          if (otherId.isEmpty) return;
          final profile = await _db.getUserProfile(otherId);
          if (!mounted) return;
          _showUserInfoSheet(context, profile, otherId);
        },
        child: CircleAvatar(
          backgroundColor: chat.type == 'group' ? Colors.blue : Colors.green,
          child: () {
            // Determine which avatar to use
            String? avatarUrl = chat.avatarUrl;
            if (chat.type == 'private' && avatarUrl == null) {
              final otherUserId = chat.participants.firstWhere(
                (p) => p != currentUserId,
                orElse: () => '',
              );
              if (otherUserId.isNotEmpty) {
                avatarUrl = _avatarCache[otherUserId];
              }
            }
            
            return avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
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
                  );
          }(),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name ?? '聊天',
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
          fontWeight: chat.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
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
          MaterialPageRoute(builder: (context) => ChatRoomScreen(chat: chat)),
        );
      },
    );
  }

  void _showUserInfoSheet(
    BuildContext context,
    UserProfile? profile,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        (profile?.photoUrl != null &&
                            profile!.photoUrl!.isNotEmpty)
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child:
                        (profile?.photoUrl == null ||
                            (profile?.photoUrl?.isEmpty ?? true))
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? '未知用戶',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (profile?.email != null)
                          Text(
                            profile!.email!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final currentUserId = _authService.currentUser?.id;
                        if (currentUserId == null) {
                          throw Exception('用戶未登入');
                        }
                        await _db.sendFriendRequest(currentUserId, userId);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已送出好友邀請'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('發送失敗: $e')));
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('加好友'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '運動偏好',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (profile?.interests ?? const <String>[])
                    .map((s) => Chip(label: Text(s)))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
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

  void _togglePinChat(Chat chat) async {
    try {
      setState(() => _isOperating = true);

      final newPinnedState = !(chat.isPinned ?? false);
      await _chatService.updateChatPinned(chat.id, newPinnedState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newPinnedState ? '聊天已置頂' : '聊天已取消置頂'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 延遲刷新以完成 Dismissible 動畫
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            _refreshKey++;
            _isOperating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失敗: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isOperating = false);
      }
    }
  }

  // Get avatar for a private chat (fetch other user's avatar)
  Future<String?> _getPrivateChatAvatar(Chat chat, String currentUserId) async {
    if (chat.type != 'private') return chat.avatarUrl;
    
    // Find the other user's ID
    final otherUserId = chat.participants.firstWhere(
      (p) => p != currentUserId,
      orElse: () => '',
    );
    
    if (otherUserId.isEmpty) return null;
    
    // Check cache first
    if (_avatarCache.containsKey(otherUserId)) {
      return _avatarCache[otherUserId];
    }
    
    // Fetch from database
    try {
      final profile = await _db.getUserProfile(otherUserId);
      final avatar = profile?.photoUrl;
      _avatarCache[otherUserId] = avatar;
      if (mounted) setState(() {});
      return avatar;
    } catch (_) {
      return null;
    }
  }

  void _deleteChat(Chat chat) async {
    try {
      setState(() => _isOperating = true);

      await _chatService.deleteChat(chat.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('聊天已刪除'),
            duration: Duration(seconds: 2),
          ),
        );

        // 延遲刷新以完成 Dismissible 動畫
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          setState(() {
            _refreshKey++;
            _isOperating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刪除失敗: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isOperating = false);
      }
    }
  }
}
