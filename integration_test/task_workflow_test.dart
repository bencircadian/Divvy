/// Integration tests for task workflow
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:divvy/models/task.dart';
import '../test/helpers/test_data.dart';
import '../test/mocks/mock_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task Workflow Integration Tests', () {
    late MockAuthProvider authProvider;
    late MockHouseholdProvider householdProvider;
    late MockTaskProvider taskProvider;

    setUp(() {
      authProvider = MockAuthProvider();
      householdProvider = MockHouseholdProvider();
      taskProvider = MockTaskProvider();

      authProvider.setAuthenticated();
      householdProvider.setHousehold();
    });

    testWidgets('Create task -> appears in list', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<MockTaskProvider>(
                builder: (context, provider, _) {
                  return ListView.builder(
                    itemCount: provider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = provider.tasks[index];
                      return ListTile(
                        title: Text(task.title),
                        key: Key('task-${task.id}'),
                      );
                    },
                  );
                },
              ),
              floatingActionButton: Builder(
                builder: (context) => FloatingActionButton(
                  onPressed: () async {
                    final provider = context.read<MockTaskProvider>();
                    await provider.createTask(
                      householdId: TestData.testHouseholdId,
                      title: 'New Integration Task',
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no tasks
      expect(find.byType(ListTile), findsNothing);

      // Create a task
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Task should appear
      expect(find.text('New Integration Task'), findsOneWidget);
    });

    testWidgets('Complete task -> moves to completed', (tester) async {
      final task = TestData.createTask(
        id: 'test-task-1',
        title: 'Task to Complete',
        status: TaskStatus.pending,
      );
      taskProvider.setTasks([task]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<MockTaskProvider>(
                builder: (context, provider, _) {
                  final pendingTasks = provider.pendingTasks;
                  final completedTasks = provider.completedTasks;

                  return Column(
                    children: [
                      Text('Pending: ${pendingTasks.length}'),
                      Text('Completed: ${completedTasks.length}'),
                      Expanded(
                        child: ListView.builder(
                          itemCount: provider.tasks.length,
                          itemBuilder: (context, index) {
                            final t = provider.tasks[index];
                            return ListTile(
                              leading: Checkbox(
                                value: t.isCompleted,
                                onChanged: (_) async {
                                  await provider.toggleTaskComplete(t);
                                },
                              ),
                              title: Text(t.title),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Pending: 1'), findsOneWidget);
      expect(find.text('Completed: 0'), findsOneWidget);

      // Complete the task
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Verify completed state
      expect(find.text('Pending: 0'), findsOneWidget);
      expect(find.text('Completed: 1'), findsOneWidget);
    });

    testWidgets('Delete task -> removed from list', (tester) async {
      taskProvider.setTasks([
        TestData.createTask(id: 'task-1', title: 'Task One'),
        TestData.createTask(id: 'task-2', title: 'Task Two'),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<MockTaskProvider>(
                builder: (context, provider, _) {
                  return ListView.builder(
                    itemCount: provider.tasks.length,
                    itemBuilder: (context, index) {
                      final t = provider.tasks[index];
                      return Dismissible(
                        key: Key(t.id),
                        onDismissed: (_) {
                          provider.deleteTask(t.id);
                        },
                        child: ListTile(title: Text(t.title)),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially 2 tasks
      expect(find.byType(ListTile), findsNWidgets(2));

      // Delete first task by swiping
      await tester.drag(find.text('Task One'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Only 1 task remaining
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Task Two'), findsOneWidget);
    });

    testWidgets('Edit task -> changes persist', (tester) async {
      final task = TestData.createTask(
        id: 'edit-task',
        title: 'Original Title',
      );
      taskProvider.setTasks([task]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<MockTaskProvider>(
                builder: (context, provider, _) {
                  final t = provider.tasks.first;
                  return Column(
                    children: [
                      Text('Title: ${t.title}'),
                      ElevatedButton(
                        onPressed: () {
                          // Simulate edit by replacing task
                          provider.setTasks([
                            t.copyWith(title: 'Updated Title'),
                          ]);
                        },
                        child: const Text('Edit'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Title: Original Title'), findsOneWidget);

      // Tap edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Title: Updated Title'), findsOneWidget);
    });

    testWidgets('Task list updates in real-time', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<MockTaskProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      Text('Count: ${provider.tasks.length}'),
                      Expanded(
                        child: ListView(
                          children: provider.tasks
                              .map((t) => ListTile(title: Text(t.title)))
                              .toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Count: 0'), findsOneWidget);

      // Simulate real-time insert
      taskProvider.setTasks([TestData.createTask(title: 'Real-time Task')]);
      await tester.pumpAndSettle();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Real-time Task'), findsOneWidget);
    });
  });
}
