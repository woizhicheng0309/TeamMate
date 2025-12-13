class CheckInRecord {
  final String id;
  final String activityId;
  final String userId;
  final bool checkedIn;
  final DateTime? checkInTime;
  final DateTime createdAt;

  CheckInRecord({
    required this.id,
    required this.activityId,
    required this.userId,
    this.checkedIn = false,
    this.checkInTime,
    required this.createdAt,
  });

  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      userId: json['user_id'] as String,
      checkedIn: json['checked_in'] as bool? ?? false,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'user_id': userId,
      'checked_in': checkedIn,
      'check_in_time': checkInTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
