import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // 位置緩存
  static Position? _cachedPosition;
  static DateTime? _cacheTime;
  static const Duration _cacheValidity = Duration(minutes: 5);
  // Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current position
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    try {
      // 檢查緩存
      if (!forceRefresh && _cachedPosition != null && _cacheTime != null) {
        final cacheAge = DateTime.now().difference(_cacheTime!);
        if (cacheAge < _cacheValidity) {
          print('Using cached location (${cacheAge.inSeconds}s old)');
          return _cachedPosition;
        }
      }

      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        // 如果超時，嘗試使用最後已知位置
        return Geolocator.getLastKnownPosition().then((pos) {
          return pos ?? _cachedPosition ?? (throw TimeoutException('Location timeout'));
        });
      });

      // 更新緩存
      _cachedPosition = position;
      _cacheTime = DateTime.now();
      
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  // Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Stream of position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
