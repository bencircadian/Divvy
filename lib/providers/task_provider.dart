import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_notification.dart';
import '../models/recurrence_rule.dart';
import '../models/task.dart';
import '../models/task_history.dart';
import '../models/task_note.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';
import 'dashboard_provider.dart';
import 'notification_provider.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentHouseholdId;
  RealtimeChannel? _tasksChannel;

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get pendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();

  List<Task> get tasksDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isAtSameMomentAs(today) ||
             (dueDay.isAfter(today) && dueDay.isBefore(tomorrow));
    }).toList()
      ..sort((a, b) {
        // Completed at bottom
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        // Then by due time
        return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
      });
  }

  List<Task> get tasksDueThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isAfter(today.subtract(const Duration(days: 1))) &&
             dueDay.isBefore(weekEnd);
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
      });
  }

  /// Get incomplete tasks due today
  List<Task> get incompleteTodayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return (dueDay.isBefore(tomorrow) || dueDay.isAtSameMomentAs(today));
    }).toList()
      ..sort((a, b) => (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));
  }

  /// Get unique upcoming tasks (after today), excluding recurring duplicates
  List<Task> get upcomingUniqueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Filter tasks after today
    final futureTasks = _tasks.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isAfter(today) || dueDay.isAtSameMomentAs(tomorrow);
    }).toList();

    // Sort by due date first so deduplication keeps the soonest occurrence
    futureTasks.sort((a, b) => (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

    // Group by parent task ID or own ID to remove recurring duplicates
    final seenTitles = <String>{};
    final uniqueTasks = <Task>[];

    for (final task in futureTasks) {
      // Use title as key for recurring tasks to avoid duplicates
      final key = task.isRecurring ? task.title : task.id;
      if (!seenTitles.contains(key)) {
        seenTitles.add(key);
        uniqueTasks.add(task);
      }
    }

    return uniqueTasks;
  }

  /// Get completed tasks sorted by completion time (most recent first)
  List<Task> get completedTasksSortedByRecent {
    return _tasks.where((t) => t.isCompleted).toList()
      ..sort((a, b) {
        final aTime = a.completedAt ?? a.createdAt;
        final bTime = b.completedAt ?? b.createdAt;
        return bTime.compareTo(aTime); // Reverse chronological
      });
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Task> get tasksSortedByDueDate {
    final sorted = List<Task>.from(_tasks);
    sorted.sort((a, b) {
      // Completed tasks go to the bottom
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;

      // Tasks without due date go after tasks with due date
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate == null) return -1;
      if (a.dueDate == null && b.dueDate == null) {
        return a.createdAt.compareTo(b.createdAt);
      }

      // Sort by due date
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sorted;
  }

  Future<void> loadTasks(String householdId) async {
    _currentHouseholdId = householdId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Check if online
    final isOnline = await CacheService.isOnline();

    if (!isOnline) {
      // Load from cache when offline
      _tasks = CacheService.getCachedTasks();
      _isLoading = false;
      _errorMessage = _tasks.isEmpty ? 'No cached data available' : null;
      notifyListeners();
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('tasks')
          .select('''
            *,
            assigned_profile:profiles!assigned_to(display_name),
            created_profile:profiles!created_by(display_name),
            completed_profile:profiles!completed_by(display_name)
          ''')
          .eq('household_id', householdId)
          .order('due_date', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false);

      _tasks = (response as List).map((json) => Task.fromJson(json)).toList();

      // Cache tasks for offline use
      await CacheService.cacheTasks(_tasks);

      _isLoading = false;
      notifyListeners();

      // Set up real-time subscription
      _subscribeToTasks(householdId);
    } catch (e) {
      debugPrint('Error loading tasks: $e');

      // Try loading from cache on error
      final cachedTasks = CacheService.getCachedTasks();
      if (cachedTasks.isNotEmpty) {
        _tasks = cachedTasks;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load tasks';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToTasks(String householdId) {
    _tasksChannel?.unsubscribe();

    _tasksChannel = SupabaseService.client
        .channel('tasks:$householdId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'household_id',
            value: householdId,
          ),
          callback: (payload) {
            _handleRealtimeEvent(payload);
          },
        )
        .subscribe();
  }

  Future<void> _handleRealtimeEvent(PostgresChangePayload payload) async {
    final eventType = payload.eventType;

    if (eventType == PostgresChangeEvent.insert ||
        eventType == PostgresChangeEvent.update) {
      // Reload to get joined profile data
      if (_currentHouseholdId != null) {
        await loadTasks(_currentHouseholdId!);
      }
    } else if (eventType == PostgresChangeEvent.delete) {
      final oldRecord = payload.oldRecord;
      final deletedId = oldRecord['id'] as String?;
      if (deletedId != null) {
        _tasks.removeWhere((t) => t.id == deletedId);
        notifyListeners();
      }
    }
  }

  Future<bool> createTask({
    required String householdId,
    required String title,
    String? description,
    String? assignedTo,
    TaskPriority priority = TaskPriority.normal,
    DateTime? dueDate,
    DuePeriod? duePeriod,
    RecurrenceRule? recurrenceRule,
    String? parentTaskId,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    _errorMessage = null;

    try {
      final response = await SupabaseService.client.from('tasks').insert({
        'household_id': householdId,
        'title': title,
        'description': description,
        'created_by': userId,
        'assigned_to': assignedTo,
        'priority': priority.name,
        'due_date': dueDate?.toIso8601String(),
        'due_period': duePeriod?.name,
        'is_recurring': recurrenceRule != null,
        'recurrence_rule': recurrenceRule?.toJson(),
        'parent_task_id': parentTaskId,
      }).select('id').single();

      // Record history
      await _recordHistory(response['id'] as String, 'created');

      // Reload tasks to show the new task immediately
      await loadTasks(householdId);
      return true;
    } catch (e) {
      debugPrint('Error creating task: $e');
      _errorMessage = 'Failed to create task';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    TaskPriority? priority,
    DateTime? dueDate,
    DuePeriod? duePeriod,
    RecurrenceRule? recurrenceRule,
    bool? clearRecurrence,
  }) async {
    _errorMessage = null;

    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (assignedTo != null) updates['assigned_to'] = assignedTo;
      if (priority != null) updates['priority'] = priority.name;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (duePeriod != null) updates['due_period'] = duePeriod.name;

      // Handle recurrence updates
      if (clearRecurrence == true) {
        updates['is_recurring'] = false;
        updates['recurrence_rule'] = null;
      } else if (recurrenceRule != null) {
        updates['is_recurring'] = true;
        updates['recurrence_rule'] = recurrenceRule.toJson();
      }

      await SupabaseService.client
          .from('tasks')
          .update(updates)
          .eq('id', taskId);

      await _recordHistory(taskId, 'edited', details: updates);

      return true;
    } catch (e) {
      debugPrint('Error updating task: $e');
      _errorMessage = 'Failed to update task';
      notifyListeners();
      return false;
    }
  }

  /// Upload a cover image for a task
  Future<String?> uploadCoverImage(String taskId, XFile imageFile) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return null;

      // Read the file bytes
      final bytes = await imageFile.readAsBytes();

      // Get file extension - handle web blob URLs by using mimeType or defaulting to jpg
      String fileExt = 'jpg';
      if (imageFile.mimeType != null) {
        // Extract extension from mimeType (e.g., "image/jpeg" -> "jpeg")
        final mimeExt = imageFile.mimeType!.split('/').last;
        fileExt = mimeExt == 'jpeg' ? 'jpg' : mimeExt;
      } else if (imageFile.path.contains('.') && !imageFile.path.startsWith('blob:')) {
        fileExt = imageFile.path.split('.').last.toLowerCase();
      }

      final fileName = '${taskId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'task-covers/$fileName';

      // Determine content type
      final contentType = imageFile.mimeType ?? 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}';

      // Upload to Supabase Storage
      await SupabaseService.client.storage
          .from('task-images')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ));

      // Store just the file path (not full URL) - we'll generate signed URLs on-demand
      await SupabaseService.client
          .from('tasks')
          .update({'cover_image_url': filePath})
          .eq('id', taskId);

      await _recordHistory(taskId, 'cover_added');

      // Reload tasks to show the update
      if (_currentHouseholdId != null) {
        await loadTasks(_currentHouseholdId!);
      }

      return filePath;
    } catch (e) {
      debugPrint('Error uploading cover image: $e');
      _errorMessage = 'Failed to upload image';
      notifyListeners();
      return null;
    }
  }

  /// Generate a signed URL for a cover image (valid for 1 hour)
  Future<String?> getSignedCoverUrl(String filePath) async {
    try {
      final response = await SupabaseService.client.storage
          .from('task-images')
          .createSignedUrl(filePath, 3600); // 1 hour expiration
      return response;
    } catch (e) {
      debugPrint('Error generating signed URL: $e');
      return null;
    }
  }

  /// Remove cover image from a task
  Future<bool> removeCoverImage(String taskId) async {
    try {
      await SupabaseService.client
          .from('tasks')
          .update({'cover_image_url': null})
          .eq('id', taskId);

      await _recordHistory(taskId, 'cover_removed');

      // Reload tasks to show the update
      if (_currentHouseholdId != null) {
        await loadTasks(_currentHouseholdId!);
      }

      return true;
    } catch (e) {
      debugPrint('Error removing cover image: $e');
      _errorMessage = 'Failed to remove image';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTaskComplete(Task task) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    _errorMessage = null;

    try {
      if (task.isCompleted) {
        // Mark as pending
        await SupabaseService.client.from('tasks').update({
          'status': 'pending',
          'completed_at': null,
          'completed_by': null,
        }).eq('id', task.id);

        await _recordHistory(task.id, 'uncompleted');
      } else {
        // Mark as completed
        await SupabaseService.client.from('tasks').update({
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
          'completed_by': userId,
        }).eq('id', task.id);

        await _recordHistory(task.id, 'completed');

        // Notify household members about completion
        await _notifyTaskCompleted(task, userId);

        // Update user's streak
        await DashboardProvider.updateStreakOnCompletion(userId, task.householdId);

        // If recurring, create the next occurrence
        if (task.isRecurring && task.recurrenceRule != null && task.dueDate != null) {
          await _createNextRecurrence(task);
        }
      }

      // Reload to show changes
      if (_currentHouseholdId != null) {
        await loadTasks(_currentHouseholdId!);
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling task: $e');
      _errorMessage = 'Failed to update task';
      notifyListeners();
      return false;
    }
  }

  Future<void> _createNextRecurrence(Task task) async {
    if (task.recurrenceRule == null || task.dueDate == null) return;

    final nextDueDate = task.recurrenceRule!.getNextOccurrence(task.dueDate!);

    // Check if recurrence has ended
    if (task.recurrenceRule!.hasEnded(nextDueDate)) return;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client.from('tasks').insert({
        'household_id': task.householdId,
        'title': task.title,
        'description': task.description,
        'created_by': userId,
        'assigned_to': task.assignedTo,
        'priority': task.priority.name,
        'due_date': nextDueDate.toIso8601String(),
        'due_period': task.duePeriod?.name,
        'is_recurring': true,
        'recurrence_rule': task.recurrenceRule!.toJson(),
        'parent_task_id': task.parentTaskId ?? task.id,
      });
    } catch (e) {
      debugPrint('Error creating next recurrence: $e');
    }
  }

  Future<bool> deleteTask(String taskId) async {
    _errorMessage = null;

    try {
      await SupabaseService.client.from('tasks').delete().eq('id', taskId);

      // Remove from local list immediately
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting task: $e');
      _errorMessage = 'Failed to delete task';
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTask(String taskId, String? assigneeId, {String? assigneeName}) async {
    _errorMessage = null;
    final currentUserId = SupabaseService.currentUser?.id;

    try {
      await SupabaseService.client
          .from('tasks')
          .update({'assigned_to': assigneeId}).eq('id', taskId);

      await _recordHistory(taskId, 'assigned', details: {
        'assignee_id': assigneeId,
        'assignee_name': assigneeName,
      });

      // Notify the assignee (if not self-assigning)
      if (assigneeId != null && assigneeId != currentUserId) {
        final task = _tasks.firstWhere((t) => t.id == taskId);
        await NotificationProvider.createNotification(
          userId: assigneeId,
          type: NotificationType.taskAssigned,
          title: 'Task assigned to you',
          body: '"${task.title}" has been assigned to you',
          data: {'task_id': taskId},
        );
      }

      // Reload tasks to show the updated assignment
      if (_currentHouseholdId != null) {
        await loadTasks(_currentHouseholdId!);
      }

      return true;
    } catch (e) {
      debugPrint('Error assigning task: $e');
      _errorMessage = 'Failed to assign task';
      notifyListeners();
      return false;
    }
  }

  /// Take ownership of a task (assign to current user)
  Future<bool> takeOwnership(String taskId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    // Get current user's display name
    try {
      final profile = await SupabaseService.client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .single();
      final displayName = profile['display_name'] as String?;

      return assignTask(taskId, userId, assigneeName: displayName ?? 'Me');
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return assignTask(taskId, userId, assigneeName: 'Me');
    }
  }

  /// Release ownership of a task (unassign)
  Future<bool> releaseOwnership(String taskId) async {
    return assignTask(taskId, null, assigneeName: null);
  }

  Future<void> _notifyTaskCompleted(Task task, String completedByUserId) async {
    try {
      // Check if we already sent a completion notification for this task today
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existingNotification = await SupabaseService.client
          .from('notifications')
          .select('id')
          .eq('type', 'taskCompleted')
          .eq('data->>task_id', task.id)
          .gte('created_at', today)
          .limit(1)
          .maybeSingle();

      if (existingNotification != null) {
        // Already notified about this task today, skip
        return;
      }

      // Get the current user's display name
      final userResponse = await SupabaseService.client
          .from('profiles')
          .select('display_name')
          .eq('id', completedByUserId)
          .single();
      final userName = userResponse['display_name'] as String? ?? 'Someone';

      // Get all household members except the current user
      final membersResponse = await SupabaseService.client
          .from('household_members')
          .select('user_id')
          .eq('household_id', task.householdId)
          .neq('user_id', completedByUserId);

      for (final member in membersResponse as List) {
        final memberId = member['user_id'] as String;
        await NotificationProvider.createNotification(
          userId: memberId,
          type: NotificationType.taskCompleted,
          title: 'Task completed',
          body: '$userName completed "${task.title}"',
          data: {'task_id': task.id},
        );
      }
    } catch (e) {
      debugPrint('Error sending completion notifications: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============ Notes Methods ============

  Future<List<TaskNote>> loadNotes(String taskId) async {
    try {
      final response = await SupabaseService.client
          .from('task_notes')
          .select('''
            *,
            profiles(display_name)
          ''')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => TaskNote.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading notes: $e');
      return [];
    }
  }

  Future<bool> addNote({
    required String taskId,
    required String content,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await SupabaseService.client.from('task_notes').insert({
        'task_id': taskId,
        'user_id': userId,
        'content': content,
      });

      // Record history
      await _recordHistory(taskId, 'note_added');

      // Handle @mentions
      await _processMentions(taskId, content, userId);

      return true;
    } catch (e) {
      debugPrint('Error adding note: $e');
      return false;
    }
  }

  Future<void> _processMentions(String taskId, String content, String authorId) async {
    if (!content.contains('@')) return;

    try {
      // Get the task to find the household
      final task = _tasks.firstWhere((t) => t.id == taskId);

      // Get the author's name
      final authorResponse = await SupabaseService.client
          .from('profiles')
          .select('display_name')
          .eq('id', authorId)
          .single();
      final authorName = authorResponse['display_name'] as String? ?? 'Someone';

      // Get all household members with their display names
      final membersResponse = await SupabaseService.client
          .from('household_members')
          .select('user_id, profiles(display_name)')
          .eq('household_id', task.householdId);

      // Create a map of lowercase names to user IDs
      final memberMap = <String, String>{};
      final memberNames = <String>[];
      for (final member in membersResponse as List) {
        final displayName = member['profiles']?['display_name'] as String?;
        if (displayName != null) {
          memberMap[displayName.toLowerCase()] = member['user_id'] as String;
          memberNames.add(displayName);
        }
      }

      // Sort by length (longest first) to match "John Smith" before "John"
      memberNames.sort((a, b) => b.length.compareTo(a.length));

      // Find mentions by matching against actual member names
      final notifiedUsers = <String>{};
      final contentLower = content.toLowerCase();

      for (final name in memberNames) {
        final pattern = '@${name.toLowerCase()}';
        if (contentLower.contains(pattern)) {
          final mentionedUserId = memberMap[name.toLowerCase()];
          if (mentionedUserId != null &&
              mentionedUserId != authorId &&
              !notifiedUsers.contains(mentionedUserId)) {
            notifiedUsers.add(mentionedUserId);

            await NotificationProvider.createNotification(
              userId: mentionedUserId,
              type: NotificationType.mentioned,
              title: 'You were mentioned',
              body: '$authorName mentioned you in "${task.title}"',
              data: {'task_id': taskId},
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing mentions: $e');
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      await SupabaseService.client.from('task_notes').delete().eq('id', noteId);
      return true;
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return false;
    }
  }

  // ============ History Methods ============

  Future<List<TaskHistory>> loadHistory(String taskId) async {
    try {
      final response = await SupabaseService.client
          .from('task_history')
          .select('''
            *,
            profiles(display_name)
          ''')
          .eq('task_id', taskId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => TaskHistory.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading history: $e');
      return [];
    }
  }

  Future<void> _recordHistory(
    String taskId,
    String action, {
    Map<String, dynamic>? details,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client.from('task_history').insert({
        'task_id': taskId,
        'user_id': userId,
        'action': action,
        'details': details,
      });
    } catch (e) {
      debugPrint('Error recording history: $e');
    }
  }

  @override
  void dispose() {
    _tasksChannel?.unsubscribe();
    super.dispose();
  }
}
