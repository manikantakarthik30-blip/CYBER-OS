import 'package:flutter/material.dart';

/// CYBER_OS Exact Color Tokens
/// Strict rule: Never use pure white (#FFFFFF), pure black (#000000), or generic Material blue.
class AppColors {
  // Base
  static const Color void_black = Color(0xFF040810); // deepest bg
  static const Color abyss = Color(0xFF070D1A); // card bg
  static const Color trench = Color(0xFF0D1525); // elevated surface
  static const Color surface = Color(0xFF111D33); // interactive surface

  // Accent — Cold Cyan (NOT generic green)
  static const Color signal = Color(0xFF00D4FF); // primary action
  static const Color signal_dim = Color(0x3300D4FF); // signal at 20% opacity
  static const Color signal_glow = Color(0x1500D4FF); // signal at 8% opacity

  // Severity
  static const Color critical = Color(0xFFFF2D55); // critical threats
  static const Color critical_dim = Color(0x20FF2D55);
  static const Color high = Color(0xFFFF6B2D); // high severity
  static const Color high_dim = Color(0x20FF6B2D);
  static const Color medium = Color(0xFFFFCC00); // medium severity
  static const Color medium_dim = Color(0x20FFCC00);
  static const Color safe = Color(0xFF00FF94); // safe / pass
  static const Color safe_dim = Color(0x2000FF94);

  // Text
  static const Color text_primary = Color(0xFFE8F4FF);
  static const Color text_secondary = Color(0xFF6B8BAE);
  static const Color text_ghost = Color(0xFF2A3F5C);
}
