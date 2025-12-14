import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Overpass API service for querying sports facilities
class OverpassService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // 添加缓存以减少重复请求
  static final Map<String, dynamic> _cache = {};
  static DateTime? _lastRequestTime;

  // 最小请求间隔（毫秒）
  static const int _minRequestInterval = 1000;

  /// 運動設施類型映射
  static const Map<String, List<String>> sportFacilityTags = {
    'basketball': ['sport=basketball', 'leisure=pitch&sport=basketball'],
    'badminton': ['sport=badminton', 'leisure=sports_centre&sport=badminton'],
    'tennis': ['sport=tennis', 'leisure=pitch&sport=tennis'],
    'football': ['sport=soccer', 'leisure=pitch&sport=soccer'],
    'running': ['sport=running', 'leisure=track', 'highway=footway'],
    'cycling': ['sport=cycling', 'route=bicycle', 'highway=cycleway'],
    'swimming': ['sport=swimming', 'leisure=swimming_pool'],
    'hiking': ['route=hiking', 'highway=path'],
  };

  /// 查詢附近的運動設施
  Future<List<SportsFacility>> queryNearbyFacilities({
    required double latitude,
    required double longitude,
    double radiusMeters = 500,
  }) async {
    try {
      // 生成缓存键
      final cacheKey =
          '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_$radiusMeters';

      // 检查缓存
      if (_cache.containsKey(cacheKey)) {
        print('Using cached Overpass data for $cacheKey');
        return _cache[cacheKey] as List<SportsFacility>;
      }

      // 限制请求频率
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now()
            .difference(_lastRequestTime!)
            .inMilliseconds;
        if (timeSinceLastRequest < _minRequestInterval) {
          await Future.delayed(
            Duration(milliseconds: _minRequestInterval - timeSinceLastRequest),
          );
        }
      }

      _lastRequestTime = DateTime.now();

      // 構建 Overpass QL 查詢
      final query = _buildOverpassQuery(latitude, longitude, radiusMeters);

      final response = await http
          .post(
            Uri.parse(_overpassUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 8), onTimeout: () {
            print('Overpass API timeout, returning empty result');
            return http.Response('{"elements":[]}', 200);
          });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final facilities = _parseFacilities(data);

        // 缓存结果（5分钟）
        _cache[cacheKey] = facilities;
        Future.delayed(
          const Duration(minutes: 5),
          () => _cache.remove(cacheKey),
        );

        return facilities;
      } else if (response.statusCode == 429) {
        print('Overpass API rate limit exceeded, using empty result');
        return [];
      } else {
        print('Overpass API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error querying Overpass API: $e');
      return [];
    }
  }

  /// 檢測位置適合的運動類型
  Future<List<String>> detectSuitableSports({
    required double latitude,
    required double longitude,
    double radiusMeters = 300,
  }) async {
    // 使用更短的超時時間來加快檢測速度
    try {
      final facilities = await queryNearbyFacilities(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Sport detection timeout, returning empty list');
          return [];
        },
      );

      if (facilities.isEmpty) {
        return [];
      }

      // 統計各種運動設施的數量
      final sportCounts = <String, int>{};
      for (final facility in facilities) {
        for (final sport in facility.suitableSports) {
          sportCounts[sport] = (sportCounts[sport] ?? 0) + 1;
        }
      }

      // 返回有設施的運動類型，按數量排序
      final suitableSports =
          sportCounts.entries.where((e) => e.value > 0).toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return suitableSports.map((e) => e.key).toList();
    } catch (e) {
      print('Error detecting suitable sports: $e');
      return [];
    }
  }

  /// 建構 Overpass 查詢語句
  String _buildOverpassQuery(double lat, double lon, double radius) {
    return '''
[out:json][timeout:10];
(
  node["leisure"="pitch"](around:$radius,$lat,$lon);
  node["leisure"="sports_centre"](around:$radius,$lat,$lon);
  node["leisure"="swimming_pool"](around:$radius,$lat,$lon);
  node["leisure"="track"](around:$radius,$lat,$lon);
  node["sport"](around:$radius,$lat,$lon);
  way["leisure"="pitch"](around:$radius,$lat,$lon);
  way["leisure"="sports_centre"](around:$radius,$lat,$lon);
  way["leisure"="swimming_pool"](around:$radius,$lat,$lon);
  way["leisure"="track"](around:$radius,$lat,$lon);
  way["sport"](around:$radius,$lat,$lon);
);
out center;
''';
  }

  /// 解析設施資料
  List<SportsFacility> _parseFacilities(Map<String, dynamic> data) {
    final facilities = <SportsFacility>[];
    final elements = data['elements'] as List<dynamic>? ?? [];

    for (final element in elements) {
      try {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        double? lat, lon;

        if (element['type'] == 'node') {
          lat = element['lat']?.toDouble();
          lon = element['lon']?.toDouble();
        } else if (element['type'] == 'way' && element['center'] != null) {
          lat = element['center']['lat']?.toDouble();
          lon = element['center']['lon']?.toDouble();
        }

        if (lat == null || lon == null) continue;

        final facility = SportsFacility(
          id: element['id'].toString(),
          name: tags['name'] ?? '運動設施',
          location: LatLng(lat, lon),
          type: tags['leisure'] ?? tags['sport'] ?? 'unknown',
          tags: tags,
          suitableSports: _detectSportsFromTags(tags),
        );

        facilities.add(facility);
      } catch (e) {
        print('Error parsing facility: $e');
      }
    }

    return facilities;
  }

  /// 從標籤檢測適合的運動類型
  List<String> _detectSportsFromTags(Map<String, dynamic> tags) {
    final sports = <String>[];

    // 檢查 sport 標籤
    final sportTag = tags['sport']?.toString().toLowerCase();
    if (sportTag != null) {
      if (sportTag.contains('basketball')) sports.add('basketball');
      if (sportTag.contains('badminton')) sports.add('badminton');
      if (sportTag.contains('tennis')) sports.add('tennis');
      if (sportTag.contains('soccer') || sportTag.contains('football')) {
        sports.add('football');
      }
      if (sportTag.contains('running')) sports.add('running');
      if (sportTag.contains('cycling')) sports.add('cycling');
      if (sportTag.contains('swimming')) sports.add('swimming');
    }

    // 檢查 leisure 標籤
    final leisureTag = tags['leisure']?.toString().toLowerCase();
    if (leisureTag != null) {
      if (leisureTag == 'pitch') {
        // 球場可能適合多種運動
        if (!sports.contains('basketball')) sports.add('basketball');
        if (!sports.contains('football')) sports.add('football');
      }
      if (leisureTag == 'swimming_pool') sports.add('swimming');
      if (leisureTag == 'track') sports.add('running');
      if (leisureTag == 'sports_centre') {
        // 運動中心通常有多種設施
        sports.addAll(['basketball', 'badminton']);
      }
    }

    return sports;
  }

  /// 獲取運動類型的中文名稱
  static String getSportNameChinese(String sportKey) {
    const names = {
      'basketball': '籃球',
      'badminton': '羽毛球',
      'tennis': '網球',
      'football': '足球',
      'running': '跑步',
      'cycling': '騎車',
      'swimming': '游泳',
      'hiking': '登山',
    };
    return names[sportKey] ?? sportKey;
  }

  /// 獲取運動類型的圖示
  static String getSportEmoji(String sportKey) {
    const emojis = {
      'basketball': '🏀',
      'badminton': '🏸',
      'tennis': '🎾',
      'football': '⚽',
      'running': '🏃',
      'cycling': '🚴',
      'swimming': '🏊',
      'hiking': '⛰️',
    };
    return emojis[sportKey] ?? '🏃';
  }
}

/// 運動設施資料模型
class SportsFacility {
  final String id;
  final String name;
  final LatLng location;
  final String type;
  final Map<String, dynamic> tags;
  final List<String> suitableSports;

  SportsFacility({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.tags,
    required this.suitableSports,
  });

  String get displayName {
    if (name != '運動設施') return name;
    if (suitableSports.isNotEmpty) {
      return suitableSports
          .map((s) => OverpassService.getSportNameChinese(s))
          .join('/');
    }
    return '運動場地';
  }
}
