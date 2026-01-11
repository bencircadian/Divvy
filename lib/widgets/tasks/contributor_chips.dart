import 'package:flutter/material.dart';

import '../../models/task_contributor.dart';

/// Widget to display contributor avatars as overlapping chips.
class ContributorChips extends StatelessWidget {
  final List<TaskContributor> contributors;
  final double avatarSize;
  final int maxVisible;
  final VoidCallback? onTap;

  const ContributorChips({
    super.key,
    required this.contributors,
    this.avatarSize = 24,
    this.maxVisible = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (contributors.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleContributors = contributors.take(maxVisible).toList();
    final extraCount = contributors.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Overlapping avatars
          SizedBox(
            width: _calculateWidth(visibleContributors.length, extraCount > 0),
            height: avatarSize,
            child: Stack(
              children: [
                ...visibleContributors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contributor = entry.value;
                  return Positioned(
                    left: index * (avatarSize * 0.7),
                    child: _ContributorAvatar(
                      contributor: contributor,
                      size: avatarSize,
                    ),
                  );
                }),
                // Extra count badge
                if (extraCount > 0)
                  Positioned(
                    left: visibleContributors.length * (avatarSize * 0.7),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '+$extraCount',
                          style: TextStyle(
                            fontSize: avatarSize * 0.4,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (contributors.length == 1) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                contributors.first.displayName ?? 'Unknown',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateWidth(int visibleCount, bool hasExtra) {
    final count = hasExtra ? visibleCount + 1 : visibleCount;
    if (count <= 1) return avatarSize;
    return avatarSize + (count - 1) * (avatarSize * 0.7);
  }
}

class _ContributorAvatar extends StatelessWidget {
  final TaskContributor contributor;
  final double size;

  const _ContributorAvatar({
    required this.contributor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: (size - 4) / 2,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: contributor.avatarUrl != null
            ? NetworkImage(contributor.avatarUrl!)
            : null,
        child: contributor.avatarUrl == null
            ? Text(
                contributor.initials,
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
    );
  }
}

/// A chip that shows all contributors in a more detailed format.
class ContributorDetailChip extends StatelessWidget {
  final TaskContributor contributor;
  final VoidCallback? onRemove;
  final bool showRemove;

  const ContributorDetailChip({
    super.key,
    required this.contributor,
    this.onRemove,
    this.showRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: CircleAvatar(
        radius: 14,
        backgroundColor: colorScheme.primaryContainer,
        backgroundImage: contributor.avatarUrl != null
            ? NetworkImage(contributor.avatarUrl!)
            : null,
        child: contributor.avatarUrl == null
            ? Text(
                contributor.initials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
      label: Text(contributor.displayName ?? 'Unknown'),
      deleteIcon: showRemove ? const Icon(Icons.close, size: 16) : null,
      onDeleted: showRemove ? onRemove : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
