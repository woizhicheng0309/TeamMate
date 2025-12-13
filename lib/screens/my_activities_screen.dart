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
  Map<String, int> _pendingCounts = {};
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
            .listen((activities) async {
              if (mounted) {
                setState(() {
                  _activities = activities;
                  _isLoading = false;
                });

                // 加載待處理申請數量
                if (activities.isNotEmpty) {
                  final activityIds = activities.map((a) => a.id).toList();
                  final counts = await _databaseService.getPendingRequestCounts(
                    activityIds,
                  );
                  if (mounted) {
                    setState(() {
                      _pendingCounts = counts;
                    });
                  }
                }
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
                        final activity = _activities[index];
                        final pendingCount = _pendingCounts[activity.id] ?? 0;

                        return Stack(
                          children: [
                            ActivityCard(activity: activity),
                            if (pendingCount > 0)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      pendingCount > 99
                                          ? '99+'
                                          : '$pendingCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
    );
  }
}
