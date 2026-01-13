class UserProfile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool? bundlesEnabled;

  UserProfile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.bundlesEnabled,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      bundlesEnabled: json['bundles_enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'bundles_enabled': bundlesEnabled,
    };
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    bool? bundlesEnabled,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      bundlesEnabled: bundlesEnabled ?? this.bundlesEnabled,
    );
  }
}
