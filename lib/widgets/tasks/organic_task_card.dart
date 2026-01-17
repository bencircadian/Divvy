import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/date_utils.dart';

/// An organic-styled task card with alternating border radius.
class OrganicTaskCard extends StatelessWidget {
  final Task task;
  final int index;
  final TaskProvider taskProvider;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionTap;

  const OrganicTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.taskProvider,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onSelectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(task);

    // Alternate border radius for organic feel
    final isEven = index % 2 == 0;
    final borderRadius = isEven
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          );

    // Check if task is overdue
    final isOverdue = task.isOverdue && !task.isCompleted;

    // Swipe background color based on completion state
    final swipeColor = task.isCompleted ? Colors.orange : AppColors.success;
    final swipeIcon = task.isCompleted ? Icons.replay : Icons.check;
    final swipeText = task.isCompleted ? 'Undo' : 'Done';

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        await taskProvider.toggleTaskComplete(task);
        return false; // Don't dismiss, just toggle
      },
      background: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        decoration: BoxDecoration(
          color: swipeColor,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              swipeText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(swipeIcon, color: Colors.white),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: GestureDetector(
          onTap: isSelectionMode
              ? onSelectionTap
              : () => context.push('/task/${task.id}'),
          onLongPress: onLongPress,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : isOverdue
                    ? AppColors.error.withValues(alpha: isDark ? 0.08 : 0.05)
                    : task.isCompleted
                        ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100])
                        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
            borderRadius: borderRadius,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isOverdue
                      ? AppColors.error.withValues(alpha: 0.3)
                      : task.isCompleted
                          ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!)
                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: task.isCompleted ? 0.6 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    taskProvider.toggleTaskComplete(task);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? AppColors.primary : Colors.transparent,
                      border: task.isCompleted
                          ? null
                          : Border.all(color: categoryColor, width: 2),
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: isDark ? const Color(0xFF102219) : Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted
                              ? (isDark ? AppColors.textSecondary : Colors.grey[500])
                              : (isDark ? AppColors.textPrimary : Colors.grey[900]),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          // Category tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getCategoryName(task),
                              style: TextStyle(
                                fontSize: 12,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Due date
                          if (task.dueDate != null)
                            Text(
                              TaskDateUtils.formatDueDateShort(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondary : Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Assignee avatar
                if (task.assignedToName != null)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        task.assignedToName![0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ), // Dismissible
    );
  }

  /// Get category color based on task category or title inference
  Color _getCategoryColor(Task task) {
    final category = task.category?.toLowerCase() ?? '';
    final lowerTitle = task.title.toLowerCase();

    // Check category first, then fall back to title inference
    if (category == 'kitchen' || lowerTitle.contains('kitchen') || lowerTitle.contains('dish') || lowerTitle.contains('cook')) {
      return AppColors.kitchen;
    } else if (category == 'bathroom' || lowerTitle.contains('bathroom') || lowerTitle.contains('toilet') || lowerTitle.contains('shower')) {
      return AppColors.bathroom;
    } else if (category == 'living' || lowerTitle.contains('living') || lowerTitle.contains('vacuum') || lowerTitle.contains('dust')) {
      return AppColors.living;
    } else if (category == 'outdoor' || lowerTitle.contains('outdoor') || lowerTitle.contains('garden') || lowerTitle.contains('yard')) {
      return AppColors.outdoor;
    } else if (category == 'pet' || lowerTitle.contains('pet') || lowerTitle.contains('dog') || lowerTitle.contains('cat') || lowerTitle.contains('feed')) {
      return AppColors.pet;
    } else if (category == 'laundry' || lowerTitle.contains('laundry') || lowerTitle.contains('wash') || lowerTitle.contains('clothes')) {
      return AppColors.laundry;
    } else if (category == 'grocery' || lowerTitle.contains('grocery') || lowerTitle.contains('shop') || lowerTitle.contains('buy')) {
      return AppColors.grocery;
    } else if (category == 'maintenance' || lowerTitle.contains('fix') || lowerTitle.contains('repair') || lowerTitle.contains('maintenance')) {
      return AppColors.maintenance;
    }
    return AppColors.primary;
  }

  /// Get category name - uses task.category if set, otherwise infers from title
  String _getCategoryName(Task task) {
    // Use explicit category if set
    if (task.category != null && task.category!.isNotEmpty) {
      return task.category![0].toUpperCase() + task.category!.substring(1);
    }

    // Fallback to inference for legacy tasks
    final lowerTitle = task.title.toLowerCase();
    if (lowerTitle.contains('kitchen') || lowerTitle.contains('dish') || lowerTitle.contains('cook')) {
      return 'Kitchen';
    } else if (lowerTitle.contains('bathroom') || lowerTitle.contains('toilet') || lowerTitle.contains('shower')) {
      return 'Bathroom';
    } else if (lowerTitle.contains('living') || lowerTitle.contains('vacuum') || lowerTitle.contains('dust')) {
      return 'Living';
    } else if (lowerTitle.contains('outdoor') || lowerTitle.contains('garden') || lowerTitle.contains('yard')) {
      return 'Outdoor';
    } else if (lowerTitle.contains('pet') || lowerTitle.contains('dog') || lowerTitle.contains('cat') || lowerTitle.contains('feed')) {
      return 'Pet';
    } else if (lowerTitle.contains('laundry') || lowerTitle.contains('wash') || lowerTitle.contains('clothes')) {
      return 'Laundry';
    } else if (lowerTitle.contains('grocery') || lowerTitle.contains('shop') || lowerTitle.contains('buy')) {
      return 'Grocery';
    } else if (lowerTitle.contains('fix') || lowerTitle.contains('repair') || lowerTitle.contains('maintenance')) {
      return 'Maintenance';
    }
    return 'Task';
  }
}
