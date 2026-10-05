import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// IMPACT-365 brand colors.
/// Core palette: deep purple #3B1E7B, gold #D4AF37, warm white #F9F9F6.
/// The other shades are derived from those three.
class AppColors {
  // Core palette
  static const deepPurple = Color(0xFF3B1E7B);
  static const gold = Color(0xFFD4AF37);
  static const warmWhite = Color(0xFFF9F9F6);

  // Shades used across the UI
  static const purple = deepPurple;
  static const purpleDark = Color(0xFF26124F);
  static const purpleLight = Color(0xFF5B3BA3);
  static const lavender = Color(0xFFEEEAF6);
  static const goldLight = Color(0xFFEAD58C);
  static const goldDark = Color(0xFFA8871F);
  static const cream = warmWhite;
  static const beige = Color(0xFFF2EFE7);
  static const ink = Color(0xFF1C1433);
  static const muted = Color(0xFF6B6680);
  static const border = Color(0xFFE6E3DA);
  static const danger = Color(0xFFC0392B);
  static const shadow = Color(0x0F3B1E7B);

  static const purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleDark, purple, purpleLight],
  );

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFE0BF55), Color(0xFFBF9A2A)],
  );

  static const sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [purpleDark, deepPurple, Color(0xFF7A4E8C), Color(0xFFD4AF37)],
    stops: [0, 0.35, 0.75, 1],
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      secondary: AppColors.gold,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  final text = GoogleFonts.outfitTextTheme(
    base.textTheme,
  ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.purple,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: AppColors.purple),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: text.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.purple
            : AppColors.border,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.purple,
    ),
  );
}
