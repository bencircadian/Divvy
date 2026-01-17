import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/household_member.dart';
import 'notification_service.dart';
import 'push_notification_service.dart';
import 'supabase_service.dart';

/// Service for processing @mentions in notes and comments.
///
/// Consolidates mention detection and notification logic that was previously
/// duplicated across TaskProvider and TaskNotesService.
class MentionService {
  /// Process @mentions in content and send notifications to mentioned users.
  ///
  /// [taskId] - The task the note belongs to
  /// [content] - The note content to scan for mentions
  /// [authorId] - The user who wrote the note
  /// [taskTitle] - Optional task title for notification message
  /// [householdMembers] - Optional pre-loaded household members (avoids extra query)
  static Future<void> processMentions({
    required String taskId,
    required String content,
    required String authorId,
    String? taskTitle,
    List<HouseholdMember>? householdMembers,
  }) async {
    if (!content.contains('@')) return;

    try {
      // Get author name
      final authorResponse = await SupabaseService.client
          .from('profiles')
          .select('display_name')
          .eq('id', authorId)
          .single();
      final authorName = authorResponse['display_name'] as String? ?? 'Someone';

      // Get task title if not provided
      String title = taskTitle ?? 'a task';
      if (taskTitle == null) {
        try {
          final taskResponse = await SupabaseService.client
              .from('tasks')
              .select('title, household_id')
              .eq('id', taskId)
              .single();
          title = taskResponse['title'] as String? ?? 'a task';
        } catch (e) {
          debugPrint('Error fetching task title: $e');
        }
      }

      // Get household members if not provided
      List<HouseholdMember> members = householdMembers ?? [];
      String? householdId;

      if (members.isEmpty) {
        // Fetch task to get household ID, then fetch members
        try {
          final taskResponse = await SupabaseService.client
              .from('tasks')
              .select('household_id')
              .eq('id', taskId)
              .single();
          householdId = taskResponse['household_id'] as String?;

          if (householdId != null) {
            final membersResponse = await SupabaseService.client
                .from('household_members')
                .select('user_id, profiles(display_name)')
                .eq('household_id', householdId);

            members = (membersResponse as List).map((m) {
              return HouseholdMember(
                householdId: householdId!,
                userId: m['user_id'] as String,
                role: 'member',
                joinedAt: DateTime.now(),
                displayName: m['profiles']?['display_name'] as String?,
              );
            }).toList();
          }
        } catch (e) {
          debugPrint('Error fetching household members: $e');
          return;
        }
      }

      // Find and notify mentioned users
      final mentionedUsers = _findMentionedUsers(content, members, authorId);

      for (final member in mentionedUsers) {
        // In-app notification
        await NotificationService.createNotification(
          userId: member.userId,
          type: NotificationType.mentioned,
          title: 'You were mentioned',
          body: '$authorName mentioned you in "$title"',
          data: {'task_id': taskId},
        );

        // Push notification
        PushNotificationService.sendPushNotification(
          userId: member.userId,
          title: 'You were mentioned',
          body: '$authorName mentioned you in "$title"',
          data: {'task_id': taskId},
        );
      }
    } catch (e) {
      debugPrint('Error processing mentions: $e');
    }
  }

  /// Find all mentioned users in content that are valid household members.
  ///
  /// Returns a list of HouseholdMember objects for users who were mentioned.
  /// Excludes the author from results.
  static List<HouseholdMember> _findMentionedUsers(
    String content,
    List<HouseholdMember> members,
    String authorId,
  ) {
    final contentLower = content.toLowerCase();
    final mentionedUsers = <HouseholdMember>[];
    final processedIds = <String>{};

    // Sort members by name length (longest first) to match "John Smith" before "John"
    final sortedMembers = List<HouseholdMember>.from(members)
      ..sort((a, b) => (b.displayName?.length ?? 0).compareTo(a.displayName?.length ?? 0));

    for (final member in sortedMembers) {
      final displayName = member.displayName;
      if (displayName == null || displayName.isEmpty) continue;
      if (member.userId == authorId) continue;
      if (processedIds.contains(member.userId)) continue;

      // Check for @mention pattern
      final pattern = '@${displayName.toLowerCase()}';
      if (contentLower.contains(pattern)) {
        processedIds.add(member.userId);
        mentionedUsers.add(member);
      }
    }

    return mentionedUsers;
  }
}
