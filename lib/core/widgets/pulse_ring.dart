import 'package:flutter/material.dart';
import '../animations/animation_constants.dart';
import '../theme/app_colors.dart';

class PulseRing extends StatefulWidget {
  final double size;
  final Color color;
  final Widget? child;
  final bool isPulsing;

  const PulseRing({
    super.key,
    required this.size,
    this.color = AppColors.signal,
    this.child,
    this.isPulsing = true,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimDuration.pulse,
    );
    if (widget.isPulsing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isPulsing)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.size * 1.5, widget.size * 1.5),
                  painter: _PulsePainter(
                    progress: _controller.value,
                    color: widget.color,
                    baseRadius: widget.size / 2,
                  ),
                );
              },
            ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double baseRadius;

  _PulsePainter({
    required this.progress,
    required this.color,
    required this.baseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Wave 1
    final radius1 = baseRadius + (baseRadius * 0.45 * progress);
    final opacity1 = (1.0 - progress).clamp(0.0, 0.65);
    final paint1 = Paint()
      ..color = color.withOpacity(opacity1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius1, paint1);

    // Wave 2 (delayed offset)
    final progress2 = (progress + 0.5) % 1.0;
    final radius2 = baseRadius + (baseRadius * 0.45 * progress2);
    final opacity2 = (1.0 - progress2).clamp(0.0, 0.45);
    final paint2 = Paint()
      ..color = color.withOpacity(opacity2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius2, paint2);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
