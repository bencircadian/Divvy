import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// A reusable colored badge/chip for displaying labels with background colors.
///
/// Used for priority indicators, category tags, status badges, etc.
class ColoredBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final double? fontSize;
  final EdgeInsets? padding;

  const ColoredBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.icon,
    this.fontSize,
    this.padding,
  });

  /// Creates a priority badge with predefined colors.
  factory ColoredBadge.priority(String priority) {
    final Color color;
    switch (priority.toLowerCase()) {
      case 'high':
        color = AppColors.error;
        break;
      case 'normal':
        color = AppColors.warning;
        break;
      case 'low':
      default:
        color = Colors.grey;
    }
    return ColoredBadge(
      label: priority[0].toUpperCase() + priority.substring(1),
      color: color,
    );
  }

  /// Creates a status badge (completed, pending, overdue).
  factory ColoredBadge.status(String status) {
    final Color color;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        color = AppColors.success;
        break;
      case 'overdue':
        color = AppColors.error;
        break;
      case 'pending':
      default:
        color = AppColors.warning;
    }
    return ColoredBadge(label: status, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = color.withValues(alpha: isDark ? 0.3 : 0.15);
    final fgColor = textColor ?? (isDark ? color.withValues(alpha: 0.9) : color);

    return Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A category badge with auto-detected color based on category name.
class CategoryBadge extends StatelessWidget {
  final String category;
  final IconData? icon;

  const CategoryBadge({
    super.key,
    required this.category,
    this.icon,
  });

  Color get _categoryColor {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('kitchen')) return AppColors.kitchen;
    if (lowerCategory.contains('bathroom')) return AppColors.bathroom;
    if (lowerCategory.contains('living')) return AppColors.living;
    if (lowerCategory.contains('outdoor')) return AppColors.outdoor;
    if (lowerCategory.contains('pet')) return AppColors.pet;
    if (lowerCategory.contains('laundry')) return AppColors.laundry;
    if (lowerCategory.contains('grocery')) return AppColors.grocery;
    if (lowerCategory.contains('maintenance')) return AppColors.maintenance;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBadge(
      label: category,
      color: _categoryColor,
      icon: icon,
    );
  }
}
