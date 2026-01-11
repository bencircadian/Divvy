import 'package:flutter/foundation.dart';

import '../models/user_streak.dart';
import '../services/supabase_service.dart';

class DashboardProvider extends ChangeNotifier {
  List<UserStreak> _streaks = [];
  Map<String, int> _taskCounts = {}; // userId -> completed task count
  bool _isLoading = false;
  String? _error;

  List<UserStreak> get streaks => _streaks;
  Map<String, int> get taskCounts => _taskCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get sorted streaks (highest first)
  List<UserStreak> get streaksSorted {
    final sorted = [..._streaks];
    sorted.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    return sorted;
  }

  Future<void> loadDashboardData(String householdId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load streaks with profile data
      final streaksResponse = await SupabaseService.client
          .from('user_streaks')
          .select('*, profiles(display_name)')
          .eq('household_id', householdId);

      _streaks = (streaksResponse as List)
          .map((json) => UserStreak.fromJson(json))
          .toList();

      // Load task completion counts using SQL aggregation (more efficient)
      try {
        final countsResponse = await SupabaseService.client
            .rpc('get_weekly_task_counts', params: {'p_household_id': householdId});

        _taskCounts = {};
        for (final row in countsResponse as List) {
          final userId = row['user_id'] as String?;
          final count = row['task_count'] as int?;
          if (userId != null && count != null) {
            _taskCounts[userId] = count;
          }
        }
      } catch (e) {
        // Fallback to client-side counting if RPC not available
        debugPrint('RPC not available, falling back to client-side counting: $e');
        await _loadTaskCountsFallback(householdId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading dashboard data: $e');
    }
  }

  /// Fallback method for loading task counts (client-side counting)
  Future<void> _loadTaskCountsFallback(String householdId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartStr = weekStart.toIso8601String().split('T')[0];

    final countsResponse = await SupabaseService.client
        .from('tasks')
        .select('completed_by')
        .eq('household_id', householdId)
        .eq('status', 'completed')
        .gte('completed_at', weekStartStr);

    _taskCounts = {};
    for (final task in countsResponse as List) {
      final completedBy = task['completed_by'] as String?;
      if (completedBy != null) {
        _taskCounts[completedBy] = (_taskCounts[completedBy] ?? 0) + 1;
      }
    }
  }

  /// Update streak when user completes a task
  static Future<void> updateStreakOnCompletion(String userId, String householdId) async {
    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().split('T')[0];

      // Get current streak data
      final existingResponse = await SupabaseService.client
          .from('user_streaks')
          .select()
          .eq('user_id', userId)
          .eq('household_id', householdId)
          .maybeSingle();

      if (existingResponse == null) {
        // Create new streak record
        await SupabaseService.client.from('user_streaks').insert({
          'user_id': userId,
          'household_id': householdId,
          'current_streak': 1,
          'longest_streak': 1,
          'last_completion_date': todayStr,
        });
      } else {
        final lastCompletionStr = existingResponse['last_completion_date'] as String?;
        final currentStreak = existingResponse['current_streak'] as int? ?? 0;
        final longestStreak = existingResponse['longest_streak'] as int? ?? 0;

        // Already completed today, no update needed
        if (lastCompletionStr == todayStr) {
          return;
        }

        int newStreak;
        if (lastCompletionStr == yesterdayStr) {
          // Continue streak
          newStreak = currentStreak + 1;
        } else {
          // Start new streak
          newStreak = 1;
        }

        final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

        await SupabaseService.client
            .from('user_streaks')
            .update({
              'current_streak': newStreak,
              'longest_streak': newLongest,
              'last_completion_date': todayStr,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('household_id', householdId);
      }
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  /// Get workload distribution (tasks assigned per member)
  Future<Map<String, int>> getWorkloadDistribution(String householdId) async {
    try {
      // Try using SQL aggregation first
      try {
        final response = await SupabaseService.client
            .rpc('get_workload_distribution', params: {'p_household_id': householdId});

        final workload = <String, int>{};
        for (final row in response as List) {
          final userId = row['user_id'] as String?;
          final count = row['task_count'] as int?;
          if (userId != null && count != null) {
            workload[userId] = count;
          }
        }
        return workload;
      } catch (e) {
        // Fallback to client-side counting
        debugPrint('RPC not available, falling back to client-side counting: $e');
        return _getWorkloadDistributionFallback(householdId);
      }
    } catch (e) {
      debugPrint('Error getting workload: $e');
      return {};
    }
  }

  /// Fallback method for workload distribution (client-side counting)
  Future<Map<String, int>> _getWorkloadDistributionFallback(String householdId) async {
    final response = await SupabaseService.client
        .from('tasks')
        .select('assigned_to')
        .eq('household_id', householdId)
        .eq('status', 'pending');

    final workload = <String, int>{};
    for (final task in response as List) {
      final assignedTo = task['assigned_to'] as String?;
      if (assignedTo != null) {
        workload[assignedTo] = (workload[assignedTo] ?? 0) + 1;
      }
    }
    return workload;
  }
}
