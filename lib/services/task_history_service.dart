import 'package:flutter/foundation.dart';
import '../models/task_history.dart';
import 'supabase_service.dart';

/// Service for tracking task history/audit log.
///
/// Extracted from TaskProvider for separation of concerns.
class TaskHistoryService {
  /// Loads history entries for a task.
  static Future<List<TaskHistory>> loadHistory(String taskId) async {
    try {
      final response = await SupabaseService.client
          .from('task_history')
          .select('*, profiles:user_id(display_name)')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskHistory.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading task history: $e');
      return [];
    }
  }

  /// Records a history entry for a task action.
  static Future<void> recordHistory({
    required String taskId,
    required String action,
    String? details,
    Map<String, dynamic>? changes,
  }) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.client.from('task_history').insert({
        'task_id': taskId,
        'user_id': userId,
        'action': action,
        'details': details,
        'changes': changes,
      });
    } catch (e) {
      debugPrint('Error recording task history: $e');
    }
  }

  /// Action constants for consistency.
  static const String actionCreated = 'created';
  static const String actionUpdated = 'updated';
  static const String actionCompleted = 'completed';
  static const String actionUncompleted = 'uncompleted';
  static const String actionAssigned = 'assigned';
  static const String actionUnassigned = 'unassigned';
  static const String actionDeleted = 'deleted';
  static const String actionNoteAdded = 'note_added';
  static const String actionNoteDeleted = 'note_deleted';
}
