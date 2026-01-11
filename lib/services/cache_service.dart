import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class CacheService {
  static const String _tasksBoxName = 'tasks_cache_encrypted';
  static const String _lastSyncKey = 'last_sync';
  static const String _encryptionKeyName = 'hive_encryption_key';

  static Box? _tasksBox;
  static bool _isInitialized = false;
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Get or generate encryption key
    final encryptionCipher = await _getEncryptionCipher();

    // Open encrypted box
    _tasksBox = await Hive.openBox(
      _tasksBoxName,
      encryptionCipher: encryptionCipher,
    );
    _isInitialized = true;
  }

  /// Get or generate the encryption cipher for Hive
  static Future<HiveAesCipher?> _getEncryptionCipher() async {
    // On web, secure storage is not persistent, so skip encryption
    // (web data is already sandboxed per origin)
    if (kIsWeb) {
      return null;
    }

    try {
      String? base64Key = await _secureStorage.read(key: _encryptionKeyName);

      if (base64Key == null) {
        // Generate a new 32-byte key
        final key = Hive.generateSecureKey();
        base64Key = base64Encode(key);
        await _secureStorage.write(key: _encryptionKeyName, value: base64Key);
      }

      final keyBytes = base64Decode(base64Key);
      return HiveAesCipher(Uint8List.fromList(keyBytes));
    } catch (e) {
      // If secure storage fails, log and continue without encryption
      debugPrint('Failed to initialize encrypted cache: $e');
      return null;
    }
  }

  /// Check if device is online
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  static Stream<bool> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }

  /// Cache tasks for offline viewing
  static Future<void> cacheTasks(List<Task> tasks) async {
    if (_tasksBox == null) return;

    final tasksJson = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await _tasksBox!.put('tasks', tasksJson);
    await _tasksBox!.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get cached tasks
  static List<Task> getCachedTasks() {
    if (_tasksBox == null) return [];

    final tasksJson = _tasksBox!.get('tasks') as List<dynamic>?;
    if (tasksJson == null) return [];

    return tasksJson
        .map((json) => Task.fromJson(jsonDecode(json as String)))
        .toList();
  }

  /// Get last sync time
  static DateTime? getLastSyncTime() {
    if (_tasksBox == null) return null;

    final lastSync = _tasksBox!.get(_lastSyncKey) as String?;
    if (lastSync == null) return null;

    return DateTime.tryParse(lastSync);
  }

  /// Clear cache
  static Future<void> clearCache() async {
    if (_tasksBox == null) return;
    await _tasksBox!.clear();
  }
}
