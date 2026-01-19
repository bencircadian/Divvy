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
  /// Returns null if next occurrence already exists or creation fails.
  static Future<Task?> createNextOccurrence(Task completedTask) async {
    if (completedTask.recurrenceRule == null) return null;

    try {
      // Determine the recurring chain root ID
      final chainRootId = completedTask.parentTaskId ?? completedTask.id;

      // Check if a pending task already exists in this recurrence chain
      // This prevents duplicate tasks when toggling complete/incomplete
      // Use limit(1) instead of maybeSingle() because multiple pending tasks
      // might exist (e.g., both parent and child are pending after un-completing)
      final existingPending = await SupabaseService.client
          .from('tasks')
          .select('id')
          .eq('household_id', completedTask.householdId)
          .eq('title', completedTask.title)
          .eq('status', 'pending')
          .or('parent_task_id.eq.$chainRootId,id.eq.$chainRootId')
          .limit(1);

      if ((existingPending as List).isNotEmpty) {
        debugPrint('Next recurrence already exists, skipping creation');
        return null;
      }

      final nextDueDate = completedTask.recurrenceRule!.getNextOccurrence(
        completedTask.dueDate ?? DateTime.now(),
      );

      // nextDueDate is guaranteed non-null by getNextOccurrence for valid rules

      final response = await SupabaseService.client.from('tasks').insert({
        'household_id': completedTask.householdId,
        'title': completedTask.title,
        'description': completedTask.description,
        'created_by': completedTask.createdBy,
        'priority': completedTask.priority.name,
        'due_date': nextDueDate.toIso8601String(),
        'due_period': completedTask.duePeriod?.name,
        'assigned_to': completedTask.assignedTo,
        'is_recurring': true,
        'recurrence_rule': completedTask.recurrenceRule!.toJson(),
        'parent_task_id': chainRootId,
        'status': 'pending',
        'category': completedTask.category,
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
