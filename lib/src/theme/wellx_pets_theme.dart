import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'wellx_colors.dart';
import 'wellx_typography.dart';
import 'wellx_spacing.dart';

/// Complete Material theme for Wellx Pets "Digital Sanctuary".
///
/// No-line rule: borders are prohibited. Boundaries via tonal shifts & shadows.
class WellxPetsTheme {
  WellxPetsTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: WellxColors.primary,
          onPrimary: WellxColors.onPrimary,
          primaryContainer: WellxColors.primaryContainer,
          secondary: WellxColors.secondary,
          onSecondary: WellxColors.onPrimary,
          tertiary: WellxColors.tertiary,
          tertiaryContainer: WellxColors.tertiaryContainer,
          surface: WellxColors.surfaceContainerLowest,
          onSurface: WellxColors.onSurface,
          surfaceContainerLowest: WellxColors.surfaceContainerLowest,
          surfaceContainerLow: WellxColors.surfaceContainerLow,
          surfaceContainer: WellxColors.surfaceContainer,
          surfaceContainerHigh: WellxColors.surfaceContainerHigh,
          surfaceContainerHighest: WellxColors.surfaceContainerHighest,
          error: WellxColors.error,
          onError: WellxColors.onError,
          outline: WellxColors.outline,
          outlineVariant: WellxColors.outlineVariant,
        ),
        scaffoldBackgroundColor: WellxColors.surface,
        // No-line rule: cards have NO border, use tonal shadow instead
        cardTheme: CardThemeData(
          color: WellxColors.surfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: WellxColors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: WellxTypography.heading,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WellxColors.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: WellxColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WellxSpacing.lg,
            vertical: WellxSpacing.lg,
          ),
          hintStyle: WellxTypography.bodyText.copyWith(
            color: WellxColors.outlineVariant,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: WellxColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: WellxSpacing.xl,
              vertical: WellxSpacing.lg,
            ),
            shape: const StadiumBorder(),
            textStyle: WellxTypography.buttonLabel,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: WellxColors.primary,
            textStyle: WellxTypography.buttonLabel.copyWith(
              color: WellxColors.primary,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: WellxColors.inkPrimary,
          selectedItemColor: Colors.white,
          unselectedItemColor: WellxColors.outline,
        ),
        dividerTheme: DividerThemeData(
          color: WellxColors.outlineVariant.withValues(alpha: 0.15),
          thickness: 0,
          space: 0,
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: WellxTypography.heroDisplay,
          headlineLarge: WellxTypography.screenTitle,
          headlineMedium: WellxTypography.heading,
          titleLarge: WellxTypography.cardTitle,
          titleMedium: WellxTypography.dataNumber,
          bodyLarge: WellxTypography.inputText,
          bodyMedium: WellxTypography.bodyText,
          bodySmall: WellxTypography.captionText,
          labelLarge: WellxTypography.buttonLabel,
          labelMedium: WellxTypography.chipText,
          labelSmall: WellxTypography.smallLabel,
        ),
      );
}
