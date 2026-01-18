import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/profile_avatar_service.dart';

/// A reusable member avatar widget showing initials or image.
///
/// Used in task lists, household info, workload views, etc.
/// Handles both external URLs (like Google profile pics) and
/// internal storage paths (which require signed URLs).
class MemberAvatar extends StatefulWidget {
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

  @override
  State<MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<MemberAvatar> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveAvatarUrl();
  }

  @override
  void didUpdateWidget(MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _resolveAvatarUrl();
    }
  }

  Future<void> _resolveAvatarUrl() async {
    debugPrint('MemberAvatar: avatarUrl=${widget.avatarUrl}');

    if (widget.avatarUrl == null) {
      setState(() => _resolvedUrl = null);
      return;
    }

    String? url;

    // If it's already a URL (http/https), use it directly
    if (widget.avatarUrl!.startsWith('http')) {
      debugPrint('MemberAvatar: Using direct URL');
      url = widget.avatarUrl;
    } else {
      // It's a storage path - get signed URL
      debugPrint('MemberAvatar: Getting signed URL for storage path');
      url = await ProfileAvatarService.getSignedUrl(widget.avatarUrl!);
    }

    if (url != null && mounted) {
      // Precache the image to force it to load
      try {
        debugPrint('MemberAvatar: Precaching image: $url');
        await precacheImage(NetworkImage(url), context);
        debugPrint('MemberAvatar: Image precached successfully');
      } catch (e) {
        debugPrint('MemberAvatar: Precache error: $e');
      }

      if (mounted) {
        setState(() => _resolvedUrl = url);
      }
    }
  }

  String get _initials {
    if (widget.displayName == null || widget.displayName!.isEmpty) return '?';
    final parts = widget.displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.displayName![0].toUpperCase();
  }

  Widget _buildInitials(Color bgColor, Color fgColor) {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: fgColor,
            fontWeight: FontWeight.bold,
            fontSize: widget.radius * 0.8,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? AppColors.primary.withValues(alpha: 0.15);
    final fgColor = widget.foregroundColor ?? AppColors.primary;

    Widget avatar;

    if (_resolvedUrl != null) {
      // Use Container with DecorationImage for web compatibility
      avatar = Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          image: DecorationImage(
            image: NetworkImage(_resolvedUrl!),
            fit: BoxFit.cover,
            onError: (error, stackTrace) {
              debugPrint('MemberAvatar: Image load error: $error');
            },
          ),
        ),
      );
    } else {
      avatar = _buildInitials(bgColor, fgColor);
    }

    if (!widget.showOnlineIndicator) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: widget.radius * 0.5,
            height: widget.radius * 0.5,
            decoration: BoxDecoration(
              color: widget.isOnline ? AppColors.success : Colors.grey,
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
