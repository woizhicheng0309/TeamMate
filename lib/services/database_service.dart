import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity.dart';
import '../models/user_profile.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Realtime subscriptions
  RealtimeChannel? _activitiesChannel;
  final _activitiesStreamController =
      StreamController<List<Activity>>.broadcast();

  // User Profile Operations
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('users')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Upsert user record (ensure FK for activities.creator_id exists)
  Future<void> upsertUser({
    required String id,
    required String email,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      await _supabase.from('users').upsert({
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error upserting user: $e');
      rethrow;
    }
  }

  // Activity Operations
  Future<List<Activity>> getNearbyActivities({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Using PostGIS for geospatial queries
      final response = await _supabase
          .from('activities')
          .select()
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true);

      final activities = (response as List)
          .map((json) => Activity.fromJson(json))
          .toList();

      // Filter by distance (you can implement PostGIS distance query on backend)
      return activities;
    } catch (e) {
      print('Error getting nearby activities: $e');
      return [];
    }
  }

  Future<Activity> createActivity(Activity activity) async {
    try {
      final response = await _supabase
          .from('activities')
          .insert(activity.toJson())
          .select()
          .single();

      return Activity.fromJson(response);
    } catch (e) {
      print('Error creating activity: $e');
      rethrow;
    }
  }

  Future<void> joinActivity(String activityId, String userId) async {
    try {
      await _supabase.from('activity_participants').insert({
        'activity_id': activityId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error joining activity: $e');
      rethrow;
    }
  }

  Future<List<Activity>> getUserActivities(String userId) async {
    try {
      final response = await _supabase
          .from('activities')
          .select()
          .eq('creator_id', userId)
          .order('event_date', ascending: false);

      return (response as List).map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user activities: $e');
      return [];
    }
  }

  // Rating Operations
  Future<void> rateActivity(
    String activityId,
    String userId,
    int rating,
    String? comment,
  ) async {
    try {
      await _supabase.from('ratings').insert({
        'activity_id': activityId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error rating activity: $e');
      rethrow;
    }
  }

  // Realtime subscriptions
  Stream<List<Activity>> subscribeToNearbyActivities({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) {
    // Cancel previous subscription
    _activitiesChannel?.unsubscribe();

    // Subscribe to activities table changes
    _activitiesChannel = _supabase
        .channel('activities_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activities',
          callback: (payload) async {
            // Fetch updated activities when changes occur
            final activities = await getNearbyActivities(
              latitude: latitude,
              longitude: longitude,
              radiusKm: radiusKm,
            );
            _activitiesStreamController.add(activities);
          },
        )
        .subscribe();

    // Initial load
    getNearbyActivities(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    ).then((activities) {
      _activitiesStreamController.add(activities);
    });

    return _activitiesStreamController.stream;
  }

  Stream<List<Activity>> subscribeToUserActivities(String userId) {
    final controller = StreamController<List<Activity>>.broadcast();

    final channel = _supabase
        .channel('user_activities_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activities',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'creator_id',
            value: userId,
          ),
          callback: (payload) async {
            final activities = await getUserActivities(userId);
            controller.add(activities);
          },
        )
        .subscribe();

    // Initial load
    getUserActivities(userId).then((activities) {
      controller.add(activities);
    });

    // Cleanup when stream is cancelled
    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  // Cleanup
  void dispose() {
    _activitiesChannel?.unsubscribe();
    _activitiesStreamController.close();
  }
}
