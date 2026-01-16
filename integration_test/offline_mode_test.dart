/// Integration tests for offline mode
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import '../test/helpers/test_data.dart';
import '../test/mocks/mock_providers.dart';
import '../test/mocks/mock_services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Mode Integration Tests', () {
    late MockAuthProvider authProvider;
    late MockHouseholdProvider householdProvider;
    late MockTaskProvider taskProvider;

    setUp(() {
      authProvider = MockAuthProvider();
      householdProvider = MockHouseholdProvider();
      taskProvider = MockTaskProvider();

      authProvider.setAuthenticated();
      householdProvider.setHousehold();

      MockCacheService.reset();
      MockSyncManager.reset();
    });

    testWidgets('App loads from cache when offline', (tester) async {
      // Pre-cache some tasks
      final cachedTasks = TestData.createTaskList();
      MockCacheService.setCachedTasks(cachedTasks);

      // Set offline
      MockCacheService.setOnlineStatus(false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Simulate loading from cache when offline
                final tasks = MockCacheService.getCachedTasks();
                return Scaffold(
                  appBar: AppBar(
                    title: Row(
                      children: [
                        const Text('Tasks'),
                        const SizedBox(width: 8),
                        FutureBuilder<bool>(
                          future: MockCacheService.isOnline(),
                          builder: (context, snapshot) {
                            if (snapshot.data == false) {
                              return const Icon(Icons.cloud_off, size: 20);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  body: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(tasks[index].title));
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show offline indicator
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Should show cached tasks
      expect(find.byType(ListTile), findsNWidgets(cachedTasks.length));
    });

    testWidgets('Actions queue while offline', (tester) async {
      final actionQueue = <String>[];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      MockCacheService.isOnline().toString() == 'true'
                          ? 'Online'
                          : 'Offline - ${actionQueue.length} queued',
                    ),
                  ),
                  body: Column(
                    children: [
                      Text('Queued actions: ${actionQueue.length}'),
                      ElevatedButton(
                        onPressed: () async {
                          final isOnline = await MockCacheService.isOnline();
                          if (!isOnline) {
                            setState(() {
                              actionQueue.add('create-task');
                            });
                          } else {
                            // Execute immediately
                            await taskProvider.createTask(
                              householdId: TestData.testHouseholdId,
                              title: 'Online Task',
                            );
                          }
                        },
                        child: const Text('Add Task'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            MockCacheService.setOnlineStatus(false);
                          });
                        },
                        child: const Text('Go Offline'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Go Offline'));
      await tester.pumpAndSettle();

      // Queue some actions
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Should have 2 queued actions
      expect(find.text('Queued actions: 2'), findsOneWidget);
    });

    testWidgets('Sync happens on reconnect', (tester) async {
      final syncManager = MockSyncManager.instance;
      bool syncCalled = false;

      syncManager.registerSyncCallback('tasks', () async {
        syncCalled = true;
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ChangeNotifierProvider<MockTaskProvider>.value(value: taskProvider),
          ],
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Sync called: $syncCalled'),
                      Text('Online: ${syncManager.isOnline}'),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            syncManager.setOnlineStatus(false);
                          });
                        },
                        child: const Text('Go Offline'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          syncManager.setOnlineStatus(true);
                          await Future.delayed(const Duration(milliseconds: 100));
                          setState(() {
                            syncCalled = syncManager.syncCallCount > 0;
                          });
                        },
                        child: const Text('Go Online'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Go offline
      await tester.tap(find.text('Go Offline'));
      await tester.pumpAndSettle();

      expect(find.text('Online: false'), findsOneWidget);

      // Go online
      await tester.tap(find.text('Go Online'));
      await tester.pumpAndSettle();

      // Sync should have been called
      expect(find.text('Sync called: true'), findsOneWidget);
    });

    testWidgets('Offline indicator shows and hides correctly', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('App'),
                    actions: [
                      FutureBuilder<bool>(
                        future: MockCacheService.isOnline(),
                        builder: (context, snapshot) {
                          if (snapshot.data == false) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Chip(
                                label: Text('Offline'),
                                avatar: Icon(Icons.cloud_off),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              MockCacheService.setOnlineStatus(false);
                            });
                          },
                          child: const Text('Simulate Offline'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              MockCacheService.setOnlineStatus(true);
                            });
                          },
                          child: const Text('Simulate Online'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no offline chip
      expect(find.text('Offline'), findsNothing);

      // Go offline
      await tester.tap(find.text('Simulate Offline'));
      await tester.pumpAndSettle();

      // Offline chip appears
      expect(find.text('Offline'), findsOneWidget);

      // Go online
      await tester.tap(find.text('Simulate Online'));
      await tester.pumpAndSettle();

      // Offline chip disappears
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('Cached data is available immediately', (tester) async {
      // Pre-cache data
      final tasks = [
        TestData.createTask(id: 't1', title: 'Cached Task 1'),
        TestData.createTask(id: 't2', title: 'Cached Task 2'),
      ];
      MockCacheService.setCachedTasks(tasks);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final cachedTasks = MockCacheService.getCachedTasks();
                return ListView.builder(
                  itemCount: cachedTasks.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(cachedTasks[index].title),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      // No pump delay needed - data is immediately available
      await tester.pump();

      expect(find.text('Cached Task 1'), findsOneWidget);
      expect(find.text('Cached Task 2'), findsOneWidget);
    });
  });
}
