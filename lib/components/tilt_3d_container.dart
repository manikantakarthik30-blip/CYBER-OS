import 'package:flutter/material.dart';

class Tilt3DContainer extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle;
  final double borderRadius;
  final bool enableGlare;

  const Tilt3DContainer({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.15,
    this.borderRadius = 28.0,
    this.enableGlare = true,
  });

  @override
  State<Tilt3DContainer> createState() => _Tilt3DContainerState();
}

class _Tilt3DContainerState extends State<Tilt3DContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<Offset> _tiltAnimation;
  Offset _currentTilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tiltAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _updateTilt(Offset localPosition, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final normalizedX = (localPosition.dx / size.width) * 2 - 1;
    final normalizedY = (localPosition.dy / size.height) * 2 - 1;

    setState(() {
      _currentTilt = Offset(
        normalizedX.clamp(-1.0, 1.0),
        normalizedY.clamp(-1.0, 1.0),
      );
    });
  }

  void _resetTilt() {
    _tiltAnimation =
        Tween<Offset>(begin: _currentTilt, end: Offset.zero).animate(
          CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
        )..addListener(() {
          setState(() {
            _currentTilt = _tiltAnimation.value;
          });
        });
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // 3D Perspective Matrix Transformation
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-_currentTilt.dy * widget.maxTiltAngle)
          ..rotateY(_currentTilt.dx * widget.maxTiltAngle);

        return MouseRegion(
          onHover: (event) => _updateTilt(event.localPosition, size),
          onExit: (_) => _resetTilt(),
          child: GestureDetector(
            onPanUpdate: (details) => _updateTilt(details.localPosition, size),
            onPanEnd: (_) => _resetTilt(),
            onPanCancel: () => _resetTilt(),
            child: Transform(
              alignment: FractionalOffset.center,
              transform: matrix,
              child: Stack(
                children: [
                  widget.child,
                  // Dynamic 3D Specular Glare
                  if (widget.enableGlare)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  -_currentTilt.dx * 1.5,
                                  -_currentTilt.dy * 1.5,
                                ),
                                radius: 1.2,
                                colors: [
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0.02),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
