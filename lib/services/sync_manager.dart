import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';

/// Centralized sync manager for handling offline/online state transitions.
///
/// Listens to connectivity changes and triggers re-sync when coming online.
class SyncManager {
  static SyncManager? _instance;
  static SyncManager get instance => _instance ??= SyncManager._();

  SyncManager._();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final _syncCallbacks = <String, Future<void> Function()>{};
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;

  /// Current online status.
  bool get isOnline => _isOnline;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Last successful sync time.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Sync status stream for UI updates.
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Initialize the sync manager and start listening to connectivity.
  Future<void> initialize() async {
    _isOnline = await CacheService.isOnline();

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivityChange);

    if (kDebugMode) {
      debugPrint('SyncManager initialized. Online: $_isOnline');
    }
  }

  /// Register a sync callback to be called when connectivity is restored.
  ///
  /// Example:
  /// ```dart
  /// SyncManager.instance.registerSyncCallback('tasks', () async {
  ///   await taskProvider.loadTasks(householdId);
  /// });
  /// ```
  void registerSyncCallback(String key, Future<void> Function() callback) {
    _syncCallbacks[key] = callback;
  }

  /// Unregister a sync callback.
  void unregisterSyncCallback(String key) {
    _syncCallbacks.remove(key);
  }

  /// Manually trigger a sync for all registered callbacks.
  Future<void> syncAll() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      for (final callback in _syncCallbacks.values) {
        await callback();
      }
      _lastSyncTime = DateTime.now();
      _syncStatusController.add(SyncStatus.synced);
    } catch (e) {
      debugPrint('Sync error: $e');
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (kDebugMode) {
      debugPrint('Connectivity changed. Online: $_isOnline, Was offline: $wasOffline');
    }

    // Coming back online after being offline
    if (_isOnline && wasOffline) {
      _onReconnected();
    }

    if (!_isOnline) {
      _syncStatusController.add(SyncStatus.offline);
    }
  }

  void _onReconnected() {
    if (kDebugMode) {
      debugPrint('Reconnected! Triggering sync...');
    }

    // Check if we need to sync based on last sync time
    final shouldSync = _lastSyncTime == null ||
        DateTime.now().difference(_lastSyncTime!).inMinutes > 5;

    if (shouldSync) {
      syncAll();
    } else {
      _syncStatusController.add(SyncStatus.synced);
    }
  }

  /// Dispose the sync manager.
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _instance = null;
  }
}

/// Sync status for UI display.
enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}
