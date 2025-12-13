import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../models/join_request.dart';
import '../services/database_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/overpass_service.dart';
import '../services/check_in_service.dart';
import 'chat_screen.dart';
import 'creator_check_in_screen.dart';
import 'participant_check_in_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final CheckInService _checkInService = CheckInService();

  bool _isJoining = false;
  bool _hasJoined = false;
  bool _hasPendingRequest = false;
  List<Map<String, dynamic>> _participants = [];
  List<JoinRequest> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
    _loadParticipants();
    _checkPendingRequest();
    _loadPendingRequests();
  }

  Future<void> _checkIfJoined() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final participants = await _databaseService.getActivityParticipants(
      widget.activity.id,
    );
    setState(() {
      _hasJoined =
          participants.any((p) => p['user_id'] == userId) ||
          widget.activity.creatorId == userId;
    });
  }

  Future<void> _checkPendingRequest() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final requests = await _databaseService.getActivityJoinRequests(
      widget.activity.id,
      status: 'pending',
    );
    setState(() {
      _hasPendingRequest = requests.any((r) => r.userId == userId);
    });
  }

  Future<void> _loadParticipants() async {
    final participants = await _databaseService.getActivityParticipants(
      widget.activity.id,
    );
    setState(() {
      _participants = participants;
    });
  }

  Future<void> _loadPendingRequests() async {
    final userId = _authService.currentUser?.id;
    if (userId == null || widget.activity.creatorId != userId) return;

    final requests = await _databaseService.getActivityJoinRequests(
      widget.activity.id,
      status: 'pending',
    );
    setState(() {
      _pendingRequests = requests;
    });
  }

  Future<void> _joinActivity() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isJoining = true);

    try {
      // 創建加入申請
      await _databaseService.createJoinRequest(widget.activity.id, userId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('申請已提交，請等待創建者回應')));
        setState(() {
          _hasPendingRequest = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('申請失敗: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _acceptRequest(JoinRequest request) async {
    try {
      await _databaseService.acceptJoinRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已接受申請')));
        _loadPendingRequests();
        _loadParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('接受失敗: ${e.toString()}')));
      }
    }
  }

  Future<void> _rejectRequest(JoinRequest request) async {
    try {
      await _databaseService.rejectJoinRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已拒絕申請')));
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('拒絕失敗: ${e.toString()}')));
      }
    }
  }

  Future<void> _oldJoinActivity() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    setState(() => _isJoining = true);

    try {
      // 加入活动
      await _databaseService.joinActivity(widget.activity.id, userId);

      // 获取所有参与者ID
      final participants = await _databaseService.getActivityParticipants(
        widget.activity.id,
      );
      final participantIds = participants
          .map((p) => p['user_id'] as String)
          .toList();

      // 创建或更新群组聊天
      await _chatService.getOrCreateGroupChat(
        activityId: widget.activity.id,
        groupName: widget.activity.title,
        participantIds: participantIds,
      );

      if (mounted) {
        setState(() {
          _hasJoined = true;
        });
        _loadParticipants();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('成功加入活動！')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加入失敗: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _startPrivateChat(String otherUserId) async {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null) return;

    // 不能和自己聊天
    if (otherUserId == currentUserId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('不能和自己聊天')));
      return;
    }

    try {
      // 创建或获取私聊
      final chat = await _chatService.getOrCreateChat(
        currentUserId,
        otherUserId,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chat: chat)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('無法開始聊天: $e')));
      }
    }
  }

  Future<void> _leaveActivity() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認退出'),
        content: const Text('確定要退出此活動嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _databaseService.leaveActivity(widget.activity.id, userId);

      if (mounted) {
        setState(() {
          _hasJoined = false;
        });
        _loadParticipants();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已退出活動')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('退出失敗: $e')));
      }
    }
  }

  Future<void> _deleteActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此活動嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _databaseService.deleteActivity(widget.activity.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('活動已刪除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刪除失敗: $e')));
      }
    }
  }

  Future<void> _endActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認結束活動'),
        content: const Text('確定要結束此活動嗎？結束後將無法再接受新的申請。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('結束'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _databaseService.endActivity(widget.activity.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('活動已結束')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('結束失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = widget.activity.creatorId == _authService.currentUser?.id;
    final sportInfo = OverpassService.getSportNameChinese(
      widget.activity.activityType,
    );
    final sportEmoji = OverpassService.getSportEmoji(
      widget.activity.activityType,
    );
    final isFull =
        widget.activity.currentParticipants >= widget.activity.maxParticipants;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        actions: isCreator
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'end') {
                      _endActivity();
                    } else if (value == 'delete') {
                      _deleteActivity();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'end',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('結束活動'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('刪除活動'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 活動類型標題
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(sportEmoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.activity.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          sportInfo,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 活動狀態提示
          if (widget.activity.isEnded)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '此活動已結束，無法接受新的申請',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 打卡狀態顯示
          if (widget.activity.creatorCheckedIn)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '創建者已打卡 - 密碼: ${widget.activity.checkInCode}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // 活動詳情
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.calendar_today,
                    '日期時間',
                    DateFormat(
                      'yyyy/MM/dd HH:mm',
                      'zh_TW',
                    ).format(widget.activity.eventDate),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.location_on,
                    '地點',
                    widget.activity.address ?? '未提供地址',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.people,
                    '參加人數',
                    '${widget.activity.currentParticipants}/${widget.activity.maxParticipants} 人',
                  ),
                  if (widget.activity.duration != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.timer,
                      '預計時長',
                      '${widget.activity.duration} 分鐘',
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (widget.activity.description != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '活動描述',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(widget.activity.description!),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 參加者列表
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '參加者 (${_participants.length + 1})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 創建者
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: const Text('活動創建者'),
                    subtitle: const Text('發起人'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 20),
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('創建者'),
                          backgroundColor: Colors.blue,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    onTap: () => _startPrivateChat(widget.activity.creatorId),
                  ),
                  // 其他參加者（過濾掉創建者）
                  ..._participants
                      .where((p) => p['user_id'] != widget.activity.creatorId)
                      .map(
                        (participant) => ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(participant['email'] ?? '參加者'),
                          trailing: const Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                          ),
                          onTap: () =>
                              _startPrivateChat(participant['user_id']),
                        ),
                      ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 待處理申請（僅創建者可見）
          if (isCreator && _pendingRequests.isNotEmpty) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notification_important,
                          size: 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '待處理申請 (${_pendingRequests.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._pendingRequests.map(
                      (request) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(
                            request.userFullName ?? request.userEmail ?? '未知用戶',
                          ),
                          subtitle: Text(
                            '申請時間: ${DateFormat('MM/dd HH:mm').format(request.createdAt)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () => _acceptRequest(request),
                                tooltip: '接受',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () => _rejectRequest(request),
                                tooltip: '拒絕',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 打卡按鈕（創建者）
          if (isCreator &&
              DateTime.now().isAfter(widget.activity.eventDate.subtract(const Duration(minutes: 5))) &&
              DateTime.now().isBefore(widget.activity.eventDate.add(const Duration(minutes: 5))) &&
              !(widget.activity.creatorCheckedIn ?? false))
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatorCheckInScreen(
                        activity: widget.activity,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on),
                label: const Text('開始打卡'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          // 打卡確認按鈕（參與者）
          if (!isCreator &&
              _hasJoined &&
              widget.activity.creatorCheckedIn == true &&
              DateTime.now().isAfter(widget.activity.eventDate.subtract(const Duration(minutes: 5))) &&
              DateTime.now().isBefore(widget.activity.eventDate.add(const Duration(minutes: 5))))
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParticipantCheckInScreen(
                        activity: widget.activity,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.verified_user),
                label: const Text('確認打卡'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // 加入/退出按鈕
          if (!isCreator)
            SizedBox(
              height: 50,
              child: _hasJoined
                  ? ElevatedButton(
                      onPressed: _leaveActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('退出活動'),
                    )
                  : _hasPendingRequest
                  ? ElevatedButton(
                      onPressed: null,
                      child: const Text('等待審核中...'),
                    )
                  : ElevatedButton(
                      onPressed: (isFull || widget.activity.isEnded)
                          ? null
                          : (_isJoining ? null : _joinActivity),
                      child: _isJoining
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.activity.isEnded
                                  ? '活動已結束'
                                  : (isFull ? '活動已滿' : '申請加入'),
                            ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
