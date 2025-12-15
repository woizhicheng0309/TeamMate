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
        return activities;
      }
    } catch (e) {
      // Silent fail - fallback to Supabase
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

      return activities;
    } catch (e) {
      return [];
    }
  }

  /// Sync user profile to AWS backend for better recommendations
  Future<void> syncUserProfile(UserProfile user) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token != null) {
        await _apiService.syncUser(user, token);
      }
    } catch (e) {
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

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get activity analytics from AWS backend
  Future<Map<String, dynamic>> getActivityAnalytics(String activityId) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) return {};

      // TODO: Implement when AWS backend adds analytics endpoint
      return {};
    } catch (e) {
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
