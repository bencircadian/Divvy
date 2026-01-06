import 'recurrence_rule.dart';

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

  // Joined data
  final String? assignedToName;
  final String? createdByName;
  final String? completedByName;

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
    this.assignedToName,
    this.createdByName,
    this.completedByName,
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
      recurrenceRule: json['recurrence_rule'] != null
          ? RecurrenceRule.fromJson(json['recurrence_rule'] as Map<String, dynamic>)
          : null,
      parentTaskId: json['parent_task_id'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      assignedToName: json['assigned_profile']?['display_name'] as String?,
      createdByName: json['created_profile']?['display_name'] as String?,
      completedByName: json['completed_profile']?['display_name'] as String?,
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
    String? assignedToName,
    String? createdByName,
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
      assignedToName: assignedToName ?? this.assignedToName,
      createdByName: createdByName ?? this.createdByName,
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
}
