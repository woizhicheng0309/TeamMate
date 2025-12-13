class JoinRequest {
  final String id;
  final String activityId;
  final String userId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  // User info (from join)
  final String? userEmail;
  final String? userFullName;
  final String? userAvatarUrl;

  JoinRequest({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userEmail,
    this.userFullName,
    this.userAvatarUrl,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userEmail: json['user_email'] as String?,
      userFullName: json['user_full_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
