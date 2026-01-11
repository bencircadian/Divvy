/// Tracks task completion timing for smart recurrence suggestions.
class RecurrenceAnalytics {
  final String id;
  final String taskId;
  final String householdId;
  final DateTime originalDueDate;
  final DateTime? actualCompletionDate;
  final int daysLate;
  final DateTime createdAt;

  const RecurrenceAnalytics({
    required this.id,
    required this.taskId,
    required this.householdId,
    required this.originalDueDate,
    this.actualCompletionDate,
    required this.daysLate,
    required this.createdAt,
  });

  factory RecurrenceAnalytics.fromJson(Map<String, dynamic> json) {
    return RecurrenceAnalytics(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      householdId: json['household_id'] as String,
      originalDueDate: DateTime.parse(json['original_due_date'] as String),
      actualCompletionDate: json['actual_completion_date'] != null
          ? DateTime.parse(json['actual_completion_date'] as String)
          : null,
      daysLate: json['days_late'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'household_id': householdId,
      'original_due_date': originalDueDate.toIso8601String().split('T')[0],
      'actual_completion_date': actualCompletionDate?.toIso8601String().split('T')[0],
      'days_late': daysLate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Whether the task was completed late.
  bool get wasLate => daysLate > 0;

  /// Whether the task was completed on time.
  bool get wasOnTime => daysLate <= 0;

  /// Whether the task was completed early.
  bool get wasEarly => daysLate < 0;
}

/// Summary of recurrence analytics for pattern detection.
class RecurrenceAnalyticsSummary {
  final String taskId;
  final int totalCompletions;
  final int lateCompletions;
  final int onTimeCompletions;
  final double averageDaysLate;
  final int consecutiveLateCount;
  final List<int> recentDelays;

  const RecurrenceAnalyticsSummary({
    required this.taskId,
    required this.totalCompletions,
    required this.lateCompletions,
    required this.onTimeCompletions,
    required this.averageDaysLate,
    required this.consecutiveLateCount,
    required this.recentDelays,
  });

  /// Whether a schedule suggestion should be shown.
  bool get shouldSuggestScheduleChange {
    // Suggest if:
    // - At least 3 completions to analyze
    // - 3+ consecutive late completions
    // - Average delay is more than 2 days
    return totalCompletions >= 3 &&
        consecutiveLateCount >= 3 &&
        averageDaysLate > 2;
  }

  /// Calculate suggested day offset based on average delay.
  int get suggestedDayOffset {
    // Round up the average delay
    return averageDaysLate.ceil();
  }

  /// Get a human-readable reason for the suggestion.
  String get suggestionReason {
    if (consecutiveLateCount >= 5) {
      return 'This task has been late $consecutiveLateCount times in a row';
    } else if (consecutiveLateCount >= 3) {
      return 'This task is often completed ${averageDaysLate.toStringAsFixed(1)} days late';
    }
    return 'Based on your completion history';
  }
}
