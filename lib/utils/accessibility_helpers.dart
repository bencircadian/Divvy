import '../models/task.dart';

/// Accessibility helper functions for generating semantic labels.
class AccessibilityHelpers {
  /// Generate a semantic label for a task.
  static String getTaskSemanticLabel(Task task) {
    final buffer = StringBuffer();

    // Task title
    buffer.write(task.title);

    // Completion status
    if (task.isCompleted) {
      buffer.write(', completed');
    } else {
      buffer.write(', pending');
    }

    // Priority
    if (task.priority == TaskPriority.high) {
      buffer.write(', high priority');
    } else if (task.priority == TaskPriority.low) {
      buffer.write(', low priority');
    }

    // Due date
    if (task.dueDate != null) {
      if (task.isDueToday) {
        buffer.write(', due today');
      } else if (task.isOverdue) {
        buffer.write(', overdue');
      } else {
        final daysUntilDue = task.dueDate!.difference(DateTime.now()).inDays;
        if (daysUntilDue == 1) {
          buffer.write(', due tomorrow');
        } else if (daysUntilDue <= 7) {
          buffer.write(', due in $daysUntilDue days');
        }
      }
    }

    // Description
    if (task.description != null && task.description!.isNotEmpty) {
      buffer.write('. Description: ${task.description}');
    }

    return buffer.toString();
  }

  /// Generate a semantic hint for a task checkbox.
  static String getTaskHint(Task task) {
    if (task.isCompleted) {
      return 'Double tap to mark as incomplete';
    }
    return 'Double tap to mark as complete';
  }

  /// Generate a semantic label for progress indicators.
  static String getProgressSemanticLabel(int current, int total) {
    final percentage = ((current / total) * 100).round();
    return '$current of $total completed, $percentage percent';
  }

  /// Generate a semantic label for a category.
  static String getCategorySemanticLabel(String category) {
    return '${_categoryDisplayName(category)} category';
  }

  static String _categoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'kitchen':
        return 'Kitchen';
      case 'bathroom':
        return 'Bathroom';
      case 'living':
        return 'Living room';
      case 'bedroom':
        return 'Bedroom';
      case 'outdoor':
        return 'Outdoor';
      case 'laundry':
        return 'Laundry';
      case 'pet':
        return 'Pet care';
      case 'children':
        return 'Children';
      default:
        return category;
    }
  }

  /// Generate a semantic label for a due date.
  static String getDueDateSemanticLabel(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isBefore(today)) {
      final daysOverdue = today.difference(due).inDays;
      return daysOverdue == 1
          ? 'Overdue by 1 day'
          : 'Overdue by $daysOverdue days';
    } else if (due == today) {
      return 'Due today';
    } else {
      final daysUntilDue = due.difference(today).inDays;
      if (daysUntilDue == 1) {
        return 'Due tomorrow';
      } else if (daysUntilDue <= 7) {
        return 'Due in $daysUntilDue days';
      } else {
        return 'Due on ${dueDate.month}/${dueDate.day}/${dueDate.year}';
      }
    }
  }

  /// Generate a semantic label for a notification.
  static String getNotificationSemanticLabel({
    required String title,
    required String body,
    required DateTime timestamp,
    required bool isRead,
  }) {
    final buffer = StringBuffer();

    buffer.write(title);
    buffer.write('. ');
    buffer.write(body);

    if (!isRead) {
      buffer.write(', unread');
    }

    // Time ago
    final ago = DateTime.now().difference(timestamp);
    if (ago.inMinutes < 1) {
      buffer.write(', just now');
    } else if (ago.inMinutes < 60) {
      buffer.write(', ${ago.inMinutes} minutes ago');
    } else if (ago.inHours < 24) {
      buffer.write(', ${ago.inHours} hours ago');
    } else {
      buffer.write(', ${ago.inDays} days ago');
    }

    return buffer.toString();
  }
}
