import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Notificador reativo de tema (Dark ou Light)
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static void toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  // TEMA ESCURO (Dark Mode Original & Otimizado)
  static ThemeData get darkTheme {
    final baseDark = ThemeData.dark();
    final monoTextTheme = GoogleFonts.robotoMonoTextTheme(baseDark.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.robotoMono().fontFamily,
      primaryColor: AppColors.buttonSky,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: monoTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.robotoMono(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.buttonSky,
        secondary: AppColors.accentGold,
        surface: AppColors.cardBackground,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF181818),
        indicatorColor: AppColors.primaryDark.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.robotoMono(
              color: AppColors.buttonCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            );
          }
          return GoogleFonts.robotoMono(
            color: Colors.grey,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.buttonCyan,
              size: 24,
            );
          }
          return const IconThemeData(
            color: Colors.grey,
            size: 24,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // TEMA CLARO (Light Mode Adaptado)
  static ThemeData get lightTheme {
    final baseLight = ThemeData.light();
    final monoTextTheme = GoogleFonts.robotoMonoTextTheme(baseLight.textTheme).apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    );

    return ThemeData(
      brightness: Brightness.light,
      fontFamily: GoogleFonts.robotoMono().fontFamily,
      primaryColor: AppColors.buttonBlue,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: monoTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: GoogleFonts.robotoMono(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.buttonBlue,
        secondary: AppColors.accentGold,
        surface: AppColors.lightCard,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        indicatorColor: AppColors.buttonSky.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.robotoMono(
              color: AppColors.buttonBlue,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            );
          }
          return GoogleFonts.robotoMono(
            color: AppColors.lightTextSecondary,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.buttonBlue,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.lightTextSecondary,
            size: 24,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
