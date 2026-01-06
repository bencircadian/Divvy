class NotificationPreferences {
  final String userId;
  final bool pushEnabled;
  final bool taskAssignedEnabled;
  final bool taskCompletedEnabled;
  final bool mentionsEnabled;
  final bool dueRemindersEnabled;
  final int reminderBeforeMinutes;

  NotificationPreferences({
    required this.userId,
    this.pushEnabled = true,
    this.taskAssignedEnabled = true,
    this.taskCompletedEnabled = true,
    this.mentionsEnabled = true,
    this.dueRemindersEnabled = true,
    this.reminderBeforeMinutes = 60,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      taskAssignedEnabled: json['task_assigned_enabled'] as bool? ?? true,
      taskCompletedEnabled: json['task_completed_enabled'] as bool? ?? true,
      mentionsEnabled: json['mentions_enabled'] as bool? ?? true,
      dueRemindersEnabled: json['due_reminders_enabled'] as bool? ?? true,
      reminderBeforeMinutes: json['reminder_before_minutes'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'push_enabled': pushEnabled,
      'task_assigned_enabled': taskAssignedEnabled,
      'task_completed_enabled': taskCompletedEnabled,
      'mentions_enabled': mentionsEnabled,
      'due_reminders_enabled': dueRemindersEnabled,
      'reminder_before_minutes': reminderBeforeMinutes,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? taskAssignedEnabled,
    bool? taskCompletedEnabled,
    bool? mentionsEnabled,
    bool? dueRemindersEnabled,
    int? reminderBeforeMinutes,
  }) {
    return NotificationPreferences(
      userId: userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      taskAssignedEnabled: taskAssignedEnabled ?? this.taskAssignedEnabled,
      taskCompletedEnabled: taskCompletedEnabled ?? this.taskCompletedEnabled,
      mentionsEnabled: mentionsEnabled ?? this.mentionsEnabled,
      dueRemindersEnabled: dueRemindersEnabled ?? this.dueRemindersEnabled,
      reminderBeforeMinutes: reminderBeforeMinutes ?? this.reminderBeforeMinutes,
    );
  }
}
