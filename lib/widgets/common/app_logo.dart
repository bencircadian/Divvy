import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// A typographic logo for the Divvy app.
/// Inspired by clean, modern wordmark logos like Waterstones and Expo.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 48,
    this.showTagline = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? (isDark ? AppColors.primaryDarkMode : AppColors.primary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Typographic logo: stylized "divvy" wordmark
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Stylized "D" lettermark in a rounded square
            Container(
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
            ),
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
        ),
        if (showTagline) ...[
          SizedBox(height: size * 0.25),
          Text(
            'keep the peace, split the work',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// A compact icon-only version of the logo for app bars, etc.
class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogoIcon({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? (isDark ? AppColors.primaryDarkMode : AppColors.primary);

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
