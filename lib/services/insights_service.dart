import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/productivity_insights.dart';

/// Service for calculating productivity insights from task completion data.
class InsightsService {
  final SupabaseClient _supabase;

  InsightsService(this._supabase);

  /// Calculate productivity insights for a user in a household.
  Future<ProductivityInsights> getInsights({
    required String userId,
    required String householdId,
  }) async {
    try {
      // Fetch completed tasks for the user
      final response = await _supabase
          .from('tasks')
          .select('completed_at')
          .eq('household_id', householdId)
          .eq('completed_by', userId)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);

      final tasks = response as List<dynamic>;

      if (tasks.isEmpty) {
        return ProductivityInsights.empty;
      }

      // Parse completion timestamps
      final completions = tasks
          .map((t) => DateTime.tryParse(t['completed_at'] as String? ?? ''))
          .whereType<DateTime>()
          .toList();

      if (completions.isEmpty) {
        return ProductivityInsights.empty;
      }

      // Calculate completions by day of week (1-7 in Dart, convert to 0-6)
      final completionsByDay = <int, int>{};
      for (final date in completions) {
        final dayIndex = date.weekday - 1; // Convert 1-7 to 0-6
        completionsByDay[dayIndex] = (completionsByDay[dayIndex] ?? 0) + 1;
      }

      // Calculate completions by time of day
      final completionsByTime = <String, int>{
        'morning': 0,
        'afternoon': 0,
        'evening': 0,
        'night': 0,
      };
      for (final date in completions) {
        final hour = date.hour;
        String timeSlot;
        if (hour >= 6 && hour < 12) {
          timeSlot = 'morning';
        } else if (hour >= 12 && hour < 17) {
          timeSlot = 'afternoon';
        } else if (hour >= 17 && hour < 21) {
          timeSlot = 'evening';
        } else {
          timeSlot = 'night';
        }
        completionsByTime[timeSlot] = (completionsByTime[timeSlot] ?? 0) + 1;
      }

      // Find best day of week
      int? bestDay;
      int bestDayCount = 0;
      completionsByDay.forEach((day, count) {
        if (count > bestDayCount) {
          bestDay = day;
          bestDayCount = count;
        }
      });

      // Find most productive time
      String? bestTime;
      int bestTimeCount = 0;
      completionsByTime.forEach((time, count) {
        if (count > bestTimeCount) {
          bestTime = time;
          bestTimeCount = count;
        }
      });

      // Calculate tasks this week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final tasksThisWeek = completions.where((d) => d.isAfter(weekStart)).length;

      // Calculate average tasks per week
      final oldestCompletion = completions.last;
      final daysSinceOldest = now.difference(oldestCompletion).inDays;
      final weeksSinceOldest = (daysSinceOldest / 7).ceil().clamp(1, 9999);
      final averagePerWeek = completions.length / weeksSinceOldest;

      // Calculate streaks
      final streakData = _calculateStreaks(completions);

      return ProductivityInsights(
        bestDayOfWeek: bestDay,
        mostProductiveTime: bestTime,
        averageTasksPerWeek: averagePerWeek,
        totalTasksCompleted: completions.length,
        tasksThisWeek: tasksThisWeek,
        currentStreak: streakData['current'] ?? 0,
        longestStreak: streakData['longest'] ?? 0,
        completionsByDay: completionsByDay,
        completionsByTime: completionsByTime,
      );
    } catch (e) {
      // Return empty insights on error
      return ProductivityInsights.empty;
    }
  }

  /// Calculate current and longest streaks.
  Map<String, int> _calculateStreaks(List<DateTime> completions) {
    if (completions.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    // Get unique completion dates
    final uniqueDates = completions
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    if (uniqueDates.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    // Calculate current streak
    int currentStreak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    // Check if streak is active (completed today or yesterday)
    if (uniqueDates.first == todayDate || uniqueDates.first == yesterday) {
      currentStreak = 1;
      for (int i = 1; i < uniqueDates.length; i++) {
        final prevDate = uniqueDates[i - 1];
        final currDate = uniqueDates[i];
        final diff = prevDate.difference(currDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    // Calculate longest streak
    int longestStreak = 1;
    int tempStreak = 1;
    final sortedAsc = uniqueDates.reversed.toList();
    for (int i = 1; i < sortedAsc.length; i++) {
      final prevDate = sortedAsc[i - 1];
      final currDate = sortedAsc[i];
      final diff = currDate.difference(prevDate).inDays;
      if (diff == 1) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 1;
      }
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }
}
