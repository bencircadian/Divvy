import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class CacheService {
  static const String _tasksBoxName = 'tasks_cache';
  static const String _lastSyncKey = 'last_sync';

  static Box? _tasksBox;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    _tasksBox = await Hive.openBox(_tasksBoxName);
    _isInitialized = true;
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
