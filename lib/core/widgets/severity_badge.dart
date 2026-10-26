import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SeverityBadge extends StatelessWidget {
  final String severity; // CRITICAL, HIGH, MEDIUM, LOW, SAFE, PASS, FAIL
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final (bg, text, border) = _getColors(severity.toUpperCase());

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        severity.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: text,
        ),
      ),
    );
  }

  (Color, Color, Color) _getColors(String sev) {
    switch (sev) {
      case 'CRITICAL':
      case 'FAIL':
        return (
          AppColors.critical_dim,
          AppColors.critical,
          AppColors.critical.withOpacity(0.6),
        );
      case 'HIGH':
        return (
          AppColors.high_dim,
          AppColors.high,
          AppColors.high.withOpacity(0.6),
        );
      case 'MEDIUM':
      case 'WARNING':
        return (
          AppColors.medium_dim,
          AppColors.medium,
          AppColors.medium.withOpacity(0.6),
        );
      case 'LOW':
      case 'SAFE':
      case 'PASS':
      case 'SECURE':
      default:
        return (
          AppColors.safe_dim,
          AppColors.safe,
          AppColors.safe.withOpacity(0.6),
        );
    }
  }
}
