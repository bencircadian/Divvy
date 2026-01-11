import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_theme.dart';

class LongPressAction extends StatefulWidget {
  final Widget child;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final bool enabled;
  final Duration holdDuration;

  const LongPressAction({
    super.key,
    required this.child,
    required this.actionLabel,
    required this.actionIcon,
    this.onAction,
    this.enabled = true,
    this.holdDuration = const Duration(milliseconds: 400),
  });

  @override
  State<LongPressAction> createState() => _LongPressActionState();
}

class _LongPressActionState extends State<LongPressAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _overlayAnimation;
  bool _isHolding = false;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.holdDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isHolding) {
      setState(() => _showOverlay = true);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!widget.enabled) return;
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!widget.enabled) return;

    if (_showOverlay) {
      // Action confirmed
      widget.onAction?.call();
      HapticFeedback.lightImpact();
    }

    setState(() {
      _isHolding = false;
      _showOverlay = false;
    });
    _controller.reverse();
  }

  void _onLongPressCancel() {
    setState(() {
      _isHolding = false;
      _showOverlay = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                widget.child,
                if (_overlayAnimation.value > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _overlayAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.actionIcon,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.actionLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
