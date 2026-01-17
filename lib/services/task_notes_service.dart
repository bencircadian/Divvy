import 'package:flutter/foundation.dart';
import '../models/household_member.dart';
import '../models/task_note.dart';
import 'mention_service.dart';
import 'supabase_service.dart';

/// Service for handling task notes and mentions.
///
/// Extracted from TaskProvider for separation of concerns.
class TaskNotesService {
  /// Loads notes for a task.
  static Future<List<TaskNote>> loadNotes(String taskId) async {
    try {
      final response = await SupabaseService.client
          .from('task_notes')
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskNote.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading task notes: $e');
      return [];
    }
  }

  /// Adds a note to a task.
  ///
  /// Returns the created note on success, null on failure.
  static Future<TaskNote?> addNote({
    required String taskId,
    required String content,
    required List<HouseholdMember> householdMembers,
  }) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return null;

      // Get user's display name
      final profileResponse = await SupabaseService.client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      final authorName = profileResponse?['display_name'] ?? 'Unknown';

      // Insert the note
      final response = await SupabaseService.client.from('task_notes').insert({
        'task_id': taskId,
        'user_id': userId,
        'content': content,
        'author_name': authorName,
      }).select().single();

      final note = TaskNote.fromJson(response);

      // Process mentions using consolidated MentionService
      await MentionService.processMentions(
        taskId: taskId,
        content: content,
        authorId: userId,
        householdMembers: householdMembers,
      );

      return note;
    } catch (e) {
      debugPrint('Error adding task note: $e');
      return null;
    }
  }

  /// Deletes a note from a task.
  static Future<bool> deleteNote(String noteId) async {
    try {
      await SupabaseService.client
          .from('task_notes')
          .delete()
          .eq('id', noteId);
      return true;
    } catch (e) {
      debugPrint('Error deleting task note: $e');
      return false;
    }
  }
}
