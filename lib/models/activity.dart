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
  final String status; // 'open', 'full', 'completed', 'cancelled', 'ended', 'failed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? checkInStartTime;
  final String? checkInCode;
  final bool? creatorCheckedIn;
  final DateTime? creatorCheckInTime;

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
    this.checkInStartTime,
    this.checkInCode,
    this.creatorCheckedIn,
    this.creatorCheckInTime,
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
      checkInStartTime: json['check_in_start_time'] != null
          ? DateTime.parse(json['check_in_start_time'] as String)
          : null,
      checkInCode: json['check_in_code'] as String?,
      creatorCheckedIn: json['creator_checked_in'] as bool?,
      creatorCheckInTime: json['creator_check_in_time'] != null
          ? DateTime.parse(json['creator_check_in_time'] as String)
          : null,
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
      'check_in_start_time': checkInStartTime?.toIso8601String(),
      'check_in_code': checkInCode,
      'creator_checked_in': creatorCheckedIn,
      'creator_check_in_time': creatorCheckInTime?.toIso8601String(),
    };
  }

  bool get isFull => currentParticipants >= maxParticipants;
  bool get isOpen => status == 'open' && !isFull;
  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isEnded =>
      status == 'ended' || status == 'completed' || status == 'cancelled' || status == 'failed';

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
    DateTime? checkInStartTime,
    String? checkInCode,
    bool? creatorCheckedIn,
    DateTime? creatorCheckInTime,
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
      checkInStartTime: checkInStartTime ?? this.checkInStartTime,
      checkInCode: checkInCode ?? this.checkInCode,
      creatorCheckedIn: creatorCheckedIn ?? this.creatorCheckedIn,
      creatorCheckInTime: creatorCheckInTime ?? this.creatorCheckInTime,
    );
  }
}
