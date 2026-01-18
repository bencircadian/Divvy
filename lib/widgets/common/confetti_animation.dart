import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A simple confetti celebration animation widget.
///
/// Shows confetti particles falling from the top of the screen.
class ConfettiAnimation extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback? onComplete;
  final Duration duration;

  const ConfettiAnimation({
    super.key,
    this.isPlaying = false,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  static const List<Color> _colors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFFFFEB3B), // Yellow
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startAnimation();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  void _startAnimation() {
    _particles.clear();
    // Generate particles
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * -0.2 - 0.1,
        color: _colors[_random.nextInt(_colors.length)],
        size: 8 + _random.nextDouble() * 6,
        velocityX: _random.nextDouble() * 0.4 - 0.2,
        velocityY: 0.5 + _random.nextDouble() * 0.5,
        rotation: _random.nextDouble() * math.pi * 2,
        rotationVelocity: _random.nextDouble() * 0.2 - 0.1,
      ));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying && _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double velocityX;
  final double velocityY;
  double rotation;
  final double rotationVelocity;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationVelocity,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update particle position based on progress
      final x = (particle.x + particle.velocityX * progress) * size.width;
      final y = (particle.y + particle.velocityY * progress) * size.height;
      final rotation = particle.rotation + particle.rotationVelocity * progress * math.pi * 10;

      // Fade out towards the end
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      if (y > 0 && y < size.height && x > 0 && x < size.width) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rotation);

        final paint = Paint()
          ..color = particle.color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        // Draw a simple rectangle
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
