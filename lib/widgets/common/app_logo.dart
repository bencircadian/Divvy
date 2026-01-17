import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// A logo for the Divvy app using the actual logo image.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final bool iconOnly;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showTagline = false,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with wordmark
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo icon from asset
            ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.28),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _FallbackIcon(
                  size: size,
                  isDark: isDark,
                ),
              ),
            ),
            if (!iconOnly) ...[
              SizedBox(width: size * 0.2),
              // "ivvy" text
              Text(
                'ivvy',
                style: TextStyle(
                  fontSize: size * 0.7,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[900],
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.4),
          Text(
            'Keep the peace, share the work',
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final double size;
  final bool isDark;

  const _FallbackIcon({required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(
          'd',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

/// A compact icon-only version of the logo for app bars, etc.
class AppLogoIcon extends StatelessWidget {
  final double size;

  const AppLogoIcon({
    super.key,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _FallbackIcon(
          size: size,
          isDark: isDark,
        ),
      ),
    );
  }
}
