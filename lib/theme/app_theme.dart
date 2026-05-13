import 'package:flutter/material.dart';

import '../shared/widgets/circlepulse_ui.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const seed = CirclePulseColors.clay;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: CirclePulseColors.warmSurface,
      primary: CirclePulseColors.clay,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CirclePulseColors.cream,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: CirclePulseColors.cocoa,
      ),
      cardTheme: CardThemeData(
        color: CirclePulseColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: CirclePulseColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CirclePulseColors.warmSurface,
        labelStyle: const TextStyle(color: CirclePulseColors.muted),
        hintStyle: TextStyle(
          color: CirclePulseColors.muted.withValues(alpha: 0.72),
        ),
        prefixIconColor: CirclePulseColors.clay,
        suffixIconColor: CirclePulseColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CirclePulseColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CirclePulseColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CirclePulseColors.clay, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CirclePulseColors.clay,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CirclePulseColors.cocoa,
          side: const BorderSide(color: CirclePulseColors.outline),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: CirclePulseColors.clay),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CirclePulseColors.cardAlt,
        selectedColor: CirclePulseColors.clay,
        side: const BorderSide(color: CirclePulseColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: Typography.blackMountainView.apply(
        bodyColor: CirclePulseColors.cocoa,
        displayColor: CirclePulseColors.cocoa,
      ),
    );
  }
}
