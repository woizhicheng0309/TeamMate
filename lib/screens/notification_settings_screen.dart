import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _notificationService = NotificationService();
  
  bool _chatNotifications = true;
  bool _activityNotifications = true;
  bool _systemNotifications = true;
  bool _pushEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _notificationService.hasPermission();
    setState(() {
      _pushEnabled = hasPermission;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermission();
    setState(() {
      _pushEnabled = granted;
    });
    
    if (granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知權限已開啟')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知權限被拒絕')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
      ),
      body: ListView(
        children: [
          // Push Notifications
          SwitchListTile(
            title: const Text('推送通知'),
            subtitle: const Text('接收應用推送通知'),
            value: _pushEnabled,
            onChanged: (value) async {
              if (value) {
                await _requestPermission();
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('關閉推送通知'),
                    content: const Text('請在系統設定中關閉應用的通知權限'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('確定'),
                      ),
                    ],
                  ),
                );
              }
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '通知類型',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Chat Notifications
          SwitchListTile(
            title: const Text('聊天消息'),
            subtitle: const Text('有新消息時接收通知'),
            value: _chatNotifications,
            onChanged: _pushEnabled ? (value) {
              setState(() => _chatNotifications = value);
            } : null,
            secondary: const Icon(Icons.chat),
          ),
          
          // Activity Notifications
          SwitchListTile(
            title: const Text('活動通知'),
            subtitle: const Text('活動更新和邀請通知'),
            value: _activityNotifications,
            onChanged: _pushEnabled ? (value) {
              setState(() => _activityNotifications = value);
            } : null,
            secondary: const Icon(Icons.event),
          ),
          
          // System Notifications
          SwitchListTile(
            title: const Text('系統通知'),
            subtitle: const Text('系統消息和更新通知'),
            value: _systemNotifications,
            onChanged: _pushEnabled ? (value) {
              setState(() => _systemNotifications = value);
            } : null,
            secondary: const Icon(Icons.info),
          ),
          
          if (!_pushEnabled)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '請先開啟推送通知權限',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
