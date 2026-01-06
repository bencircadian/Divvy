import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../common/animated_checkbox.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onTakeOwnership;
  final VoidCallback? onAddNote;
  final VoidCallback? onDelete;
  final VoidCallback? onSnooze;
  final bool isOwnedByMe;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onTakeOwnership,
    this.onAddNote,
    this.onDelete,
    this.onSnooze,
    this.isOwnedByMe = false,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  bool _isDragging = false;

  Task get task => widget.task;

  void _handleSwipeComplete() {
    HapticFeedback.mediumImpact();
    widget.onToggleComplete?.call();
  }

  void _handleSwipeNote() {
    HapticFeedback.lightImpact();
    widget.onAddNote?.call();
  }

  void _showOptionsMenu() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                task.isCompleted ? Icons.undo : Icons.check_circle,
                color: Colors.green,
              ),
              title: Text(task.isCompleted ? 'Mark as incomplete' : 'Mark as complete'),
              onTap: () {
                Navigator.pop(context);
                widget.onToggleComplete?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment, color: Colors.blue),
              title: const Text('Add note / Tag someone'),
              onTap: () {
                Navigator.pop(context);
                widget.onAddNote?.call();
              },
            ),
            if (!task.isCompleted) ...[
              ListTile(
                leading: Icon(
                  widget.isOwnedByMe ? Icons.person_off : Icons.person_add,
                  color: Colors.purple,
                ),
                title: Text(widget.isOwnedByMe ? 'Release task' : "I'll take this"),
                onTap: () {
                  Navigator.pop(context);
                  widget.onTakeOwnership?.call();
                },
              ),
              if (widget.onSnooze != null)
                ListTile(
                  leading: const Icon(Icons.snooze, color: Colors.orange),
                  title: const Text('Snooze to tomorrow'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSnooze?.call();
                  },
                ),
            ],
            if (widget.onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete task'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = task.isOverdue;

    return GestureDetector(
      onHorizontalDragStart: (_) {
        setState(() => _isDragging = true);
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent += details.delta.dx;
          _dragExtent = _dragExtent.clamp(-100.0, 100.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragExtent < -60) {
          // Swipe left - complete
          _handleSwipeComplete();
        } else if (_dragExtent > 60) {
          // Swipe right - add note
          _handleSwipeNote();
        }
        setState(() {
          _dragExtent = 0;
          _isDragging = false;
        });
      },
      onLongPress: _showOptionsMenu,
      child: Stack(
        children: [
          // Background indicators
          Positioned.fill(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Right swipe indicator (notes)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        children: [
                          Icon(Icons.comment, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text('Note', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  // Left swipe indicator (complete)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            task.isCompleted ? 'Undo' : 'Done',
                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(task.isCompleted ? Icons.undo : Icons.check_circle, color: Colors.green[700]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Foreground card
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: _isDragging ? 4 : 1,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Animated Checkbox
                      AnimatedCheckbox(
                        isChecked: task.isCompleted,
                        onTap: () => widget.onToggleComplete?.call(),
                        activeColor: task.isCompleted ? AppColors.success : AppColors.primary,
                      ),
                      const SizedBox(width: 12),

                      // Task content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted ? Colors.grey : null,
                              ),
                            ),
                            if (task.description != null &&
                                task.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Show completed by info for completed tasks
                            if (task.isCompleted && task.completedAt != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formatCompletedInfo(task),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Due date with overdue badge
                                if (task.dueDate != null) ...[
                                  if (isOverdue) ...[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: isOverdue ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDueDate(task.dueDate!, task.duePeriod),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isOverdue ? AppColors.error : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight:
                                          isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],

                                // Assigned to
                                if (task.assignedToName != null) ...[
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.assignedToName!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],

                                const Spacer(),

                                // Recurring indicator
                                if (task.isRecurring) ...[
                                  Icon(
                                    Icons.repeat,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Priority indicator
                                if (task.priority == TaskPriority.high) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'High',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Chevron
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompletedInfo(Task task) {
    final completedBy = task.completedByName ?? 'Someone';
    final completedAt = _formatCompletedAt(task.completedAt!);
    return 'Completed by $completedBy at $completedAt';
  }

  String _formatCompletedAt(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    final timeStr = DateFormat('h:mm a').format(date).toLowerCase();

    if (dateDay == today) {
      return '$timeStr today';
    } else if (dateDay == yesterday) {
      return '$timeStr yesterday';
    } else {
      final month = DateFormat('MMM').format(date);
      final day = date.day;
      return '$timeStr $month ${_ordinal(day)}';
    }
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  String _formatDueDate(DateTime dueDate, DuePeriod? period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    String dateStr;
    if (dueDay == today) {
      dateStr = 'Today';
    } else if (dueDay == tomorrow) {
      dateStr = 'Tomorrow';
    } else if (dueDay.isBefore(today)) {
      dateStr = 'Overdue';
    } else if (dueDay.difference(today).inDays < 7) {
      dateStr = DateFormat('EEEE').format(dueDate); // Day name
    } else {
      dateStr = DateFormat('MMM d').format(dueDate);
    }

    if (period != null) {
      final periodStr = period.name[0].toUpperCase() + period.name.substring(1);
      return '$dateStr, $periodStr';
    }

    return dateStr;
  }
}
