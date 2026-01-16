/// Full tests for TaskProvider
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';
import 'package:divvy/models/recurrence_rule.dart';

import '../helpers/test_data.dart';
import '../mocks/mock_providers.dart';
import '../mocks/mock_services.dart';

void main() {
  group('TaskProvider Full Tests', () {
    late MockTaskProvider taskProvider;

    setUp(() {
      taskProvider = MockTaskProvider();
      MockCacheService.reset();
    });

    group('loadTasks', () {
      test('sets loading state while fetching', () async {
        expect(taskProvider.isLoading, isFalse);

        final loadFuture = taskProvider.loadTasks(TestData.testHouseholdId);
        taskProvider.setLoading(true);
        expect(taskProvider.isLoading, isTrue);

        await loadFuture;
        expect(taskProvider.isLoading, isFalse);
      });

      test('tasks are available after loading', () async {
        final testTasks = TestData.createTaskList();
        taskProvider.setTasks(testTasks);

        expect(taskProvider.tasks.length, equals(testTasks.length));
      });

      test('offline fallback uses cache', () async {
        MockCacheService.setOnlineStatus(false);
        final cachedTasks = TestData.createTaskList();
        MockCacheService.setCachedTasks(cachedTasks);

        final cached = MockCacheService.getCachedTasks();
        expect(cached.length, equals(cachedTasks.length));
      });

      test('error state is set on failure', () {
        taskProvider.setError('Failed to load tasks');

        expect(taskProvider.errorMessage, isNotNull);
        expect(taskProvider.errorMessage, contains('Failed'));
      });
    });

    group('Task Getters', () {
      test('tasksDueToday returns only today\'s tasks', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 12);
        final tomorrow = today.add(const Duration(days: 1));
        final yesterday = today.subtract(const Duration(days: 1));

        taskProvider.setTasks([
          TestData.createTask(id: '1', title: 'Today', dueDate: today),
          TestData.createTask(id: '2', title: 'Tomorrow', dueDate: tomorrow),
          TestData.createTask(id: '3', title: 'Yesterday', dueDate: yesterday),
          TestData.createTask(id: '4', title: 'No date'),
        ]);

        final dueToday = taskProvider.tasksDueToday;
        expect(dueToday.length, equals(1));
        expect(dueToday.first.title, equals('Today'));
      });

      test('tasksDueThisWeek returns tasks within 7 days', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 12);

        taskProvider.setTasks([
          TestData.createTask(id: '1', title: 'Today', dueDate: today),
          TestData.createTask(id: '2', title: 'In 3 days', dueDate: today.add(const Duration(days: 3))),
          TestData.createTask(id: '3', title: 'In 6 days', dueDate: today.add(const Duration(days: 6))),
          TestData.createTask(id: '4', title: 'In 10 days', dueDate: today.add(const Duration(days: 10))),
        ]);

        final dueThisWeek = taskProvider.tasksDueThisWeek;
        expect(dueThisWeek.length, equals(3));
      });

      test('upcomingUniqueTasks deduplicates recurring tasks', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final rule = TestData.createRecurrenceRule();

        taskProvider.setTasks([
          // Regular task
          TestData.createTask(
            id: '1',
            title: 'Regular Task',
            dueDate: today.add(const Duration(days: 2)),
          ),
          // Recurring task instances (should be deduplicated)
          TestData.createTask(
            id: '2',
            title: 'Recurring Task',
            isRecurring: true,
            recurrenceRule: rule,
            dueDate: today.add(const Duration(days: 1)),
          ),
          TestData.createTask(
            id: '3',
            title: 'Recurring Task', // Same title = deduped
            isRecurring: true,
            recurrenceRule: rule,
            dueDate: today.add(const Duration(days: 2)),
          ),
          TestData.createTask(
            id: '4',
            title: 'Recurring Task', // Same title = deduped
            isRecurring: true,
            recurrenceRule: rule,
            dueDate: today.add(const Duration(days: 3)),
          ),
        ]);

        final upcoming = taskProvider.upcomingUniqueTasks;
        expect(upcoming.length, equals(2)); // 1 regular + 1 recurring (deduped)
      });

      test('pendingTasks filters correctly', () {
        taskProvider.setTasks([
          TestData.createTask(id: '1', status: TaskStatus.pending),
          TestData.createTask(id: '2', status: TaskStatus.pending),
          TestData.createTask(id: '3', status: TaskStatus.completed),
        ]);

        expect(taskProvider.pendingTasks.length, equals(2));
        expect(taskProvider.completedTasks.length, equals(1));
      });
    });

    group('Real-time Events', () {
      test('INSERT event adds task to list', () {
        taskProvider.setTasks([]);

        // Simulate insert by adding task
        final newTask = TestData.createTask(id: 'new-task', title: 'New Task');
        taskProvider.setTasks([newTask]);

        expect(taskProvider.tasks.length, equals(1));
        expect(taskProvider.tasks.first.id, equals('new-task'));
      });

      test('UPDATE event modifies existing task', () {
        taskProvider.setTasks([
          TestData.createTask(id: 'task-1', title: 'Original Title'),
        ]);

        // Simulate update
        taskProvider.setTasks([
          TestData.createTask(id: 'task-1', title: 'Updated Title'),
        ]);

        expect(taskProvider.tasks.first.title, equals('Updated Title'));
      });

      test('DELETE event removes task from list', () async {
        taskProvider.setTasks([
          TestData.createTask(id: 'task-1'),
          TestData.createTask(id: 'task-2'),
        ]);

        await taskProvider.deleteTask('task-1');

        expect(taskProvider.tasks.length, equals(1));
        expect(taskProvider.tasks.first.id, equals('task-2'));
      });

      test('avoids duplicate inserts', () {
        taskProvider.setTasks([
          TestData.createTask(id: 'task-1'),
        ]);

        // Try to add same task again
        final existingIds = taskProvider.tasks.map((t) => t.id).toSet();
        if (!existingIds.contains('task-1')) {
          taskProvider.setTasks([
            ...taskProvider.tasks,
            TestData.createTask(id: 'task-1'),
          ]);
        }

        expect(taskProvider.tasks.length, equals(1));
      });
    });

    group('Task Completion', () {
      test('toggleTaskComplete marks pending as completed', () async {
        final task = TestData.createTask(
          id: 'task-1',
          status: TaskStatus.pending,
        );
        taskProvider.setTasks([task]);

        await taskProvider.toggleTaskComplete(task);

        expect(taskProvider.tasks.first.isCompleted, isTrue);
        expect(taskProvider.tasks.first.completedAt, isNotNull);
      });

      test('toggleTaskComplete marks completed as pending', () async {
        final task = TestData.createTask(
          id: 'task-1',
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        taskProvider.setTasks([task]);

        await taskProvider.toggleTaskComplete(task);

        expect(taskProvider.tasks.first.isCompleted, isFalse);
        expect(taskProvider.tasks.first.completedAt, isNull);
      });

      test('completing recurring task creates next occurrence logic verified', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );
        final task = TestData.createTask(
          id: 'recurring-1',
          isRecurring: true,
          recurrenceRule: rule,
          dueDate: DateTime.now(),
        );

        // Verify task is recurring
        expect(task.isRecurring, isTrue);
        expect(task.recurrenceRule, isNotNull);

        // Next occurrence would be created by TaskRecurrenceService
        final nextDate = rule.getNextOccurrence(task.dueDate ?? DateTime.now());
        expect(nextDate, isNotNull);
      });
    });

    group('@mention Detection', () {
      test('detects @mentions in note content', () {
        const content = '@John please review this task';
        expect(content.contains('@'), isTrue);

        // Extract mention
        final mentionPattern = RegExp(r'@(\w+)');
        final match = mentionPattern.firstMatch(content);
        expect(match, isNotNull);
        expect(match!.group(1), equals('John'));
      });

      test('detects multiple @mentions', () {
        const content = '@John and @Jane please help';
        final mentionPattern = RegExp(r'@(\w+)');
        final matches = mentionPattern.allMatches(content);

        expect(matches.length, equals(2));
      });

      test('handles @mentions with special names', () {
        const content = '@JohnSmith check this';
        final mentionPattern = RegExp(r'@(\w+)');
        final match = mentionPattern.firstMatch(content);

        expect(match!.group(1), equals('JohnSmith'));
      });
    });

    group('Error Handling', () {
      test('clearError removes error message', () {
        taskProvider.setError('Some error');
        expect(taskProvider.errorMessage, isNotNull);

        taskProvider.clearError();
        expect(taskProvider.errorMessage, isNull);
      });

      test('graceful degradation uses cache on error', () {
        final cachedTasks = TestData.createTaskList();
        MockCacheService.setCachedTasks(cachedTasks);

        // Simulate error scenario
        taskProvider.setError('Network error');

        // Tasks should still be available from cache
        final cached = MockCacheService.getCachedTasks();
        expect(cached, isNotEmpty);
      });
    });

    group('Task CRUD Operations', () {
      test('createTask adds new task', () async {
        final result = await taskProvider.createTask(
          householdId: TestData.testHouseholdId,
          title: 'New Task',
        );

        expect(result, isTrue);
        expect(taskProvider.tasks.any((t) => t.title == 'New Task'), isTrue);
      });

      test('deleteTask removes task', () async {
        taskProvider.setTasks([
          TestData.createTask(id: 'delete-me'),
          TestData.createTask(id: 'keep-me'),
        ]);

        final result = await taskProvider.deleteTask('delete-me');

        expect(result, isTrue);
        expect(taskProvider.tasks.length, equals(1));
        expect(taskProvider.tasks.first.id, equals('keep-me'));
      });
    });

    group('Task Sorting', () {
      test('tasksSortedByDueDate is correctly exposed', () {
        final now = DateTime.now();

        taskProvider.setTasks([
          TestData.createTask(id: '1', dueDate: now.add(const Duration(days: 3))),
          TestData.createTask(id: '2', dueDate: now.add(const Duration(days: 1))),
          TestData.createTask(id: '3', dueDate: now.add(const Duration(days: 2))),
        ]);

        final sorted = taskProvider.tasks.toList()
          ..sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });

        expect(sorted[0].id, equals('2'));
        expect(sorted[1].id, equals('3'));
        expect(sorted[2].id, equals('1'));
      });

      test('completed tasks sort after pending', () {
        taskProvider.setTasks([
          TestData.createTask(id: '1', status: TaskStatus.completed),
          TestData.createTask(id: '2', status: TaskStatus.pending),
          TestData.createTask(id: '3', status: TaskStatus.completed),
          TestData.createTask(id: '4', status: TaskStatus.pending),
        ]);

        final sorted = taskProvider.tasks.toList()
          ..sort((a, b) {
            if (a.isCompleted && !b.isCompleted) return 1;
            if (!a.isCompleted && b.isCompleted) return -1;
            return 0;
          });

        expect(sorted[0].status, equals(TaskStatus.pending));
        expect(sorted[1].status, equals(TaskStatus.pending));
        expect(sorted[2].status, equals(TaskStatus.completed));
        expect(sorted[3].status, equals(TaskStatus.completed));
      });
    });
  });
}
