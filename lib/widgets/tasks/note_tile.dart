import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/task_note.dart';

class NoteTile extends StatelessWidget {
  final TaskNote note;
  final bool canDelete;
  final VoidCallback? onDelete;

  const NoteTile({
    super.key,
    required this.note,
    this.canDelete = false,
    this.onDelete,
  });

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (note.userName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.userName ?? 'Unknown',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatDate(note.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    padding: EdgeInsets.zero,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
