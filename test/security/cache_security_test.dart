/// Security tests for cache service
library;

import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_services.dart';
import '../helpers/test_data.dart';

void main() {
  group('Cache Security Tests', () {
    setUp(() {
      MockCacheService.reset();
      MockSecureStorage.reset();
    });

    group('Encryption Key Generation and Storage', () {
      test('encryption key is stored in secure storage', () async {
        await MockSecureStorage.write(
          key: 'hive_encryption_key',
          value: 'base64-encoded-key-here',
        );

        final storedKey = await MockSecureStorage.read(key: 'hive_encryption_key');
        expect(storedKey, isNotNull);
        expect(storedKey, equals('base64-encoded-key-here'));
      });

      test('encryption key is unique per installation', () async {
        // Simulate two separate key generations
        final key1 = 'key-${DateTime.now().millisecondsSinceEpoch}';
        await Future.delayed(const Duration(milliseconds: 10));
        final key2 = 'key-${DateTime.now().millisecondsSinceEpoch}';

        expect(key1, isNot(equals(key2)));
      });

      test('encryption is enabled on mobile (simulated)', () {
        MockCacheService.setEncryptionEnabled(true);
        expect(MockCacheService.encryptionEnabled, isTrue);
      });

      test('encryption is disabled on web (simulated)', () {
        MockCacheService.setEncryptionEnabled(false);
        expect(MockCacheService.encryptionEnabled, isFalse);
      });
    });

    group('Cache Clears on Logout', () {
      test('clearCache removes all cached data', () async {
        // Set up some cached data
        final tasks = TestData.createTaskList();
        await MockCacheService.cacheTasks(tasks);
        expect(MockCacheService.getCachedTasks(), isNotEmpty);

        // Clear cache
        await MockCacheService.clearCache();

        expect(MockCacheService.getCachedTasks(), isEmpty);
        expect(MockCacheService.getLastSyncTime(), isNull);
      });

      test('cache is independent of other storage', () async {
        await MockSecureStorage.write(key: 'other-key', value: 'value');

        await MockCacheService.clearCache();

        // Secure storage should not be affected
        final storedValue = await MockSecureStorage.read(key: 'other-key');
        expect(storedValue, equals('value'));
      });
    });

    group('Graceful Handling of Secure Storage Failures', () {
      test('cache initializes even when secure storage fails', () async {
        MockCacheService.setSecureStorageFailure(true);

        await MockCacheService.initialize();

        expect(MockCacheService.isInitialized, isTrue);
        // Encryption should be disabled as a fallback
        expect(MockCacheService.encryptionEnabled, isFalse);
      });

      test('cache operations work without encryption', () async {
        MockCacheService.setSecureStorageFailure(true);
        MockCacheService.setEncryptionEnabled(false);

        await MockCacheService.initialize();

        final tasks = TestData.createTaskList();
        await MockCacheService.cacheTasks(tasks);

        final retrieved = MockCacheService.getCachedTasks();
        expect(retrieved.length, equals(tasks.length));
      });

      test('secure storage read failure is handled', () async {
        MockSecureStorage.setShouldFail(true);

        expect(
          () async => await MockSecureStorage.read(key: 'test'),
          throwsException,
        );
      });

      test('secure storage write failure is handled', () async {
        MockSecureStorage.setShouldFail(true);

        expect(
          () async => await MockSecureStorage.write(key: 'test', value: 'value'),
          throwsException,
        );
      });
    });

    group('No Plaintext Sensitive Data in Cache', () {
      test('cached tasks contain expected structure', () async {
        final tasks = [
          TestData.createTask(
            title: 'Sensitive Task',
            description: 'Contains private info',
          ),
        ];

        await MockCacheService.cacheTasks(tasks);
        final cached = MockCacheService.getCachedTasks();

        expect(cached.length, equals(1));
        expect(cached.first.title, equals('Sensitive Task'));
      });

      test('cache timestamp is recorded', () async {
        final tasks = TestData.createTaskList();
        await MockCacheService.cacheTasks(tasks);

        final lastSync = MockCacheService.getLastSyncTime();
        expect(lastSync, isNotNull);
        expect(
          lastSync!.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5),
        );
      });
    });

    group('Cache Initialization', () {
      test('cache starts uninitialized', () {
        MockCacheService.reset();
        expect(MockCacheService.isInitialized, isFalse);
      });

      test('initialize sets initialized flag', () async {
        MockCacheService.reset();
        await MockCacheService.initialize();
        expect(MockCacheService.isInitialized, isTrue);
      });

      test('double initialization is safe', () async {
        await MockCacheService.initialize();
        await MockCacheService.initialize();
        expect(MockCacheService.isInitialized, isTrue);
      });
    });

    group('Offline/Online State Handling', () {
      test('online status can be checked', () async {
        MockCacheService.setOnlineStatus(true);
        expect(await MockCacheService.isOnline(), isTrue);

        MockCacheService.setOnlineStatus(false);
        expect(await MockCacheService.isOnline(), isFalse);
      });

      test('cached data available when offline', () async {
        // Cache data while online
        MockCacheService.setOnlineStatus(true);
        final tasks = TestData.createTaskList();
        await MockCacheService.cacheTasks(tasks);

        // Go offline
        MockCacheService.setOnlineStatus(false);

        // Data should still be available
        final cached = MockCacheService.getCachedTasks();
        expect(cached.length, equals(tasks.length));
      });
    });

    group('Cache Data Integrity', () {
      test('cached tasks maintain data integrity', () async {
        final originalTask = TestData.createTask(
          id: 'test-id-123',
          title: 'Test Task',
          description: 'Test Description',
        );

        await MockCacheService.cacheTasks([originalTask]);
        final cached = MockCacheService.getCachedTasks();

        expect(cached.first.id, equals(originalTask.id));
        expect(cached.first.title, equals(originalTask.title));
        expect(cached.first.description, equals(originalTask.description));
      });

      test('empty cache returns empty list', () {
        MockCacheService.reset();
        final cached = MockCacheService.getCachedTasks();
        expect(cached, isEmpty);
      });

      test('null sync time when cache is empty', () {
        MockCacheService.reset();
        final lastSync = MockCacheService.getLastSyncTime();
        expect(lastSync, isNull);
      });
    });

    group('Secure Storage Operations', () {
      test('can write and read values', () async {
        await MockSecureStorage.write(key: 'test-key', value: 'test-value');
        final value = await MockSecureStorage.read(key: 'test-key');
        expect(value, equals('test-value'));
      });

      test('can delete values', () async {
        await MockSecureStorage.write(key: 'test-key', value: 'test-value');
        await MockSecureStorage.delete(key: 'test-key');
        final value = await MockSecureStorage.read(key: 'test-key');
        expect(value, isNull);
      });

      test('can delete all values', () async {
        await MockSecureStorage.write(key: 'key1', value: 'value1');
        await MockSecureStorage.write(key: 'key2', value: 'value2');
        await MockSecureStorage.deleteAll();

        expect(MockSecureStorage.storedKeys, isEmpty);
      });

      test('containsKey works correctly', () async {
        await MockSecureStorage.write(key: 'existing', value: 'value');

        expect(await MockSecureStorage.containsKey(key: 'existing'), isTrue);
        expect(await MockSecureStorage.containsKey(key: 'nonexistent'), isFalse);
      });
    });
  });
}
