import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _supabase = Supabase.instance.client;
  
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  UserProfile? _profile;

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final profile = await _databaseService.getUserProfile(user.id);
        setState(() {
          _profile = profile;
          _nameController.text = profile?.displayName ?? '';
          _bioController.text = profile?.phoneNumber ?? '';
          _avatarUrl = profile?.photoUrl;
        });
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    
    try {
      // 显示选择来源的对话框
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('選擇圖片來源'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('從相簿選擇'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // 选择图片
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final user = _authService.currentUser;
      if (user == null) throw Exception('用戶未登入');

      // 读取图片文件
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // 上传到 Supabase Storage
      await _supabase.storage.from('profiles').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // 获取公开 URL
      final imageUrl = _supabase.storage.from('profiles').getPublicUrl(filePath);

      // 更新本地状态
      setState(() {
        _avatarUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('圖片上傳成功')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('圖片上傳失敗: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profile == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = _profile!.copyWith(
        displayName: _nameController.text.trim(),
        photoUrl: _avatarUrl ?? _profile!.photoUrl,
        phoneNumber: _bioController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('個人資料已更新')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯個人資料'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('儲存'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  _isUploadingImage
                      ? const CircleAvatar(
                          radius: 50,
                          child: CircularProgressIndicator(),
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: _avatarUrl == null || _avatarUrl!.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        color: Colors.white,
                        onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入姓名';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Phone Field
            TextFormField(
              controller: _bioController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: '電話號碼',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '09XX-XXX-XXX',
                helperText: '請輸入台灣手機號碼 (10位數字)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入電話號碼';
                }
                // 移除所有非數字字元
                final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                // 台灣手機號碼：09 開頭，共 10 位數字
                if (digitsOnly.length != 10 || !digitsOnly.startsWith('09')) {
                  return '請輸入正確的台灣手機號碼 (09XX-XXX-XXX)';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email (Read-only)
            TextFormField(
              initialValue: _authService.currentUser?.email ?? '',
              decoration: const InputDecoration(
                labelText: '電子郵件',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}
