/// Productivity insights data model for user task completion analytics.
class ProductivityInsights {
  /// Best day of week for completing tasks (0 = Monday, 6 = Sunday).
  final int? bestDayOfWeek;

  /// Most productive time of day ('morning', 'afternoon', 'evening', 'night').
  final String? mostProductiveTime;

  /// Average tasks completed per week.
  final double averageTasksPerWeek;

  /// Total tasks completed all time.
  final int totalTasksCompleted;

  /// Tasks completed this week.
  final int tasksThisWeek;

  /// Current streak in days.
  final int currentStreak;

  /// Longest streak in days.
  final int longestStreak;

  /// Task completion by day of week (0 = Monday, 6 = Sunday).
  final Map<int, int> completionsByDay;

  /// Task completion by time of day.
  final Map<String, int> completionsByTime;

  const ProductivityInsights({
    this.bestDayOfWeek,
    this.mostProductiveTime,
    this.averageTasksPerWeek = 0,
    this.totalTasksCompleted = 0,
    this.tasksThisWeek = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completionsByDay = const {},
    this.completionsByTime = const {},
  });

  /// Get the day name from day index.
  static String getDayName(int dayIndex) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayIndex % 7];
  }

  /// Get short day name from day index.
  static String getShortDayName(int dayIndex) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayIndex % 7];
  }

  /// Get friendly time description.
  static String getTimeName(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return 'Morning (6am-12pm)';
      case 'afternoon':
        return 'Afternoon (12pm-5pm)';
      case 'evening':
        return 'Evening (5pm-9pm)';
      case 'night':
        return 'Night (9pm-6am)';
      default:
        return timeSlot;
    }
  }

  /// Get short time description.
  static String getShortTimeName(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return 'Morning';
      case 'afternoon':
        return 'Afternoon';
      case 'evening':
        return 'Evening';
      case 'night':
        return 'Night';
      default:
        return timeSlot;
    }
  }

  /// Best day name for display.
  String? get bestDayName => bestDayOfWeek != null ? getDayName(bestDayOfWeek!) : null;

  /// Most productive time for display.
  String? get productiveTimeName =>
      mostProductiveTime != null ? getShortTimeName(mostProductiveTime!) : null;

  factory ProductivityInsights.fromJson(Map<String, dynamic> json) {
    return ProductivityInsights(
      bestDayOfWeek: json['best_day_of_week'] as int?,
      mostProductiveTime: json['most_productive_time'] as String?,
      averageTasksPerWeek: (json['average_tasks_per_week'] as num?)?.toDouble() ?? 0,
      totalTasksCompleted: json['total_tasks_completed'] as int? ?? 0,
      tasksThisWeek: json['tasks_this_week'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      completionsByDay: (json['completions_by_day'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          ) ??
          {},
      completionsByTime: (json['completions_by_time'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'best_day_of_week': bestDayOfWeek,
      'most_productive_time': mostProductiveTime,
      'average_tasks_per_week': averageTasksPerWeek,
      'total_tasks_completed': totalTasksCompleted,
      'tasks_this_week': tasksThisWeek,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'completions_by_day': completionsByDay.map((k, v) => MapEntry(k.toString(), v)),
      'completions_by_time': completionsByTime,
    };
  }

  /// Empty insights with no data.
  static const empty = ProductivityInsights();

  /// Check if insights have meaningful data.
  bool get hasData => totalTasksCompleted > 0;
}
