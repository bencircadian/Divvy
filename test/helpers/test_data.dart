/// Test data factories for Divvy app tests
library;

import 'package:divvy/models/task.dart';
import 'package:divvy/models/user_profile.dart';
import 'package:divvy/models/household.dart';
import 'package:divvy/models/household_member.dart';
import 'package:divvy/models/recurrence_rule.dart';
import 'package:divvy/models/task_note.dart';
import 'package:divvy/models/task_history.dart';
import 'package:divvy/models/app_notification.dart';
import 'package:divvy/models/notification_preferences.dart';
import 'package:divvy/models/user_streak.dart';
import 'package:divvy/models/task_template.dart';

/// Test data factory for creating test objects
class TestData {
  // Common IDs
  static const String testUserId = 'user-123';
  static const String testUserId2 = 'user-456';
  static const String testHouseholdId = 'household-789';
  static const String testTaskId = 'task-abc';
  static const String testTaskId2 = 'task-def';

  // Base timestamps
  static final DateTime now = DateTime(2026, 1, 11, 12, 0, 0);
  static final DateTime yesterday = now.subtract(const Duration(days: 1));
  static final DateTime tomorrow = now.add(const Duration(days: 1));
  static final DateTime nextWeek = now.add(const Duration(days: 7));

  // ============ Task Factory ============

  static Task createTask({
    String? id,
    String? householdId,
    String? title,
    String? description,
    String? createdBy,
    String? assignedTo,
    TaskStatus status = TaskStatus.pending,
    TaskPriority priority = TaskPriority.normal,
    DateTime? dueDate,
    DuePeriod? duePeriod,
    DateTime? createdAt,
    DateTime? completedAt,
    String? completedBy,
    bool isRecurring = false,
    RecurrenceRule? recurrenceRule,
    String? parentTaskId,
    String? coverImageUrl,
    String? assignedToName,
    String? createdByName,
  }) {
    return Task(
      id: id ?? testTaskId,
      householdId: householdId ?? testHouseholdId,
      title: title ?? 'Test Task',
      description: description,
      createdBy: createdBy ?? testUserId,
      assignedTo: assignedTo,
      status: status,
      priority: priority,
      dueDate: dueDate,
      duePeriod: duePeriod,
      createdAt: createdAt ?? now,
      completedAt: completedAt,
      completedBy: completedBy,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      parentTaskId: parentTaskId,
      coverImageUrl: coverImageUrl,
      assignedToName: assignedToName,
      createdByName: createdByName,
    );
  }

  static Map<String, dynamic> createTaskJson({
    String? id,
    String? householdId,
    String? title,
    String? description,
    String? createdBy,
    String? assignedTo,
    String status = 'pending',
    String priority = 'normal',
    String? dueDate,
    String? duePeriod,
    String? createdAt,
    String? completedAt,
    String? completedBy,
    bool isRecurring = false,
    Map<String, dynamic>? recurrenceRule,
    String? parentTaskId,
    String? coverImageUrl,
  }) {
    return {
      'id': id ?? testTaskId,
      'household_id': householdId ?? testHouseholdId,
      'title': title ?? 'Test Task',
      'description': description,
      'created_by': createdBy ?? testUserId,
      'assigned_to': assignedTo,
      'status': status,
      'priority': priority,
      'due_date': dueDate,
      'due_period': duePeriod,
      'created_at': createdAt ?? now.toIso8601String(),
      'completed_at': completedAt,
      'completed_by': completedBy,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule,
      'parent_task_id': parentTaskId,
      'cover_image_url': coverImageUrl,
    };
  }

  // ============ UserProfile Factory ============

  static UserProfile createUserProfile({
    String? id,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? testUserId,
      displayName: displayName ?? 'Test User',
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? now,
    );
  }

  static Map<String, dynamic> createUserProfileJson({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? createdAt,
  }) {
    return {
      'id': id ?? testUserId,
      'display_name': displayName ?? 'Test User',
      'avatar_url': avatarUrl,
      'created_at': createdAt ?? now.toIso8601String(),
    };
  }

  // ============ Household Factory ============

  static Household createHousehold({
    String? id,
    String? name,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Household(
      id: id ?? testHouseholdId,
      name: name ?? 'Test Household',
      inviteCode: inviteCode ?? 'ABC123',
      createdBy: createdBy ?? testUserId,
      createdAt: createdAt ?? now,
    );
  }

  static Map<String, dynamic> createHouseholdJson({
    String? id,
    String? name,
    String? inviteCode,
    String? createdBy,
    String? createdAt,
  }) {
    return {
      'id': id ?? testHouseholdId,
      'name': name ?? 'Test Household',
      'invite_code': inviteCode ?? 'ABC123',
      'created_by': createdBy ?? testUserId,
      'created_at': createdAt ?? now.toIso8601String(),
    };
  }

  // ============ HouseholdMember Factory ============

  static HouseholdMember createHouseholdMember({
    String? householdId,
    String? userId,
    String role = 'member',
    DateTime? joinedAt,
    String? displayName,
    String? avatarUrl,
  }) {
    return HouseholdMember(
      householdId: householdId ?? testHouseholdId,
      userId: userId ?? testUserId,
      role: role,
      joinedAt: joinedAt ?? now,
      displayName: displayName ?? 'Test Member',
      avatarUrl: avatarUrl,
    );
  }

  static Map<String, dynamic> createHouseholdMemberJson({
    String? householdId,
    String? userId,
    String role = 'member',
    String? joinedAt,
    String? displayName,
    String? avatarUrl,
  }) {
    return {
      'household_id': householdId ?? testHouseholdId,
      'user_id': userId ?? testUserId,
      'role': role,
      'joined_at': joinedAt ?? now.toIso8601String(),
      if (displayName != null || avatarUrl != null)
        'profiles': {
          'display_name': displayName,
          'avatar_url': avatarUrl,
        },
    };
  }

  // ============ RecurrenceRule Factory ============

  static RecurrenceRule createRecurrenceRule({
    RecurrenceFrequency frequency = RecurrenceFrequency.daily,
    int interval = 1,
    List<int>? days,
    DateTime? endDate,
  }) {
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      days: days,
      endDate: endDate,
    );
  }

  static Map<String, dynamic> createRecurrenceRuleJson({
    String frequency = 'daily',
    int interval = 1,
    List<int>? days,
    String? endDate,
  }) {
    return {
      'frequency': frequency,
      'interval': interval,
      if (days != null) 'days': days,
      if (endDate != null) 'endDate': endDate,
    };
  }

  // ============ TaskNote Factory ============

  static TaskNote createTaskNote({
    String? id,
    String? taskId,
    String? userId,
    String? content,
    DateTime? createdAt,
    String? userName,
  }) {
    return TaskNote(
      id: id ?? 'note-123',
      taskId: taskId ?? testTaskId,
      userId: userId ?? testUserId,
      content: content ?? 'Test note content',
      createdAt: createdAt ?? now,
      userName: userName ?? 'Test User',
    );
  }

  static Map<String, dynamic> createTaskNoteJson({
    String? id,
    String? taskId,
    String? userId,
    String? content,
    String? createdAt,
    String? userName,
  }) {
    return {
      'id': id ?? 'note-123',
      'task_id': taskId ?? testTaskId,
      'user_id': userId ?? testUserId,
      'content': content ?? 'Test note content',
      'created_at': createdAt ?? now.toIso8601String(),
      if (userName != null)
        'profiles': {'display_name': userName},
    };
  }

  // ============ TaskHistory Factory ============

  static TaskHistory createTaskHistory({
    String? id,
    String? taskId,
    String? userId,
    TaskAction action = TaskAction.created,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    String? userName,
  }) {
    return TaskHistory(
      id: id ?? 'history-123',
      taskId: taskId ?? testTaskId,
      userId: userId ?? testUserId,
      action: action,
      details: details,
      createdAt: createdAt ?? now,
      userName: userName ?? 'Test User',
    );
  }

  static Map<String, dynamic> createTaskHistoryJson({
    String? id,
    String? taskId,
    String? userId,
    String action = 'created',
    Map<String, dynamic>? details,
    String? createdAt,
    String? userName,
  }) {
    return {
      'id': id ?? 'history-123',
      'task_id': taskId ?? testTaskId,
      'user_id': userId ?? testUserId,
      'action': action,
      'details': details,
      'created_at': createdAt ?? now.toIso8601String(),
      if (userName != null)
        'profiles': {'display_name': userName},
    };
  }

  // ============ AppNotification Factory ============

  static AppNotification createAppNotification({
    String? id,
    String? userId,
    NotificationType type = NotificationType.taskAssigned,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool read = false,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? 'notification-123',
      userId: userId ?? testUserId,
      type: type,
      title: title ?? 'Test Notification',
      body: body ?? 'Test notification body',
      data: data ?? {},
      read: read,
      createdAt: createdAt ?? now,
    );
  }

  static Map<String, dynamic> createAppNotificationJson({
    String? id,
    String? userId,
    String type = 'task_assigned',
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool read = false,
    String? createdAt,
  }) {
    return {
      'id': id ?? 'notification-123',
      'user_id': userId ?? testUserId,
      'type': type,
      'title': title ?? 'Test Notification',
      'body': body ?? 'Test notification body',
      'data': data ?? {},
      'read': read,
      'created_at': createdAt ?? now.toIso8601String(),
    };
  }

  // ============ NotificationPreferences Factory ============

  static NotificationPreferences createNotificationPreferences({
    String? userId,
    bool pushEnabled = true,
    bool taskAssignedEnabled = true,
    bool taskCompletedEnabled = true,
    bool mentionsEnabled = true,
    bool dueRemindersEnabled = true,
    int reminderBeforeMinutes = 60,
  }) {
    return NotificationPreferences(
      userId: userId ?? testUserId,
      pushEnabled: pushEnabled,
      taskAssignedEnabled: taskAssignedEnabled,
      taskCompletedEnabled: taskCompletedEnabled,
      mentionsEnabled: mentionsEnabled,
      dueRemindersEnabled: dueRemindersEnabled,
      reminderBeforeMinutes: reminderBeforeMinutes,
    );
  }

  static Map<String, dynamic> createNotificationPreferencesJson({
    String? userId,
    bool pushEnabled = true,
    bool taskAssignedEnabled = true,
    bool taskCompletedEnabled = true,
    bool mentionsEnabled = true,
    bool dueRemindersEnabled = true,
    int reminderBeforeMinutes = 60,
  }) {
    return {
      'user_id': userId ?? testUserId,
      'push_enabled': pushEnabled,
      'task_assigned_enabled': taskAssignedEnabled,
      'task_completed_enabled': taskCompletedEnabled,
      'mentions_enabled': mentionsEnabled,
      'due_reminders_enabled': dueRemindersEnabled,
      'reminder_before_minutes': reminderBeforeMinutes,
    };
  }

  // ============ UserStreak Factory ============

  static UserStreak createUserStreak({
    String? id,
    String? userId,
    String? householdId,
    int currentStreak = 0,
    int longestStreak = 0,
    DateTime? lastCompletionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? displayName,
  }) {
    return UserStreak(
      id: id ?? 'streak-123',
      userId: userId ?? testUserId,
      householdId: householdId ?? testHouseholdId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastCompletionDate: lastCompletionDate,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      displayName: displayName ?? 'Test User',
    );
  }

  static Map<String, dynamic> createUserStreakJson({
    String? id,
    String? userId,
    String? householdId,
    int currentStreak = 0,
    int longestStreak = 0,
    String? lastCompletionDate,
    String? createdAt,
    String? updatedAt,
    String? displayName,
  }) {
    return {
      'id': id ?? 'streak-123',
      'user_id': userId ?? testUserId,
      'household_id': householdId ?? testHouseholdId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completion_date': lastCompletionDate,
      'created_at': createdAt ?? now.toIso8601String(),
      'updated_at': updatedAt ?? now.toIso8601String(),
      if (displayName != null)
        'profiles': {'display_name': displayName},
    };
  }

  // ============ TaskTemplate Factory ============

  static TaskTemplate createTaskTemplate({
    String? id,
    String? category,
    String? title,
    String? description,
    Map<String, dynamic>? suggestedRecurrence,
    bool isSystem = true,
  }) {
    return TaskTemplate(
      id: id ?? 'template-123',
      category: category ?? 'kitchen',
      title: title ?? 'Test Template',
      description: description,
      suggestedRecurrence: suggestedRecurrence,
      isSystem: isSystem,
    );
  }

  static Map<String, dynamic> createTaskTemplateJson({
    String? id,
    String? category,
    String? title,
    String? description,
    Map<String, dynamic>? suggestedRecurrence,
    bool isSystem = true,
  }) {
    return {
      'id': id ?? 'template-123',
      'category': category ?? 'kitchen',
      'title': title ?? 'Test Template',
      'description': description,
      'suggested_recurrence': suggestedRecurrence,
      'is_system': isSystem,
    };
  }

  // ============ List Factories ============

  /// Creates a list of tasks with various states for testing
  static List<Task> createTaskList() {
    return [
      createTask(id: 'task-1', title: 'Pending Task', status: TaskStatus.pending),
      createTask(id: 'task-2', title: 'Completed Task', status: TaskStatus.completed, completedAt: now),
      createTask(id: 'task-3', title: 'High Priority', priority: TaskPriority.high, dueDate: now),
      createTask(id: 'task-4', title: 'Low Priority', priority: TaskPriority.low),
      createTask(id: 'task-5', title: 'Due Today', dueDate: now),
      createTask(id: 'task-6', title: 'Due Tomorrow', dueDate: tomorrow),
      createTask(id: 'task-7', title: 'Overdue', dueDate: yesterday),
      createTask(id: 'task-8', title: 'Assigned Task', assignedTo: testUserId, assignedToName: 'Test User'),
      createTask(id: 'task-9', title: 'Recurring Task', isRecurring: true, recurrenceRule: createRecurrenceRule()),
    ];
  }

  /// Creates a list of household members
  static List<HouseholdMember> createMemberList() {
    return [
      createHouseholdMember(userId: testUserId, displayName: 'User 1', role: 'admin'),
      createHouseholdMember(userId: testUserId2, displayName: 'User 2', role: 'member'),
    ];
  }
}
