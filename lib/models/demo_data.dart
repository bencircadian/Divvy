import '../models/task.dart';

/// Demo data for the interactive demo board shown before sign-up.
class DemoData {
  /// Sample tasks for the demo board
  static List<Task> get sampleTasks => [
    Task(
      id: 'demo-1',
      householdId: 'demo-household',
      title: 'Wash the dishes',
      description: 'Don\'t forget the pots and pans!',
      category: 'kitchen',
      priority: TaskPriority.normal,
      dueDate: DateTime.now(),
      status: TaskStatus.pending,
      createdBy: 'demo-user',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Task(
      id: 'demo-2',
      householdId: 'demo-household',
      title: 'Take out the trash',
      description: 'Recycling goes out on Tuesday',
      category: 'outdoor',
      priority: TaskPriority.high,
      dueDate: DateTime.now(),
      status: TaskStatus.pending,
      createdBy: 'demo-user',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Task(
      id: 'demo-3',
      householdId: 'demo-household',
      title: 'Vacuum living room',
      category: 'living',
      priority: TaskPriority.low,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.pending,
      createdBy: 'demo-user',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Task(
      id: 'demo-4',
      householdId: 'demo-household',
      title: 'Clean bathroom sink',
      category: 'bathroom',
      priority: TaskPriority.normal,
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: TaskStatus.completed,
      completedAt: DateTime.now().subtract(const Duration(hours: 2)),
      completedBy: 'demo-user',
      createdBy: 'demo-user',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Task(
      id: 'demo-5',
      householdId: 'demo-household',
      title: 'Water the plants',
      category: 'outdoor',
      priority: TaskPriority.low,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: TaskStatus.pending,
      createdBy: 'demo-user',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
