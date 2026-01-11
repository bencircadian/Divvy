import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appreciation.dart';

/// Service for managing task appreciations.
class AppreciationService {
  final SupabaseClient _supabase;

  AppreciationService(this._supabase);

  /// Send an appreciation for a completed task.
  Future<Appreciation?> sendAppreciation({
    required String taskId,
    required String fromUserId,
    required String toUserId,
    String reactionType = 'thanks',
  }) async {
    try {
      // Check if user already sent appreciation for this task
      final existing = await _supabase
          .from('task_appreciations')
          .select()
          .eq('task_id', taskId)
          .eq('from_user_id', fromUserId)
          .maybeSingle();

      if (existing != null) {
        // Already sent appreciation, update reaction type
        final response = await _supabase
            .from('task_appreciations')
            .update({'reaction_type': reactionType})
            .eq('id', existing['id'])
            .select()
            .single();

        return Appreciation.fromJson(response);
      }

      // Create new appreciation
      final response = await _supabase.from('task_appreciations').insert({
        'task_id': taskId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'reaction_type': reactionType,
      }).select().single();

      // Increment appreciation count on recipient's profile
      await _supabase.rpc('increment_appreciation_count', params: {
        'user_id_param': toUserId,
      }).catchError((e) {
        // Ignore if RPC doesn't exist
        debugPrint('Could not increment appreciation count: $e');
        return null;
      });

      // Create notification for recipient
      await _createAppreciationNotification(
        taskId: taskId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        reactionType: reactionType,
      );

      return Appreciation.fromJson(response);
    } catch (e) {
      debugPrint('Error sending appreciation: $e');
      return null;
    }
  }

  /// Remove an appreciation.
  Future<bool> removeAppreciation({
    required String taskId,
    required String fromUserId,
  }) async {
    try {
      await _supabase
          .from('task_appreciations')
          .delete()
          .eq('task_id', taskId)
          .eq('from_user_id', fromUserId);
      return true;
    } catch (e) {
      debugPrint('Error removing appreciation: $e');
      return false;
    }
  }

  /// Check if user has sent appreciation for a task.
  Future<Appreciation?> getAppreciation({
    required String taskId,
    required String fromUserId,
  }) async {
    try {
      final response = await _supabase
          .from('task_appreciations')
          .select()
          .eq('task_id', taskId)
          .eq('from_user_id', fromUserId)
          .maybeSingle();

      if (response == null) return null;
      return Appreciation.fromJson(response);
    } catch (e) {
      debugPrint('Error getting appreciation: $e');
      return null;
    }
  }

  /// Get all appreciations for a task.
  Future<List<Appreciation>> getTaskAppreciations(String taskId) async {
    try {
      final response = await _supabase
          .from('task_appreciations')
          .select('*, from_profile:profiles!task_appreciations_from_user_id_fkey(display_name)')
          .eq('task_id', taskId);

      return (response as List).map((json) {
        final fromProfile = json['from_profile'] as Map<String, dynamic>?;
        return Appreciation.fromJson({
          ...json,
          'from_user_name': fromProfile?['display_name'],
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting task appreciations: $e');
      return [];
    }
  }

  /// Get appreciation count for a user.
  Future<int> getUserAppreciationCount(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('appreciation_count')
          .eq('id', userId)
          .maybeSingle();

      return response?['appreciation_count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting appreciation count: $e');
      return 0;
    }
  }

  /// Create a notification for the appreciation.
  Future<void> _createAppreciationNotification({
    required String taskId,
    required String fromUserId,
    required String toUserId,
    required String reactionType,
  }) async {
    try {
      // Get task title and sender name
      final taskResponse = await _supabase
          .from('tasks')
          .select('title, household_id')
          .eq('id', taskId)
          .maybeSingle();

      final senderResponse = await _supabase
          .from('profiles')
          .select('display_name')
          .eq('id', fromUserId)
          .maybeSingle();

      final taskTitle = taskResponse?['title'] as String? ?? 'a task';
      final householdId = taskResponse?['household_id'] as String?;
      final senderName = senderResponse?['display_name'] as String? ?? 'Someone';

      if (householdId == null) return;

      await _supabase.from('notifications').insert({
        'user_id': toUserId,
        'household_id': householdId,
        'type': 'appreciation',
        'title': '$senderName ${Appreciation(
          id: '',
          taskId: taskId,
          fromUserId: fromUserId,
          toUserId: toUserId,
          reactionType: reactionType,
          createdAt: DateTime.now(),
        ).displayText}!',
        'message': 'For completing "$taskTitle"',
        'task_id': taskId,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error creating appreciation notification: $e');
    }
  }
}
