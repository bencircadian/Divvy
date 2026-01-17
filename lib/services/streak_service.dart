import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// Service for managing user completion streaks.
///
/// Extracted from DashboardProvider to avoid circular dependency
/// with TaskProvider.
class StreakService {
  /// Update streak when user completes a task.
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
}
