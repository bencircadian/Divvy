import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/task.dart';

/// Enum representing task categories.
enum TaskCategory {
  kitchen,
  bathroom,
  living,
  outdoor,
  pet,
  laundry,
  grocery,
  maintenance,
  admin,
  children,
  other,
}

/// Utility class for task category colors and names.
///
/// Consolidates duplicate category logic from multiple screens and widgets.
class CategoryUtils {
  /// Get the display color for a task's category.
  static Color getCategoryColor(Task task) {
    final category = _resolveCategory(task);
    return _categoryColors[category] ?? AppColors.primary;
  }

  /// Get the display name for a task's category.
  static String getCategoryName(Task task) {
    final category = _resolveCategory(task);
    return _categoryNames[category] ?? 'Other';
  }

  /// Get color for a category string.
  static Color getColorForCategory(String? categoryString) {
    final category = _parseCategoryString(categoryString);
    return _categoryColors[category] ?? AppColors.primary;
  }

  /// Get display name for a category string.
  static String getNameForCategory(String? categoryString) {
    if (categoryString != null && categoryString.isNotEmpty) {
      return categoryString[0].toUpperCase() + categoryString.substring(1);
    }
    return 'Other';
  }

  /// Resolve the category for a task, using explicit category or inferring from title.
  static TaskCategory _resolveCategory(Task task) {
    // Use explicit category if set
    if (task.category != null && task.category!.isNotEmpty) {
      return _parseCategoryString(task.category);
    }

    // Fallback to inference from title for legacy tasks
    return _inferCategoryFromTitle(task.title);
  }

  /// Parse a category string to TaskCategory enum.
  static TaskCategory _parseCategoryString(String? category) {
    if (category == null || category.isEmpty) return TaskCategory.other;

    switch (category.toLowerCase()) {
      case 'kitchen':
        return TaskCategory.kitchen;
      case 'bathroom':
        return TaskCategory.bathroom;
      case 'living':
        return TaskCategory.living;
      case 'outdoor':
        return TaskCategory.outdoor;
      case 'pet':
        return TaskCategory.pet;
      case 'laundry':
        return TaskCategory.laundry;
      case 'grocery':
        return TaskCategory.grocery;
      case 'maintenance':
        return TaskCategory.maintenance;
      case 'admin':
        return TaskCategory.admin;
      case 'children':
        return TaskCategory.children;
      default:
        return TaskCategory.other;
    }
  }

  /// Infer category from task title (for legacy tasks without explicit category).
  static TaskCategory _inferCategoryFromTitle(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('kitchen') ||
        lowerTitle.contains('dish') ||
        lowerTitle.contains('cook')) {
      return TaskCategory.kitchen;
    } else if (lowerTitle.contains('bathroom') ||
        lowerTitle.contains('toilet') ||
        lowerTitle.contains('shower')) {
      return TaskCategory.bathroom;
    } else if (lowerTitle.contains('living') ||
        lowerTitle.contains('vacuum') ||
        lowerTitle.contains('dust')) {
      return TaskCategory.living;
    } else if (lowerTitle.contains('outdoor') ||
        lowerTitle.contains('garden') ||
        lowerTitle.contains('yard')) {
      return TaskCategory.outdoor;
    } else if (lowerTitle.contains('pet') ||
        lowerTitle.contains('dog') ||
        lowerTitle.contains('cat') ||
        lowerTitle.contains('feed')) {
      return TaskCategory.pet;
    } else if (lowerTitle.contains('laundry') ||
        lowerTitle.contains('wash') ||
        lowerTitle.contains('clothes')) {
      return TaskCategory.laundry;
    } else if (lowerTitle.contains('grocery') ||
        lowerTitle.contains('shop') ||
        lowerTitle.contains('buy')) {
      return TaskCategory.grocery;
    } else if (lowerTitle.contains('fix') ||
        lowerTitle.contains('repair') ||
        lowerTitle.contains('maintenance')) {
      return TaskCategory.maintenance;
    } else if (lowerTitle.contains('bill') ||
        lowerTitle.contains('pay') ||
        lowerTitle.contains('admin')) {
      return TaskCategory.admin;
    } else if (lowerTitle.contains('child') || lowerTitle.contains('kid')) {
      return TaskCategory.children;
    }

    return TaskCategory.other;
  }

  /// Category to color mapping.
  static const Map<TaskCategory, Color> _categoryColors = {
    TaskCategory.kitchen: AppColors.kitchen,
    TaskCategory.bathroom: AppColors.bathroom,
    TaskCategory.living: AppColors.living,
    TaskCategory.outdoor: AppColors.outdoor,
    TaskCategory.pet: AppColors.pet,
    TaskCategory.laundry: AppColors.laundry,
    TaskCategory.grocery: AppColors.grocery,
    TaskCategory.maintenance: AppColors.maintenance,
    TaskCategory.admin: AppColors.admin,
    TaskCategory.children: AppColors.children,
    TaskCategory.other: AppColors.primary,
  };

  /// Category to display name mapping.
  static const Map<TaskCategory, String> _categoryNames = {
    TaskCategory.kitchen: 'Kitchen',
    TaskCategory.bathroom: 'Bathroom',
    TaskCategory.living: 'Living',
    TaskCategory.outdoor: 'Outdoor',
    TaskCategory.pet: 'Pet',
    TaskCategory.laundry: 'Laundry',
    TaskCategory.grocery: 'Grocery',
    TaskCategory.maintenance: 'Maintenance',
    TaskCategory.admin: 'Admin',
    TaskCategory.children: 'Children',
    TaskCategory.other: 'Other',
  };
}
