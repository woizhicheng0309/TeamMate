import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';
import '../models/activity.dart';
import '../models/user_profile.dart';

/// Recommendation service that combines Supabase data with AWS backend intelligence
class RecommendationService {
  final ApiService _apiService = ApiService();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get recommended activities using AWS backend ML/algorithm
  /// Falls back to Supabase if backend unavailable
  Future<List<Activity>> getRecommendedActivities({
    required String userId,
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Try to get intelligent recommendations from AWS backend
      final token = _supabase.auth.currentSession?.accessToken;
      if (token != null) {
        final activities = await _apiService.getNearbyActivities(
          latitude: latitude,
          longitude: longitude,
          radius: radiusKm,
          token: token,
        );
        print(
          '✅ Got ${activities.length} recommended activities from AWS backend',
        );
        return activities;
      }
    } catch (e) {
      print('⚠️ AWS backend unavailable, falling back to Supabase: $e');
    }

    // Fallback: Use Supabase direct query
    try {
      final response = await _supabase
          .from('activities')
          .select()
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true)
          .limit(20);

      final activities = (response as List)
          .map((json) => Activity.fromJson(json))
          .toList();

      print('📊 Got ${activities.length} activities from Supabase');
      return activities;
    } catch (e) {
      print('Error getting activities from Supabase: $e');
      return [];
    }
  }

  /// Sync user profile to AWS backend for better recommendations
  Future<void> syncUserProfile(UserProfile user) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token != null) {
        await _apiService.syncUser(user, token);
        print('✅ User profile synced to AWS backend');
      }
    } catch (e) {
      print('⚠️ Failed to sync user to AWS backend: $e');
      // Non-critical, continue without backend sync
    }
  }

  /// Get similar users for matching (AWS backend feature)
  Future<List<UserProfile>> getSimilarUsers({
    required String userId,
    required String activityType,
  }) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) return [];

      // TODO: Implement when AWS backend adds this endpoint
      // final response = await _apiService.getSimilarUsers(userId, activityType, token);

      print('ℹ️ Similar users feature pending AWS backend implementation');
      return [];
    } catch (e) {
      print('Error getting similar users: $e');
      return [];
    }
  }

  /// Get activity analytics from AWS backend
  Future<Map<String, dynamic>> getActivityAnalytics(String activityId) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) return {};

      // TODO: Implement when AWS backend adds analytics endpoint
      print('ℹ️ Activity analytics feature pending AWS backend implementation');
      return {};
    } catch (e) {
      print('Error getting activity analytics: $e');
      return {};
    }
  }

  /// Check AWS backend health
  Future<bool> isBackendHealthy() async {
    try {
      final health = await _apiService.checkHealth();
      return health['status'] == 'running';
    } catch (e) {
      return false;
    }
  }
}
