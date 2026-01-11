# Divvy Refactor Baseline Report

**Date:** 2026-01-11
**Total Lines of Code:** 12,825 (lib folder)
**Total Dart Files:** 47 (lib), 1 (test)

---

## 1. Flutter Analyze Results

**Total Issues: 13**

| Type | Count |
|------|-------|
| Errors | 0 |
| Warnings | 3 |
| Infos | 10 |

### Detailed Issues:

#### Warnings (3)
1. `lib/screens/home/home_screen.dart:16` - **unused_import**: `note_input.dart` is imported but never used
2. `lib/screens/home/home_screen.dart:491` - **unused_local_variable**: `isOwnedByMe` declared but never used
3. `lib/screens/main_shell.dart:45` - **unused_element**: `_signOut` method declared but never called

#### Infos (10)
1. `lib/main.dart:3` - **depend_on_referenced_packages**: flutter_web_plugins not a declared dependency
2. `lib/screens/notifications/notification_settings_screen.dart:162-163` - **deprecated_member_use**: Radio.groupValue/onChanged deprecated
3. `lib/screens/settings/settings_screen.dart:223-244` - **deprecated_member_use**: Radio.groupValue/onChanged deprecated (6 instances)
4. `lib/screens/tasks/task_detail_screen.dart:158` - **use_build_context_synchronously**: BuildContext used across async gap

---

## 2. Test Results

```
Total Tests: 1
Passed: 1 (100%)
Failed: 0
Skipped: 0
```

**Note:** Only a placeholder test exists. No actual app functionality is tested.

```dart
// test/widget_test.dart - Current content:
testWidgets('Placeholder test', (WidgetTester tester) async {
  expect(1 + 1, equals(2));
});
```

---

## 3. Codebase Structure Analysis

### File Size Distribution (Lines of Code)

| File | Lines | Status |
|------|-------|--------|
| task_detail_screen.dart | 1,100 | Very Large |
| quick_setup_screen.dart | 1,058 | Very Large |
| dashboard_screen.dart | 974 | Very Large |
| task_provider.dart | 915 | Very Large |
| home_screen.dart | 799 | Large |
| create_task_screen.dart | 591 | Large |
| auth_provider.dart | 533 | Large |
| task_tile.dart | 480 | Moderate |
| note_input.dart | 432 | Moderate |
| main_shell.dart | 385 | Moderate |
| signup_screen.dart | 357 | Moderate |
| settings_screen.dart | 344 | Moderate |

**8 files exceed 400 lines** - candidates for refactoring

---

## 4. Code Smells Identified

### 4.1 Duplicated Code (High Priority)

#### `_formatDueDate` - Duplicated in 3 files
- `lib/screens/home/home_screen.dart:682-696`
- `lib/screens/dashboard/dashboard_screen.dart:960-972`
- `lib/screens/tasks/task_detail_screen.dart:1093-1098`

#### `_getPriorityColor` - Duplicated in 2 files
- `lib/screens/dashboard/dashboard_screen.dart:941-950`
- Task-related coloring logic repeated

#### `isDark` Theme Check Pattern - Repeated ~50+ times
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
```

#### Category Color/Name Logic - Duplicated
- `lib/screens/home/home_screen.dart:638-680` - `_getCategoryColor` and `_getCategoryName` share identical keyword matching logic

### 4.2 Large Methods/Widgets (Medium Priority)

| File | Method | Lines |
|------|--------|-------|
| dashboard_screen.dart | `_buildWorkloadCard` | ~90 |
| dashboard_screen.dart | `_buildWeeklySummary` | ~120 |
| dashboard_screen.dart | `_buildUpcomingTasks` | ~110 |
| home_screen.dart | `_buildProgressBlob` | ~140 |
| task_detail_screen.dart | `_buildDetailView` | ~150 |
| task_detail_screen.dart | `_buildCoverImageSection` | ~140 |

### 4.3 Unused Code (High Priority - Quick Fixes)

1. **Unused import:**
   - `home_screen.dart:16` imports `note_input.dart` but doesn't use it

2. **Unused variables:**
   - `home_screen.dart:491` - `isOwnedByMe` is declared but never used

3. **Unused methods:**
   - `main_shell.dart:45` - `_signOut()` is defined but never called

### 4.4 Deprecated API Usage (Medium Priority)

Radio widget `groupValue` and `onChanged` are deprecated in favor of `RadioGroup`:
- `notification_settings_screen.dart:162-163`
- `settings_screen.dart:223-244` (multiple instances)

### 4.5 Async Safety Issues (Medium Priority)

- `task_detail_screen.dart:158` - Using BuildContext after await without checking `mounted`

### 4.6 Magic Numbers/Strings (Low Priority)

| Location | Value | Description |
|----------|-------|-------------|
| home_screen.dart:95 | `20` | Weekly goal hardcoded |
| Various files | `24`, `16`, `12`, `8` | Spacing values not using AppSpacing |
| Various files | `BorderRadius.circular(20)` | Not using AppRadius constants |

### 4.7 Missing const Constructors (Low Priority)

Several widgets could be const but aren't:
- Various Icon widgets
- Various Text widgets with static strings
- Container decorations with static values

### 4.8 Missing List Keys (Low Priority)

ListView builders without explicit keys:
- `dashboard_screen.dart` - multiple list builders
- `home_screen.dart` - task list mapping

---

## 5. Architecture Observations

### 5.1 Provider Structure
- **TaskProvider** (915 lines) - Does too much: CRUD, real-time, notes, history, image upload, notifications
- **AuthProvider** (533 lines) - Handles auth, profile, linking - reasonably scoped
- **DashboardProvider** (198 lines) - Well-scoped
- **HouseholdProvider** (255 lines) - Well-scoped

### 5.2 Service Layer
- **SupabaseService** - Static utility class for Supabase client access
- **CacheService** - Handles Hive caching
- Direct Supabase calls in providers (acceptable pattern)

### 5.3 Theme Usage
- `app_theme.dart` has well-defined constants (AppColors, AppSpacing, AppRadius, etc.)
- **Inconsistent usage** - Many hardcoded values instead of using theme constants

---

## 6. Files Planned for Refactoring

### Phase 1: Quick Wins (Low Risk)
1. `home_screen.dart` - Remove unused import and variable
2. `main_shell.dart` - Remove unused `_signOut` method
3. `notification_settings_screen.dart` - Update deprecated Radio widgets
4. `settings_screen.dart` - Update deprecated Radio widgets
5. `task_detail_screen.dart` - Fix async context issue

### Phase 2: Extract Utilities (Medium Risk)
1. Create `lib/utils/date_utils.dart` - Extract `_formatDueDate`
2. Create `lib/utils/priority_utils.dart` - Extract `_getPriorityColor`
3. Create `lib/utils/category_utils.dart` - Extract category color/name logic

### Phase 3: Apply Theme Constants (Low Risk)
1. Replace hardcoded spacing with `AppSpacing.*`
2. Replace hardcoded radius with `AppRadius.*`
3. Replace hardcoded colors with `AppColors.*`

### Phase 4: Widget Extraction (Medium Risk)
1. Extract reusable components from large screens
2. Break up large build methods into smaller widgets

---

## 7. Risk Assessment Summary

| Refactoring Type | Risk Level | Impact |
|------------------|------------|--------|
| Remove unused code | Low | Minimal |
| Fix deprecated APIs | Low | Minimal |
| Fix async context | Low | Minimal |
| Extract utility functions | Medium | Moderate |
| Apply theme constants | Low | Visual consistency |
| Break up large widgets | Medium | Maintainability |
| Provider restructuring | High | Not recommended without tests |

---

## 8. Recommendations

1. **Do NOT refactor provider internals** - No test coverage means high regression risk
2. **Focus on quick wins first** - Unused code, deprecations, theme consistency
3. **Extract utilities carefully** - Ensure exact same behavior
4. **Add tests before major refactoring** - Consider adding tests for critical flows first

---

## Approval Required

Please review this baseline and confirm before proceeding to Phase 2 (Analysis & Planning).
