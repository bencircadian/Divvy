import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recurrence_analytics.dart';
import '../models/recurrence_rule.dart';
import '../models/schedule_suggestion.dart';

/// Service for smart recurrence analysis and suggestions.
class SmartRecurrenceService {
  final SupabaseClient _supabase;

  SmartRecurrenceService(this._supabase);

  /// Record a task completion for analytics.
  Future<void> recordCompletion({
    required String taskId,
    required String householdId,
    required DateTime originalDueDate,
    required DateTime actualCompletionDate,
  }) async {
    try {
      final daysLate = actualCompletionDate.difference(originalDueDate).inDays;

      await _supabase.from('recurrence_analytics').insert({
        'task_id': taskId,
        'household_id': householdId,
        'original_due_date': originalDueDate.toIso8601String().split('T')[0],
        'actual_completion_date': actualCompletionDate.toIso8601String().split('T')[0],
        'days_late': daysLate,
      });
    } catch (e) {
      debugPrint('Error recording completion analytics: $e');
    }
  }

  /// Get analytics summary for a recurring task.
  Future<RecurrenceAnalyticsSummary?> getAnalyticsSummary(String taskId) async {
    try {
      final response = await _supabase
          .from('recurrence_analytics')
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: false)
          .limit(10);

      final analytics = (response as List)
          .map((json) => RecurrenceAnalytics.fromJson(json))
          .toList();

      if (analytics.isEmpty) return null;

      // Calculate metrics
      final totalCompletions = analytics.length;
      final lateCompletions = analytics.where((a) => a.wasLate).length;
      final onTimeCompletions = totalCompletions - lateCompletions;

      final totalDaysLate = analytics.fold<int>(0, (sum, a) => sum + a.daysLate);
      final averageDaysLate = totalCompletions > 0 ? totalDaysLate / totalCompletions : 0.0;

      // Count consecutive late completions (from most recent)
      int consecutiveLateCount = 0;
      for (final a in analytics) {
        if (a.wasLate) {
          consecutiveLateCount++;
        } else {
          break;
        }
      }

      // Get recent delays
      final recentDelays = analytics
          .take(5)
          .map((a) => a.daysLate)
          .toList();

      return RecurrenceAnalyticsSummary(
        taskId: taskId,
        totalCompletions: totalCompletions,
        lateCompletions: lateCompletions,
        onTimeCompletions: onTimeCompletions,
        averageDaysLate: averageDaysLate,
        consecutiveLateCount: consecutiveLateCount,
        recentDelays: recentDelays,
      );
    } catch (e) {
      debugPrint('Error getting analytics summary: $e');
      return null;
    }
  }

  /// Generate a schedule suggestion for a recurring task.
  Future<ScheduleSuggestion?> generateSuggestion({
    required String taskId,
    required String taskTitle,
    required RecurrenceRule currentSchedule,
  }) async {
    try {
      final summary = await getAnalyticsSummary(taskId);
      if (summary == null || !summary.shouldSuggestScheduleChange) {
        return null;
      }

      // Check if suggestion was dismissed
      final dismissedResponse = await _supabase
          .from('tasks')
          .select('suggestion_dismissed')
          .eq('id', taskId)
          .maybeSingle();

      if (dismissedResponse?['suggestion_dismissed'] == true) {
        return null;
      }

      // Generate suggestion based on pattern
      final suggestedSchedule = _generateSuggestedSchedule(
        currentSchedule,
        summary.averageDaysLate.round(),
      );

      if (suggestedSchedule == null) return null;

      return ScheduleSuggestion(
        taskId: taskId,
        taskTitle: taskTitle,
        currentSchedule: currentSchedule,
        suggestedSchedule: suggestedSchedule,
        reason: summary.suggestionReason,
        confidence: _calculateConfidence(summary),
        type: _determineSuggestionType(currentSchedule, suggestedSchedule),
        averageDaysLate: summary.averageDaysLate.round(),
        consecutiveLateCount: summary.consecutiveLateCount,
      );
    } catch (e) {
      debugPrint('Error generating suggestion: $e');
      return null;
    }
  }

  /// Generate a suggested schedule based on delay pattern.
  RecurrenceRule? _generateSuggestedSchedule(
    RecurrenceRule current,
    int averageDaysLate,
  ) {
    // For weekly tasks, shift the day of week
    if (current.frequency == RecurrenceFrequency.weekly &&
        current.days != null &&
        current.days!.isNotEmpty) {
      final currentDay = current.days!.first;
      final suggestedDay = ((currentDay + averageDaysLate) % 7);

      return current.copyWith(
        days: [suggestedDay],
      );
    }

    // For daily tasks with interval, increase the interval
    if (current.frequency == RecurrenceFrequency.daily) {
      return current.copyWith(
        interval: current.interval + 1,
      );
    }

    // For other frequencies, shift start date would be handled differently
    return null;
  }

  /// Calculate confidence score for the suggestion.
  double _calculateConfidence(RecurrenceAnalyticsSummary summary) {
    double confidence = 0.5;

    // More data = more confidence
    if (summary.totalCompletions >= 10) {
      confidence += 0.2;
    } else if (summary.totalCompletions >= 5) {
      confidence += 0.1;
    }

    // More consistent delay pattern = more confidence
    if (summary.consecutiveLateCount >= 5) {
      confidence += 0.2;
    } else if (summary.consecutiveLateCount >= 3) {
      confidence += 0.1;
    }

    // Reasonable average delay = more confidence
    if (summary.averageDaysLate >= 2 && summary.averageDaysLate <= 5) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// Determine the type of suggestion.
  SuggestionType _determineSuggestionType(
    RecurrenceRule current,
    RecurrenceRule suggested,
  ) {
    if (current.days != suggested.days) {
      return SuggestionType.changeDayOfWeek;
    }
    if (current.interval < suggested.interval) {
      return SuggestionType.increaseInterval;
    }
    return SuggestionType.delayDay;
  }

  /// Accept a schedule suggestion and update the task.
  Future<bool> acceptSuggestion({
    required String taskId,
    required RecurrenceRule newSchedule,
  }) async {
    try {
      await _supabase.from('tasks').update({
        'recurrence_rule': newSchedule.toJson(),
      }).eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Error accepting suggestion: $e');
      return false;
    }
  }

  /// Dismiss a schedule suggestion.
  Future<bool> dismissSuggestion(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'suggestion_dismissed': true,
      }).eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Error dismissing suggestion: $e');
      return false;
    }
  }

  /// Reset dismissed suggestion (for when schedule changes).
  Future<bool> resetDismissedSuggestion(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'suggestion_dismissed': false,
      }).eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Error resetting dismissed suggestion: $e');
      return false;
    }
  }

  /// Clear analytics for a task (e.g., when schedule changes).
  Future<bool> clearAnalytics(String taskId) async {
    try {
      await _supabase
          .from('recurrence_analytics')
          .delete()
          .eq('task_id', taskId);

      return true;
    } catch (e) {
      debugPrint('Error clearing analytics: $e');
      return false;
    }
  }
}
