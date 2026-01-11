import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/services/sync_manager.dart';

void main() {
  group('SyncStatus', () {
    test('has all expected values', () {
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.offline));
      expect(SyncStatus.values, contains(SyncStatus.error));
    });

    test('has correct number of values', () {
      expect(SyncStatus.values.length, 5);
    });
  });

  group('SyncManager', () {
    test('instance returns singleton', () {
      final instance1 = SyncManager.instance;
      final instance2 = SyncManager.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('initial state is correct', () {
      final manager = SyncManager.instance;
      expect(manager.isOnline, isTrue); // Default assumption
      expect(manager.isSyncing, isFalse);
      expect(manager.lastSyncTime, isNull);
    });

    test('can register and unregister callbacks', () {
      final manager = SyncManager.instance;
      var callbackCalled = false;

      manager.registerSyncCallback('test', () async {
        callbackCalled = true;
      });

      // Unregister before syncing to avoid side effects
      manager.unregisterSyncCallback('test');
      expect(callbackCalled, isFalse);
    });
  });
}
