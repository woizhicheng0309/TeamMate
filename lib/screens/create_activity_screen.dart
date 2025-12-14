import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'location_picker_screen.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '10');

  // Step 1: Location selection
  bool _hasSelectedLocation = false;
  LatLng? _selectedLocation;
  String? _address;
  List<String> _suitableSports = [];

  // Step 2: Activity details
  String? _selectedActivityType;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isLoading = false;

  final Map<String, Map<String, String>> _allSportsInfo = {
    'basketball': {'label': '籃球', 'icon': '🏀'},
    'badminton': {'label': '羽毛球', 'icon': '🏸'},
    'running': {'label': '跑步', 'icon': '🏃'},
    'cycling': {'label': '騎車', 'icon': '🚴'},
    'swimming': {'label': '游泳', 'icon': '🏊'},
    'hiking': {'label': '登山', 'icon': '⛰️'},
    'tennis': {'label': '網球', 'icon': '🎾'},
    'football': {'label': '足球', 'icon': '⚽'},
  };

  @override
  void initState() {
    super.initState();
    // 不再自動打開地圖，讓用戶手動選擇
  }

  Future<void> _showLocationPicker() async {
    // 快速獲取位置（使用緩存，不顯示加載對話框）
    final position = await _locationService.getCurrentPosition();
    final initialLocation = position != null
        ? LatLng(position.latitude, position.longitude)
        : const LatLng(24.179738855398015, 120.64867252111435);

    if (!mounted) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: initialLocation,
          detectFacilities: true,
          showActivities: true,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result['location'] as LatLng;
        _address = result['address'] as String;
        _suitableSports = (result['suitableSports'] as List<String>?) ?? [];
        _hasSelectedLocation = true;

        // 自动选择第一个适合的运动
        if (_suitableSports.isNotEmpty) {
          _selectedActivityType = _suitableSports.first;
        }
      });
    }
    // 如果用户取消选择，保持当前状态不变
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇活動地點')));
      return;
    }
    if (_selectedActivityType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請選擇運動類型')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null || user.email == null) {
        throw Exception('使用者資訊缺失，請重新登入');
      }

      // Ensure user exists in users table (FK for creator_id)
      await _databaseService.upsertUser(
        id: user.id,
        email: user.email!,
        fullName: user.userMetadata?['full_name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      );

      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // 轉換本地時間為 UTC（台灣時區 GMT+8）
      final eventDateTimeUTC = eventDateTime.toUtc();
      
      print('⏰ 時間轉換:');
      print('  本地時間: $eventDateTime');
      print('  UTC 時間: $eventDateTimeUTC');

      final activity = Activity(
        id: const Uuid().v4(),
        creatorId: _authService.currentUser!.id,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        activityType: _selectedActivityType!,
        eventDate: eventDateTimeUTC,  // 使用 UTC 時間
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _address,
        maxParticipants: int.parse(_maxParticipantsController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.createActivity(activity);

      // 創建群組聊天，包含創建者
      // 由於 createActivity 已經自動將創建者加入，需要獲取當前參與者列表
      final participants = await _databaseService.getActivityParticipants(
        activity.id,
      );
      final participantIds = participants
          .map((p) => p['user_id'] as String)
          .toList();

      await _chatService.getOrCreateGroupChat(
        activityId: activity.id,
        groupName: activity.title,
        participantIds: participantIds,
      );

      if (mounted) {
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _formKey.currentState!.reset();

        // 重置状态
        setState(() {
          _hasSelectedLocation = false;
          _selectedLocation = null;
          _address = null;
          _suitableSports = [];
          _selectedActivityType = null;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('活動建立成功！')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('建立失敗: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 直接顯示表單，不等待位置選擇
    if (!_hasSelectedLocation) {
      return Scaffold(
        appBar: AppBar(title: const Text('建立新活動')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_location_alt,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  '選擇活動地點',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '點擊下方按鈕來選擇你的活動地點',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showLocationPicker,
                  icon: const Icon(Icons.map),
                  label: const Text('選擇地點'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 如果没有适合的运动，显示警告
    if (_suitableSports.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('建立新活動')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  '此地點附近沒有適合的運動設施',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _address ?? '未知地點',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _showLocationPicker,
                  icon: const Icon(Icons.map),
                  label: const Text('重新選擇地點'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // 重置状态，返回初始选择位置的界面
                    if (mounted) {
                      setState(() {
                        _hasSelectedLocation = false;
                        _selectedLocation = null;
                        _address = null;
                        _suitableSports = [];
                      });
                    }
                  },
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 有适合的运动，显示创建表单
    return Scaffold(
      appBar: AppBar(title: const Text('建立新活動')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Location Display Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          '活動地點',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _showLocationPicker,
                          child: const Text('重新選擇'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _address ?? '未知地點',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Suitable Sports Display
            const Text(
              '適合的運動類型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suitableSports.map((sportKey) {
                final sportInfo = _allSportsInfo[sportKey];
                if (sportInfo == null) return const SizedBox.shrink();

                return ChoiceChip(
                  label: Text('${sportInfo['icon']} ${sportInfo['label']}'),
                  selected: _selectedActivityType == sportKey,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedActivityType = sportKey);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '活動標題',
                border: OutlineInputBorder(),
                hintText: '例：週六下午打籃球',
              ),
              validator: (value) => value?.isEmpty ?? true ? '請輸入標題' : null,
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '活動描述（選填）',
                border: OutlineInputBorder(),
                hintText: '描述活動內容、地點細節等',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('日期'),
                    subtitle: Text(
                      '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                    ),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('時間'),
                    subtitle: Text(
                      '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Max Participants
            TextFormField(
              controller: _maxParticipantsController,
              decoration: const InputDecoration(
                labelText: '最多參加人數',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return '請輸入人數';
                if (int.tryParse(value!) == null) return '請輸入有效數字';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createActivity,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('建立活動', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }
}
