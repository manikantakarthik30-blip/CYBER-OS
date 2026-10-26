import 'package:flutter/material.dart';
import '../animations/animation_constants.dart';
import '../theme/app_colors.dart';

class CyberCard extends StatefulWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderWidth;

  const CyberCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderWidth = 1.0,
  });

  @override
  State<CyberCard> createState() => _CyberCardState();
}

class _CyberCardState extends State<CyberCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.signal_dim;
    final borderColor = _isHovered
        ? AppColors.signal_dim
        : AppColors.text_ghost.withOpacity(0.4);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AnimDuration.fast,
          curve: AnimCurve.enter,
          decoration: BoxDecoration(
            color: AppColors.abyss,
            border: Border.all(
              color: borderColor,
              width: widget.borderWidth,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.15),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                if (widget.accentColor != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 3.5,
                    child: Container(color: widget.accentColor),
                  ),
                Padding(
                  padding: widget.accentColor != null
                      ? widget.padding.add(const EdgeInsets.only(left: 3.5))
                      : widget.padding,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

