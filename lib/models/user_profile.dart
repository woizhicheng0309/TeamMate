class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final List<String>? interests;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Notification settings
  final bool notificationChat;
  final bool notificationActivity;
  final bool notificationSystem;
  
  // Privacy settings
  final bool privacyShowEmail;
  final bool privacyShowPhone;
  final bool privacyShowLocation;
  final bool privacyAllowFriendRequests;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.interests,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.notificationChat = true,
    this.notificationActivity = true,
    this.notificationSystem = true,
    this.privacyShowEmail = true,
    this.privacyShowPhone = false,
    this.privacyShowLocation = true,
    this.privacyAllowFriendRequests = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['full_name'] as String?,
      photoUrl: json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notificationChat: json['notification_chat'] as bool? ?? true,
      notificationActivity: json['notification_activity'] as bool? ?? true,
      notificationSystem: json['notification_system'] as bool? ?? true,
      privacyShowEmail: json['privacy_show_email'] as bool? ?? true,
      privacyShowPhone: json['privacy_show_phone'] as bool? ?? false,
      privacyShowLocation: json['privacy_show_location'] as bool? ?? true,
      privacyAllowFriendRequests: json['privacy_allow_friend_requests'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': displayName,
      'avatar_url': photoUrl,
      'phone_number': phoneNumber,
      'interests': interests,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notification_chat': notificationChat,
      'notification_activity': notificationActivity,
      'notification_system': notificationSystem,
      'privacy_show_email': privacyShowEmail,
      'privacy_show_phone': privacyShowPhone,
      'privacy_show_location': privacyShowLocation,
      'privacy_allow_friend_requests': privacyAllowFriendRequests,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    List<String>? interests,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? notificationChat,
    bool? notificationActivity,
    bool? notificationSystem,
    bool? privacyShowEmail,
    bool? privacyShowPhone,
    bool? privacyShowLocation,
    bool? privacyAllowFriendRequests,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      interests: interests ?? this.interests,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationChat: notificationChat ?? this.notificationChat,
      notificationActivity: notificationActivity ?? this.notificationActivity,
      notificationSystem: notificationSystem ?? this.notificationSystem,
      privacyShowEmail: privacyShowEmail ?? this.privacyShowEmail,
      privacyShowPhone: privacyShowPhone ?? this.privacyShowPhone,
      privacyShowLocation: privacyShowLocation ?? this.privacyShowLocation,
      privacyAllowFriendRequests: privacyAllowFriendRequests ?? this.privacyAllowFriendRequests,
    );
  }
}
