import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../models/household_member.dart';
import '../models/task_note.dart';
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

      // Process mentions and create notifications
      await _processMentions(
        taskId: taskId,
        noteContent: content,
        authorId: userId,
        authorName: authorName,
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

  /// Processes @mentions in note content and creates notifications.
  static Future<void> _processMentions({
    required String taskId,
    required String noteContent,
    required String authorId,
    required String authorName,
    required List<HouseholdMember> householdMembers,
  }) async {
    // Find @mentions in content
    final mentionRegex = RegExp(r'@(\w+(?:\s+\w+)?)');
    final matches = mentionRegex.allMatches(noteContent);

    if (matches.isEmpty) return;

    // Get task title for notification
    String taskTitle = 'a task';
    try {
      final taskResponse = await SupabaseService.client
          .from('tasks')
          .select('title')
          .eq('id', taskId)
          .maybeSingle();
      taskTitle = taskResponse?['title'] ?? 'a task';
    } catch (e) {
      debugPrint('Error fetching task title: $e');
    }

    // Process each mention
    final notifications = <Map<String, dynamic>>[];
    final processedUserIds = <String>{};

    for (final match in matches) {
      final mentionedName = match.group(1)?.toLowerCase() ?? '';

      // Find matching household member (fuzzy match)
      final member = _findMemberByName(mentionedName, householdMembers);

      if (member != null &&
          member.userId != authorId &&
          !processedUserIds.contains(member.userId)) {
        processedUserIds.add(member.userId);

        notifications.add({
          'user_id': member.userId,
          'type': NotificationType.mentioned.name,
          'title': 'You were mentioned',
          'body': '$authorName mentioned you in "$taskTitle"',
          'data': {
            'task_id': taskId,
            'note_content': noteContent.length > 100
                ? '${noteContent.substring(0, 100)}...'
                : noteContent,
          },
        });
      }
    }

    // Batch insert notifications
    if (notifications.isNotEmpty) {
      try {
        await SupabaseService.client.from('notifications').insert(notifications);
      } catch (e) {
        debugPrint('Error creating mention notifications: $e');
      }
    }
  }

  /// Finds a household member by fuzzy name matching.
  static HouseholdMember? _findMemberByName(
    String searchName,
    List<HouseholdMember> members,
  ) {
    final search = searchName.toLowerCase().trim();
    if (search.isEmpty) return null;

    // Exact match first
    for (final member in members) {
      final displayName = member.displayName?.toLowerCase() ?? '';
      if (displayName == search) return member;
    }

    // First name match
    for (final member in members) {
      final displayName = member.displayName?.toLowerCase() ?? '';
      final firstName = displayName.split(' ').first;
      if (firstName == search) return member;
    }

    // Partial match (starts with)
    for (final member in members) {
      final displayName = member.displayName?.toLowerCase() ?? '';
      if (displayName.startsWith(search)) return member;
    }

    return null;
  }
}
