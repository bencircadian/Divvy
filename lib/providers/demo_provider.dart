import 'package:flutter/foundation.dart';

import '../models/demo_data.dart';
import '../models/task.dart';

/// Provider for managing demo mode state.
///
/// Allows users to interact with sample tasks before creating an account.
class DemoProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isInitialized = false;

  List<Task> get tasks => _tasks;
  bool get isInitialized => _isInitialized;

  /// Get pending (incomplete) tasks
  List<Task> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  /// Get completed tasks
  List<Task> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  /// Get tasks due today
  List<Task> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay == today && !t.isCompleted;
    }).toList();
  }

  /// Initialize demo with sample tasks
  void initialize() {
    if (_isInitialized) return;
    _tasks = DemoData.sampleTasks;
    _isInitialized = true;
    notifyListeners();
  }

  /// Reset demo to initial state
  void reset() {
    _tasks = DemoData.sampleTasks;
    notifyListeners();
  }

  /// Toggle task completion status
  void toggleTaskComplete(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final updatedTask = task.copyWith(
      status: task.isCompleted ? TaskStatus.pending : TaskStatus.completed,
      completedAt: !task.isCompleted ? DateTime.now() : null,
      completedBy: !task.isCompleted ? 'demo-user' : null,
    );

    _tasks[index] = updatedTask;
    notifyListeners();
  }

  /// Add a new task to the demo
  void addTask({
    required String title,
    String? description,
    String? category,
    DateTime? dueDate,
  }) {
    final newTask = Task(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      householdId: 'demo-household',
      title: title,
      description: description,
      category: category ?? 'living',
      priority: TaskPriority.normal,
      dueDate: dueDate ?? DateTime.now(),
      status: TaskStatus.pending,
      createdBy: 'demo-user',
      createdAt: DateTime.now(),
    );

    _tasks.insert(0, newTask);
    notifyListeners();
  }

  /// Clear all demo data (called when user signs up)
  void clear() {
    _tasks = [];
    _isInitialized = false;
    notifyListeners();
  }
}
