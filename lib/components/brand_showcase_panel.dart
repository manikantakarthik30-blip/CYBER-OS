import 'dart:math' as math;

import 'package:flutter/material.dart';

class BrandShowcasePanel extends StatefulWidget {
  const BrandShowcasePanel({super.key});

  @override
  State<BrandShowcasePanel> createState() => _BrandShowcasePanelState();
}

class _BrandShowcasePanelState extends State<BrandShowcasePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.4),
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: -_rotationController.value * 4 * math.pi,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF06B6D4)
                                  .withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.6),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              '✨ NEXT-GEN PLATFORM',
              style: TextStyle(
                color: Color(0xFF818CF8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Experience The\nNext Dimension',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Immerse yourself in our cinematic 3D workspace. Seamlessly connect, collaborate, and scale your creative vision.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
