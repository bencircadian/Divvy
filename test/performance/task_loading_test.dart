/// Performance tests for task loading
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';

import '../helpers/test_data.dart';
import '../helpers/test_helpers.dart';
import '../mocks/mock_services.dart';

void main() {
  group('Task Loading Performance Tests', () {
    setUp(() {
      MockCacheService.reset();
    });

    group('Load Time Benchmarks', () {
      test('load 100 tasks completes in < 100ms', () async {
        final tasks = generateLargeTskList(100);

        await assertCompletesWithin(
          () async {
            MockCacheService.setCachedTasks(tasks);
            final loaded = MockCacheService.getCachedTasks();
            expect(loaded.length, equals(100));
          },
          const Duration(milliseconds: 100),
          reason: 'Loading 100 tasks should complete quickly',
        );
      });

      test('load 1000 tasks completes in < 500ms', () async {
        final tasks = generateLargeTskList(1000);

        await assertCompletesWithin(
          () async {
            MockCacheService.setCachedTasks(tasks);
            final loaded = MockCacheService.getCachedTasks();
            expect(loaded.length, equals(1000));
          },
          const Duration(milliseconds: 500),
          reason: 'Loading 1000 tasks should complete within 500ms',
        );
      });

      test('load 5000 tasks completes in < 2000ms', () async {
        final tasks = generateLargeTskList(5000);

        await assertCompletesWithin(
          () async {
            MockCacheService.setCachedTasks(tasks);
            final loaded = MockCacheService.getCachedTasks();
            expect(loaded.length, equals(5000));
          },
          const Duration(milliseconds: 2000),
          reason: 'Loading 5000 tasks should complete within 2 seconds',
        );
      });
    });

    group('Incremental Loading Performance', () {
      test('adding tasks one by one is efficient', () async {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          final task = TestData.createTask(
            id: 'task-$i',
            title: 'Task $i',
          );
          final current = MockCacheService.getCachedTasks();
          await MockCacheService.cacheTasks([...current, task]);
        }

        stopwatch.stop();

        expect(
          stopwatch.elapsed,
          lessThan(const Duration(seconds: 2)),
          reason: 'Adding 100 tasks incrementally should be efficient',
        );
      });

      test('batch loading is faster than incremental', () async {
        // Incremental loading
        final incrementalStopwatch = Stopwatch()..start();
        for (int i = 0; i < 50; i++) {
          final task = TestData.createTask(id: 'inc-$i');
          final current = MockCacheService.getCachedTasks();
          await MockCacheService.cacheTasks([...current, task]);
        }
        incrementalStopwatch.stop();

        MockCacheService.reset();

        // Batch loading
        final batchStopwatch = Stopwatch()..start();
        final batchTasks = List.generate(
          50,
          (i) => TestData.createTask(id: 'batch-$i'),
        );
        await MockCacheService.cacheTasks(batchTasks);
        batchStopwatch.stop();

        expect(
          batchStopwatch.elapsed,
          lessThan(incrementalStopwatch.elapsed),
          reason: 'Batch loading should be faster than incremental',
        );
      });
    });

    group('Task Sorting Performance', () {
      test('sorting 1000 tasks by due date is fast', () async {
        final tasks = generateLargeTskList(1000);

        await assertCompletesWithin(
          () async {
            final sorted = List<Task>.from(tasks);
            sorted.sort((a, b) {
              if (a.dueDate == null && b.dueDate == null) return 0;
              if (a.dueDate == null) return 1;
              if (b.dueDate == null) return -1;
              return a.dueDate!.compareTo(b.dueDate!);
            });
            expect(sorted.length, equals(1000));
          },
          const Duration(milliseconds: 50),
          reason: 'Sorting 1000 tasks should be fast',
        );
      });

      test('filtering tasks by status is fast', () async {
        final tasks = generateLargeTskList(1000);

        await assertCompletesWithin(
          () async {
            final pending = tasks.where((t) => t.status == TaskStatus.pending).toList();
            final completed = tasks.where((t) => t.status == TaskStatus.completed).toList();
            expect(pending.length + completed.length, equals(1000));
          },
          const Duration(milliseconds: 50),
          reason: 'Filtering 1000 tasks by status should be fast',
        );
      });

      test('complex filtering (due today) is efficient', () async {
        final tasks = generateLargeTskList(1000);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        await assertCompletesWithin(
          () async {
            final dueToday = tasks.where((t) {
              if (t.dueDate == null) return false;
              final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
              return dueDay.isAtSameMomentAs(today) ||
                     (dueDay.isAfter(today) && dueDay.isBefore(tomorrow));
            }).toList();

            // Result depends on test data, just verify operation completes
            expect(dueToday, isA<List<Task>>());
          },
          const Duration(milliseconds: 50),
          reason: 'Complex date filtering should be efficient',
        );
      });
    });

    group('Task Deduplication Performance', () {
      test('deduplicating recurring tasks is efficient', () async {
        // Create tasks with recurring duplicates
        final tasks = <Task>[];
        for (int i = 0; i < 100; i++) {
          // Add 5 instances of each recurring task
          for (int j = 0; j < 5; j++) {
            tasks.add(TestData.createTask(
              id: 'task-$i-$j',
              title: 'Recurring Task $i',
              isRecurring: true,
              dueDate: DateTime.now().add(Duration(days: j)),
            ));
          }
        }

        await assertCompletesWithin(
          () async {
            final seenTitles = <String>{};
            final uniqueTasks = <Task>[];

            for (final task in tasks) {
              final key = task.isRecurring ? task.title : task.id;
              if (!seenTitles.contains(key)) {
                seenTitles.add(key);
                uniqueTasks.add(task);
              }
            }

            expect(uniqueTasks.length, equals(100));
          },
          const Duration(milliseconds: 50),
          reason: 'Deduplication should be efficient',
        );
      });
    });

    group('Memory Usage', () {
      test('large task lists do not cause excessive memory allocation', () async {
        // This is a simple heuristic test - in production you'd use memory profiling
        final tasks = generateLargeTskList(10000);

        // Perform multiple operations to stress memory
        final pending = tasks.where((t) => !t.isCompleted).toList();
        final completed = tasks.where((t) => t.isCompleted).toList();
        final sorted = List<Task>.from(tasks)..sort((a, b) =>
            (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

        // If we get here without OOM, the test passes
        expect(pending.length + completed.length, equals(10000));
        expect(sorted.length, equals(10000));
      });

      test('task list operations are non-destructive', () async {
        final originalTasks = generateLargeTskList(100);
        MockCacheService.setCachedTasks(originalTasks);

        // Perform various operations
        final cached = MockCacheService.getCachedTasks();
        cached.removeAt(0);
        cached.add(TestData.createTask(id: 'new-task'));

        // Original should be unchanged
        final stillCached = MockCacheService.getCachedTasks();
        expect(stillCached.length, equals(100));
      });
    });

    group('Edge Cases', () {
      test('empty task list operations are fast', () async {
        await assertCompletesWithin(
          () async {
            MockCacheService.setCachedTasks([]);
            final cached = MockCacheService.getCachedTasks();
            final pending = cached.where((t) => !t.isCompleted).toList();
            final sorted = List<Task>.from(cached)..sort((a, b) =>
                (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

            expect(pending, isEmpty);
            expect(sorted, isEmpty);
          },
          const Duration(milliseconds: 10),
          reason: 'Empty list operations should be instant',
        );
      });

      test('single task operations are fast', () async {
        await assertCompletesWithin(
          () async {
            final task = TestData.createTask();
            MockCacheService.setCachedTasks([task]);
            final cached = MockCacheService.getCachedTasks();

            expect(cached.length, equals(1));
          },
          const Duration(milliseconds: 10),
          reason: 'Single task operations should be instant',
        );
      });
    });
  });
}
