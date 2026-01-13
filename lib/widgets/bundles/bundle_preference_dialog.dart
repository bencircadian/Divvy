import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Dialog shown to users who haven't set their bundle preference yet.
/// Allows them to choose between bundled or individual task view.
class BundlePreferenceDialog extends StatefulWidget {
  const BundlePreferenceDialog({super.key});

  /// Shows the dialog and returns the user's choice (true = bundles, false = individual)
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BundlePreferenceDialog(),
    );
  }

  @override
  State<BundlePreferenceDialog> createState() => _BundlePreferenceDialogState();
}

class _BundlePreferenceDialogState extends State<BundlePreferenceDialog> {
  bool? _selectedOption;
  bool _isLoading = false;

  Future<void> _savePreference() async {
    if (_selectedOption == null) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.setBundlesPreference(_selectedOption!);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(_selectedOption);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dashboard_customize_outlined,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Title
            Text(
              'How do you want to see tasks?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              'You can change this anytime in Settings',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),

            // Option 1: Bundles enabled
            _OptionCard(
              icon: Icons.folder_outlined,
              title: 'Bundle tasks together',
              description: 'Group related tasks into bundles like "Morning Routine" or "Weekly Cleaning"',
              isSelected: _selectedOption == true,
              onTap: () => setState(() => _selectedOption = true),
            ),
            SizedBox(height: AppSpacing.sm),

            // Option 2: Individual tasks
            _OptionCard(
              icon: Icons.list_alt_outlined,
              title: 'See tasks separately',
              description: 'View all tasks individually without grouping them into bundles',
              isSelected: _selectedOption == false,
              onTap: () => setState(() => _selectedOption = false),
            ),
            SizedBox(height: AppSpacing.lg),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedOption != null && !_isLoading
                    ? _savePreference
                    : null,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
