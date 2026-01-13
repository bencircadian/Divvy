import 'dart:convert';

import 'recurrence_rule.dart';
import 'task_contributor.dart';

enum TaskStatus { pending, completed }

enum TaskPriority { low, normal, high }

enum DuePeriod { morning, afternoon, evening }

class Task {
  final String id;
  final String householdId;
  final String title;
  final String? description;
  final String createdBy;
  final String? assignedTo;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DuePeriod? duePeriod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? completedBy;

  // Recurrence fields
  final bool isRecurring;
  final RecurrenceRule? recurrenceRule;
  final String? parentTaskId;

  // Cover image
  final String? coverImageUrl;

  // Category for organizing tasks
  final String? category;

  // Bundle/routine grouping
  final String? bundleId;
  final int? bundleOrder;

  // Joined data
  final String? assignedToName;
  final String? createdByName;
  final String? completedByName;

  // Multi-person task contributors
  final List<TaskContributor>? contributors;

  Task({
    required this.id,
    required this.householdId,
    required this.title,
    this.description,
    required this.createdBy,
    this.assignedTo,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.normal,
    this.dueDate,
    this.duePeriod,
    required this.createdAt,
    this.completedAt,
    this.completedBy,
    this.isRecurring = false,
    this.recurrenceRule,
    this.parentTaskId,
    this.coverImageUrl,
    this.category,
    this.bundleId,
    this.bundleOrder,
    this.assignedToName,
    this.createdByName,
    this.completedByName,
    this.contributors,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      duePeriod: _parseDuePeriod(json['due_period'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      completedBy: json['completed_by'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceRule: _parseRecurrenceRule(json['recurrence_rule']),
      parentTaskId: json['parent_task_id'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      category: json['category'] as String?,
      bundleId: json['bundle_id'] as String?,
      bundleOrder: json['bundle_order'] as int?,
      assignedToName: json['assigned_profile']?['display_name'] as String?,
      createdByName: json['created_profile']?['display_name'] as String?,
      completedByName: json['completed_profile']?['display_name'] as String?,
      contributors: (json['contributors'] as List<dynamic>?)
          ?.map((c) => TaskContributor.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'status': status.name,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'due_period': duePeriod?.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'completed_by': completedBy,
      'is_recurring': isRecurring,
      'recurrence_rule': recurrenceRule?.toJson(),
      'parent_task_id': parentTaskId,
      'cover_image_url': coverImageUrl,
      'category': category,
      'bundle_id': bundleId,
      'bundle_order': bundleOrder,
    };
  }

  Task copyWith({
    String? id,
    String? householdId,
    String? title,
    String? description,
    String? createdBy,
    String? assignedTo,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DuePeriod? duePeriod,
    DateTime? createdAt,
    DateTime? completedAt,
    String? completedBy,
    bool? isRecurring,
    RecurrenceRule? recurrenceRule,
    String? parentTaskId,
    String? coverImageUrl,
    String? category,
    String? bundleId,
    int? bundleOrder,
    String? assignedToName,
    String? createdByName,
    String? completedByName,
    List<TaskContributor>? contributors,
  }) {
    return Task(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      duePeriod: duePeriod ?? this.duePeriod,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      bundleId: bundleId ?? this.bundleId,
      bundleOrder: bundleOrder ?? this.bundleOrder,
      assignedToName: assignedToName ?? this.assignedToName,
      createdByName: createdByName ?? this.createdByName,
      completedByName: completedByName ?? this.completedByName,
      contributors: contributors ?? this.contributors,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  static TaskStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }

  static TaskPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.normal;
    }
  }

  static DuePeriod? _parseDuePeriod(String? period) {
    switch (period) {
      case 'morning':
        return DuePeriod.morning;
      case 'afternoon':
        return DuePeriod.afternoon;
      case 'evening':
        return DuePeriod.evening;
      default:
        return null;
    }
  }

  /// Parse recurrence_rule which may be a JSON string or a Map
  static RecurrenceRule? _parseRecurrenceRule(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        // Parse JSON string to Map
        final decoded = jsonDecode(value) as Map<String, dynamic>;
        return RecurrenceRule.fromJson(decoded);
      } else if (value is Map<String, dynamic>) {
        // Already a Map
        return RecurrenceRule.fromJson(value);
      }
    } catch (e) {
      // If parsing fails, return null rather than crashing
      return null;
    }
    return null;
  }
}
