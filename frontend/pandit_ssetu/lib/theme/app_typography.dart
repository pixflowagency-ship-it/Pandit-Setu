import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Design System — Typography Scale
class AppTypography {
  static const List<String> sansSerifFallback = [
    'Lato',
    'Noto Sans',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    fontFamilyFallback: sansSerifFallback,
  );

  static const TextStyle sacredDevanagari = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    fontStyle: FontStyle.normal,
    fontFamilyFallback: [
      'Noto Sans Devanagari',
      'Mukta',
      'Noto Sans',
      'sans-serif',
    ],
  );
}
