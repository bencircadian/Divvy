class HouseholdMember {
  final String householdId;
  final String userId;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;

  // Optional: populated when fetching with profile data
  final String? displayName;
  final String? avatarUrl;

  HouseholdMember({
    required this.householdId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';

  factory HouseholdMember.fromJson(Map<String, dynamic> json) {
    // Handle nested profile data if present
    final profile = json['profiles'] as Map<String, dynamic>?;

    return HouseholdMember(
      householdId: json['household_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'household_id': householdId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
