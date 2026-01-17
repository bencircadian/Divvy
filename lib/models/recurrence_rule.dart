enum RecurrenceFrequency { daily, weekly, monthly }

class RecurrenceRule {
  final RecurrenceFrequency frequency;
  final int interval; // Every N days/weeks/months
  final List<int>? days; // For weekly: 0=Sun, 1=Mon, etc. For monthly: day of month
  final DateTime? endDate;

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.days,
    this.endDate,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: _parseFrequency(json['frequency'] as String),
      interval: json['interval'] as int? ?? 1,
      days: (json['days'] as List<dynamic>?)?.map((e) => e as int).toList(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      if (days != null) 'days': days,
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
    };
  }

  static RecurrenceFrequency _parseFrequency(String value) {
    switch (value) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  /// Calculate the next occurrence date from a given date
  DateTime getNextOccurrence(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(Duration(days: interval));

      case RecurrenceFrequency.weekly:
        if (days == null || days!.isEmpty) {
          return from.add(Duration(days: 7 * interval));
        }
        // Find next day in the week cycle
        var next = from.add(const Duration(days: 1));
        int weeksAdded = 0;
        while (true) {
          if (days!.contains(next.weekday % 7)) {
            // Check if we've moved to a new week
            if (next.weekday < from.weekday ||
                (next.weekday == from.weekday && next.isAfter(from))) {
              if (weeksAdded >= interval - 1 || next.isAfter(from)) {
                return next;
              }
            } else if (weeksAdded >= interval) {
              return next;
            }
          }
          next = next.add(const Duration(days: 1));
          if (next.weekday == DateTime.monday && next.isAfter(from.add(const Duration(days: 1)))) {
            weeksAdded++;
          }
        }

      case RecurrenceFrequency.monthly:
        // Calculate target year and month
        int targetMonth = from.month + interval;
        int targetYear = from.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }

        // Find the last valid day in the target month
        int targetDay = from.day;
        int daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        if (targetDay > daysInTargetMonth) {
          targetDay = daysInTargetMonth;
        }

        return DateTime(targetYear, targetMonth, targetDay);
    }
  }

  /// Check if the recurrence has ended
  bool hasEnded(DateTime date) {
    if (endDate == null) return false;
    return date.isAfter(endDate!);
  }

  /// Get a human-readable description
  String get description {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';

      case RecurrenceFrequency.weekly:
        if (days == null || days!.isEmpty) {
          return interval == 1 ? 'Weekly' : 'Every $interval weeks';
        }
        final dayNames = days!.map(_dayName).join(', ');
        return interval == 1
            ? 'Weekly on $dayNames'
            : 'Every $interval weeks on $dayNames';

      case RecurrenceFrequency.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
    }
  }

  static String _dayName(int day) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return names[day % 7];
  }

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    List<int>? days,
    DateTime? endDate,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      days: days ?? this.days,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecurrenceRule) return false;

    // Compare days lists properly
    bool daysEqual = false;
    if (days == null && other.days == null) {
      daysEqual = true;
    } else if (days != null && other.days != null && days!.length == other.days!.length) {
      daysEqual = true;
      for (int i = 0; i < days!.length; i++) {
        if (days![i] != other.days![i]) {
          daysEqual = false;
          break;
        }
      }
    }

    return other.frequency == frequency &&
        other.interval == interval &&
        daysEqual &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
    frequency,
    interval,
    days != null ? Object.hashAll(days!) : null,
    endDate,
  );
}
