import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/accessibility_helpers.dart';
import '../../utils/category_utils.dart';
import '../../utils/date_utils.dart';
import '../common/undo_completion_snackbar.dart';

/// An organic-styled task card with alternating border radius.
class OrganicTaskCard extends StatefulWidget {
  final Task task;
  final int index;
  final TaskProvider taskProvider;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionTap;
  final VoidCallback? onTaskCompleted;

  const OrganicTaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.taskProvider,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onLongPress,
    this.onSelectionTap,
    this.onTaskCompleted,
  });

  @override
  State<OrganicTaskCard> createState() => _OrganicTaskCardState();
}

class _OrganicTaskCardState extends State<OrganicTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _colorAnimation;
  bool _isAnimatingCompletion = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // More pronounced bounce animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_animationController);

    // Checkmark pops in
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Color fill animation
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleCompletion() async {
    if (_isAnimatingCompletion) return;

    final wasCompleted = widget.task.isCompleted;

    // Only animate if completing (not uncompleting)
    if (!wasCompleted) {
      setState(() => _isAnimatingCompletion = true);

      // Haptic feedback at start
      HapticFeedback.mediumImpact();

      // Play animation
      await _animationController.forward();

      // Second haptic at completion
      HapticFeedback.lightImpact();

      // Small delay to let user see the completed state
      await Future.delayed(const Duration(milliseconds: 150));

      // Now actually complete the task
      await widget.taskProvider.toggleTaskComplete(widget.task);
      widget.onTaskCompleted?.call();

      // Reset animation state
      if (mounted) {
        _animationController.reset();
        setState(() => _isAnimatingCompletion = false);

        // Show undo snackbar
        UndoCompletionSnackbar.show(
          context: context,
          task: widget.task,
          taskProvider: widget.taskProvider,
        );
      }
    } else {
      // Uncompleting - just do it with haptic
      HapticFeedback.mediumImpact();
      await widget.taskProvider.toggleTaskComplete(widget.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = CategoryUtils.getCategoryColor(widget.task);

    // Alternate border radius for organic feel
    final isEven = widget.index % 2 == 0;
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
    final isOverdue = widget.task.isOverdue && !widget.task.isCompleted;

    // Swipe background color based on completion state
    final swipeColor =
        widget.task.isCompleted ? Colors.orange : AppColors.success;
    final swipeIcon = widget.task.isCompleted ? Icons.replay : Icons.check;
    final swipeText = widget.task.isCompleted ? 'Undo' : 'Done';

    // Show as completed during animation
    final showAsCompleted = widget.task.isCompleted || _isAnimatingCompletion;

    return Semantics(
      label: AccessibilityHelpers.getTaskSemanticLabel(widget.task),
      hint: AccessibilityHelpers.getTaskHint(widget.task),
      button: true,
      child: Dismissible(
        key: Key(widget.task.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          await _handleCompletion();
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
            onTap: widget.isSelectionMode
                ? widget.onSelectionTap
                : () => context.push('/task/${widget.task.id}'),
            onLongPress: widget.onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : isOverdue
                        ? AppColors.error.withValues(alpha: isDark ? 0.08 : 0.05)
                        : showAsCompleted
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.grey[100])
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white),
                borderRadius: borderRadius,
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.primary
                      : isOverdue
                          ? AppColors.error.withValues(alpha: 0.3)
                          : showAsCompleted
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey[200]!)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey[200]!),
                  width: widget.isSelected ? 2 : 1,
                ),
              ),
              child: Opacity(
                opacity: showAsCompleted ? 0.6 : 1.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animated Checkbox
                    GestureDetector(
                      onTap: _handleCompletion,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final isAnimating = _isAnimatingCompletion;
                          final colorProgress = isAnimating ? _colorAnimation.value : (showAsCompleted ? 1.0 : 0.0);

                          return Transform.scale(
                            scale: isAnimating ? _scaleAnimation.value : 1.0,
                            child: Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.lerp(
                                  Colors.transparent,
                                  AppColors.success,
                                  colorProgress,
                                ),
                                border: colorProgress < 1.0
                                    ? Border.all(
                                        color: Color.lerp(
                                          categoryColor,
                                          AppColors.success,
                                          colorProgress,
                                        )!,
                                        width: 2,
                                      )
                                    : null,
                                boxShadow: isAnimating && colorProgress > 0.5
                                    ? [
                                        BoxShadow(
                                          color: AppColors.success.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: colorProgress > 0.3
                                  ? Transform.scale(
                                      scale: isAnimating ? _checkAnimation.value : 1.0,
                                      child: Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Task content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: showAsCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: showAsCompleted
                                  ? (isDark
                                      ? AppColors.textSecondary
                                      : Colors.grey[500])
                                  : (isDark
                                      ? AppColors.textPrimary
                                      : Colors.grey[900]),
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              // Category tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  CategoryUtils.getCategoryName(widget.task),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Due date
                              if (widget.task.dueDate != null)
                                Text(
                                  TaskDateUtils.formatDueDateShort(
                                      widget.task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondary
                                        : Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Assignee avatar
                    if (widget.task.assignedToName != null)
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
                            widget.task.assignedToName![0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? AppColors.textPrimary : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ), // Dismissible
    ); // Semantics
  }
}
