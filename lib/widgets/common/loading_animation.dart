import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class LoadingAnimation extends StatefulWidget {
  final String? message;
  final bool showMessage;
  final bool fullScreen;

  const LoadingAnimation({
    super.key,
    this.message,
    this.showMessage = true,
    this.fullScreen = false,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;
  int _messageIndex = 0;
  Timer? _messageTimer;

  final List<String> _loadingMessages = [
    'Getting things ready',
    'Loading your tasks',
    'Almost there',
    'Organizing your day',
    'Syncing with household',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Cycle through messages every 3 seconds
    if (widget.message == null) {
      _messageIndex = math.Random().nextInt(_loadingMessages.length);
      _startMessageCycle();
    }
  }

  void _startMessageCycle() {
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message ?? _loadingMessages[_messageIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Elegant animated logo
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _rotationController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.15),
                              primaryColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      // Rotating track
                      CustomPaint(
                        size: const Size(100, 100),
                        painter: _ModernSpinnerPainter(
                          color: primaryColor,
                          progress: _rotationController.value,
                          trackColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                      // Center logo
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    isDark
                                        ? primaryColor.withValues(alpha: 0.8)
                                        : Color.lerp(primaryColor, Colors.black, 0.15)!,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'd',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          if (widget.showMessage) ...[
            const SizedBox(height: 40),
            // Animated loading text with dots
            AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                final dotCount = (_dotsController.value * 3).floor() + 1;
                final dots = '.' * dotCount;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '$message$dots',
                    key: ValueKey('$message-$dotCount'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(child: content),
      );
    }

    return content;
  }
}

class _ModernSpinnerPainter extends CustomPainter {
  final Color color;
  final double progress;
  final Color trackColor;

  _ModernSpinnerPainter({
    required this.color,
    required this.progress,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.3),
        color,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(progress * math.pi * 2 - math.pi / 2),
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      progress * math.pi * 2 - math.pi / 2,
      math.pi * 0.8,
      false,
      arcPaint,
    );

    // Draw leading dot
    final dotAngle = progress * math.pi * 2 - math.pi / 2 + math.pi * 0.8;
    final dotX = center.dx + radius * math.cos(dotAngle);
    final dotY = center.dy + radius * math.sin(dotAngle);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
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
