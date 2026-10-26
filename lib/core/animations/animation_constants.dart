import 'package:flutter/animation.dart';

class AnimDuration {
  static const micro = Duration(milliseconds: 120); // instant feedback
  static const fast = Duration(milliseconds: 250); // button press response
  static const normal = Duration(milliseconds: 400); // screen transitions
  static const slow = Duration(milliseconds: 700); // reveal animations
  static const cinematic = Duration(milliseconds: 1200); // hero entrance
  static const pulse = Duration(milliseconds: 2000); // idle pulse loop
}

class AnimCurve {
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const bounce = Curves.elasticOut;
  static const sharp = Curves.easeInOutQuart;
  static const signal = Curves.easeInOutSine; // for pulse/glow loops
}
