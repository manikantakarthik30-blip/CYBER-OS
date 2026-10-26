import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.void_black,
      canvasColor: AppColors.void_black,
      cardColor: AppColors.abyss,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.signal,
        secondary: AppColors.signal,
        surface: AppColors.surface,
        error: AppColors.critical,
        onPrimary: AppColors.void_black,
        onSecondary: AppColors.void_black,
        onSurface: AppColors.text_primary,
        onError: AppColors.text_primary,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display,
        headlineMedium: AppTypography.headline,
        titleMedium: AppTypography.subheadline,
        bodyMedium: AppTypography.body,
        labelSmall: AppTypography.label,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.signal_dim),
        radius: const Radius.circular(2),
        thickness: WidgetStateProperty.all(4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.text_ghost,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
