// Main test file - imports and runs all tests
// Individual test files are in test/models/, test/providers/, test/widgets/

import 'package:flutter_test/flutter_test.dart';

// Model tests
import 'models/task_test.dart' as task_test;
import 'models/recurrence_rule_test.dart' as recurrence_rule_test;
import 'models/user_profile_test.dart' as user_profile_test;
import 'models/household_test.dart' as household_test;
import 'models/household_member_test.dart' as household_member_test;
import 'models/task_note_test.dart' as task_note_test;
import 'models/task_history_test.dart' as task_history_test;
import 'models/app_notification_test.dart' as app_notification_test;
import 'models/notification_preferences_test.dart' as notification_preferences_test;
import 'models/user_streak_test.dart' as user_streak_test;
import 'models/task_template_test.dart' as task_template_test;

// Provider tests
import 'providers/task_filter_test.dart' as task_filter_test;

// Widget tests
import 'widgets/error_view_test.dart' as error_view_test;
import 'widgets/loading_animation_test.dart' as loading_animation_test;

void main() {
  group('Divvy App Tests', () {
    group('Model Tests', () {
      task_test.main();
      recurrence_rule_test.main();
      user_profile_test.main();
      household_test.main();
      household_member_test.main();
      task_note_test.main();
      task_history_test.main();
      app_notification_test.main();
      notification_preferences_test.main();
      user_streak_test.main();
      task_template_test.main();
    });

    group('Provider Tests', () {
      task_filter_test.main();
    });

    group('Widget Tests', () {
      error_view_test.main();
      loading_animation_test.main();
    });
  });
}
