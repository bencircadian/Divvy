import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/appreciation.dart';

/// An animated button for sending appreciations.
class AppreciationButton extends StatefulWidget {
  final bool hasAppreciated;
  final String? reactionType;
  final int appreciationCount;
  final VoidCallback? onTap;
  final Function(String reactionType)? onLongPress;
  final bool isLoading;
  final bool compact;

  const AppreciationButton({
    super.key,
    required this.hasAppreciated,
    this.reactionType,
    this.appreciationCount = 0,
    this.onTap,
    this.onLongPress,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  State<AppreciationButton> createState() => _AppreciationButtonState();
}

class _AppreciationButtonState extends State<AppreciationButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartAnimation;

  final List<_FloatingHeart> _floatingHearts = [];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _heartAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AppreciationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasAppreciated && !oldWidget.hasAppreciated) {
      _playAppreciationAnimation();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _playAppreciationAnimation() {
    HapticFeedback.lightImpact();
    _heartController.forward(from: 0);
    _addFloatingHearts();
  }

  void _addFloatingHearts() {
    final random = Random();
    for (int i = 0; i < 5; i++) {
      setState(() {
        _floatingHearts.add(_FloatingHeart(
          key: UniqueKey(),
          emoji: Appreciation.getEmoji(widget.reactionType ?? 'thanks'),
          offsetX: (random.nextDouble() - 0.5) * 40,
          delay: Duration(milliseconds: i * 50),
          onComplete: () {
            setState(() {
              _floatingHearts.removeWhere((h) => h.key == _floatingHearts.first.key);
            });
          },
        ));
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    _showReactionPicker();
  }

  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReactionPicker(
        selectedType: widget.reactionType,
        onSelected: (type) {
          Navigator.pop(context);
          widget.onLongPress?.call(type);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final emoji = widget.hasAppreciated
        ? Appreciation.getEmoji(widget.reactionType ?? 'thanks')
        : '🙏';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Floating hearts animation
        ..._floatingHearts.map((heart) => Positioned(
              left: 0,
              bottom: 0,
              child: _FloatingHeartWidget(
                emoji: heart.emoji,
                offsetX: heart.offsetX,
                delay: heart.delay,
                onComplete: heart.onComplete,
              ),
            )),

        // Main button
        GestureDetector(
          onTapDown: widget.isLoading ? null : _onTapDown,
          onTapUp: widget.isLoading ? null : _onTapUp,
          onTapCancel: widget.isLoading ? null : _onTapCancel,
          onLongPress: widget.isLoading ? null : _onLongPress,
          child: AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _heartAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * _heartAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8 : 12,
                vertical: widget.compact ? 4 : 8,
              ),
              decoration: BoxDecoration(
                color: widget.hasAppreciated
                    ? primaryColor.withValues(alpha: 0.15)
                    : (isDark ? Colors.grey[800] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.hasAppreciated
                      ? primaryColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: widget.compact ? 16 : 20,
                      height: widget.compact ? 16 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          emoji,
                          style: TextStyle(
                            fontSize: widget.compact ? 14 : 18,
                          ),
                        ),
                        if (widget.appreciationCount > 0 && !widget.compact) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${widget.appreciationCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.hasAppreciated
                                  ? primaryColor
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingHeart {
  final Key key;
  final String emoji;
  final double offsetX;
  final Duration delay;
  final VoidCallback onComplete;

  _FloatingHeart({
    required this.key,
    required this.emoji,
    required this.offsetX,
    required this.delay,
    required this.onComplete,
  });
}

class _FloatingHeartWidget extends StatefulWidget {
  final String emoji;
  final double offsetX;
  final Duration delay;
  final VoidCallback onComplete;

  const _FloatingHeartWidget({
    required this.emoji,
    required this.offsetX,
    required this.delay,
    required this.onComplete,
  });

  @override
  State<_FloatingHeartWidget> createState() => _FloatingHeartWidgetState();
}

class _FloatingHeartWidgetState extends State<_FloatingHeartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _position;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _position = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward().then((_) => widget.onComplete());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.offsetX, _position.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReactionPicker extends StatelessWidget {
  final String? selectedType;
  final Function(String) onSelected;

  const _ReactionPicker({
    this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: Appreciation.reactionTypes.map((type) {
          final isSelected = type == selectedType;
          return GestureDetector(
            onTap: () => onSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                Appreciation.getEmoji(type),
                style: TextStyle(
                  fontSize: isSelected ? 32 : 28,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
