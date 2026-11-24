import 'package:flutter/material.dart';

class AppColors {
  // Unified Brand Palette (aligned with iShower Portal Web)
  static const Color primary = Color(0xFF0878E9);
  static const Color primaryDark = Color(0xFF0661BE);
  static const Color primaryLight = Color(0xFF1599F5);
  static const Color navy = Color(0xFF0F1E36);
  static const Color accentGold = Color(0xFFD97706);

  // Clean Light Mode (Default — aligned with Portal Web)
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEEF2F7);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Sleek Dark Mode (Deep Slate Navy)
  static const Color background = Color(0xFF0B1220);
  static const Color cardBackground = Color(0xFF131E32);
  static const Color surface = Color(0xFF18263E);
  static const Color cardSurface = Color(0xFF1E2E4A);
  static const Color border = Color(0xFF233552);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Interactive Blue Accents (Light & Dark accessible)
  static const Color buttonBlue = Color(0xFF0878E9);
  static const Color buttonSky = Color(0xFF38BDF8);
  static const Color buttonCyan = Color(0xFF38BDF8);
  static const Color secondary = Color(0xFFD97706);
  static const Color accent = Color(0xFFD97706);

  // Semantic Status Colors
  static const Color statusAvailable = Color(0xFF16A34A);
  static const Color statusAvailableBackground = Color(0x1F16A34A);
  static const Color statusBusy = Color(0xFFDC2626);
  static const Color statusBusyBackground = Color(0x1FDC2626);
  static const Color statusCleaning = Color(0xFFD97706);
  static const Color statusCleaningBackground = Color(0x1FD97706);

  // Cohesive Brand Gradients
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF0878E9), Color(0xFF1599F5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF0754B2), Color(0xFF0878E9), Color(0xFF1599F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = buttonGradient;
}
