import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// CYBER_OS Typography System
/// Primary font: Rajdhani (Headers & Displays)
/// Secondary font: JetBrains Mono (Body, Code, Labels, Logs)
class AppTypography {
  // Display — Rajdhani Bold — used for score numbers, hero text
  static TextStyle display = GoogleFonts.rajdhani(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    color: AppColors.text_primary,
    height: 1.0,
  );

  // Headline — Rajdhani SemiBold — screen titles
  static TextStyle headline = GoogleFonts.rajdhani(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.text_primary,
  );

  // Subheadline — Rajdhani SemiBold
  static TextStyle subheadline = GoogleFonts.rajdhani(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.text_primary,
  );

  // Label — JetBrains Mono — module names, status tags, file paths
  static TextStyle label = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.text_secondary,
  );

  // Body — JetBrains Mono — vulnerability descriptions, scan logs
  static TextStyle body = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.3,
    color: AppColors.text_secondary,
    height: 1.6,
  );

  // Code — JetBrains Mono — file paths, code snippets
  static TextStyle code = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    color: AppColors.signal,
    letterSpacing: 0.5,
  );

  // Terminal / Micro — JetBrains Mono
  static TextStyle terminal = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.text_secondary,
    height: 1.4,
  );
}
