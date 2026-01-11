# Divvy Refactoring Plan

**Date:** 2026-01-11
**Based on:** REFACTOR_BASELINE.md

---

## Overview

This plan prioritizes safe refactorings that improve code quality without risking functionality. Given the lack of test coverage, we avoid structural changes to providers and business logic.

---

## Task List (Prioritized)

### HIGH PRIORITY - Quick Wins (Low Risk)

#### Task 1: Remove Unused Code
**Risk:** Low | **Impact:** Cleaner codebase, fewer analyzer warnings

| File | Line | Issue | Fix |
|------|------|-------|-----|
| `lib/screens/home/home_screen.dart` | 16 | Unused import `note_input.dart` | Delete line |
| `lib/screens/home/home_screen.dart` | 491 | Unused variable `isOwnedByMe` | Delete line |
| `lib/screens/main_shell.dart` | 45-47 | Unused method `_signOut()` | Delete method |

**Expected Result:** -3 analyzer warnings

---

#### Task 2: Fix Async Context Safety
**Risk:** Low | **Impact:** Prevents potential crashes

| File | Line | Issue | Fix |
|------|------|-------|-----|
| `lib/screens/tasks/task_detail_screen.dart` | ~79 | Using `context` after `await` | Add `if (!mounted) return;` check |

**Expected Result:** -1 analyzer info

---

#### Task 3: Extract Duplicated `_formatDueDate` Utility
**Risk:** Low | **Impact:** DRY code, single source of truth

**Current Locations (4 files):**
- `lib/screens/home/home_screen.dart:682`
- `lib/screens/dashboard/dashboard_screen.dart:960`
- `lib/screens/tasks/task_detail_screen.dart:1093`
- `lib/widgets/tasks/task_tile.dart:454`

**Plan:**
1. Create `lib/utils/date_formatter.dart`
2. Implement unified `formatDueDate(DateTime date, {DuePeriod? period})` function
3. Replace all 4 implementations with calls to the utility
4. Ensure exact same output for all existing use cases

**New File:**
```dart
// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';
import '../models/task.dart';

String formatDueDate(DateTime dueDate, {DuePeriod? period}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

  String dateStr;
  if (taskDate == today) {
    dateStr = 'Today';
  } else if (taskDate == tomorrow) {
    dateStr = 'Tomorrow';
  } else if (taskDate.isBefore(today.add(const Duration(days: 7)))) {
    dateStr = DateFormat('EEE').format(dueDate);
  } else {
    dateStr = DateFormat('MMM d').format(dueDate);
  }

  if (period != null) {
    return '$dateStr (${period.name})';
  }
  return dateStr;
}
```

**Expected Result:** -3 duplicated methods, +1 reusable utility

---

#### Task 4: Extract Duplicated `_getPriorityColor` Utility
**Risk:** Low | **Impact:** DRY code, consistent priority colors

**Current Location:**
- `lib/screens/dashboard/dashboard_screen.dart:941`

**Plan:**
1. Create `lib/utils/priority_utils.dart`
2. Move function to utility file
3. Update imports in dashboard_screen.dart

**New File:**
```dart
// lib/utils/priority_utils.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/task.dart';

Color getPriorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return AppColors.error;
    case TaskPriority.normal:
      return AppColors.warning;
    case TaskPriority.low:
      return AppColors.primary.withOpacity(0.6);
  }
}
```

**Expected Result:** Centralized priority color logic

---

#### Task 5: Extract Category Color/Name Logic
**Risk:** Low | **Impact:** DRY code, eliminates duplicate keyword matching

**Current Location:**
- `lib/screens/home/home_screen.dart:638-680`

Two methods (`_getCategoryColor` and `_getCategoryName`) share identical keyword matching logic.

**Plan:**
1. Create `lib/utils/category_utils.dart`
2. Create unified category detection with both color and name
3. Replace both methods with utility calls

**New File:**
```dart
// lib/utils/category_utils.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum TaskCategory {
  kitchen(AppColors.kitchen, 'Kitchen', ['kitchen', 'dish', 'cook']),
  bathroom(AppColors.bathroom, 'Bathroom', ['bathroom', 'toilet', 'shower']),
  living(AppColors.living, 'Living', ['living', 'vacuum', 'dust']),
  outdoor(AppColors.outdoor, 'Outdoor', ['outdoor', 'garden', 'yard']),
  pet(AppColors.pet, 'Pet', ['pet', 'dog', 'cat', 'feed']),
  laundry(AppColors.laundry, 'Laundry', ['laundry', 'wash', 'clothes']),
  grocery(AppColors.grocery, 'Grocery', ['grocery', 'shop', 'buy']),
  maintenance(AppColors.maintenance, 'Maintenance', ['fix', 'repair', 'maintenance']),
  general(AppColors.primary, 'Task', []);

  final Color color;
  final String name;
  final List<String> keywords;

  const TaskCategory(this.color, this.name, this.keywords);

  static TaskCategory fromTitle(String title) {
    final lowerTitle = title.toLowerCase();
    for (final category in TaskCategory.values) {
      if (category.keywords.any((k) => lowerTitle.contains(k))) {
        return category;
      }
    }
    return TaskCategory.general;
  }
}

Color getCategoryColor(String title) => TaskCategory.fromTitle(title).color;
String getCategoryName(String title) => TaskCategory.fromTitle(title).name;
```

**Expected Result:** Single source of truth for category detection

---

### MEDIUM PRIORITY - Theme Consistency

#### Task 6: Apply AppSpacing Constants
**Risk:** Low | **Impact:** Consistent spacing, easier to maintain

**Scope:** 109 EdgeInsets instances, 198 SizedBox instances across 22 files

**Approach:** Replace common patterns incrementally:
- `4` → `AppSpacing.xs`
- `8` → `AppSpacing.sm`
- `16` → `AppSpacing.md`
- `24` → `AppSpacing.lg`
- `32` → `AppSpacing.xl`
- `48` → `AppSpacing.xxl`

**Files to update (prioritized by impact):**
1. `dashboard_screen.dart` (35 SizedBox, 25 EdgeInsets)
2. `quick_setup_screen.dart` (18 SizedBox, 12 EdgeInsets)
3. `task_detail_screen.dart` (35 SizedBox, 10 EdgeInsets)
4. `home_screen.dart` (11 SizedBox, 12 EdgeInsets)
5. `create_task_screen.dart` (13 SizedBox, 6 EdgeInsets)

**Expected Result:** Consistent spacing throughout app

---

#### Task 7: Apply AppRadius Constants
**Risk:** Low | **Impact:** Consistent border radius

**Scope:** 25 BorderRadius.circular() calls

**Mapping:**
- `BorderRadius.circular(8)` → `BorderRadius.circular(AppRadius.sm)`
- `BorderRadius.circular(12)` → `BorderRadius.circular(AppRadius.md)`
- `BorderRadius.circular(16)` → `BorderRadius.circular(AppRadius.lg)`
- `BorderRadius.circular(20)` or `BorderRadius.circular(24)` → `BorderRadius.circular(AppRadius.xl)`

**Files to update:**
1. `dashboard_screen.dart` (6 instances)
2. `task_detail_screen.dart` (5 instances)
3. `task_tile.dart` (3 instances)
4. `home_screen.dart` (3 instances)
5. `note_input.dart` (2 instances)
6. Others (6 instances)

**Expected Result:** Consistent border radius throughout app

---

### LOWER PRIORITY - Code Quality

#### Task 8: Update Deprecated RadioListTile Usage
**Risk:** Low | **Impact:** Future-proof code

**Files:**
- `lib/screens/notifications/notification_settings_screen.dart:159-171`
- `lib/screens/settings/settings_screen.dart:221-250`

**Note:** The `groupValue` and `onChanged` parameters on `RadioListTile` are deprecated in favor of `RadioGroup`. However, this is a newer Flutter API and the current code works correctly. This can be deferred.

**Expected Result:** -8 analyzer infos (when implemented)

---

#### Task 9: Add const Constructors Where Possible
**Risk:** Low | **Impact:** Slightly better performance

**Scope:** Review all widget constructors for const eligibility

**Common patterns to fix:**
- `Icon(Icons.xyz)` → `const Icon(Icons.xyz)`
- `Text('static')` → `const Text('static')`
- `SizedBox(height: 16)` → `const SizedBox(height: 16)`
- `EdgeInsets.all(16)` → `const EdgeInsets.all(16)`

**Expected Result:** Better build-time optimization

---

#### Task 10: Add Keys to List Items
**Risk:** Low | **Impact:** Better list performance and state preservation

**Files with ListView.builder without keys:**
- `dashboard_screen.dart` - multiple lists
- `home_screen.dart` - task list
- `task_detail_screen.dart` - notes list

**Pattern:**
```dart
// Before
itemBuilder: (context, index) {
  final task = tasks[index];
  return TaskTile(task: task);
}

// After
itemBuilder: (context, index) {
  final task = tasks[index];
  return TaskTile(key: ValueKey(task.id), task: task);
}
```

**Expected Result:** Better list performance

---

## NOT RECOMMENDED (High Risk Without Tests)

The following refactorings are deferred until test coverage improves:

1. **Restructuring TaskProvider** - Too many responsibilities but high regression risk
2. **Breaking up large screens** - Could affect state management and navigation
3. **Changing Hive/Supabase sync patterns** - Critical functionality, needs tests first
4. **Modifying authentication flows** - Security-critical, needs tests first

---

## Execution Order

| Phase | Tasks | Estimated Changes |
|-------|-------|-------------------|
| 1 | Tasks 1-2 | 4 lines removed, 1 line added |
| 2 | Tasks 3-5 | 3 new files, ~80 lines changed |
| 3 | Tasks 6-7 | ~150 lines changed (spacing/radius) |
| 4 | Tasks 8-10 | ~50 lines changed |

---

## Verification Checklist

After each task:
- [ ] `flutter analyze` shows same or fewer issues
- [ ] `flutter test` passes (1/1)
- [ ] App builds without errors
- [ ] Visual appearance unchanged

After all tasks:
- [ ] Full `flutter analyze` run
- [ ] Manual verification of core flows
- [ ] Update REFACTOR_RESULTS.md

---

## Approval Required

Please review this plan and approve before I begin Phase 3 (Incremental Refactoring).

**Confirm which tasks you want me to execute:**
- [ ] All tasks (1-10)
- [ ] High priority only (1-5)
- [ ] Specific tasks: ___
