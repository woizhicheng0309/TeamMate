import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../models/check_in_record.dart';

class CheckInService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate 4-digit check-in code
  String generateCheckInCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // Check if user is within range of activity location (within 100 meters)
  bool isWithinRange(
    double userLat,
    double userLng,
    double activityLat,
    double activityLng,
    double radiusInMeters,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _toRadians(activityLat - userLat);
    final dLng = _toRadians(activityLng - userLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(userLat)) *
            cos(_toRadians(activityLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadiusMeters * c;

    return distance <= radiusInMeters;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Creator checks in at activity location
  Future<String?> creatorCheckIn({
    required String activityId,
    required double activityLat,
    required double activityLng,
  }) async {
    try {
      // Request location permission
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Check if within 100 meters of activity location
      if (!isWithinRange(
        position.latitude,
        position.longitude,
        activityLat,
        activityLng,
        100,
      )) {
        return null;
      }

      // Generate check-in code
      final checkInCode = generateCheckInCode();

      // Update activity with check-in info
      await _supabase
          .from('activities')
          .update({
            'check_in_code': checkInCode,
            'creator_checked_in': true,
            'creator_check_in_time': DateTime.now().toIso8601String(),
            'creator_check_in_location':
                '(${position.longitude},${position.latitude})', // PostgreSQL point format: (longitude, latitude)
          })
          .eq('id', activityId);

      return checkInCode;
    } catch (e) {
      return null;
    }
  }

  // Participant checks in with code
  Future<bool> participantCheckIn({
    required String activityId,
    required String userId,
    required String enteredCode,
    required double activityLat,
    required double activityLng,
  }) async {
    try {
      // Get activity check-in code
      final activity = await _supabase
          .from('activities')
          .select('check_in_code, creator_checked_in')
          .eq('id', activityId)
          .single();

      // Handle both string and int types for check_in_code
      var correctCode = activity['check_in_code'];
      if (correctCode is int) {
        correctCode = correctCode.toString();
      }
      correctCode = correctCode as String?;

      final creatorCheckedIn = activity['creator_checked_in'] as bool? ?? false;

      // Verify creator has checked in
      if (!creatorCheckedIn) {
        return false;
      }

      // Verify code (compare as strings)
      if (correctCode == null || enteredCode.trim() != correctCode.trim()) {
        return false;
      }

      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Check if within 100 meters of activity location
      if (!isWithinRange(
        position.latitude,
        position.longitude,
        activityLat,
        activityLng,
        100,
      )) {
        return false;
      }

      // Update check-in record
      await _supabase.from('participants_check_in').upsert({
        'activity_id': activityId,
        'user_id': userId,
        'checked_in': true,
        'check_in_time': DateTime.now().toIso8601String(),
        'check_in_location':
            '(${position.longitude},${position.latitude})', // PostgreSQL point format: (longitude, latitude)
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get check-in records for activity
  Stream<List<CheckInRecord>> getActivityCheckInRecords(String activityId) {
    return _supabase
        .from('participants_check_in')
        .stream(primaryKey: ['id'])
        .eq('activity_id', activityId)
        .map(
          (data) => data.map((json) => CheckInRecord.fromJson(json)).toList(),
        );
  }

  // Get check-in status for a participant
  Future<CheckInRecord?> getParticipantCheckInStatus(
    String activityId,
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('participants_check_in')
          .select()
          .eq('activity_id', activityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return CheckInRecord.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Mark activity as failed if creator didn't check in within time
  Future<void> markActivityAsFailed(String activityId) async {
    try {
      await _supabase
          .from('activities')
          .update({'status': 'failed'})
          .eq('id', activityId);
    } catch (e) {
      rethrow;
    }
  }
}
