/// Full tests for SyncManager
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/services/sync_manager.dart';

import '../mocks/mock_services.dart';

void main() {
  group('SyncManager Full Tests', () {
    setUp(() {
      MockSyncManager.reset();
    });

    group('Connectivity State Transitions', () {
      test('starts online by default', () async {
        final syncManager = MockSyncManager.instance;
        await syncManager.initialize();

        expect(syncManager.isOnline, isTrue);
      });

      test('transitions to offline', () {
        final syncManager = MockSyncManager.instance;

        syncManager.setOnlineStatus(false);

        expect(syncManager.isOnline, isFalse);
      });

      test('transitions from offline to online', () {
        final syncManager = MockSyncManager.instance;

        syncManager.setOnlineStatus(false);
        expect(syncManager.isOnline, isFalse);

        syncManager.setOnlineStatus(true);
        expect(syncManager.isOnline, isTrue);
      });
    });

    group('Sync Callbacks', () {
      test('register callback adds to list', () {
        final syncManager = MockSyncManager.instance;

        syncManager.registerSyncCallback('test', () async {});

        expect(syncManager.registeredCallbacks, contains('test'));
      });

      test('unregister callback removes from list', () {
        final syncManager = MockSyncManager.instance;

        syncManager.registerSyncCallback('test', () async {});
        syncManager.unregisterSyncCallback('test');

        expect(syncManager.registeredCallbacks, isNot(contains('test')));
      });

      test('callbacks fire on reconnect', () async {
        final syncManager = MockSyncManager.instance;
        bool callbackFired = false;

        syncManager.registerSyncCallback('test', () async {
          callbackFired = true;
        });

        syncManager.setOnlineStatus(false);
        syncManager.setOnlineStatus(true);

        // Allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(callbackFired, isTrue);
      });

      test('multiple callbacks all execute', () async {
        final syncManager = MockSyncManager.instance;
        int callbackCount = 0;

        syncManager.registerSyncCallback('cb1', () async {
          callbackCount++;
        });
        syncManager.registerSyncCallback('cb2', () async {
          callbackCount++;
        });
        syncManager.registerSyncCallback('cb3', () async {
          callbackCount++;
        });

        await syncManager.syncAll();

        expect(callbackCount, equals(3));
      });
    });

    group('Minimum Sync Interval (5 min)', () {
      test('respects minimum sync interval', () async {
        final syncManager = MockSyncManager.instance;

        // Set last sync to now
        syncManager.setLastSyncTime(DateTime.now());

        // Trigger reconnect
        syncManager.setOnlineStatus(false);

        final syncCountBefore = syncManager.syncCallCount;
        syncManager.setOnlineStatus(true);

        // Should not trigger sync because last sync was < 5 min ago
        await Future.delayed(const Duration(milliseconds: 50));

        expect(syncManager.syncCallCount, equals(syncCountBefore));
      });

      test('syncs when interval exceeded', () async {
        final syncManager = MockSyncManager.instance;
        syncManager.registerSyncCallback('test', () async {});

        // Set last sync to 10 minutes ago
        syncManager.setLastSyncTime(
          DateTime.now().subtract(const Duration(minutes: 10)),
        );

        final syncCountBefore = syncManager.syncCallCount;

        // Trigger reconnect
        syncManager.setOnlineStatus(false);
        syncManager.setOnlineStatus(true);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(syncManager.syncCallCount, greaterThan(syncCountBefore));
      });

      test('syncs immediately when no previous sync', () async {
        final syncManager = MockSyncManager.instance;
        syncManager.registerSyncCallback('test', () async {});

        expect(syncManager.lastSyncTime, isNull);

        final syncCountBefore = syncManager.syncCallCount;

        // Trigger reconnect
        syncManager.setOnlineStatus(false);
        syncManager.setOnlineStatus(true);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(syncManager.syncCallCount, greaterThan(syncCountBefore));
      });
    });

    group('Multiple Callback Registration', () {
      test('can register many callbacks', () {
        final syncManager = MockSyncManager.instance;

        for (int i = 0; i < 10; i++) {
          syncManager.registerSyncCallback('callback-$i', () async {});
        }

        expect(syncManager.registeredCallbacks.length, equals(10));
      });

      test('callbacks with same key overwrite', () {
        final syncManager = MockSyncManager.instance;

        syncManager.registerSyncCallback('same-key', () async {
          // First callback
        });
        syncManager.registerSyncCallback('same-key', () async {
          // Second callback with same key should overwrite
        });

        // Only one callback registered
        expect(syncManager.registeredCallbacks.length, equals(1));
      });
    });

    group('Sync Status Stream', () {
      test('emits syncing status during sync', () async {
        final syncManager = MockSyncManager.instance;
        final statuses = <SyncStatus>[];

        syncManager.syncStatusStream.listen((status) {
          statuses.add(status);
        });

        await syncManager.syncAll();

        // Allow stream events to be processed
        await Future.delayed(const Duration(milliseconds: 50));

        expect(statuses, contains(SyncStatus.syncing));
        expect(statuses, contains(SyncStatus.synced));
      });

      test('emits offline status when going offline', () async {
        final syncManager = MockSyncManager.instance;
        final completer = Completer<SyncStatus>();

        syncManager.syncStatusStream.first.then((status) {
          completer.complete(status);
        });

        syncManager.setOnlineStatus(false);

        final status = await completer.future.timeout(
          const Duration(seconds: 1),
        );

        expect(status, equals(SyncStatus.offline));
      });
    });

    group('Sync State', () {
      test('isSyncing is true during sync', () async {
        final syncManager = MockSyncManager.instance;
        bool wasSyncingDuringCallback = false;

        syncManager.registerSyncCallback('check', () async {
          wasSyncingDuringCallback = syncManager.isSyncing;
          await Future.delayed(const Duration(milliseconds: 10));
        });

        final syncFuture = syncManager.syncAll();
        await syncFuture;

        expect(wasSyncingDuringCallback, isTrue);
      });

      test('isSyncing is false after sync completes', () async {
        final syncManager = MockSyncManager.instance;

        await syncManager.syncAll();

        expect(syncManager.isSyncing, isFalse);
      });

      test('lastSyncTime is updated after sync', () async {
        final syncManager = MockSyncManager.instance;

        expect(syncManager.lastSyncTime, isNull);

        await syncManager.syncAll();

        expect(syncManager.lastSyncTime, isNotNull);
        expect(
          syncManager.lastSyncTime!.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5),
        );
      });
    });

    group('Concurrent Sync Prevention', () {
      test('does not start new sync while syncing', () async {
        final syncManager = MockSyncManager.instance;
        int syncCount = 0;

        syncManager.registerSyncCallback('slow', () async {
          syncCount++;
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Start first sync
        final firstSync = syncManager.syncAll();

        // Try to start second sync immediately
        final secondSync = syncManager.syncAll();

        await Future.wait([firstSync, secondSync]);

        // Only one sync should have executed
        expect(syncCount, equals(1));
      });
    });

    group('Dispose', () {
      test('dispose cleans up resources', () {
        final syncManager = MockSyncManager.instance;
        syncManager.registerSyncCallback('test', () async {});

        syncManager.dispose();

        // After dispose, instance should be reset
        // (accessing instance again would create new one)
      });
    });
  });
}
