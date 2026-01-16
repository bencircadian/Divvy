/// Mock services for testing
library;

import 'dart:async';
import 'package:divvy/models/task.dart';
import 'package:divvy/services/sync_manager.dart';

/// Mock CacheService for testing
class MockCacheService {
  static bool _isInitialized = false;
  static bool _isOnline = true;
  static List<Task> _cachedTasks = [];
  static DateTime? _lastSyncTime;
  static bool _encryptionEnabled = true;
  static bool _shouldFailSecureStorage = false;

  /// Reset mock state
  static void reset() {
    _isInitialized = false;
    _isOnline = true;
    _cachedTasks = [];
    _lastSyncTime = null;
    _encryptionEnabled = true;
    _shouldFailSecureStorage = false;
  }

  /// Configure encryption behavior
  static void setEncryptionEnabled(bool enabled) {
    _encryptionEnabled = enabled;
  }

  /// Configure secure storage failure mode
  static void setSecureStorageFailure(bool shouldFail) {
    _shouldFailSecureStorage = shouldFail;
  }

  /// Simulate initialization
  static Future<void> initialize() async {
    if (_shouldFailSecureStorage) {
      // Simulates graceful handling when secure storage fails
      _encryptionEnabled = false;
    }
    _isInitialized = true;
  }

  static bool get isInitialized => _isInitialized;
  static bool get encryptionEnabled => _encryptionEnabled;

  /// Set online/offline state
  static void setOnlineStatus(bool online) {
    _isOnline = online;
  }

  /// Check if online
  static Future<bool> isOnline() async {
    return _isOnline;
  }

  /// Stream of connectivity changes
  static Stream<bool> get onConnectivityChanged {
    return Stream.value(_isOnline);
  }

  /// Cache tasks
  static Future<void> cacheTasks(List<Task> tasks) async {
    _cachedTasks = List.from(tasks);
    _lastSyncTime = DateTime.now();
  }

  /// Get cached tasks
  static List<Task> getCachedTasks() {
    return List.from(_cachedTasks);
  }

  /// Get last sync time
  static DateTime? getLastSyncTime() {
    return _lastSyncTime;
  }

  /// Clear cache
  static Future<void> clearCache() async {
    _cachedTasks = [];
    _lastSyncTime = null;
  }

  /// Set cached tasks directly for testing
  static void setCachedTasks(List<Task> tasks) {
    _cachedTasks = List.from(tasks);
  }
}

/// Mock SyncManager for testing
class MockSyncManager {
  static MockSyncManager? _instance;
  static MockSyncManager get instance => _instance ??= MockSyncManager._();

  MockSyncManager._();

  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final Map<String, Future<void> Function()> _syncCallbacks = {};
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  int _syncCallCount = 0;

  /// Reset mock state
  static void reset() {
    _instance?._syncStatusController.close();
    _instance = null;
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncCallCount => _syncCallCount;
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Set online status
  void setOnlineStatus(bool online) {
    final wasOffline = !_isOnline;
    _isOnline = online;

    if (_isOnline && wasOffline) {
      // Simulate reconnection
      _onReconnected();
    }

    if (!_isOnline) {
      _syncStatusController.add(SyncStatus.offline);
    }
  }

  /// Initialize the mock sync manager
  Future<void> initialize() async {
    _isOnline = true;
  }

  /// Register a sync callback
  void registerSyncCallback(String key, Future<void> Function() callback) {
    _syncCallbacks[key] = callback;
  }

  /// Unregister a sync callback
  void unregisterSyncCallback(String key) {
    _syncCallbacks.remove(key);
  }

  /// Get registered callback keys
  List<String> get registeredCallbacks => _syncCallbacks.keys.toList();

  /// Manually trigger sync
  Future<void> syncAll() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncCallCount++;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      for (final callback in _syncCallbacks.values) {
        await callback();
      }
      _lastSyncTime = DateTime.now();
      _syncStatusController.add(SyncStatus.synced);
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  void _onReconnected() {
    final shouldSync = _lastSyncTime == null ||
        DateTime.now().difference(_lastSyncTime!).inMinutes > 5;

    if (shouldSync) {
      syncAll();
    } else {
      _syncStatusController.add(SyncStatus.synced);
    }
  }

  /// Simulate setting last sync time for testing minimum interval
  void setLastSyncTime(DateTime time) {
    _lastSyncTime = time;
  }

  void dispose() {
    _syncStatusController.close();
    _instance = null;
  }
}

/// Mock SecureStorage for testing
class MockSecureStorage {
  static final Map<String, String> _storage = {};
  static bool _shouldFail = false;
  static bool _isEmpty = false;

  /// Reset mock state
  static void reset() {
    _storage.clear();
    _shouldFail = false;
    _isEmpty = false;
  }

  /// Configure failure mode
  static void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  /// Configure empty state
  static void setIsEmpty(bool isEmpty) {
    _isEmpty = isEmpty;
  }

  /// Read a value
  static Future<String?> read({required String key}) async {
    if (_shouldFail) {
      throw Exception('Secure storage read failed');
    }
    if (_isEmpty) {
      return null;
    }
    return _storage[key];
  }

  /// Write a value
  static Future<void> write({required String key, required String value}) async {
    if (_shouldFail) {
      throw Exception('Secure storage write failed');
    }
    _storage[key] = value;
  }

  /// Delete a value
  static Future<void> delete({required String key}) async {
    if (_shouldFail) {
      throw Exception('Secure storage delete failed');
    }
    _storage.remove(key);
  }

  /// Delete all values
  static Future<void> deleteAll() async {
    if (_shouldFail) {
      throw Exception('Secure storage deleteAll failed');
    }
    _storage.clear();
  }

  /// Check if key exists
  static Future<bool> containsKey({required String key}) async {
    if (_shouldFail) {
      throw Exception('Secure storage containsKey failed');
    }
    return _storage.containsKey(key);
  }

  /// Get all stored keys (for verification in tests)
  static Set<String> get storedKeys => _storage.keys.toSet();
}

/// Mock Connectivity for testing
class MockConnectivity {
  static bool _isConnected = true;
  static final _connectivityController = StreamController<bool>.broadcast();

  /// Reset mock state
  static void reset() {
    _isConnected = true;
  }

  /// Set connectivity state
  static void setConnected(bool connected) {
    _isConnected = connected;
    _connectivityController.add(connected);
  }

  /// Check connectivity
  static Future<bool> checkConnectivity() async {
    return _isConnected;
  }

  /// Connectivity change stream
  static Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Dispose
  static void dispose() {
    _connectivityController.close();
  }
}
