import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/activity_card.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  List<Activity> _activities = [];
  bool _isLoading = true;
  StreamSubscription<List<Activity>>? _activitiesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMyActivities();
  }

  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMyActivities() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        // Subscribe to realtime updates
        _activitiesSubscription?.cancel();
        _activitiesSubscription = _databaseService
            .subscribeToUserActivities(userId)
            .listen((activities) {
              if (mounted) {
                setState(() {
                  _activities = activities;
                  _isLoading = false;
                });
              }
            });
      }
    } catch (e) {
      print('Error loading my activities: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的活動')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMyActivities,
              child: _activities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '您還沒有建立任何活動',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        return ActivityCard(activity: _activities[index]);
                      },
                    ),
            ),
    );
  }
}
