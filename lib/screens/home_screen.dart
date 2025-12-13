import 'package:flutter/material.dart';
import 'nearby_activities_screen.dart';
import 'create_activity_screen.dart';
import 'my_activities_screen.dart';
import 'profile_screen.dart';
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
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請允許位置權限以使用附近活動功能'),
          duration: Duration(seconds: 3),
        ),
      );
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '搜尋活動'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: '建立活動',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: '我的活動'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '個人資料'),
        ],
      ),
    );
  }
}
