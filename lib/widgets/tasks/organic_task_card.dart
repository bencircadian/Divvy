import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/accessibility_helpers.dart';
import '../../utils/category_utils.dart';
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
    final categoryColor = CategoryUtils.getCategoryColor(task);

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

    return Semantics(
      label: AccessibilityHelpers.getTaskSemanticLabel(task),
      hint: AccessibilityHelpers.getTaskHint(task),
      button: true,
      child: Dismissible(
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
                              CategoryUtils.getCategoryName(task),
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
      ), // Semantics
    );
  }
}
