import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_contributor.dart';

/// Service for managing task contributors (multi-person tasks).
class TaskContributorService {
  final SupabaseClient _supabase;

  TaskContributorService(this._supabase);

  /// Claim credit for a completed task.
  Future<TaskContributor?> claimCredit({
    required String taskId,
    required String userId,
    String? contributionNote,
  }) async {
    try {
      // Check if user has already claimed credit
      final existing = await _supabase
          .from('task_contributors')
          .select()
          .eq('task_id', taskId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Already claimed, return existing
        return TaskContributor.fromJson(existing);
      }

      // Create new contributor entry
      final response = await _supabase.from('task_contributors').insert({
        'task_id': taskId,
        'user_id': userId,
        'contribution_note': contributionNote,
      }).select('*, profile:profiles!task_contributors_user_id_fkey(display_name, avatar_url)').single();

      return TaskContributor.fromJson(response);
    } catch (e) {
      debugPrint('Error claiming credit: $e');
      return null;
    }
  }

  /// Remove credit claim from a task.
  Future<bool> removeCredit({
    required String taskId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('task_contributors')
          .delete()
          .eq('task_id', taskId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error removing credit: $e');
      return false;
    }
  }

  /// Get all contributors for a task.
  Future<List<TaskContributor>> getTaskContributors(String taskId) async {
    try {
      final response = await _supabase
          .from('task_contributors')
          .select('*, profile:profiles!task_contributors_user_id_fkey(display_name, avatar_url)')
          .eq('task_id', taskId)
          .order('claimed_at', ascending: true);

      return (response as List)
          .map((json) => TaskContributor.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting task contributors: $e');
      return [];
    }
  }

  /// Check if a user has claimed credit for a task.
  Future<bool> hasClaimedCredit({
    required String taskId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('task_contributors')
          .select('id')
          .eq('task_id', taskId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking credit claim: $e');
      return false;
    }
  }

  /// Update contribution note.
  Future<bool> updateContributionNote({
    required String taskId,
    required String userId,
    required String? note,
  }) async {
    try {
      await _supabase
          .from('task_contributors')
          .update({'contribution_note': note})
          .eq('task_id', taskId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating contribution note: $e');
      return false;
    }
  }

  /// Get contributor count for a task.
  Future<int> getContributorCount(String taskId) async {
    try {
      final response = await _supabase
          .from('task_contributors')
          .select('id')
          .eq('task_id', taskId);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting contributor count: $e');
      return 0;
    }
  }
}
