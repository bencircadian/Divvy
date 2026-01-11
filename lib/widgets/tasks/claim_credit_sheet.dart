import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../models/task_contributor.dart';
import 'contributor_chips.dart';

/// Bottom sheet for claiming credit on a completed task.
class ClaimCreditSheet extends StatefulWidget {
  final Task task;
  final List<TaskContributor> contributors;
  final String currentUserId;
  final bool hasClaimedCredit;
  final Future<bool> Function(String? note) onClaimCredit;
  final Future<bool> Function() onRemoveCredit;

  const ClaimCreditSheet({
    super.key,
    required this.task,
    required this.contributors,
    required this.currentUserId,
    required this.hasClaimedCredit,
    required this.onClaimCredit,
    required this.onRemoveCredit,
  });

  @override
  State<ClaimCreditSheet> createState() => _ClaimCreditSheetState();
}

class _ClaimCreditSheetState extends State<ClaimCreditSheet> {
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill note if user already has one
    final existingContribution = widget.contributors
        .where((c) => c.userId == widget.currentUserId)
        .firstOrNull;
    if (existingContribution?.contributionNote != null) {
      _noteController.text = existingContribution!.contributionNote!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleClaimCredit() async {
    setState(() => _isLoading = true);
    try {
      final note = _noteController.text.trim();
      final success = await widget.onClaimCredit(note.isEmpty ? null : note);
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRemoveCredit() async {
    setState(() => _isLoading = true);
    try {
      final success = await widget.onRemoveCredit();
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            widget.hasClaimedCredit ? 'Your Contribution' : 'Claim Credit',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.sm),

          // Task title
          Text(
            widget.task.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Current contributors
          if (widget.contributors.isNotEmpty) ...[
            Text(
              'Contributors',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.contributors.map((contributor) {
                final isCurrentUser = contributor.userId == widget.currentUserId;
                return ContributorDetailChip(
                  contributor: contributor,
                  showRemove: isCurrentUser && widget.hasClaimedCredit,
                  onRemove: isCurrentUser ? _handleRemoveCredit : null,
                );
              }).toList(),
            ),
            SizedBox(height: AppSpacing.lg),
          ],

          // Contribution note input
          if (!widget.hasClaimedCredit || widget.contributors.any((c) => c.userId == widget.currentUserId)) ...[
            Text(
              'Add a note (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'What did you help with?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                contentPadding: EdgeInsets.all(AppSpacing.md),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: AppSpacing.lg),
          ],

          // Action buttons
          if (!widget.hasClaimedCredit)
            FilledButton.icon(
              onPressed: _isLoading ? null : _handleClaimCredit,
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.add),
              label: const Text('Claim Credit'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleRemoveCredit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.error,
                            ),
                          )
                        : const Text('Remove Credit'),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),

          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
