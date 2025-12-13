import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';

class SportsPreferencesScreen extends StatefulWidget {
  const SportsPreferencesScreen({super.key});

  @override
  State<SportsPreferencesScreen> createState() => _SportsPreferencesScreenState();
}

class _SportsPreferencesScreenState extends State<SportsPreferencesScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  
  final List<String> _availableSports = [
    '籃球',
    '足球',
    '羽毛球',
    '網球',
    '乒乓球',
    '排球',
    '游泳',
    '跑步',
    '健身',
    '瑜伽',
    '登山',
    '騎自行車',
  ];
  
  Set<String> _selectedSports = {};
  bool _isLoading = false;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        final profile = await _databaseService.getUserProfile(userId);
        setState(() {
          _profile = profile;
          _selectedSports = Set<String>.from(profile?.interests ?? []);
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_profile == null) return;
    
    setState(() => _isLoading = true);

    try {
      final updatedProfile = _profile!.copyWith(
        interests: _selectedSports.toList(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('運動偏好已更新')),
        );
        Navigator.pop(context);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('運動偏好'),
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
              onPressed: _savePreferences,
              child: const Text('儲存'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '選擇你喜歡的運動',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '選擇的運動將幫助我們為你推薦更合適的活動',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSports.map((sport) {
                    final isSelected = _selectedSports.contains(sport);
                    return FilterChip(
                      label: Text(sport),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSports.add(sport);
                          } else {
                            _selectedSports.remove(sport);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
