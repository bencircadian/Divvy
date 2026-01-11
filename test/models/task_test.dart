import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';
import '../helpers/test_data.dart';

void main() {
  group('Task', () {
    group('fromJson', () {
      test('parses minimal valid JSON', () {
        final json = TestData.createTaskJson();
        final task = Task.fromJson(json);

        expect(task.id, TestData.testTaskId);
        expect(task.householdId, TestData.testHouseholdId);
        expect(task.title, 'Test Task');
        expect(task.createdBy, TestData.testUserId);
        expect(task.status, TaskStatus.pending);
        expect(task.priority, TaskPriority.normal);
      });

      test('parses all fields correctly', () {
        final json = TestData.createTaskJson(
          id: 'custom-id',
          title: 'Custom Task',
          description: 'A description',
          assignedTo: 'assignee-id',
          status: 'completed',
          priority: 'high',
          dueDate: '2026-01-15T10:00:00.000Z',
          duePeriod: 'morning',
          completedAt: '2026-01-11T12:00:00.000Z',
          completedBy: 'completer-id',
          isRecurring: true,
          recurrenceRule: {'frequency': 'daily', 'interval': 1},
          parentTaskId: 'parent-id',
          coverImageUrl: 'https://example.com/image.jpg',
        );

        final task = Task.fromJson(json);

        expect(task.id, 'custom-id');
        expect(task.title, 'Custom Task');
        expect(task.description, 'A description');
        expect(task.assignedTo, 'assignee-id');
        expect(task.status, TaskStatus.completed);
        expect(task.priority, TaskPriority.high);
        expect(task.dueDate, isNotNull);
        expect(task.duePeriod, DuePeriod.morning);
        expect(task.completedAt, isNotNull);
        expect(task.completedBy, 'completer-id');
        expect(task.isRecurring, true);
        expect(task.recurrenceRule, isNotNull);
        expect(task.parentTaskId, 'parent-id');
        expect(task.coverImageUrl, 'https://example.com/image.jpg');
      });

      test('parses status correctly', () {
        expect(Task.fromJson(TestData.createTaskJson(status: 'pending')).status, TaskStatus.pending);
        expect(Task.fromJson(TestData.createTaskJson(status: 'completed')).status, TaskStatus.completed);
        expect(Task.fromJson(TestData.createTaskJson(status: 'unknown')).status, TaskStatus.pending);
      });

      test('parses priority correctly', () {
        expect(Task.fromJson(TestData.createTaskJson(priority: 'low')).priority, TaskPriority.low);
        expect(Task.fromJson(TestData.createTaskJson(priority: 'normal')).priority, TaskPriority.normal);
        expect(Task.fromJson(TestData.createTaskJson(priority: 'high')).priority, TaskPriority.high);
        expect(Task.fromJson(TestData.createTaskJson(priority: 'unknown')).priority, TaskPriority.normal);
      });

      test('parses due period correctly', () {
        expect(Task.fromJson(TestData.createTaskJson(duePeriod: 'morning')).duePeriod, DuePeriod.morning);
        expect(Task.fromJson(TestData.createTaskJson(duePeriod: 'afternoon')).duePeriod, DuePeriod.afternoon);
        expect(Task.fromJson(TestData.createTaskJson(duePeriod: 'evening')).duePeriod, DuePeriod.evening);
        expect(Task.fromJson(TestData.createTaskJson(duePeriod: null)).duePeriod, isNull);
      });

      test('handles null optional fields', () {
        final json = TestData.createTaskJson();
        final task = Task.fromJson(json);

        expect(task.description, isNull);
        expect(task.assignedTo, isNull);
        expect(task.dueDate, isNull);
        expect(task.completedAt, isNull);
        expect(task.recurrenceRule, isNull);
      });

      test('parses nested profile data', () {
        final json = {
          ...TestData.createTaskJson(),
          'assigned_profile': {'display_name': 'Assigned User'},
          'created_profile': {'display_name': 'Creator'},
          'completed_profile': {'display_name': 'Completer'},
        };

        final task = Task.fromJson(json);

        expect(task.assignedToName, 'Assigned User');
        expect(task.createdByName, 'Creator');
        expect(task.completedByName, 'Completer');
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final task = TestData.createTask(
          id: 'task-1',
          title: 'My Task',
          description: 'Description',
          assignedTo: 'user-2',
          status: TaskStatus.completed,
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 1, 15),
          duePeriod: DuePeriod.afternoon,
          isRecurring: true,
          recurrenceRule: TestData.createRecurrenceRule(),
        );

        final json = task.toJson();

        expect(json['id'], 'task-1');
        expect(json['title'], 'My Task');
        expect(json['description'], 'Description');
        expect(json['assigned_to'], 'user-2');
        expect(json['status'], 'completed');
        expect(json['priority'], 'high');
        expect(json['due_date'], isNotNull);
        expect(json['due_period'], 'afternoon');
        expect(json['is_recurring'], true);
        expect(json['recurrence_rule'], isNotNull);
      });

      test('handles null values', () {
        final task = TestData.createTask();
        final json = task.toJson();

        expect(json['description'], isNull);
        expect(json['assigned_to'], isNull);
        expect(json['due_date'], isNull);
        expect(json['completed_at'], isNull);
      });
    });

    group('copyWith', () {
      test('creates a copy with updated values', () {
        final original = TestData.createTask(title: 'Original');
        final copy = original.copyWith(title: 'Updated');

        expect(copy.title, 'Updated');
        expect(copy.id, original.id);
        expect(original.title, 'Original'); // Original unchanged
      });

      test('preserves all fields when not specified', () {
        final original = TestData.createTask(
          title: 'Task',
          description: 'Desc',
          priority: TaskPriority.high,
        );
        final copy = original.copyWith(title: 'New Title');

        expect(copy.description, original.description);
        expect(copy.priority, original.priority);
        expect(copy.createdBy, original.createdBy);
      });
    });

    group('computed properties', () {
      test('isCompleted returns true for completed status', () {
        final completedTask = TestData.createTask(status: TaskStatus.completed);
        final pendingTask = TestData.createTask(status: TaskStatus.pending);

        expect(completedTask.isCompleted, true);
        expect(pendingTask.isCompleted, false);
      });

      test('isPending returns true for pending status', () {
        final completedTask = TestData.createTask(status: TaskStatus.completed);
        final pendingTask = TestData.createTask(status: TaskStatus.pending);

        expect(pendingTask.isPending, true);
        expect(completedTask.isPending, false);
      });

      test('isOverdue returns true for past due dates on pending tasks', () {
        final overdueTask = TestData.createTask(
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          status: TaskStatus.pending,
        );
        final futureTask = TestData.createTask(
          dueDate: DateTime.now().add(const Duration(days: 1)),
          status: TaskStatus.pending,
        );
        final completedOverdueTask = TestData.createTask(
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          status: TaskStatus.completed,
        );
        final noDueDateTask = TestData.createTask(status: TaskStatus.pending);

        expect(overdueTask.isOverdue, true);
        expect(futureTask.isOverdue, false);
        expect(completedOverdueTask.isOverdue, false); // Completed tasks not overdue
        expect(noDueDateTask.isOverdue, false); // No due date = not overdue
      });

      test('isDueToday returns true for tasks due today', () {
        final now = DateTime.now();
        final todayTask = TestData.createTask(
          dueDate: DateTime(now.year, now.month, now.day, 14, 0),
        );
        final tomorrowTask = TestData.createTask(
          dueDate: DateTime(now.year, now.month, now.day + 1),
        );
        final noDueDateTask = TestData.createTask();

        expect(todayTask.isDueToday, true);
        expect(tomorrowTask.isDueToday, false);
        expect(noDueDateTask.isDueToday, false);
      });
    });
  });

  group('TaskStatus enum', () {
    test('has correct values', () {
      expect(TaskStatus.values.length, 2);
      expect(TaskStatus.pending.name, 'pending');
      expect(TaskStatus.completed.name, 'completed');
    });
  });

  group('TaskPriority enum', () {
    test('has correct values', () {
      expect(TaskPriority.values.length, 3);
      expect(TaskPriority.low.name, 'low');
      expect(TaskPriority.normal.name, 'normal');
      expect(TaskPriority.high.name, 'high');
    });
  });

  group('DuePeriod enum', () {
    test('has correct values', () {
      expect(DuePeriod.values.length, 3);
      expect(DuePeriod.morning.name, 'morning');
      expect(DuePeriod.afternoon.name, 'afternoon');
      expect(DuePeriod.evening.name, 'evening');
    });
  });
}
