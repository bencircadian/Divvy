import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task_history.dart';

class HistoryTimeline extends StatelessWidget {
  final List<TaskHistory> history;

  const HistoryTimeline({
    super.key,
    required this.history,
  });

  IconData _getActionIcon(TaskAction action) {
    switch (action) {
      case TaskAction.created:
        return Icons.add_circle_outline;
      case TaskAction.completed:
        return Icons.check_circle_outline;
      case TaskAction.uncompleted:
        return Icons.radio_button_unchecked;
      case TaskAction.edited:
        return Icons.edit_outlined;
      case TaskAction.assigned:
        return Icons.person_outline;
      case TaskAction.noteAdded:
        return Icons.note_add_outlined;
    }
  }

  Color _getActionColor(BuildContext context, TaskAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (action) {
      case TaskAction.created:
        return colorScheme.primary;
      case TaskAction.completed:
        return Colors.green;
      case TaskAction.uncompleted:
        return colorScheme.tertiary;
      case TaskAction.edited:
        return colorScheme.secondary;
      case TaskAction.assigned:
        return Colors.blue;
      case TaskAction.noteAdded:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No activity yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isLast = index == history.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _getActionColor(context, item.action).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getActionIcon(item.action),
                        size: 16,
                        color: _getActionColor(context, item.action),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: item.userName ?? 'Someone',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: ' ${item.actionText}'),
                                ],
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            _formatDate(item.createdAt),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
