import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';

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

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '10');

  String _selectedActivityType = 'basketball';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String? _address;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  final List<Map<String, String>> _activityTypes = [
    {'key': 'basketball', 'label': '籃球', 'icon': '🏀'},
    {'key': 'badminton', 'label': '羽毛球', 'icon': '🏸'},
    {'key': 'running', 'label': '跑步', 'icon': '🏃'},
    {'key': 'cycling', 'label': '騎車', 'icon': '🚴'},
    {'key': 'swimming', 'label': '游泳', 'icon': '🏊'},
    {'key': 'hiking', 'label': '登山', 'icon': '⛰️'},
    {'key': 'tennis', 'label': '網球', 'icon': '🎾'},
    {'key': 'football', 'label': '足球', 'icon': '⚽'},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('Starting to get location...');
      final position = await _locationService.getCurrentPosition();
      print('Position: $position');

      if (position != null) {
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        print('Address: $address');

        if (mounted) {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _address = address;
          });
        }
      } else {
        print('Position is null');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('無法獲取位置，請檢查權限設定')));
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('位置錯誤: $e')));
      }
    }
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請允許位置權限')));
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

      final activity = Activity(
        id: const Uuid().v4(),
        creatorId: _authService.currentUser!.id,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        activityType: _selectedActivityType,
        eventDate: eventDateTime,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
        maxParticipants: int.parse(_maxParticipantsController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.createActivity(activity);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('活動建立成功！')));

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _formKey.currentState!.reset();
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
    return Scaffold(
      appBar: AppBar(title: const Text('建立新活動')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Activity Type Selection
            const Text(
              '活動類型',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activityTypes.map((type) {
                return ChoiceChip(
                  label: Text('${type['icon']} ${type['label']}'),
                  selected: _selectedActivityType == type['key'],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedActivityType = type['key']!);
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

            const SizedBox(height: 16),

            // Location
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('活動地點'),
                subtitle: Text(_address ?? '獲取位置中...'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _getCurrentLocation,
                ),
              ),
            ),

            const SizedBox(height: 24),

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
