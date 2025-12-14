import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import '../services/recommendation_service.dart';
import '../services/location_service.dart';
import '../widgets/activity_card.dart';

class NearbyActivitiesScreen extends StatefulWidget {
  const NearbyActivitiesScreen({super.key});

  @override
  State<NearbyActivitiesScreen> createState() => _NearbyActivitiesScreenState();
}

class _NearbyActivitiesScreenState extends State<NearbyActivitiesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final RecommendationService _recommendationService = RecommendationService();
  final LocationService _locationService = LocationService();

  List<Activity> _activities = [];
  bool _isLoading = true;
  Position? _currentPosition;
  String _selectedFilter = 'all';
  StreamSubscription<List<Activity>>? _activitiesSubscription;
  bool _isUsingBackend = false;

  final List<Map<String, String>> _activityTypes = [
    {'key': 'all', 'label': '全部'},
    {'key': 'basketball', 'label': '籃球'},
    {'key': 'badminton', 'label': '羽毛球'},
    {'key': 'running', 'label': '跑步'},
    {'key': 'cycling', 'label': '騎車'},
    {'key': 'swimming', 'label': '游泳'},
    {'key': 'hiking', 'label': '登山'},
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _checkBackendHealth();
  }

  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkBackendHealth() async {
    final isHealthy = await _recommendationService.isBackendHealthy();
    setState(() => _isUsingBackend = isHealthy);
  }

  Future<void> _loadActivities() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Get current location (使用緩存)
      _currentPosition = await _locationService.getCurrentPosition();

      if (_currentPosition != null) {
        // Subscribe to realtime updates
        _activitiesSubscription?.cancel();
        _activitiesSubscription = _databaseService
            .subscribeToNearbyActivities(
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
              radiusKm: 10.0,
            )
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
      print('Error loading activities: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Activity> get _filteredActivities {
    if (_selectedFilter == 'all') return _activities;
    return _activities.where((a) => a.activityType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('附近活動'),
            const SizedBox(width: 8),
            if (_isUsingBackend)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: _loadActivities,
              child: _filteredActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '附近沒有活動',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredActivities.length,
                      itemBuilder: (context, index) {
                        return ActivityCard(
                          activity: _filteredActivities[index],
                          currentPosition: _currentPosition,
                        );
                      },
                    ),
            ),
    );
  }

  // 加載中的骨架屏
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 24,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('篩選活動類型'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _activityTypes.map((type) {
            return RadioListTile<String>(
              title: Text(type['label']!),
              value: type['key']!,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
