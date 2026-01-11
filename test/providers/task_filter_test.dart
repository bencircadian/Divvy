import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';
import '../helpers/test_data.dart';

/// Tests for task filtering and computation logic
/// These tests validate the filtering algorithms used in TaskProvider
/// without requiring actual provider instantiation or Supabase mocking
void main() {
  group('Task Filtering Logic', () {
    late List<Task> testTasks;
    late DateTime now;
    late DateTime today;
    late DateTime tomorrow;

    setUp(() {
      now = DateTime(2026, 1, 11, 12, 0, 0);
      today = DateTime(now.year, now.month, now.day);
      tomorrow = today.add(const Duration(days: 1));

      testTasks = [
        // Pending tasks
        TestData.createTask(
          id: '1',
          title: 'Pending no due date',
          status: TaskStatus.pending,
        ),
        TestData.createTask(
          id: '2',
          title: 'Pending due today',
          status: TaskStatus.pending,
          dueDate: today.add(const Duration(hours: 14)),
        ),
        TestData.createTask(
          id: '3',
          title: 'Pending due tomorrow',
          status: TaskStatus.pending,
          dueDate: tomorrow.add(const Duration(hours: 10)),
        ),
        TestData.createTask(
          id: '4',
          title: 'Pending overdue',
          status: TaskStatus.pending,
          dueDate: today.subtract(const Duration(days: 1)),
        ),
        // Completed tasks
        TestData.createTask(
          id: '5',
          title: 'Completed today',
          status: TaskStatus.completed,
          dueDate: today,
          completedAt: now,
        ),
        TestData.createTask(
          id: '6',
          title: 'Completed yesterday',
          status: TaskStatus.completed,
          completedAt: today.subtract(const Duration(days: 1)),
        ),
        // Different priorities
        TestData.createTask(
          id: '7',
          title: 'High priority',
          status: TaskStatus.pending,
          priority: TaskPriority.high,
          dueDate: today,
        ),
        TestData.createTask(
          id: '8',
          title: 'Low priority',
          status: TaskStatus.pending,
          priority: TaskPriority.low,
        ),
        // Assigned tasks
        TestData.createTask(
          id: '9',
          title: 'Assigned task',
          status: TaskStatus.pending,
          assignedTo: TestData.testUserId,
        ),
        TestData.createTask(
          id: '10',
          title: 'Unassigned task',
          status: TaskStatus.pending,
          assignedTo: null,
        ),
        // Recurring task
        TestData.createTask(
          id: '11',
          title: 'Recurring task',
          status: TaskStatus.pending,
          isRecurring: true,
          recurrenceRule: TestData.createRecurrenceRule(),
          dueDate: tomorrow,
        ),
      ];
    });

    group('pendingTasks filter', () {
      List<Task> filterPending(List<Task> tasks) {
        return tasks.where((t) => t.status == TaskStatus.pending).toList();
      }

      test('returns only pending tasks', () {
        final pending = filterPending(testTasks);

        expect(pending.every((t) => t.status == TaskStatus.pending), true);
        expect(pending.length, 9); // All except the 2 completed
      });

      test('excludes completed tasks', () {
        final pending = filterPending(testTasks);

        expect(pending.any((t) => t.title == 'Completed today'), false);
        expect(pending.any((t) => t.title == 'Completed yesterday'), false);
      });
    });

    group('completedTasks filter', () {
      List<Task> filterCompleted(List<Task> tasks) {
        return tasks.where((t) => t.status == TaskStatus.completed).toList();
      }

      test('returns only completed tasks', () {
        final completed = filterCompleted(testTasks);

        expect(completed.every((t) => t.status == TaskStatus.completed), true);
        expect(completed.length, 2);
      });
    });

    group('tasksDueToday filter', () {
      List<Task> filterDueToday(List<Task> tasks, DateTime currentDate) {
        final todayStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final tomorrowStart = todayStart.add(const Duration(days: 1));

        return tasks.where((t) {
          if (t.dueDate == null) return false;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return dueDay.isAtSameMomentAs(todayStart) ||
              (dueDay.isAfter(todayStart) && dueDay.isBefore(tomorrowStart));
        }).toList();
      }

      test('returns tasks due today', () {
        final dueToday = filterDueToday(testTasks, now);

        expect(dueToday.any((t) => t.title == 'Pending due today'), true);
        expect(dueToday.any((t) => t.title == 'Completed today'), true);
        expect(dueToday.any((t) => t.title == 'High priority'), true);
      });

      test('excludes tasks due tomorrow', () {
        final dueToday = filterDueToday(testTasks, now);

        expect(dueToday.any((t) => t.title == 'Pending due tomorrow'), false);
      });

      test('excludes tasks without due date', () {
        final dueToday = filterDueToday(testTasks, now);

        expect(dueToday.any((t) => t.title == 'Pending no due date'), false);
      });
    });

    group('incompleteTodayTasks filter', () {
      List<Task> filterIncompleteToday(List<Task> tasks, DateTime currentDate) {
        final todayStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final tomorrowStart = todayStart.add(const Duration(days: 1));

        return tasks.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return (dueDay.isBefore(tomorrowStart) || dueDay.isAtSameMomentAs(todayStart));
        }).toList();
      }

      test('returns incomplete tasks due today or earlier', () {
        final incomplete = filterIncompleteToday(testTasks, now);

        expect(incomplete.any((t) => t.title == 'Pending due today'), true);
        expect(incomplete.any((t) => t.title == 'High priority'), true);
        expect(incomplete.any((t) => t.title == 'Pending overdue'), true);
      });

      test('excludes completed tasks', () {
        final incomplete = filterIncompleteToday(testTasks, now);

        expect(incomplete.any((t) => t.title == 'Completed today'), false);
      });

      test('excludes tasks due after today', () {
        final incomplete = filterIncompleteToday(testTasks, now);

        expect(incomplete.any((t) => t.title == 'Pending due tomorrow'), false);
      });
    });

    group('upcomingUniqueTasks filter', () {
      List<Task> filterUpcomingUnique(List<Task> tasks, DateTime currentDate) {
        final todayStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final tomorrowStart = todayStart.add(const Duration(days: 1));

        // Filter tasks after today
        final futureTasks = tasks.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return dueDay.isAfter(todayStart) || dueDay.isAtSameMomentAs(tomorrowStart);
        }).toList();

        // Sort by due date
        futureTasks.sort((a, b) =>
            (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

        // Remove recurring duplicates by title
        final seenTitles = <String>{};
        final uniqueTasks = <Task>[];

        for (final task in futureTasks) {
          final key = task.isRecurring ? task.title : task.id;
          if (!seenTitles.contains(key)) {
            seenTitles.add(key);
            uniqueTasks.add(task);
          }
        }

        return uniqueTasks;
      }

      test('returns tasks due after today', () {
        final upcoming = filterUpcomingUnique(testTasks, now);

        expect(upcoming.any((t) => t.title == 'Pending due tomorrow'), true);
        expect(upcoming.any((t) => t.title == 'Recurring task'), true);
      });

      test('excludes tasks due today', () {
        final upcoming = filterUpcomingUnique(testTasks, now);

        expect(upcoming.any((t) => t.title == 'Pending due today'), false);
        expect(upcoming.any((t) => t.title == 'High priority'), false);
      });

      test('excludes completed tasks', () {
        final upcoming = filterUpcomingUnique(testTasks, now);

        expect(upcoming.any((t) => t.status == TaskStatus.completed), false);
      });

      test('deduplicates recurring tasks by title', () {
        // Create a standalone list with explicit recurring tasks
        final testNow = DateTime(2026, 1, 11, 12, 0, 0);
        final testTomorrow = DateTime(2026, 1, 12);
        final tasksWithDuplicate = [
          TestData.createTask(
            id: 'recurring-1',
            title: 'Weekly Cleanup',
            status: TaskStatus.pending,
            isRecurring: true,
            dueDate: testTomorrow,
          ),
          TestData.createTask(
            id: 'recurring-2',
            title: 'Weekly Cleanup', // Same title - should be deduplicated
            status: TaskStatus.pending,
            isRecurring: true,
            dueDate: testTomorrow.add(const Duration(days: 7)),
          ),
          TestData.createTask(
            id: 'non-recurring',
            title: 'One-time task',
            status: TaskStatus.pending,
            isRecurring: false,
            dueDate: testTomorrow,
          ),
        ];

        final upcoming = filterUpcomingUnique(tasksWithDuplicate, testNow);

        // Should only have one "Weekly Cleanup" since both are recurring with same title
        final recurringCount = upcoming.where((t) => t.title == 'Weekly Cleanup').length;
        expect(recurringCount, 1);

        // Non-recurring task should be included
        expect(upcoming.any((t) => t.title == 'One-time task'), true);
      });
    });

    group('unassigned tasks filter', () {
      List<Task> filterUnassigned(List<Task> tasks) {
        return tasks.where((t) => t.assignedTo == null && t.status == TaskStatus.pending).toList();
      }

      test('returns pending tasks without assignee', () {
        final unassigned = filterUnassigned(testTasks);

        expect(unassigned.every((t) => t.assignedTo == null), true);
        expect(unassigned.every((t) => t.status == TaskStatus.pending), true);
      });

      test('excludes assigned tasks', () {
        final unassigned = filterUnassigned(testTasks);

        expect(unassigned.any((t) => t.title == 'Assigned task'), false);
      });
    });

    group('sorting', () {
      test('sorts by due date with completed at bottom', () {
        List<Task> sortTasksByDueDate(List<Task> tasks) {
          final sorted = List<Task>.from(tasks);
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

        final sorted = sortTasksByDueDate(testTasks);

        // Completed tasks should be at the end
        final completedIndices = sorted
            .asMap()
            .entries
            .where((e) => e.value.isCompleted)
            .map((e) => e.key)
            .toList();
        final pendingIndices = sorted
            .asMap()
            .entries
            .where((e) => !e.value.isCompleted)
            .map((e) => e.key)
            .toList();

        // All pending indices should be less than completed indices
        if (completedIndices.isNotEmpty && pendingIndices.isNotEmpty) {
          expect(pendingIndices.last < completedIndices.first, true);
        }
      });
    });

    group('priority filtering', () {
      test('filters by priority', () {
        final highPriority = testTasks.where((t) => t.priority == TaskPriority.high).toList();
        final normalPriority = testTasks.where((t) => t.priority == TaskPriority.normal).toList();
        final lowPriority = testTasks.where((t) => t.priority == TaskPriority.low).toList();

        expect(highPriority.length, 1);
        expect(highPriority.first.title, 'High priority');

        expect(lowPriority.length, 1);
        expect(lowPriority.first.title, 'Low priority');

        // Most tasks default to normal priority
        expect(normalPriority.length, greaterThan(0));
      });
    });
  });

  group('Task Computation', () {
    group('workload distribution', () {
      test('calculates task count per assignee', () {
        Map<String, int> calculateWorkload(List<Task> tasks) {
          final workload = <String, int>{};
          for (final task in tasks) {
            if (task.assignedTo != null && task.status == TaskStatus.pending) {
              workload[task.assignedTo!] = (workload[task.assignedTo!] ?? 0) + 1;
            }
          }
          return workload;
        }

        final tasks = [
          TestData.createTask(id: '1', assignedTo: 'user-1', status: TaskStatus.pending),
          TestData.createTask(id: '2', assignedTo: 'user-1', status: TaskStatus.pending),
          TestData.createTask(id: '3', assignedTo: 'user-2', status: TaskStatus.pending),
          TestData.createTask(id: '4', assignedTo: 'user-1', status: TaskStatus.completed),
          TestData.createTask(id: '5', assignedTo: null, status: TaskStatus.pending),
        ];

        final workload = calculateWorkload(tasks);

        expect(workload['user-1'], 2);
        expect(workload['user-2'], 1);
        expect(workload.containsKey(null), false);
      });
    });

    group('weekly completion count', () {
      test('counts tasks completed in last 7 days', () {
        Map<String, int> calculateWeeklyCompletions(List<Task> tasks, DateTime now) {
          final weekAgo = now.subtract(const Duration(days: 7));
          final counts = <String, int>{};

          for (final task in tasks) {
            if (task.status == TaskStatus.completed &&
                task.completedBy != null &&
                task.completedAt != null &&
                task.completedAt!.isAfter(weekAgo)) {
              counts[task.completedBy!] = (counts[task.completedBy!] ?? 0) + 1;
            }
          }

          return counts;
        }

        final now = DateTime(2026, 1, 11);
        final tasks = [
          // Completed this week
          TestData.createTask(
            id: '1',
            status: TaskStatus.completed,
            completedBy: 'user-1',
            completedAt: now.subtract(const Duration(days: 1)),
          ),
          TestData.createTask(
            id: '2',
            status: TaskStatus.completed,
            completedBy: 'user-1',
            completedAt: now.subtract(const Duration(days: 3)),
          ),
          TestData.createTask(
            id: '3',
            status: TaskStatus.completed,
            completedBy: 'user-2',
            completedAt: now.subtract(const Duration(days: 2)),
          ),
          // Completed before this week
          TestData.createTask(
            id: '4',
            status: TaskStatus.completed,
            completedBy: 'user-1',
            completedAt: now.subtract(const Duration(days: 10)),
          ),
          // Pending task
          TestData.createTask(
            id: '5',
            status: TaskStatus.pending,
          ),
        ];

        final counts = calculateWeeklyCompletions(tasks, now);

        expect(counts['user-1'], 2);
        expect(counts['user-2'], 1);
      });
    });
  });
}
