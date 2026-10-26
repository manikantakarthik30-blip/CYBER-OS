import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedParticleBackground extends StatefulWidget {
  final Widget child;
  const AnimatedParticleBackground({super.key, required this.child});

  @override
  State<AnimatedParticleBackground> createState() =>
      _AnimatedParticleBackgroundState();
}

class _AnimatedParticleBackgroundState extends State<AnimatedParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 40; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3.5 + 1.0,
          speed: _random.nextDouble() * 0.2 + 0.05,
          opacity: _random.nextDouble() * 0.6 + 0.2,
          color: i % 3 == 0
              ? const Color(0xFF6366F1)
              : i % 3 == 1
              ? const Color(0xFF06B6D4)
              : const Color(0xFFD946EF),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF090D16),
                  Color(0xFF0F172A),
                  Color(0xFF060913),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  blurRadius: 180,
                  spreadRadius: 80,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.18),
                  blurRadius: 200,
                  spreadRadius: 90,
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final yPos = (particle.y - (progress * particle.speed)) % 1.0;
      final offset = Offset(particle.x * size.width, yPos * size.height);

      paint.color = particle.color.withValues(alpha: particle.opacity);
      canvas.drawCircle(offset, particle.size, paint);

      paint.color = particle.color.withValues(alpha: particle.opacity * 0.3);
      canvas.drawCircle(offset, particle.size * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
