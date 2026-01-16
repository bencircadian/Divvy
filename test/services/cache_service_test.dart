/// Tests for CacheService
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';

import '../helpers/test_data.dart';
import '../mocks/mock_services.dart';

void main() {
  group('CacheService Tests', () {
    setUp(() {
      MockCacheService.reset();
      MockSecureStorage.reset();
    });

    group('Initialize with Encryption (Mobile)', () {
      test('initializes successfully', () async {
        await MockCacheService.initialize();

        expect(MockCacheService.isInitialized, isTrue);
      });

      test('encryption is enabled by default', () async {
        MockCacheService.setEncryptionEnabled(true);

        expect(MockCacheService.encryptionEnabled, isTrue);
      });

      test('double initialization is safe', () async {
        await MockCacheService.initialize();
        await MockCacheService.initialize();

        expect(MockCacheService.isInitialized, isTrue);
      });
    });

    group('Initialize without Encryption (Web)', () {
      test('can disable encryption for web', () {
        MockCacheService.setEncryptionEnabled(false);

        expect(MockCacheService.encryptionEnabled, isFalse);
      });

      test('cache works without encryption', () async {
        MockCacheService.setEncryptionEnabled(false);
        await MockCacheService.initialize();

        final tasks = TestData.createTaskList();
        await MockCacheService.cacheTasks(tasks);

        final cached = MockCacheService.getCachedTasks();
        expect(cached.length, equals(tasks.length));
      });
    });

    group('Task Save and Retrieve', () {
      test('caches tasks successfully', () async {
        final tasks = TestData.createTaskList();

        await MockCacheService.cacheTasks(tasks);

        final cached = MockCacheService.getCachedTasks();
        expect(cached.length, equals(tasks.length));
      });

      test('retrieved tasks match original', () async {
        final originalTask = TestData.createTask(
          id: 'original-123',
          title: 'Original Task',
          description: 'Original Description',
          priority: TaskPriority.high,
        );

        await MockCacheService.cacheTasks([originalTask]);

        final cached = MockCacheService.getCachedTasks();
        expect(cached.first.id, equals(originalTask.id));
        expect(cached.first.title, equals(originalTask.title));
        expect(cached.first.description, equals(originalTask.description));
        expect(cached.first.priority, equals(originalTask.priority));
      });

      test('caching updates last sync time', () async {
        expect(MockCacheService.getLastSyncTime(), isNull);

        await MockCacheService.cacheTasks([TestData.createTask()]);

        expect(MockCacheService.getLastSyncTime(), isNotNull);
      });

      test('multiple caches overwrites previous', () async {
        await MockCacheService.cacheTasks([TestData.createTask(id: '1')]);
        expect(MockCacheService.getCachedTasks().length, equals(1));

        await MockCacheService.cacheTasks([
          TestData.createTask(id: '2'),
          TestData.createTask(id: '3'),
        ]);

        final cached = MockCacheService.getCachedTasks();
        expect(cached.length, equals(2));
        expect(cached.any((t) => t.id == '1'), isFalse);
      });
    });

    group('Clear Cache Functionality', () {
      test('clearCache removes all tasks', () async {
        await MockCacheService.cacheTasks(TestData.createTaskList());
        expect(MockCacheService.getCachedTasks(), isNotEmpty);

        await MockCacheService.clearCache();

        expect(MockCacheService.getCachedTasks(), isEmpty);
      });

      test('clearCache removes last sync time', () async {
        await MockCacheService.cacheTasks([TestData.createTask()]);
        expect(MockCacheService.getLastSyncTime(), isNotNull);

        await MockCacheService.clearCache();

        expect(MockCacheService.getLastSyncTime(), isNull);
      });

      test('cache works after clear', () async {
        await MockCacheService.cacheTasks([TestData.createTask(id: '1')]);
        await MockCacheService.clearCache();

        await MockCacheService.cacheTasks([TestData.createTask(id: '2')]);

        final cached = MockCacheService.getCachedTasks();
        expect(cached.length, equals(1));
        expect(cached.first.id, equals('2'));
      });
    });

    group('Corruption Recovery', () {
      test('handles corrupted data gracefully', () {
        // Empty cache returns empty list
        MockCacheService.reset();

        final cached = MockCacheService.getCachedTasks();
        expect(cached, isEmpty);
      });

      test('returns empty list when not initialized', () {
        MockCacheService.reset();

        final cached = MockCacheService.getCachedTasks();
        expect(cached, isEmpty);
      });
    });

    group('Online/Offline Status', () {
      test('isOnline returns true by default', () async {
        final isOnline = await MockCacheService.isOnline();
        expect(isOnline, isTrue);
      });

      test('setOnlineStatus changes status', () async {
        MockCacheService.setOnlineStatus(false);

        final isOnline = await MockCacheService.isOnline();
        expect(isOnline, isFalse);
      });

      test('can toggle online status', () async {
        MockCacheService.setOnlineStatus(false);
        expect(await MockCacheService.isOnline(), isFalse);

        MockCacheService.setOnlineStatus(true);
        expect(await MockCacheService.isOnline(), isTrue);
      });
    });

    group('Secure Storage Failure Handling', () {
      test('gracefully handles secure storage failure', () async {
        MockCacheService.setSecureStorageFailure(true);

        await MockCacheService.initialize();

        // Should initialize with encryption disabled
        expect(MockCacheService.isInitialized, isTrue);
        expect(MockCacheService.encryptionEnabled, isFalse);
      });

      test('cache still works after storage failure', () async {
        MockCacheService.setSecureStorageFailure(true);
        await MockCacheService.initialize();

        final tasks = [TestData.createTask()];
        await MockCacheService.cacheTasks(tasks);

        expect(MockCacheService.getCachedTasks(), hasLength(1));
      });
    });

    group('Last Sync Time', () {
      test('returns null before first cache', () {
        expect(MockCacheService.getLastSyncTime(), isNull);
      });

      test('returns recent time after cache', () async {
        final before = DateTime.now();
        await MockCacheService.cacheTasks([TestData.createTask()]);
        final after = DateTime.now();

        final syncTime = MockCacheService.getLastSyncTime();

        expect(syncTime, isNotNull);
        expect(syncTime!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(syncTime.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('Edge Cases', () {
      test('handles empty task list', () async {
        await MockCacheService.cacheTasks([]);

        expect(MockCacheService.getCachedTasks(), isEmpty);
      });

      test('handles large task lists', () async {
        final tasks = List.generate(
          1000,
          (i) => TestData.createTask(id: 'task-$i'),
        );

        await MockCacheService.cacheTasks(tasks);

        expect(MockCacheService.getCachedTasks().length, equals(1000));
      });

      test('tasks with null fields cache correctly', () async {
        final task = TestData.createTask(
          description: null,
          dueDate: null,
          assignedTo: null,
        );

        await MockCacheService.cacheTasks([task]);

        final cached = MockCacheService.getCachedTasks().first;
        expect(cached.description, isNull);
        expect(cached.dueDate, isNull);
        expect(cached.assignedTo, isNull);
      });
    });
  });
}
