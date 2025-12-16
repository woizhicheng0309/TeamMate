import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/chat.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class GroupMembersScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final List<String> participantIds;

  const GroupMembersScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.participantIds,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final _db = DatabaseService();
  final _authService = AuthService();
  final _chatService = ChatService();
  List<UserProfile> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await _db.getUsersByIds(widget.participantIds);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入成員失敗: $e')),
      );
    }
  }

  Future<void> _startPrivateChat(UserProfile member) async {
    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('用戶未登入');
      }

      // 获取或创建私聊
      final chat = await _chatService.getOrCreateChat(currentUserId, member.id);
      
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(chat: chat),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始聊天失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chatName} (${widget.participantIds.length} 位成員)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(child: Text('沒有成員'))
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isCurrentUser =
                        member.id == _authService.currentUser?.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.photoUrl != null
                              ? NetworkImage(member.photoUrl!)
                              : null,
                          child: member.photoUrl == null
                              ? Text(
                                  (member.displayName?.isNotEmpty ?? false)
                                      ? member.displayName![0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(member.displayName ?? 'Unknown'),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '我',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: (member.interests?.isNotEmpty ?? false)
                            ? Text(
                                '興趣: ${member.interests!.join(", ")}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: isCurrentUser
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: () => _startPrivateChat(member),
                                tooltip: '私聊',
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
