import 'package:flutter/material.dart';
import 'nearby_activities_screen.dart';
import 'create_activity_screen.dart';
import 'my_activities_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final LocationService _locationService = LocationService();

  final List<Widget> _screens = [
    const NearbyActivitiesScreen(),
    const CreateActivityScreen(),
    const MyActivitiesScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 延遲請求權限避免阻塞啟動
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _requestLocationPermission();
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      final hasPermission = await _locationService.checkPermissions()
          .timeout(const Duration(seconds: 3));
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('請允許位置權限以使用附近活動功能'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '搜尋'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: '建立',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: '活動'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '聊天'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
