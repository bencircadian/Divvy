import 'package:flutter/foundation.dart';

import '../models/appreciation.dart';
import '../services/appreciation_service.dart';
import '../services/supabase_service.dart';

/// Provider for managing appreciation state.
class AppreciationProvider extends ChangeNotifier {
  final AppreciationService _service;

  /// Cache of appreciations sent by current user: taskId -> Appreciation.
  final Map<String, Appreciation> _sentAppreciations = {};

  /// Cache of appreciation counts per task: taskId -> count.
  final Map<String, int> _taskAppreciationCounts = {};

  /// Whether an appreciation action is in progress.
  bool _isLoading = false;

  /// Current user's total appreciation count received.
  int _totalAppreciationsReceived = 0;

  AppreciationProvider() : _service = AppreciationService(SupabaseService.client);

  bool get isLoading => _isLoading;
  int get totalAppreciationsReceived => _totalAppreciationsReceived;

  /// Check if current user has sent appreciation for a task.
  bool hasSentAppreciation(String taskId) {
    return _sentAppreciations.containsKey(taskId);
  }

  /// Get the appreciation sent by current user for a task.
  Appreciation? getSentAppreciation(String taskId) {
    return _sentAppreciations[taskId];
  }

  /// Get appreciation count for a task.
  int getAppreciationCount(String taskId) {
    return _taskAppreciationCounts[taskId] ?? 0;
  }

  /// Send an appreciation for a completed task.
  Future<bool> sendAppreciation({
    required String taskId,
    required String fromUserId,
    required String toUserId,
    String reactionType = 'thanks',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final appreciation = await _service.sendAppreciation(
        taskId: taskId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        reactionType: reactionType,
      );

      if (appreciation != null) {
        _sentAppreciations[taskId] = appreciation;
        _taskAppreciationCounts[taskId] = (_taskAppreciationCounts[taskId] ?? 0) + 1;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending appreciation: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove an appreciation.
  Future<bool> removeAppreciation({
    required String taskId,
    required String fromUserId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.removeAppreciation(
        taskId: taskId,
        fromUserId: fromUserId,
      );

      if (success) {
        _sentAppreciations.remove(taskId);
        final count = _taskAppreciationCounts[taskId] ?? 0;
        if (count > 0) {
          _taskAppreciationCounts[taskId] = count - 1;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error removing appreciation: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load appreciation status for a task.
  Future<void> loadAppreciationStatus({
    required String taskId,
    required String currentUserId,
  }) async {
    try {
      final appreciation = await _service.getAppreciation(
        taskId: taskId,
        fromUserId: currentUserId,
      );

      if (appreciation != null) {
        _sentAppreciations[taskId] = appreciation;
      } else {
        _sentAppreciations.remove(taskId);
      }

      final allAppreciations = await _service.getTaskAppreciations(taskId);
      _taskAppreciationCounts[taskId] = allAppreciations.length;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading appreciation status: $e');
    }
  }

  /// Load total appreciation count for current user.
  Future<void> loadUserAppreciationCount(String userId) async {
    try {
      _totalAppreciationsReceived = await _service.getUserAppreciationCount(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user appreciation count: $e');
    }
  }

  /// Clear all cached data.
  void clear() {
    _sentAppreciations.clear();
    _taskAppreciationCounts.clear();
    _totalAppreciationsReceived = 0;
    notifyListeners();
  }
}
