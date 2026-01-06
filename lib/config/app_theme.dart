/// Divvy App Theme & Style Guide
///
/// This file contains all the agreed styles and formatting for the Divvy app.
/// Reference this file when creating new UI components to ensure consistency.
library;

import 'package:flutter/material.dart';

/// Primary brand color - Modern Green (fresh & energizing)
const Color primaryColor = Color(0xFF13EC80);

/// App-wide spacing values
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// App-wide border radius values
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double circular = 999;
}

/// App-wide text styles (extend theme text styles)
class AppTextStyles {
  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(fontSize: 16);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14);
  static const TextStyle bodySmall = TextStyle(fontSize: 12);

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}

/// App-wide colors
class AppColors {
  // Brand colors - Modern Green palette
  static const Color primary = Color(0xFF13EC80);
  static const Color primaryLight = Color(0xFF4FF59E);
  static const Color primaryDark = Color(0xFF0BBF66);

  // Background colors (Light mode)
  static const Color backgroundLight = Color(0xFFF6F8F7);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Background colors (Dark mode)
  static const Color backgroundDark = Color(0xFF102219);
  static const Color cardDark = Color(0xFF162E22);
  static const Color surfaceDark = Color(0xFF1A3929);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Priority colors
  static const Color priorityHigh = Color(0xFFF44336);
  static const Color priorityNormal = Color(0xFFFF9800);
  static const Color priorityLow = Color(0xFF9E9E9E);

  // Category colors (for templates)
  static const Color kitchen = Color(0xFFFF9800);
  static const Color bathroom = Color(0xFF2196F3);
  static const Color living = Color(0xFF4CAF50);
  static const Color outdoor = Color(0xFF009688);
  static const Color pet = Color(0xFFE91E63);
  static const Color children = Color(0xFF9C27B0);
  static const Color laundry = Color(0xFF3F51B5);
  static const Color grocery = Color(0xFFFFC107);
  static const Color maintenance = Color(0xFF795548);
  static const Color admin = Color(0xFF673AB7);
}

/// App-wide shadows
class AppShadows {
  static List<BoxShadow> get light => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get heavy => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Card shadow that adapts to light/dark mode
  static List<BoxShadow> cardShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// FAB shadow with primary color glow
  static List<BoxShadow> get fabShadow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

/// App-wide animation durations
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}

/// ============================================================================
/// STYLE GUIDE RULES
/// ============================================================================
///
/// 1. SPACING
///    - Use AppSpacing constants for all padding/margin
///    - Standard card padding: AppSpacing.md (16)
///    - List item spacing: AppSpacing.sm (8)
///    - Section spacing: AppSpacing.lg (24)
///
/// 2. COLORS
///    - Always use theme colors via Theme.of(context).colorScheme
///    - For category-specific colors, use AppColors constants
///    - Never hardcode colors - define them in AppColors
///
/// 3. TYPOGRAPHY
///    - Use theme text styles: Theme.of(context).textTheme
///    - Section headers: titleSmall with primary color
///    - Card titles: titleMedium
///    - Body text: bodyMedium
///
/// 4. BUTTONS
///    - Primary actions: FilledButton
///    - Secondary actions: OutlinedButton
///    - Tertiary/text actions: TextButton
///    - Destructive actions: Red-styled FilledButton
///
/// 5. FORMS
///    - All inputs use OutlineInputBorder with AppRadius.md
///    - Error states use colorScheme.error
///    - Labels inside InputDecoration
///
/// 6. CARDS
///    - Use Material 3 Card widget
///    - Standard margin: horizontal 16, vertical 4
///    - Border radius: AppRadius.md (12)
///
/// 7. BOTTOM SHEETS
///    - Include drag handle at top
///    - Title centered with titleLarge
///    - Use DraggableScrollableSheet for long content
///
/// 8. DIALOGS
///    - Title should be a question or action
///    - Cancel button: TextButton (left)
///    - Confirm button: FilledButton (right)
///
/// 9. LOADING STATES
///    - Use CircularProgressIndicator for page loads
///    - Use LinearProgressIndicator for progress tracking
///    - Button loading: Shrink button text, show small spinner
///
/// 10. EMPTY STATES
///     - Center on screen
///     - Large icon (64px) in grey
///     - Descriptive text below
///     - Optional action button
///
