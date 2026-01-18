import 'package:hive_flutter/hive_flutter.dart';

/// Service to track user's onboarding progress.
///
/// Persists checklist items to Hive for a Loom-style post-signup checklist.
class OnboardingProgressService {
  static const String _boxName = 'onboarding_progress';
  static const String _dismissedKey = 'dismissed';
  static const String _firstTaskCompletedKey = 'first_task_completed';
  static const String _firstMemberInvitedKey = 'first_member_invited';
  static const String _profileCompletedKey = 'profile_completed';

  static Box? _box;

  /// Initialize the service
  static Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Check if the checklist has been dismissed
  static bool get isDismissed => _box?.get(_dismissedKey, defaultValue: false) ?? false;

  /// Dismiss the checklist permanently
  static Future<void> dismiss() async {
    await _box?.put(_dismissedKey, true);
  }

  /// Check if the first task has been completed
  static bool get hasCompletedFirstTask =>
      _box?.get(_firstTaskCompletedKey, defaultValue: false) ?? false;

  /// Mark first task as completed
  static Future<void> markFirstTaskCompleted() async {
    await _box?.put(_firstTaskCompletedKey, true);
  }

  /// Check if first household member has been invited
  static bool get hasInvitedFirstMember =>
      _box?.get(_firstMemberInvitedKey, defaultValue: false) ?? false;

  /// Mark first member as invited
  static Future<void> markFirstMemberInvited() async {
    await _box?.put(_firstMemberInvitedKey, true);
  }

  /// Check if profile has been completed
  static bool get hasCompletedProfile =>
      _box?.get(_profileCompletedKey, defaultValue: false) ?? false;

  /// Mark profile as completed
  static Future<void> markProfileCompleted() async {
    await _box?.put(_profileCompletedKey, true);
  }

  /// Get the progress percentage (0.0 to 1.0)
  static double get progressPercentage {
    int completed = 0;
    const int total = 3;

    if (hasCompletedFirstTask) completed++;
    if (hasInvitedFirstMember) completed++;
    if (hasCompletedProfile) completed++;

    return completed / total;
  }

  /// Check if all items are completed
  static bool get isComplete =>
      hasCompletedFirstTask && hasInvitedFirstMember && hasCompletedProfile;

  /// Check if the checklist should be shown
  static bool get shouldShow => !isDismissed && !isComplete;

  /// Reset all progress (for testing)
  static Future<void> reset() async {
    await _box?.clear();
  }
}

/// Enum for checklist items
enum OnboardingChecklistItem {
  completeFirstTask,
  inviteHouseholdMember,
  completeProfile,
}
