import 'package:flutter/material.dart';

/// Centralized Design System — Color Palette for SARV MANGAL
/// Allows instant global rebranding without touching screen business logic.
class AppColors {
  // Primary Brand: Deep Sacred Saffron / Kesari
  static const Color primary = Color(0xFFE65100);
  static const Color primaryLight = Color(0xFFFFA726);
  static const Color primaryDark = Color(0xFFBF360C);

  // Secondary Brand: Sacred Vedic Gold / Marigold
  static const Color secondary = Color(0xFFFFB300);
  static const Color secondaryDark = Color(0xFFFF8F00);
  static const Color secondaryLight = Color(0xFFFFE082);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFFFBF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF7ECE0);
  static const Color cardBorder = Color(0xFFF0E0D0);
  static const Color divider = Color(0xFFEEDCD0);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF6B655F);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0288D1);
  static const Color infoLight = Color(0xFFE1F5FE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
