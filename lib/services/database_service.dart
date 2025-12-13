import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity.dart';
import '../models/user_profile.dart';
import '../models/join_request.dart';

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

      final createdActivity = Activity.fromJson(response);

      // 自動將創建者加入活動
      await joinActivity(createdActivity.id, createdActivity.creatorId);

      return createdActivity;
    } catch (e) {
      print('Error creating activity: $e');
      rethrow;
    }
  }

  Future<void> joinActivity(String activityId, String userId) async {
    try {
      // 檢查是否已經加入
      final existing = await _supabase
          .from('participants')
          .select()
          .eq('activity_id', activityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // 已經是參與者，直接返回
        return;
      }

      // 插入參與者記錄
      await _supabase.from('participants').insert({
        'activity_id': activityId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // 更新活動的當前參加人數
      final activity = await _supabase
          .from('activities')
          .select('current_participants, title')
          .eq('id', activityId)
          .single();

      await _supabase
          .from('activities')
          .update({
            'current_participants': (activity['current_participants'] ?? 0) + 1,
          })
          .eq('id', activityId);

      // 自動加入群組聊天
      await _joinActivityGroupChat(activityId, userId, activity['title'] ?? '活動');
    } catch (e) {
      print('Error joining activity: $e');
      rethrow;
    }
  }

  Future<void> _joinActivityGroupChat(
    String activityId,
    String userId,
    String activityTitle,
  ) async {
    try {
      // 獲取所有參與者 ID
      final participantsData = await _supabase
          .from('participants')
          .select('user_id')
          .eq('activity_id', activityId);

      final participantIds = <String>{};
      for (final p in participantsData as List) {
        participantIds.add(p['user_id'] as String);
      }

      // 檢查是否已有群組聊天
      final existingChat = await _supabase
          .from('chats')
          .select('id, participants')
          .eq('activity_id', activityId)
          .eq('type', 'group')
          .maybeSingle();

      if (existingChat != null) {
        // 更新參與者列表
        final currentParticipants = Set<String>.from(
          (existingChat['participants'] as List<dynamic>)
              .map((e) => e.toString()),
        );
        currentParticipants.addAll(participantIds);

        await _supabase
            .from('chats')
            .update({
              'participants': currentParticipants.toList(),
            })
            .eq('id', existingChat['id']);
      } else {
        // 創建新群組聊天
        await _supabase.from('chats').insert({
          'type': 'group',
          'activity_id': activityId,
          'name': activityTitle,
          'participants': participantIds.toList(),
          'last_message': null,
          'last_message_time': DateTime.now().toIso8601String(),
        });
      }

      print('✅ 成功加入群組聊天: $activityTitle');
    } catch (e) {
      print('⚠️ 加入群組聊天失敗: $e');
      // 不拋出異常，以免影響加入活動的主流程
    }
  }

  Future<void> leaveActivity(String activityId, String userId) async {
    try {
      // 刪除參與者記錄
      await _supabase
          .from('participants')
          .delete()
          .eq('activity_id', activityId)
          .eq('user_id', userId);

      // 刪除相關的加入申請記錄，這樣用戶可以重新申請
      await _supabase
          .from('join_requests')
          .delete()
          .eq('activity_id', activityId)
          .eq('user_id', userId);

      // 更新活動的當前參加人數
      final activity = await _supabase
          .from('activities')
          .select('current_participants')
          .eq('id', activityId)
          .single();

      await _supabase
          .from('activities')
          .update({
            'current_participants':
                ((activity['current_participants'] ?? 1) - 1).clamp(0, 999),
          })
          .eq('id', activityId);
    } catch (e) {
      print('Error leaving activity: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getActivityParticipants(
    String activityId,
  ) async {
    try {
      final response = await _supabase
          .from('participants')
          .select('user_id, users(email, full_name, avatar_url)')
          .eq('activity_id', activityId);

      return (response as List).map((item) {
        return {
          'user_id': item['user_id'],
          'email': item['users']?['email'],
          'full_name': item['users']?['full_name'],
          'avatar_url': item['users']?['avatar_url'],
        };
      }).toList();
    } catch (e) {
      print('Error getting activity participants: $e');
      return [];
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

  Future<void> deleteActivity(String activityId) async {
    try {
      // 由於有 CASCADE 外鍵，刪除活動會自動刪除相關的參與者、評分、聊天等記錄
      await _supabase.from('activities').delete().eq('id', activityId);
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }

  Future<void> endActivity(String activityId) async {
    try {
      await _supabase
          .from('activities')
          .update({'status': 'ended'})
          .eq('id', activityId);
    } catch (e) {
      print('Error ending activity: $e');
      rethrow;
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

  // Join Request Operations
  Future<void> createJoinRequest(String activityId, String userId) async {
    try {
      // 檢查是否已有待處理的申請
      final existing = await _supabase
          .from('join_requests')
          .select()
          .eq('activity_id', activityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        if (existing['status'] == 'pending') {
          throw Exception('您已經提交過申請，請等待創建者回應');
        } else if (existing['status'] == 'accepted') {
          throw Exception('您的申請已經被接受');
        } else if (existing['status'] == 'rejected') {
          // 如果之前被拒絕，可以重新申請
          await _supabase
              .from('join_requests')
              .update({
                'status': 'pending',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing['id']);
          return;
        }
      }

      // 創建新申請
      await _supabase.from('join_requests').insert({
        'activity_id': activityId,
        'user_id': userId,
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating join request: $e');
      rethrow;
    }
  }

  Future<List<JoinRequest>> getActivityJoinRequests(
    String activityId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('join_requests')
          .select('''
            *,
            user:users(id, full_name, email, avatar_url)
          ''')
          .eq('activity_id', activityId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => JoinRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting join requests: $e');
      return [];
    }
  }

  Future<int> getPendingRequestCount(String activityId) async {
    try {
      final response = await _supabase
          .from('join_requests')
          .select()
          .eq('activity_id', activityId)
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      print('Error getting pending request count: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getPendingRequestCounts(
    List<String> activityIds,
  ) async {
    try {
      final response = await _supabase
          .from('join_requests')
          .select('activity_id')
          .inFilter('activity_id', activityIds)
          .eq('status', 'pending');

      final counts = <String, int>{};
      for (final activityId in activityIds) {
        counts[activityId] = 0;
      }

      for (final item in response) {
        final activityId = item['activity_id'] as String;
        counts[activityId] = (counts[activityId] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting pending request counts: $e');
      return {};
    }
  }

  Future<void> acceptJoinRequest(String requestId) async {
    try {
      // 獲取申請資訊
      final request = await _supabase
          .from('join_requests')
          .select()
          .eq('id', requestId)
          .single();

      final activityId = request['activity_id'] as String;
      final userId = request['user_id'] as String;

      // 檢查是否已經是參與者
      final existing = await _supabase
          .from('participants')
          .select()
          .eq('activity_id', activityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // 添加為參與者
        await _supabase.from('participants').insert({
          'activity_id': activityId,
          'user_id': userId,
        });

        // 更新活動參與人數
        final activity = await _supabase
            .from('activities')
            .select('current_participants')
            .eq('id', activityId)
            .single();

        await _supabase
            .from('activities')
            .update({
              'current_participants':
                  (activity['current_participants'] ?? 0) + 1,
            })
            .eq('id', activityId);

        // 獲取群組聊天並添加用戶
        final groupChat = await _supabase
            .from('chats')
            .select()
            .eq('activity_id', activityId)
            .eq('type', 'group')
            .maybeSingle();

        if (groupChat != null) {
          final chatId = groupChat['id'];
          final participants = List<String>.from(
            groupChat['participants'] ?? [],
          );
          if (!participants.contains(userId)) {
            participants.add(userId);
            await _supabase
                .from('chats')
                .update({'participants': participants})
                .eq('id', chatId);
          }
        }
      }

      // 更新申請狀態為已接受
      await _supabase
          .from('join_requests')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      print('Error accepting join request: $e');
      rethrow;
    }
  }

  Future<void> rejectJoinRequest(String requestId) async {
    try {
      await _supabase
          .from('join_requests')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      print('Error rejecting join request: $e');
      rethrow;
    }
  }

  // Cleanup
  void dispose() {
    _activitiesChannel?.unsubscribe();
    _activitiesStreamController.close();
  }
}
