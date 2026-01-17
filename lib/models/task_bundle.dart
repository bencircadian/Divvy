import 'task.dart';

/// Represents a bundle/routine of related tasks.
class TaskBundle {
  final String id;
  final String householdId;
  final String name;
  final String? description;
  final String icon;
  final String color;
  final String createdBy;
  final DateTime createdAt;

  /// List of tasks in this bundle.
  final List<Task>? tasks;

  const TaskBundle({
    required this.id,
    required this.householdId,
    required this.name,
    this.description,
    this.icon = 'list',
    this.color = '#009688',
    required this.createdBy,
    required this.createdAt,
    this.tasks,
  });

  factory TaskBundle.fromJson(Map<String, dynamic> json) {
    return TaskBundle(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'list',
      color: json['color'] as String? ?? '#009688',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      tasks: (json['tasks'] as List<dynamic>?)
          ?.map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'household_id': householdId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskBundle copyWith({
    String? id,
    String? householdId,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? createdBy,
    DateTime? createdAt,
    List<Task>? tasks,
  }) {
    return TaskBundle(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      tasks: tasks ?? this.tasks,
    );
  }

  /// Total number of tasks in the bundle.
  int get totalTasks => tasks?.length ?? 0;

  /// Number of completed tasks.
  int get completedTasks =>
      tasks?.where((t) => t.isCompleted).length ?? 0;

  /// Number of pending tasks.
  int get pendingTasks => totalTasks - completedTasks;

  /// Progress percentage (0.0 to 1.0).
  double get progress {
    if (totalTasks == 0) return 0;
    return completedTasks / totalTasks;
  }

  /// Progress percentage as integer (0 to 100).
  int get progressPercent => (progress * 100).round();

  /// Whether all tasks are completed.
  bool get isComplete => totalTasks > 0 && completedTasks == totalTasks;

  /// Whether the bundle has no tasks.
  bool get isEmpty => totalTasks == 0;

  /// Get tasks sorted by bundle order.
  List<Task> get sortedTasks {
    if (tasks == null) return [];
    final sorted = List<Task>.from(tasks!);
    sorted.sort((a, b) => (a.bundleOrder ?? 999).compareTo(b.bundleOrder ?? 999));
    return sorted;
  }

  /// Available icons for bundles.
  static const List<String> availableIcons = [
    'list',
    'home',
    'cleaning_services',
    'bed',
    'kitchen',
    'bathroom',
    'yard',
    'pets',
    'restaurant',
    'local_laundry_service',
    'fitness_center',
    'self_improvement',
  ];

  /// Available colors for bundles (hex values).
  static const List<String> availableColors = [
    '#009688', // Teal
    '#F67280', // Rose
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#9C27B0', // Purple
    '#FF9800', // Orange
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#E91E63', // Pink
    '#00BCD4', // Cyan
  ];
}
