import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  bool _showEmail = true;
  bool _showPhone = false;
  bool _showLocation = true;
  bool _allowFriendRequests = true;
  bool _isLoading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final profile = await _databaseService.getUserProfile(userId);
        setState(() {
          _profile = profile;
          _showEmail = profile?.privacyShowEmail ?? true;
          _showPhone = profile?.privacyShowPhone ?? false;
          _showLocation = profile?.privacyShowLocation ?? true;
          _allowFriendRequests = profile?.privacyAllowFriendRequests ?? true;
        });
      }
    } catch (e) {
      // Silent fail
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_profile == null) return;

    try {
      final updatedProfile = _profile!.copyWith(
        privacyShowEmail: _showEmail,
        privacyShowPhone: _showPhone,
        privacyShowLocation: _showLocation,
        privacyAllowFriendRequests: _allowFriendRequests,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('隱私設定已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('隱私設定')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '個人資訊可見性',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          SwitchListTile(
            title: const Text('顯示電子郵件'),
            subtitle: const Text('其他用戶可以看到你的電子郵件'),
            value: _showEmail,
            onChanged: (value) {
              setState(() => _showEmail = value);
              _saveSettings();
            },
            secondary: const Icon(Icons.email),
          ),

          SwitchListTile(
            title: const Text('顯示電話號碼'),
            subtitle: const Text('其他用戶可以看到你的電話號碼'),
            value: _showPhone,
            onChanged: (value) {
              setState(() => _showPhone = value);
              _saveSettings();
            },
            secondary: const Icon(Icons.phone),
          ),

          SwitchListTile(
            title: const Text('顯示位置'),
            subtitle: const Text('在活動中顯示你的位置'),
            value: _showLocation,
            onChanged: (value) {
              setState(() => _showLocation = value);
              _saveSettings();
            },
            secondary: const Icon(Icons.location_on),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '社交設定',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          SwitchListTile(
            title: const Text('允許好友邀請'),
            subtitle: const Text('其他用戶可以向你發送好友邀請'),
            value: _allowFriendRequests,
            onChanged: (value) {
              setState(() => _allowFriendRequests = value);
              _saveSettings();
            },
            secondary: const Icon(Icons.person_add),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('封鎖名單'),
            subtitle: const Text('管理已封鎖的用戶'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('封鎖名單功能開發中')));
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('刪除帳號'),
            subtitle: const Text('永久刪除你的帳號和所有數據'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除帳號'),
        content: const Text(
          '警告：此操作無法撤銷！\n\n'
          '刪除帳號將：\n'
          '• 永久刪除你的個人資料\n'
          '• 移除你參與的所有活動\n'
          '• 刪除你的聊天記錄\n'
          '• 無法恢復任何數據\n\n'
          '確定要繼續嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement account deletion
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('帳號刪除功能開發中')));
      }
    }
  }
}
