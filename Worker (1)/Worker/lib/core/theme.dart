import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Pitch-deck card/main teal — splash and login backgrounds.
  static const Color splash = Color(0xFFAEDDE3);

  /// Deep teal — buttons, icons, active nav, logo mark.
  static const Color primary = Color(0xFF17707D);
  static const Color primaryDark = Color(0xFF12525C);

  /// Light teal wash for chips, icon tiles, and selected states on white.
  static const Color primarySoft = Color(0xFFD7F0F3);
  static const Color accent = Color(0xFF17707D);
  static const Color accentSoft = Color(0xFFD7F0F3);

  /// Headings on teal surfaces.
  static const Color headingOnTeal = Color(0xFF12525C);

  /// Secondary text on teal surfaces.
  static const Color mutedOnTeal = Color(0xFF3F7078);

  /// Body text on white surfaces.
  static const Color navy = Color(0xFF1A1A1A);
  static const Color link = Color(0xFF17707D);
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD4E4E7);
  static const Color muted = Color(0xFF3F7078);
  static const Color navInactive = Color(0xFF9AA8AB);
  static const Color fieldFill = Color(0xFFEEF7F8);
  static const Color error = Color(0xFFB42318);
  static const Color errorSoft = Color(0xFFFEECEC);
  static const Color success = Color(0xFF17707D);
  static const Color successSoft = Color(0xFFD7F0F3);
  static const Color warning = Color(0xFF9A5B12);
  static const Color warningSoft = Color(0xFFF8EEDC);
  static const Color starFilled = Color(0xFFF5A623);
  static const Color starEmpty = Color(0xFFD9D9D9);
  static const Color shimmerBase = Color(0xFFE4EEF0);
  static const Color shimmerHighlight = Color(0xFFF7FBFC);

  /// Aliases so existing worker screens compile against the shared palette.
  static const Color canvas = background;
  static const Color surface = card;
  static const Color ink = navy;
  static const Color line = border;
  static const Color danger = error;
  static const Color accentDark = primaryDark;
  static const Color teal = primary;
  static const Color tealDark = primaryDark;
  static const Color tealSoft = primarySoft;
  static const Color gold = warning;
  static const Color goldSoft = warningSoft;
}

class AppRadii {
  AppRadii._();

  static const double card = 16;
  static const double sheet = 24;
  static const double button = 10;
  static const double field = 10;
  static const double pill = 99;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.headingOnTeal,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.navy,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    final radius = BorderRadius.circular(AppRadii.button);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.navy),
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(color: Color(0xFF8AA3A7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.card,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        elevation: 0,
        height: 68,
        indicatorColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.navInactive,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.navInactive,
            size: 24,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 24),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }
}
