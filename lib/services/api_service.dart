import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/activity.dart';
import '../models/user_profile.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  // Helper method to build headers
  Map<String, String> _buildHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Check server health
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl.replaceAll('/api', '')}/'))
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // User endpoints
  Future<UserProfile> syncUser(UserProfile user, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/users/sync'),
            headers: _buildHeaders(token: token),
            body: json.encode(user.toJson()),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('User sync failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserProfile> getUser(String userId, String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/$userId'),
            headers: _buildHeaders(token: token),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Get user failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Activity endpoints
  Future<List<Activity>> getNearbyActivities({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    String? token,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/activities/nearby',
      ).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _buildHeaders(token: token))
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Activity.fromJson(json)).toList();
      } else {
        throw Exception('Get nearby activities failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Activity> createActivity(Activity activity, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/activities'),
            headers: _buildHeaders(token: token),
            body: json.encode(activity.toJson()),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Activity.fromJson(json.decode(response.body));
      } else {
        throw Exception('Create activity failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Activity> getActivity(String activityId, String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/activities/$activityId'),
            headers: _buildHeaders(token: token),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return Activity.fromJson(json.decode(response.body));
      } else {
        throw Exception('Get activity failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinActivity(String activityId, String token) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/activities/$activityId/join'),
            headers: _buildHeaders(token: token),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Join activity failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveActivity(String activityId, String token) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/activities/$activityId/leave'),
            headers: _buildHeaders(token: token),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Leave activity failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Activity>> getUserActivities(String userId, String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/users/$userId/activities'),
            headers: _buildHeaders(token: token),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Activity.fromJson(json)).toList();
      } else {
        throw Exception('Get user activities failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cleanup
  void dispose() {
    _client.close();
  }
}
