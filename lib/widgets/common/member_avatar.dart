import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// A reusable member avatar widget showing initials or image.
///
/// Used in task lists, household info, workload views, etc.
class MemberAvatar extends StatelessWidget {
  final String? displayName;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showOnlineIndicator;
  final bool isOnline;

  const MemberAvatar({
    super.key,
    this.displayName,
    this.avatarUrl,
    this.radius = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  String get _initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? AppColors.primary.withValues(alpha: 0.15);
    final fgColor = foregroundColor ?? AppColors.primary;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              _initials,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );

    if (!showOnlineIndicator) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A row widget showing member avatar with name and optional info.
class MemberRow extends StatelessWidget {
  final String? displayName;
  final String? avatarUrl;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double avatarRadius;

  const MemberRow({
    super.key,
    this.displayName,
    this.avatarUrl,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.avatarRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            MemberAvatar(
              displayName: displayName,
              avatarUrl: avatarUrl,
              radius: avatarRadius,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName ?? 'Unknown',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
