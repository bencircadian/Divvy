class UserStreak {
  final String id;
  final String userId;
  final String householdId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from join
  final String? displayName;

  UserStreak({
    required this.id,
    required this.userId,
    required this.householdId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletionDate,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    // Handle nested profile data if present
    final profile = json['profiles'] as Map<String, dynamic>?;

    return UserStreak(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      householdId: json['household_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastCompletionDate: json['last_completion_date'] != null
          ? DateTime.parse(json['last_completion_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      displayName: profile?['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'household_id': householdId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completion_date': lastCompletionDate?.toIso8601String().split('T')[0],
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletionDate,
  }) {
    return UserStreak(
      id: id,
      userId: userId,
      householdId: householdId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      displayName: displayName,
    );
  }
}
