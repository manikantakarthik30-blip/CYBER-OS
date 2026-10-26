import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ScanLineOverlay extends StatefulWidget {
  final Widget child;
  final bool isScanning;

  const ScanLineOverlay({
    super.key,
    required this.child,
    this.isScanning = true,
  });

  @override
  State<ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<ScanLineOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ScanLineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    return Stack(
      children: [
        widget.child,
        if (widget.isScanning)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final top = _controller.value * constraints.maxHeight;
                      return Stack(
                        children: [
                          Positioned(
                            top: top,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.signal.withOpacity(0.0),
                                    AppColors.signal.withOpacity(0.8),
                                    AppColors.signal.withOpacity(0.0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.signal.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
