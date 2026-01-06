import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class AnimatedCheckbox extends StatefulWidget {
  final bool isChecked;
  final VoidCallback? onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedCheckbox({
    super.key,
    required this.isChecked,
    this.onTap,
    this.size = 28,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fillAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);

    _fillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    if (widget.isChecked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      if (widget.isChecked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.primary;
    final inactiveColor = widget.inactiveColor ?? Colors.grey[400]!;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.lerp(inactiveColor, activeColor, _fillAnimation.value)!,
                  width: 2,
                ),
                color: Color.lerp(
                  Colors.transparent,
                  activeColor,
                  _fillAnimation.value,
                ),
              ),
              child: Center(
                child: Transform.scale(
                  scale: _checkAnimation.value,
                  child: Icon(
                    Icons.check,
                    size: widget.size * 0.6,
                    color: Colors.white.withValues(alpha: _checkAnimation.value),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Success glow effect for completed tasks
class SuccessGlow extends StatefulWidget {
  final Widget child;
  final bool showGlow;
  final VoidCallback? onGlowComplete;

  const SuccessGlow({
    super.key,
    required this.child,
    this.showGlow = false,
    this.onGlowComplete,
  });

  @override
  State<SuccessGlow> createState() => _SuccessGlowState();
}

class _SuccessGlowState extends State<SuccessGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onGlowComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(SuccessGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGlow && !oldWidget.showGlow) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _glowAnimation.value > 0
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: _glowAnimation.value),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }
}
