class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  // 用户信息 (来自 join)
  final String? fromUserEmail;
  final String? fromUserFullName;
  final String? fromUserAvatarUrl;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fromUserEmail,
    this.fromUserFullName,
    this.fromUserAvatarUrl,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    // 解析嵌套的 user 对象
    final userObj = json['from_user'] as Map<String, dynamic>?;
    
    // 確保處理 user_id 和 friend_id 的格式
    final fromUserId = json['from_user_id'] ?? json['user_id'];
    final toUserId = json['to_user_id'] ?? json['friend_id'];

    return FriendRequest(
      id: json['id'] as String,
      fromUserId: fromUserId as String,
      toUserId: toUserId as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      fromUserEmail: userObj?['email'] as String?,
      fromUserFullName: userObj?['full_name'] as String?,
      fromUserAvatarUrl: userObj?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
