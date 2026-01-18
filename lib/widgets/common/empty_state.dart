import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// A reusable empty state widget for displaying when no content is available.
///
/// Used across dashboard, home, task lists, and other screens.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.iconSize = 64,
  });

  /// Factory constructor for new user welcome state
  factory EmptyState.forNewUser({
    required VoidCallback onCreateTask,
    VoidCallback? onExplore,
  }) {
    return EmptyState(
      icon: Icons.task_alt,
      title: 'Welcome to Divvy!',
      subtitle: 'Get started by creating your first task or exploring templates.',
      actionLabel: 'Create Task',
      onAction: onCreateTask,
      secondaryActionLabel: onExplore != null ? 'Explore Templates' : null,
      onSecondaryAction: onExplore,
      iconColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for use inside Card widgets with an icon bubble.
/// Follows the dashboard design pattern with colored icon container.
class CardEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const CardEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
  });

  /// Factory for "all caught up" task state
  factory CardEmptyState.tasksDone() => const CardEmptyState(
        icon: Icons.check_circle,
        message: 'All caught up! No tasks due today.',
        color: AppColors.success,
      );

  /// Factory for no upcoming tasks
  factory CardEmptyState.noUpcoming() => const CardEmptyState(
        icon: Icons.event_available,
        message: 'No upcoming tasks scheduled.',
        color: AppColors.info,
      );

  /// Factory for no streaks
  factory CardEmptyState.noStreaks() => CardEmptyState(
        icon: Icons.local_fire_department,
        message: 'Complete tasks daily to build your streak!',
        color: Colors.orange,
      );

  /// Factory for no workload
  factory CardEmptyState.noWorkload() => const CardEmptyState(
        icon: Icons.balance,
        message: 'Tasks will appear here once assigned.',
        color: AppColors.primary,
      );

  /// Factory for no bundles
  factory CardEmptyState.noBundles() => const CardEmptyState(
        icon: Icons.folder_outlined,
        message: 'Group related tasks into bundles.',
        color: AppColors.primary,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact empty state for use in cards or smaller containers.
class EmptyStateCompact extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? color;

  const EmptyStateCompact({
    super.key,
    required this.icon,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: effectiveColor),
          SizedBox(width: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: effectiveColor),
          ),
        ],
      ),
    );
  }
}
