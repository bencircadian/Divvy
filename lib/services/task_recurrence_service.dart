import 'package:flutter/foundation.dart';
import '../models/recurrence_rule.dart';
import '../models/task.dart';
import 'supabase_service.dart';

/// Service for handling task recurrence logic.
///
/// Extracted from TaskProvider for separation of concerns.
class TaskRecurrenceService {
  /// Creates the next occurrence of a recurring task.
  ///
  /// Called when a recurring task is completed.
  static Future<Task?> createNextOccurrence(Task completedTask) async {
    if (completedTask.recurrenceRule == null) return null;

    try {
      final nextDueDate = completedTask.recurrenceRule!.getNextOccurrence(
        completedTask.dueDate ?? DateTime.now(),
      );

      // nextDueDate is guaranteed non-null by getNextOccurrence for valid rules

      final response = await SupabaseService.client.from('tasks').insert({
        'household_id': completedTask.householdId,
        'title': completedTask.title,
        'description': completedTask.description,
        'priority': completedTask.priority.name,
        'due_date': nextDueDate.toIso8601String(),
        'due_period': completedTask.duePeriod?.name,
        'assigned_to': completedTask.assignedTo,
        'recurrence_rule': completedTask.recurrenceRule!.toJson(),
        'is_completed': false,
      }).select().single();

      return Task.fromJson(response);
    } catch (e) {
      debugPrint('Error creating next recurrence: $e');
      return null;
    }
  }

  /// Calculates the next due date for a recurrence rule.
  static DateTime? calculateNextDueDate(
    RecurrenceRule rule,
    DateTime fromDate,
  ) {
    return rule.getNextOccurrence(fromDate);
  }

  /// Checks if a task should create a new occurrence when completed.
  static bool shouldCreateNextOccurrence(Task task) {
    if (task.recurrenceRule == null) return false;
    if (!task.isCompleted) return false;

    // Check if recurrence has ended
    final rule = task.recurrenceRule!;
    if (rule.endDate != null && DateTime.now().isAfter(rule.endDate!)) {
      return false;
    }

    return true;
  }
}
