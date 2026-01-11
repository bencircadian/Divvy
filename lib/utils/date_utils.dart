import 'package:intl/intl.dart';
import '../models/task.dart';

/// Utility functions for formatting task due dates in the app
class TaskDateUtils {
  /// Formats a due date for display in task lists and details.
  ///
  /// Returns relative strings like "Today", "Tomorrow", "Overdue" for nearby dates,
  /// or formatted dates for dates further away.
  ///
  /// If [period] is provided, it will be appended (e.g., "Today, Morning").
  static String formatDueDate(DateTime dueDate, {DuePeriod? period}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    String dateStr;
    if (dueDay == today) {
      dateStr = 'Today';
    } else if (dueDay == tomorrow) {
      dateStr = 'Tomorrow';
    } else if (dueDay.isBefore(today)) {
      dateStr = 'Overdue';
    } else if (dueDay.difference(today).inDays < 7) {
      dateStr = DateFormat('EEEE').format(dueDate); // Full day name
    } else {
      dateStr = DateFormat('MMM d').format(dueDate);
    }

    if (period != null) {
      final periodStr = period.name[0].toUpperCase() + period.name.substring(1);
      return '$dateStr, $periodStr';
    }

    return dateStr;
  }

  /// Formats a date with short day names (e.g., "Mon" instead of "Monday").
  ///
  /// Used in compact displays like dashboard widgets.
  static String formatDueDateShort(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDay == today) {
      return 'Today';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow';
    } else if (dueDay.difference(today).inDays < 7 && dueDay.isAfter(today)) {
      return DateFormat('EEE').format(dueDate); // Short day name
    } else {
      return DateFormat('MMM d').format(dueDate);
    }
  }
}
