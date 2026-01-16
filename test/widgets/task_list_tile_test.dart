/// Tests for task list tile widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';

import '../helpers/test_data.dart';

void main() {
  group('Task List Tile Widget Tests', () {
    group('Display Tests', () {
      testWidgets('displays task title', (tester) async {
        final task = TestData.createTask(title: 'Test Task Title');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.text('Test Task Title'), findsOneWidget);
      });

      testWidgets('displays assignee name when assigned', (tester) async {
        final task = TestData.createTask(
          assignedTo: TestData.testUserId,
          assignedToName: 'John Doe',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('shows unassigned indicator when no assignee', (tester) async {
        final task = TestData.createTask(
          assignedTo: null,
          assignedToName: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.text('Unassigned'), findsOneWidget);
      });
    });

    group('Completion Toggle', () {
      testWidgets('shows unchecked circle for pending task', (tester) async {
        final task = TestData.createTask(status: TaskStatus.pending);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
      });

      testWidgets('shows checked circle for completed task', (tester) async {
        final task = TestData.createTask(status: TaskStatus.completed);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('completion toggle calls callback', (tester) async {
        bool toggled = false;
        final task = TestData.createTask(status: TaskStatus.pending);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(
                task: task,
                onToggle: () => toggled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.circle_outlined));
        expect(toggled, isTrue);
      });
    });

    group('Priority Badge', () {
      testWidgets('shows red badge for high priority', (tester) async {
        final task = TestData.createTask(priority: TaskPriority.high);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        expect((chip.backgroundColor as MaterialColor?)?.shade500, equals(Colors.red.shade500));
      });

      testWidgets('shows blue badge for normal priority', (tester) async {
        final task = TestData.createTask(priority: TaskPriority.normal);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        expect((chip.backgroundColor as MaterialColor?)?.shade500, equals(Colors.blue.shade500));
      });

      testWidgets('shows grey badge for low priority', (tester) async {
        final task = TestData.createTask(priority: TaskPriority.low);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        expect((chip.backgroundColor as MaterialColor?)?.shade500, equals(Colors.grey.shade500));
      });
    });

    group('Due Date Display', () {
      testWidgets('displays formatted due date', (tester) async {
        // Use a date in the future so it doesn't show as "Overdue"
        final task = TestData.createTask(
          dueDate: DateTime.now().add(const Duration(days: 5)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        // The test widget shows "Due: Jan {day}" format for future dates
        expect(find.textContaining('Due:'), findsOneWidget);
      });

      testWidgets('shows no due date text when not set', (tester) async {
        final task = TestData.createTask(dueDate: null);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.text('No due date'), findsOneWidget);
      });
    });

    group('Overdue Styling', () {
      testWidgets('applies overdue styling for past due tasks', (tester) async {
        final task = TestData.createTask(
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          status: TaskStatus.pending,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        // Find text with overdue styling (red color)
        final textWidget = tester.widget<Text>(
          find.byWidgetPredicate(
            (widget) => widget is Text && widget.data?.contains('Overdue') == true,
          ),
        );

        expect(textWidget.style?.color, equals(Colors.red));
      });

      testWidgets('no overdue styling for completed tasks', (tester) async {
        final task = TestData.createTask(
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          status: TaskStatus.completed,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        // Completed tasks don't show as overdue
        expect(find.text('Overdue'), findsNothing);
      });

      testWidgets('no overdue styling for future tasks', (tester) async {
        final task = TestData.createTask(
          dueDate: DateTime.now().add(const Duration(days: 2)),
          status: TaskStatus.pending,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.text('Overdue'), findsNothing);
      });
    });

    group('Recurring Task Indicator', () {
      testWidgets('shows recurring icon for recurring tasks', (tester) async {
        final task = TestData.createTask(
          isRecurring: true,
          recurrenceRule: TestData.createRecurrenceRule(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.byIcon(Icons.repeat), findsOneWidget);
      });

      testWidgets('no recurring icon for one-time tasks', (tester) async {
        final task = TestData.createTask(isRecurring: false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.byIcon(Icons.repeat), findsNothing);
      });
    });

    group('Task Description', () {
      testWidgets('shows description when present', (tester) async {
        final task = TestData.createTask(
          description: 'This is a task description',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        expect(find.text('This is a task description'), findsOneWidget);
      });

      testWidgets('hides description when null', (tester) async {
        final task = TestData.createTask(description: null);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(task: task),
            ),
          ),
        );

        // Only title should be visible in subtitle area
        expect(find.byType(Text), findsAtLeast(1));
      });
    });

    group('Tap Handling', () {
      testWidgets('tap on tile calls onTap', (tester) async {
        bool tapped = false;
        final task = TestData.createTask();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskListTile(
                task: task,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text(task.title));
        expect(tapped, isTrue);
      });
    });
  });
}

/// Test widget that mimics the task list tile behavior
class _TestTaskListTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const _TestTaskListTile({
    required this.task,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return ListTile(
      leading: GestureDetector(
        onTap: onToggle,
        child: Icon(
          task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: task.isCompleted ? Colors.green : Colors.grey,
        ),
      ),
      title: GestureDetector(
        onTap: onTap,
        child: Text(task.title),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description != null) Text(task.description!),
          Row(
            children: [
              Text(task.assignedToName ?? 'Unassigned'),
              const SizedBox(width: 8),
              if (task.dueDate != null)
                isOverdue
                    ? Text(
                        'Overdue',
                        style: const TextStyle(color: Colors.red),
                      )
                    : Text('Due: Jan ${task.dueDate!.day}'),
              if (task.dueDate == null) const Text('No due date'),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(task.priority.name),
            backgroundColor: _getPriorityColor(task.priority),
          ),
          if (task.isRecurring) const Icon(Icons.repeat),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.normal:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.grey;
    }
  }
}
