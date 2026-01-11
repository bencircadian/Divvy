# Divvy App Redesign - Implementation Plan

## Executive Summary

This plan outlines a **safe, incremental approach** to redesigning the Divvy app without breaking existing functionality. The key principle is: **modify existing files rather than replacing them**, ensuring backward compatibility at every step.

---

## Current State Analysis

### Existing Theme Infrastructure (KEEP & MODIFY)
- `lib/config/app_theme.dart` - Contains AppColors, AppSpacing, AppRadius, AppShadows
- `lib/providers/theme_provider.dart` - Theme switching already works
- `lib/main.dart` - Has `_buildTheme()` method for light/dark themes

### Existing Screens (MODIFY IN PLACE)
- `lib/screens/main_shell.dart` - Header, bottom nav, FAB
- `lib/screens/dashboard/dashboard_screen.dart` - Dashboard
- `lib/screens/home/home_screen.dart` - Tasks list
- `lib/screens/settings/settings_screen.dart` - Settings

### Existing Widgets (KEEP & EXTEND)
- `lib/widgets/common/` - empty_state, member_avatar, detail_row, etc.
- `lib/widgets/tasks/` - task_tile, organic_task_card, etc.

---

## Implementation Phases

### Phase 1: Update Color Palette (LOW RISK)
**Goal**: Change colors without breaking any functionality

**Files to modify**:
1. `lib/config/app_theme.dart` - Update AppColors class

**Changes**:
```dart
// OLD (Green palette)
static const Color primary = Color(0xFF13EC80);

// NEW (Teal for light, context-aware for dark)
// Light Mode: Teal primary, Copper accent
// Dark Mode: Rose/Pink primary, Teal accent
```

**New color structure**:
```dart
class AppColors {
  // === LIGHT MODE COLORS ===
  static const Color primaryLight = Color(0xFF009688);      // Teal
  static const Color primaryLightDark = Color(0xFF00796B);  // Darker teal
  static const Color accentLight = Color(0xFFE07A5F);       // Copper/Terracotta
  static const Color accentLightAlt = Color(0xFFF4A261);    // Light copper

  // === DARK MODE COLORS ===
  static const Color primaryDark = Color(0xFFF67280);       // Rose/Pink
  static const Color primaryDarkLight = Color(0xFFFFB3BA);  // Light pink
  static const Color accentDark = Color(0xFF4DB6AC);        // Teal accent

  // === SHARED/EXISTING (keep these) ===
  // Keep existing background, card, status, category colors
}
```

**Safety**: Only color values change, no structural changes.

---

### Phase 2: Update Theme Builder (LOW RISK)
**Goal**: Make main.dart use the new color palette dynamically

**File to modify**: `lib/main.dart`

**Changes to `_buildTheme()`**:
- Use `AppColors.primaryLight` for light theme
- Use `AppColors.primaryDark` for dark theme
- Add accent color support

**Safety**: Existing theme structure remains, only color values change.

---

### Phase 3: Update Bottom Nav & FAB Shape (MEDIUM RISK)
**Goal**: Change FAB from circle to rounded square, update nav item styling

**File to modify**: `lib/screens/main_shell.dart`

**Changes**:
1. FAB shape: `CircleBorder()` → `RoundedRectangleBorder(borderRadius: 14)`
2. Nav items: Update from pill shape to square with rounded corners

**Before**:
```dart
// Current FAB
FloatingActionButton(
  shape: const CircleBorder(),
  ...
)

// Current nav item
borderRadius: BorderRadius.circular(AppRadius.xl), // pill shape
```

**After**:
```dart
// New FAB - rounded square
FloatingActionButton(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ...
)

// New nav item - square with rounded corners
borderRadius: BorderRadius.circular(10), // square-ish
```

**Safety**: Visual change only, no logic changes.

---

### Phase 4: Create New Widget Components (NO RISK)
**Goal**: Add new reusable widgets without touching existing code

**New files to create**:

1. `lib/widgets/dashboard/stat_card.dart`
   - Teal/pink stat cards with icon, label, value
   - Used for "Points Earned", "Chore Ratio", etc.

2. `lib/widgets/dashboard/progress_task_card.dart`
   - Progress bar card for "Kitchen Cleanup 6/10" style
   - Copper/accent progress bar

3. `lib/widgets/dashboard/weekly_overview_card.dart`
   - Two-column stats card
   - Total time + Rank display

4. `lib/widgets/dashboard/leaderboard_item.dart`
   - Avatar + name + points
   - "This Month's Pro" section

**Safety**: New files only, no existing code modified.

---

### Phase 5: Update Dashboard Screen (MEDIUM RISK)
**Goal**: Rebuild dashboard using new widgets

**File to modify**: `lib/screens/dashboard/dashboard_screen.dart`

**Strategy**:
1. Keep existing structure
2. Replace individual sections with new widgets
3. Test after each section change

**Order of changes**:
1. Replace stats row with new StatCard widgets
2. Update task list items to use accent colors
3. Add new sections (Weekly Overview, Leaderboard)

**Safety**: Incremental changes, test after each.

---

### Phase 6: Update Remaining Screens (LOW-MEDIUM RISK)
**Goal**: Apply new styling to other screens

**Files to modify**:
1. `lib/screens/home/home_screen.dart` - Task list styling
2. `lib/screens/settings/settings_screen.dart` - Theme toggle, styling
3. `lib/screens/tasks/task_detail_screen.dart` - Detail view styling

**Safety**: Visual updates only, keep existing logic.

---

### Phase 7: Polish & Animations (LOW RISK)
**Goal**: Add micro-interactions

**Changes**:
1. Checkbox toggle animations (already exists in animated_checkbox.dart)
2. Card press feedback
3. Page transitions

---

## File-by-File Change Summary

| File | Action | Risk | Phase |
|------|--------|------|-------|
| `lib/config/app_theme.dart` | Modify | Low | 1 |
| `lib/main.dart` | Modify | Low | 2 |
| `lib/screens/main_shell.dart` | Modify | Medium | 3 |
| `lib/widgets/dashboard/stat_card.dart` | Create | None | 4 |
| `lib/widgets/dashboard/progress_task_card.dart` | Create | None | 4 |
| `lib/widgets/dashboard/weekly_overview_card.dart` | Create | None | 4 |
| `lib/widgets/dashboard/leaderboard_item.dart` | Create | None | 4 |
| `lib/screens/dashboard/dashboard_screen.dart` | Modify | Medium | 5 |
| `lib/screens/home/home_screen.dart` | Modify | Low | 6 |
| `lib/screens/settings/settings_screen.dart` | Modify | Low | 6 |

---

## Testing Strategy

After each phase:
1. Run `flutter analyze` - Check for errors
2. Run `flutter test` - Ensure tests pass
3. Test light mode visually
4. Test dark mode visually
5. Build and deploy to Vercel

---

## Rollback Plan

Each phase is independent. If a phase breaks the app:
1. `git revert HEAD` to undo last commit
2. Push to restore previous version
3. Investigate issue before retrying

---

## Color Reference Quick Guide

### Light Mode
| Element | Color | Hex |
|---------|-------|-----|
| Primary (buttons, FAB) | Teal | #009688 |
| Accent (progress bars) | Copper | #E07A5F |
| Background | Light grey | #F5F5F5 |
| Cards | White | #FFFFFF |
| Text Primary | Dark | #1A1A1A |

### Dark Mode
| Element | Color | Hex |
|---------|-------|-----|
| Primary (buttons, FAB) | Rose/Pink | #F67280 |
| Accent (secondary) | Teal | #4DB6AC |
| Background | Navy | #1E1E2E |
| Cards | Dark surface | #2A2A3C |
| Text Primary | White | #FFFFFF |

---

## Estimated Implementation Order

1. **Phase 1** - Colors (30 min)
2. **Phase 2** - Theme builder (15 min)
3. **Phase 3** - Nav & FAB (30 min)
4. **Phase 4** - New widgets (1-2 hours)
5. **Phase 5** - Dashboard (1 hour)
6. **Phase 6** - Other screens (1 hour)
7. **Phase 7** - Polish (30 min)

**Total: ~4-5 hours of work**

---

## Questions to Clarify Before Starting

1. Should we keep the category colors (kitchen=orange, bathroom=blue, etc.) or update them too?
2. Should the header style change significantly or just get new colors?
3. Are there specific mockup images to reference for exact spacing/sizing?
4. Should the Schedule/Ranking screens be implemented or just styled?
