import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/task_bundle.dart';
import 'bundle_progress_bar.dart';

/// A card widget displaying a task bundle with progress.
class BundleCard extends StatelessWidget {
  final TaskBundle bundle;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool compact;

  const BundleCard({
    super.key,
    required this.bundle,
    this.onTap,
    this.showProgress = true,
    this.compact = false,
  });

  Color get bundleColor {
    try {
      final hex = bundle.color.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  IconData get bundleIcon {
    switch (bundle.icon) {
      case 'home':
        return Icons.home;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'bed':
        return Icons.bed;
      case 'kitchen':
        return Icons.kitchen;
      case 'bathroom':
        return Icons.bathroom;
      case 'yard':
        return Icons.yard;
      case 'pets':
        return Icons.pets;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'self_improvement':
        return Icons.self_improvement;
      default:
        return Icons.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (compact) {
      return _buildCompactCard(context, theme, colorScheme, isDark);
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon and menu
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bundleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      bundleIcon,
                      color: bundleColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  // Name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bundle.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (bundle.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            bundle.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Progress indicator or chevron
                  if (bundle.isComplete)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 24,
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),

              if (showProgress && bundle.totalTasks > 0) ...[
                SizedBox(height: AppSpacing.md),

                // Progress bar
                BundleProgressBar(
                  progress: bundle.progress,
                  color: bundleColor,
                  height: 6,
                ),

                SizedBox(height: AppSpacing.sm),

                // Task count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${bundle.completedTasks} of ${bundle.totalTasks} tasks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${bundle.progressPercent}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: bundleColor,
                      ),
                    ),
                  ],
                ),
              ] else if (bundle.isEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  'No tasks yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bundleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  bundleIcon,
                  color: bundleColor,
                  size: 18,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              // Name
              Expanded(
                child: Text(
                  bundle.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Progress circle
              if (bundle.totalTasks > 0)
                BundleProgressCircle(
                  progress: bundle.progress,
                  color: bundleColor,
                  size: 32,
                  strokeWidth: 3,
                  child: Text(
                    '${bundle.progressPercent}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
