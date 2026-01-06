import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class LoadingAnimation extends StatefulWidget {
  final String? message;
  final bool showMessage;

  const LoadingAnimation({
    super.key,
    this.message,
    this.showMessage = true,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;

  final List<String> _loadingMessages = [
    'Getting things ready...',
    'Loading your tasks...',
    'Almost there...',
    'Organizing your day...',
    'Syncing with household...',
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = math.Random();
    final message = widget.message ?? _loadingMessages[random.nextInt(_loadingMessages.length)];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated logo/icon
          AnimatedBuilder(
            animation: Listenable.merge([_rotationController, _bounceAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating ring
                    Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _ArcPainter(
                            color: AppColors.primary,
                            progress: 0.3,
                          ),
                        ),
                      ),
                    ),
                    // Inner D logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'D',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (widget.showMessage) ...[
            const SizedBox(height: 24),
            // Animated loading text
            FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_fadeController),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ArcPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Simple inline loader for buttons
class ButtonLoader extends StatefulWidget {
  final Color? color;

  const ButtonLoader({super.key, this.color});

  @override
  State<ButtonLoader> createState() => _ButtonLoaderState();
}

class _ButtonLoaderState extends State<ButtonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = math.sin((_controller.value + delay) * math.pi * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (widget.color ?? Colors.white).withValues(alpha: 0.5 + value * 0.5),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// Task completion celebration animation
class CompletionCelebration extends StatefulWidget {
  final VoidCallback? onComplete;

  const CompletionCelebration({super.key, this.onComplete});

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward().then((_) => widget.onComplete?.call());
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
        return Transform.scale(
          scale: 1 + (_controller.value * 0.3),
          child: Opacity(
            opacity: 1 - _controller.value,
            child: Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 48,
            ),
          ),
        );
      },
    );
  }
}
