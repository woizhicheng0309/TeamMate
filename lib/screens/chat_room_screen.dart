import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';

class ChatRoomScreen extends StatefulWidget {
  final Chat chat;

  const ChatRoomScreen({super.key, required this.chat});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final Map<String, String?> _avatarCache = {};
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
    // 對於群組聊天，提前批量加載所有參與者的頭像
    if (widget.chat.type == 'group') {
      _preloadAllAvatars();
    }
  }

  // 批量預加載群組成員頭像
  Future<void> _preloadAllAvatars() async {
    for (final participantId in widget.chat.participants) {
      if (participantId != _authService.userId) {
        _ensureAvatar(participantId);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final userId = _authService.userId;
    if (userId != null) {
      await _chatService.markMessagesAsRead(widget.chat.id, userId);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final userId = _authService.userId;
    final userEmail = _authService.userEmail;
    if (userId == null) return;

    try {
      await _chatService.sendMessage(
        chatId: widget.chat.id,
        senderId: userId,
        senderName: userEmail ?? 'User',
        content: content,
      );

      _messageController.clear();

      // 滾動到底部
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('發送失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.userId;

    // For private chats, get other user's info
    String chatTitle = widget.chat.name ?? '聊天';
    String? chatAvatar = widget.chat.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: widget.chat.type == 'private'
                  ? () async {
                      // 獲取對方 ID
                      final otherUserId = widget.chat.participants.firstWhere(
                        (id) => id != _authService.userId,
                        orElse: () => '',
                      );
                      if (otherUserId.isNotEmpty) {
                        final profile = await _db.getUserProfile(otherUserId);
                        if (!mounted) return;
                        _showUserInfoSheet(context, profile, otherUserId);
                      }
                    }
                  : null,
              child: chatAvatar != null && chatAvatar.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(chatAvatar),
                        onBackgroundImageError: (_, __) {},
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: widget.chat.type == 'group'
                            ? Colors.blue
                            : Colors.green,
                        child: Icon(
                          widget.chat.type == 'group'
                              ? Icons.group
                              : Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chatTitle, style: const TextStyle(fontSize: 16)),
                  if (widget.chat.type == 'group')
                    Text(
                      '${widget.chat.participants.length} 位成員',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getChatMessages(widget.chat.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('錯誤: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '開始對話',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 首次加載或有新消息時滾動到底部
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && messages.isNotEmpty) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == userId;
                    final isSystem = message.type == 'system';

                    if (isSystem) {
                      return _buildSystemMessage(message);
                    }

                    // Preload avatar if not in message (for messages sent before avatar feature)
                    if (!isMe && message.senderAvatar == null) {
                      _ensureAvatar(message.senderId);
                    }

                    return _buildMessage(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(Message message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildMessage(Message message, bool isMe) {
    // For private chats, use the chat's avatar (other user's avatar)
    // Use sender's avatar from message for all cases
    String? displayAvatar;
    if (isMe) {
      // For current user's message, use the avatar from the message
      displayAvatar = message.senderAvatar;
    } else {
      // For other users' messages, try multiple sources
      displayAvatar =
          message.senderAvatar ??
          _avatarCache[message.senderId] ??
          widget.chat.avatarUrl;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () async {
                final profile = await _db.getUserProfile(message.senderId);
                if (!mounted) return;
                _showUserInfoSheet(context, profile, message.senderId);
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage:
                    displayAvatar != null && displayAvatar.isNotEmpty
                    ? NetworkImage(displayAvatar)
                    : null,
                backgroundColor: Colors.blue,
                onBackgroundImageError: displayAvatar != null
                    ? (_, __) {}
                    : null,
                child: displayAvatar == null || displayAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty
                  ? NetworkImage(displayAvatar)
                  : null,
              backgroundColor: Colors.grey[300],
              child: displayAvatar == null || displayAvatar.isEmpty
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // 當接收到訊息時，嘗試預載入缺失的頭像（僅對方）
  Future<void> _ensureAvatar(String userId) async {
    if (_avatarCache.containsKey(userId)) return;
    try {
      final profile = await _db.getUserProfile(userId);
      final url = profile?.photoUrl;
      _avatarCache[userId] = url;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<bool> _checkFriendship(String userId) async {
    final currentUserId = _authService.userId;
    if (currentUserId == null) return false;

    try {
      final status = await _db.checkFriendshipStatus(currentUserId, userId);
      return status == 'accepted';
    } catch (e) {
      return false;
    }
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
        return FutureBuilder<bool>(
          future: _checkFriendship(userId),
          builder: (context, snapshot) {
            final isFriend = snapshot.data ?? false;

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage:
                            profile?.photoUrl != null &&
                                profile!.photoUrl!.isNotEmpty
                            ? NetworkImage(profile.photoUrl!)
                            : null,
                        backgroundColor: Colors.blue,
                        child:
                            profile?.photoUrl == null ||
                                profile!.photoUrl!.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.displayName ?? '用戶',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (profile?.interests != null &&
                      profile!.interests!.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '運動偏好',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: profile.interests!
                          .map(
                            (interest) => Chip(
                              label: Text(interest),
                              backgroundColor: Colors.blue[50],
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 根據好友關係顯示不同按鈕
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const CircularProgressIndicator()
                  else if (isFriend)
                    // 已經是好友，顯示刪除好友按鈕
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final currentUserId = _authService.userId;
                          if (currentUserId == null) {
                            throw Exception('用戶未登入');
                          }
                          await _db.removeFriend(currentUserId, userId);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已刪除好友')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
                        }
                      },
                      icon: const Icon(Icons.person_remove),
                      label: const Text('刪除好友'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    )
                  else
                    // 還不是好友，顯示加好友按鈕
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final currentUserId = _authService.userId;
                          if (currentUserId == null) {
                            throw Exception('用戶未登入');
                          }
                          await _db.sendFriendRequest(currentUserId, userId);
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已送出好友邀請')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('發送失敗: $e')));
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('加好友'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '輸入訊息...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
