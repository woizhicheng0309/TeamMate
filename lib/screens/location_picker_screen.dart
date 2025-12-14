import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/overpass_service.dart';
import '../services/database_service.dart';
import '../models/activity.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final bool showActivities; // 是否顯示其他活動
  final bool detectFacilities; // 是否檢測設施

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.showActivities = false,
    this.detectFacilities = true,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(24.1797, 120.6486); // 台中預設
  String _selectedAddress = '載入中...';
  bool _isLoading = false;

  final OverpassService _overpassService = OverpassService();
  final DatabaseService _databaseService = DatabaseService();

  List<SportsFacility> _facilities = [];
  List<Activity> _nearbyActivities = [];
  Set<Marker> _markers = {};
  List<String> _suitableSports = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _updateAddress(_selectedLocation);
      // 延遲加載設施以加快地圖顯示
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (widget.detectFacilities) {
          _loadFacilitiesAndSports(_selectedLocation);
        }
        if (widget.showActivities) {
          _loadNearbyActivities(_selectedLocation);
        }
      });
    } else {
      // 没有初始位置时才获取当前位置
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selectedLocation = newLocation);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 15),
      );

      await _updateAddress(newLocation);

      // 获取当前位置后加载设施
      if (widget.detectFacilities) {
        _loadFacilitiesAndSports(newLocation);
      }
      if (widget.showActivities) {
        _loadNearbyActivities(newLocation);
      }
    } catch (e) {
      print('Error getting current location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateAddress(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _selectedAddress = [
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
            ].where((s) => s != null && s.isNotEmpty).join(', ');
          });
        }
      }
    } catch (e) {
      print('Error getting address: $e');
      if (mounted) {
        setState(() {
          _selectedAddress =
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
      }
    }
  }

  void _onMapTapped(LatLng location) {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
      _selectedAddress = '載入中...';
    });
    _updateAddress(location);

    // 延遲載入設施以避免過度查詢（減少延遲時間以提升響應速度）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (widget.detectFacilities) {
        _loadFacilitiesAndSports(location);
      }
      if (widget.showActivities) {
        _loadNearbyActivities(location);
      }
    });
  }

  /// 載入運動設施和檢測適合的運動
  Future<void> _loadFacilitiesAndSports(LatLng location) async {
    try {
      // 並行查詢以加快速度
      final results = await Future.wait([
        _overpassService.queryNearbyFacilities(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusMeters: 50,
        ),
        _overpassService.detectSuitableSports(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusMeters: 50,
        ),
      ]);

      if (mounted) {
        setState(() {
          _facilities = results[0] as List<SportsFacility>;
          _suitableSports = results[1] as List<String>;
        });
        _updateMarkers();
      }
    } catch (e) {
      print('Error loading facilities: $e');
    }
  }

  /// 載入附近的活動
  Future<void> _loadNearbyActivities(LatLng location) async {
    try {
      final activities = await _databaseService.getNearbyActivities(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: 5.0,
      );

      if (mounted) {
        setState(() {
          _nearbyActivities = activities;
        });
        _updateMarkers();
      }
    } catch (e) {
      print('Error loading activities: $e');
    }
  }

  /// 更新地圖標記
  void _updateMarkers() {
    final markers = <Marker>{};

    // 選擇的位置標記
    markers.add(
      Marker(
        markerId: const MarkerId('selected'),
        position: _selectedLocation,
        draggable: true,
        onDragEnd: _onMapTapped,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: '選擇的位置',
          snippet: _suitableSports.isNotEmpty
              ? '適合: ${_suitableSports.map((s) => OverpassService.getSportNameChinese(s)).join(', ')}'
              : '附近無運動設施',
        ),
      ),
    );

    // 活動標記
    for (final activity in _nearbyActivities) {
      markers.add(
        Marker(
          markerId: MarkerId('activity_${activity.id}'),
          position: LatLng(activity.latitude, activity.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title:
                '${OverpassService.getSportEmoji(activity.activityType)} ${activity.title}',
            snippet:
                '${activity.currentParticipants}/${activity.maxParticipants} 人',
          ),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'location': _selectedLocation,
      'address': _selectedAddress,
      'suitableSports': _suitableSports,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇活動地點'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
            tooltip: '確認',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            onCameraMove: (position) {
              // 延遲重新載入以避免過度查詢
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                if (widget.detectFacilities || widget.showActivities) {
                  final center = position.target;
                  if (widget.detectFacilities) {
                    _loadFacilitiesAndSports(center);
                  }
                  if (widget.showActivities) {
                    _loadNearbyActivities(center);
                  }
                }
              });
            },
          ),

          // Suitable Sports Info (if detectFacilities enabled)
          if (widget.detectFacilities)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: _suitableSports.isEmpty
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _suitableSports.isEmpty
                      ? const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '此處沒有適合的運動設施',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  '此處適合的運動',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _suitableSports.map((sport) {
                                return Chip(
                                  label: Text(
                                    '${OverpassService.getSportEmoji(sport)} ${OverpassService.getSportNameChinese(sport)}',
                                  ),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ),
            ),

          // Address Card at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          '選擇的位置',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    if (widget.showActivities &&
                        _nearbyActivities.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      Text(
                        '附近有 ${_nearbyActivities.length} 個活動',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmLocation,
                        icon: const Icon(Icons.check),
                        label: const Text('確認位置'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My Location Button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              tooltip: '我的位置',
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
