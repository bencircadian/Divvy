/// Represents a user who contributed to completing a task.
class TaskContributor {
  final String id;
  final String taskId;
  final String userId;
  final DateTime claimedAt;
  final String? contributionNote;

  /// Optional display name from profile join.
  final String? displayName;

  /// Optional avatar URL from profile join.
  final String? avatarUrl;

  const TaskContributor({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.claimedAt,
    this.contributionNote,
    this.displayName,
    this.avatarUrl,
  });

  factory TaskContributor.fromJson(Map<String, dynamic> json) {
    // Handle nested profile data if present
    final profile = json['profile'] as Map<String, dynamic>?;

    return TaskContributor(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      claimedAt: DateTime.parse(json['claimed_at'] as String),
      contributionNote: json['contribution_note'] as String?,
      displayName: profile?['display_name'] as String? ?? json['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String? ?? json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'claimed_at': claimedAt.toIso8601String(),
      'contribution_note': contributionNote,
    };
  }

  /// Get initials for display.
  String get initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  TaskContributor copyWith({
    String? id,
    String? taskId,
    String? userId,
    DateTime? claimedAt,
    String? contributionNote,
    String? displayName,
    String? avatarUrl,
  }) {
    return TaskContributor(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      claimedAt: claimedAt ?? this.claimedAt,
      contributionNote: contributionNote ?? this.contributionNote,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
