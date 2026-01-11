import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// A reusable detail row showing icon + label + value pattern.
///
/// Used extensively in task detail screens, settings, info displays.
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final FontWeight? valueFontWeight;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.valueFontWeight,
    this.trailing,
    this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: valueColor,
                    fontWeight: valueFontWeight,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }

    if (showDivider) {
      return Column(
        children: [
          content,
          Divider(height: 1, indent: AppSpacing.xxl),
        ],
      );
    }

    return content;
  }
}

/// A compact inline detail showing icon + value only.
class DetailChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;
  final double iconSize;

  const DetailChip({
    super.key,
    required this.icon,
    required this.value,
    this.color,
    this.iconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: effectiveColor),
        SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(color: effectiveColor),
        ),
      ],
    );
  }
}
