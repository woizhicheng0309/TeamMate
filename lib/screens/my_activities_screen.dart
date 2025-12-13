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

class _MyActivitiesScreenState extends State<MyActivitiesScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  
  List<Activity> _createdActivities = [];
  List<Activity> _joinedActivities = [];
  Map<String, int> _pendingCounts = {};
  bool _isLoadingCreated = true;
  bool _isLoadingJoined = true;
  
  StreamSubscription<List<Activity>>? _createdSubscription;
  StreamSubscription<List<Activity>>? _joinedSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createdSubscription?.cancel();
    _joinedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    // Load created activities
    _createdSubscription?.cancel();
    _createdSubscription = _databaseService
        .subscribeToUserActivities(userId)
        .listen((activities) async {
          if (mounted) {
            setState(() {
              _createdActivities = activities;
              _isLoadingCreated = false;
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

    // Load joined activities
    _joinedSubscription?.cancel();
    _joinedSubscription = _databaseService
        .subscribeToJoinedActivities(userId)
        .listen((activities) {
          if (mounted) {
            setState(() {
              _joinedActivities = activities;
              _isLoadingJoined = false;
            });
          }
        });
  }

  Widget _buildActivityList(List<Activity> activities, bool isLoading,
      {bool showPendingCount = false}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              showPendingCount ? '您還沒有加入任何活動' : '您還沒有建立任何活動',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final pendingCount = _pendingCounts[activity.id] ?? 0;

        return Stack(
          children: [
            ActivityCard(activity: activity),
            if (showPendingCount && pendingCount > 0)
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
                      pendingCount > 99 ? '99+' : '$pendingCount',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的活動'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.create),
              text: '我創辦的',
            ),
            Tab(
              icon: Icon(Icons.group),
              text: '我加入的',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
              await _loadActivities();
            },
            child: _buildActivityList(
              _createdActivities,
              _isLoadingCreated,
              showPendingCount: true,
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
              await _loadActivities();
            },
            child: _buildActivityList(
              _joinedActivities,
              _isLoadingJoined,
              showPendingCount: false,
            ),
          ),
        ],
      ),
    );
  }
}
