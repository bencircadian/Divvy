import 'recurrence_rule.dart';

/// Represents a smart suggestion to change a task's schedule.
class ScheduleSuggestion {
  final String taskId;
  final String taskTitle;
  final RecurrenceRule currentSchedule;
  final RecurrenceRule suggestedSchedule;
  final String reason;
  final double confidence;
  final SuggestionType type;
  final int averageDaysLate;
  final int consecutiveLateCount;

  const ScheduleSuggestion({
    required this.taskId,
    required this.taskTitle,
    required this.currentSchedule,
    required this.suggestedSchedule,
    required this.reason,
    required this.confidence,
    required this.type,
    required this.averageDaysLate,
    required this.consecutiveLateCount,
  });

  /// Get a human-readable description of the schedule change.
  String get changeDescription {
    final current = currentSchedule.humanReadable;
    final suggested = suggestedSchedule.humanReadable;
    return 'Change from "$current" to "$suggested"';
  }

  /// Get a short description of the suggestion.
  String get shortDescription {
    switch (type) {
      case SuggestionType.delayDay:
        return 'Move to later in the week';
      case SuggestionType.reduceFrequency:
        return 'Reduce frequency';
      case SuggestionType.increaseInterval:
        return 'Space out more';
      case SuggestionType.changeDayOfWeek:
        return 'Change day of week';
    }
  }

  /// Get an icon for the suggestion type.
  String get iconName {
    switch (type) {
      case SuggestionType.delayDay:
        return 'schedule';
      case SuggestionType.reduceFrequency:
        return 'trending_down';
      case SuggestionType.increaseInterval:
        return 'expand';
      case SuggestionType.changeDayOfWeek:
        return 'calendar_today';
    }
  }
}

/// Types of schedule suggestions.
enum SuggestionType {
  /// Move the task to a later day of the week.
  delayDay,

  /// Reduce how often the task recurs.
  reduceFrequency,

  /// Increase the interval between occurrences.
  increaseInterval,

  /// Change which day of the week the task is due.
  changeDayOfWeek,
}

/// Extension on RecurrenceRule to generate human-readable descriptions.
extension RecurrenceRuleDescription on RecurrenceRule {
  String get humanReadable {
    // Use the existing description property if available
    return description;
  }

  /// Get days of week (alias for days property).
  List<int>? get daysOfWeek => days;
}
