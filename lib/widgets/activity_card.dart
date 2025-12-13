import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../services/location_service.dart';
import '../screens/activity_detail_screen.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final Position? currentPosition;

  const ActivityCard({super.key, required this.activity, this.currentPosition});

  String _getActivityIcon(String type) {
    const icons = {
      'basketball': '🏀',
      'badminton': '🏸',
      'running': '🏃',
      'cycling': '🚴',
      'swimming': '🏊',
      'hiking': '⛰️',
      'tennis': '🎾',
      'football': '⚽',
    };
    return icons[type] ?? '🏃';
  }

  String _getDistanceText() {
    if (currentPosition == null) return '';

    final distance = LocationService().calculateDistance(
      currentPosition!.latitude,
      currentPosition!.longitude,
      activity.latitude,
      activity.longitude,
    );

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  Color _getStatusColor() {
    if (activity.status == 'completed') return Colors.grey;
    if (activity.status == 'cancelled') return Colors.red;
    if (activity.isFull) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (activity.status == 'completed') return '已完成';
    if (activity.status == 'cancelled') return '已取消';
    if (activity.isFull) return '已滿';
    return '開放中';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd (E) HH:mm', 'zh_TW');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Text(
                    _getActivityIcon(activity.activityType),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (currentPosition != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getDistanceText(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (activity.description != null) ...[
                Text(
                  activity.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
              ],

              // Details Row
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(activity.eventDate),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${activity.currentParticipants}/${activity.maxParticipants}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),

              if (activity.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
