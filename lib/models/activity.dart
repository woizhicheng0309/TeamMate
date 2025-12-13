class Activity {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String activityType; // e.g., 'basketball', 'running', 'cycling'
  final DateTime eventDate;
  final String? duration; // e.g., '2 hours'
  final double latitude;
  final double longitude;
  final String? address;
  final int maxParticipants;
  final int currentParticipants;
  final String status; // 'open', 'full', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  Activity({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.activityType,
    required this.eventDate,
    this.duration,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.maxParticipants,
    this.currentParticipants = 0,
    this.status = 'open',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      activityType: json['activity_type'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      duration: json['duration'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      maxParticipants: json['max_participants'] as int,
      currentParticipants: json['current_participants'] as int? ?? 0,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'activity_type': activityType,
      'event_date': eventDate.toIso8601String(),
      'duration': duration,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isFull => currentParticipants >= maxParticipants;
  bool get isOpen => status == 'open' && !isFull;
  bool get isPast => eventDate.isBefore(DateTime.now());

  Activity copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? description,
    String? activityType,
    DateTime? eventDate,
    String? duration,
    double? latitude,
    double? longitude,
    String? address,
    int? maxParticipants,
    int? currentParticipants,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      activityType: activityType ?? this.activityType,
      eventDate: eventDate ?? this.eventDate,
      duration: duration ?? this.duration,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
