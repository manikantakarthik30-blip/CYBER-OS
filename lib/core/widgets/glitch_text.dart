import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool animateOnEntry;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.animateOnEntry = true,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glitchAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _glitchAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.animateOnEntry) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant GlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? const TextStyle(color: AppColors.text_primary);

    return AnimatedBuilder(
      animation: _glitchAnim,
      builder: (context, child) {
        final factor = _glitchAnim.value;
        if (factor <= 0.01) {
          return Text(widget.text, style: baseStyle);
        }

        return Stack(
          children: [
            // Layer 2: Offset Signal (Cyan)
            Transform.translate(
              offset: Offset(3.0 * factor, 0),
              child: Text(
                widget.text,
                style: baseStyle.copyWith(
                  color: AppColors.signal.withOpacity(0.45 * factor),
                ),
              ),
            ),
            // Layer 3: Offset Critical (Red)
            Transform.translate(
              offset: Offset(-2.0 * factor, 0),
              child: Text(
                widget.text,
                style: baseStyle.copyWith(
                  color: AppColors.critical.withOpacity(0.35 * factor),
                ),
              ),
            ),
            // Layer 1: Base text
            Text(widget.text, style: baseStyle),
          ],
        );
      },
    );
  }
}
