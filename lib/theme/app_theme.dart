import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    final bodyText = GoogleFonts.dmSansTextTheme(
      Typography.blackMountainView.apply(
        bodyColor: CirclePulseColors.cocoa,
        displayColor: CirclePulseColors.cocoa,
      ),
    );
    final display = GoogleFonts.sourceSerif4TextTheme(bodyText);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CirclePulseColors.cream,
      textTheme: bodyText.copyWith(
        displayLarge: display.displayLarge,
        displayMedium: display.displayMedium,
        displaySmall: display.displaySmall,
        headlineLarge: display.headlineLarge,
        headlineMedium: display.headlineMedium,
        headlineSmall: display.headlineSmall,
        titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: CirclePulseColors.cocoa,
        titleTextStyle: GoogleFonts.sourceSerif4(
          color: CirclePulseColors.cocoa,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
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
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
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
    );
  }
}
