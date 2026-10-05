import 'package:flutter/material.dart';

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

/// IMPACT-365 typography.
///
/// Inter is the app font; Source Serif 4 (italic) is used only for Bible
/// verses so Scripture stands apart from the interface.
///
/// One scale for the whole app — pick the role, not a size:
///
/// | Role          | Size/line | Weight | Used for                                  |
/// |---------------|-----------|--------|-------------------------------------------|
/// | display       | 34/40     | 700    | Hero numbers, splash name                 |
/// | headline      | 28/34     | 700    | Page heroes (welcome, onboarding, greeting)|
/// | titleLarge    | 22/28     | 600    | Screen titles                             |
/// | titleMedium   | 18/24     | 600    | Card & section headings                   |
/// | titleSmall    | 16/22     | 600    | List item titles, emphasised lines        |
/// | bodyLarge     | 16/24     | 400    | Reading text (devotions, long paragraphs) |
/// | bodyMedium    | 14/20     | 400    | Default text                              |
/// | bodyStrong    | 14/20     | 600    | Short emphasised text inside body         |
/// | bodySmall     | 13/18     | 400    | Secondary text, captions, timestamps      |
/// | labelLarge    | 16/20     | 600    | Buttons                                   |
/// | labelMedium   | 13/16     | 600    | Chips, tabs, navigation, small badges     |
/// | labelSmall    | 11/14     | 600    | Overlines, tiny badges (tracked)          |
/// | scripture     | 17/26     | 400 i  | Bible verse text (serif italic)           |
/// | scriptureLarge| 21/30     | 400 i  | Featured verse (verse of the day)         |
/// | scriptureRef  | 13/16     | 600    | Verse reference ("Jean 3:16"), usually gold|
class AppText {
  static const fontFamily = 'Inter';
  static const scriptureFamily = 'SourceSerif4';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );
  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );
  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
  );
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w600,
  );
  static const labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );
  static const scripture = TextStyle(
    fontFamily: scriptureFamily,
    fontSize: 17,
    height: 26 / 17,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
  );
  static const scriptureLarge = TextStyle(
    fontFamily: scriptureFamily,
    fontSize: 21,
    height: 30 / 21,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
  );

  static const scriptureRef = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// Material text theme built from the scale above.
  static TextTheme textTheme(Color color) => TextTheme(
    displayLarge: display.copyWith(fontSize: 44, height: 52 / 44),
    displayMedium: display.copyWith(fontSize: 38, height: 46 / 38),
    displaySmall: display,
    headlineLarge: headline.copyWith(fontSize: 32, height: 38 / 32),
    headlineMedium: headline,
    headlineSmall: headline.copyWith(fontSize: 24, height: 30 / 24),
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  ).apply(bodyColor: color, displayColor: color);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: AppText.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      secondary: AppColors.gold,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  final text = AppText.textTheme(AppColors.ink);

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppText.titleMedium.copyWith(color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: AppText.bodyMedium.copyWith(color: AppColors.muted),
      labelStyle: AppText.bodyMedium.copyWith(color: AppColors.muted),
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
        textStyle: AppText.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.purple,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: AppColors.purple),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: AppText.labelLarge,
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
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: AppText.labelMedium),
    ),
    tabBarTheme: const TabBarThemeData(
      labelStyle: AppText.labelMedium,
      unselectedLabelStyle: AppText.labelMedium,
    ),
    chipTheme: const ChipThemeData(labelStyle: AppText.labelMedium),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.purple,
      contentTextStyle: AppText.bodyMedium.copyWith(color: Colors.white),
    ),
  );
}
