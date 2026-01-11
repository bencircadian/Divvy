import 'package:flutter/material.dart';

/// An animated progress bar for task bundles.
class BundleProgressBar extends StatelessWidget {
  final double progress;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showPercentage;
  final Duration animationDuration;

  const BundleProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.showPercentage = false,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ??
        colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: animationDuration,
                      curve: Curves.easeInOut,
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            effectiveColor,
                            effectiveColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(height / 2),
                        boxShadow: progress > 0 ? [
                          BoxShadow(
                            color: effectiveColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ],
    );
  }
}

/// A circular progress indicator for bundles.
class BundleProgressCircle extends StatelessWidget {
  final double progress;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const BundleProgressCircle({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.size = 60,
    this.strokeWidth = 6,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ??
        colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.transparent,
            color: effectiveBackgroundColor,
          ),
          // Progress circle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return CircularProgressIndicator(
                value: value.clamp(0.0, 1.0),
                strokeWidth: strokeWidth,
                backgroundColor: Colors.transparent,
                color: effectiveColor,
                strokeCap: StrokeCap.round,
              );
            },
          ),
          // Center content
          if (child != null)
            Center(child: child),
        ],
      ),
    );
  }
}
