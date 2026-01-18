/// Performance tests for widget rendering
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';

import '../helpers/test_data.dart';

void main() {
  group('Widget Performance Tests', () {
    testWidgets('task list renders 50 items efficiently', (tester) async {
      final tasks = List.generate(
        50,
        (i) => TestData.createTask(
          id: 'task-$i',
          title: 'Task $i',
          status: i % 2 == 0 ? TaskStatus.pending : TaskStatus.completed,
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  leading: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                  ),
                  title: Text(task.title),
                  subtitle: task.description != null
                      ? Text(task.description!)
                      : null,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // ListView with 50 items should render efficiently
      // Allow generous time for CI environments where performance varies significantly
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 2000)),
        reason: 'Task list should render within 2000ms',
      );
    });

    testWidgets('scrolling through list is smooth', (tester) async {
      final tasks = List.generate(
        100,
        (i) => TestData.createTask(
          id: 'task-$i',
          title: 'Task $i for scrolling test',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.title),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down multiple times
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 5; i++) {
        await tester.fling(
          find.byType(ListView),
          const Offset(0, -300),
          1000,
        );
        await tester.pumpAndSettle();
      }

      stopwatch.stop();

      // Total scroll operations should complete in reasonable time
      // Allow generous timeout for CI environments under load
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 5)),
        reason: 'Scrolling should complete within 5 seconds',
      );
    });

    testWidgets('checkbox toggle is responsive', (tester) async {
      bool isChecked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    setState(() {
                      isChecked = value ?? false;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();

      // Toggle checkbox 10 times
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
      }

      stopwatch.stop();

      // Rapid toggles should complete quickly
      // Allow extra time for slower CI environments
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 1000)),
        reason: 'Checkbox toggles should be responsive',
      );
    });

    testWidgets('task card with image placeholder loads quickly', (tester) async {
      final task = TestData.createTask(
        title: 'Task with cover image',
        coverImageUrl: 'https://example.com/image.jpg',
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder for image
                  Container(
                    height: 150,
                    color: Colors.grey[300],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(task.description ?? 'No description'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Allow generous time for CI environments
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 500)),
        reason: 'Task card should load quickly',
      );
    });

    testWidgets('task list with mixed content renders correctly', (tester) async {
      final tasks = <Task>[];

      // Add various task types
      for (int i = 0; i < 20; i++) {
        tasks.add(TestData.createTask(
          id: 'task-$i',
          title: 'Task $i with potentially long title that might wrap',
          description: i % 3 == 0 ? 'This task has a description' : null,
          priority: TaskPriority.values[i % 3],
          dueDate: i % 2 == 0 ? DateTime.now().add(Duration(days: i)) : null,
          isRecurring: i % 4 == 0,
        ));
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getPriorityColor(task.priority),
                      child: Icon(
                        task.isCompleted ? Icons.check : Icons.task,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description != null)
                          Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (task.dueDate != null)
                          Text(
                            'Due: ${task.dueDate!.toString().split(' ')[0]}',
                            style: TextStyle(
                              color: task.dueDate!.isBefore(DateTime.now())
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: task.isRecurring
                        ? const Icon(Icons.repeat)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Allow generous time for CI environments
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 2000)),
        reason: 'Mixed content list should render quickly',
      );

      // ListView.builder uses lazy rendering, so only visible cards are in tree
      // Verify at least some cards are rendered
      expect(find.byType(Card), findsAtLeast(1));
    });

    testWidgets('navigation is responsive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: Center(
              child: Text('Page 1'),
            ),
          ),
          routes: {
            '/page2': (context) => const Scaffold(
              body: Center(
                child: Text('Page 2'),
              ),
            ),
          },
        ),
      );

      final context = tester.element(find.text('Page 1'));
      final stopwatch = Stopwatch()..start();

      Navigator.of(context).pushNamed('/page2');
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Allow extra time for CI environments
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(milliseconds: 1000)),
        reason: 'Navigation should be responsive',
      );

      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('rebuild count stays low with optimized widgets', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              buildCount++;
              return Scaffold(
                body: const Center(child: Text('Test')),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() {}),
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      );

      expect(buildCount, equals(1));

      // Trigger rebuild
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(buildCount, equals(2));

      // Multiple rapid rebuilds
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
      }

      expect(buildCount, equals(7)); // Initial + 1 + 5
    });
  });
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
