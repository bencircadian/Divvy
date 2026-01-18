import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import 'undo_completion_snackbar.dart';

/// A reusable animated checkbox for completing tasks.
///
/// Provides consistent animation across all task completion interactions.
class AnimatedTaskCheckbox extends StatefulWidget {
  final Task task;
  final TaskProvider taskProvider;
  final Color categoryColor;
  final double size;
  final VoidCallback? onCompleted;

  const AnimatedTaskCheckbox({
    super.key,
    required this.task,
    required this.taskProvider,
    required this.categoryColor,
    this.size = 24,
    this.onCompleted,
  });

  @override
  State<AnimatedTaskCheckbox> createState() => _AnimatedTaskCheckboxState();
}

class _AnimatedTaskCheckboxState extends State<AnimatedTaskCheckbox>
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

    // Pronounced bounce animation
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

  Future<void> _handleTap() async {
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
      widget.onCompleted?.call();

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
    final showAsCompleted = widget.task.isCompleted || _isAnimatingCompletion;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final isAnimating = _isAnimatingCompletion;
          final colorProgress = isAnimating
              ? _colorAnimation.value
              : (showAsCompleted ? 1.0 : 0.0);

          return Transform.scale(
            scale: isAnimating ? _scaleAnimation.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
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
                          widget.categoryColor,
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
                        size: widget.size * 0.58,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
