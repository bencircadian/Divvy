import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

/// Shows an undo snackbar when a task is completed.
///
/// The snackbar displays for [duration] seconds with a countdown timer.
/// If the user taps "Undo", the task completion is reverted.
class UndoCompletionSnackbar {
  static const Duration defaultDuration = Duration(seconds: 3);

  /// Shows the undo snackbar and returns a Future that completes when
  /// the snackbar is dismissed (either by timeout or undo action).
  ///
  /// Returns true if the task was undone, false otherwise.
  static Future<bool> show({
    required BuildContext context,
    required Task task,
    required TaskProvider taskProvider,
    Duration duration = defaultDuration,
  }) async {
    final completer = Completer<bool>();

    ScaffoldMessenger.of(context).clearSnackBars();

    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _UndoSnackbarContent(
          taskTitle: task.title,
          duration: duration,
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.primary,
          onPressed: () async {
            // Uncomplete the task
            await taskProvider.toggleTaskComplete(task);
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          },
        ),
      ),
    );

    // Wait for snackbar to close
    controller.closed.then((reason) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }
}

class _UndoSnackbarContent extends StatefulWidget {
  final String taskTitle;
  final Duration duration;

  const _UndoSnackbarContent({
    required this.taskTitle,
    required this.duration,
  });

  @override
  State<_UndoSnackbarContent> createState() => _UndoSnackbarContentState();
}

class _UndoSnackbarContentState extends State<_UndoSnackbarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _secondsRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration.inSeconds;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D3A) : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular countdown indicator
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: 1 - _controller.value,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                    );
                  },
                ),
                // Countdown number
                Text(
                  '$_secondsRemaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Task completed message
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Task completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.taskTitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
