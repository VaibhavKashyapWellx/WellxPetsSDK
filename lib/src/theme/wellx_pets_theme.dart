import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wellx_colors.dart';
import 'wellx_typography.dart';
import 'wellx_spacing.dart';

/// Complete Material theme for Wellx Pets.
class WellxPetsTheme {
  WellxPetsTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: WellxColors.deepPurple,
          onPrimary: Colors.white,
          primaryContainer: WellxColors.lightPurple,
          secondary: WellxColors.midPurple,
          onSecondary: Colors.white,
          surface: WellxColors.cardSurface,
          onSurface: WellxColors.textPrimary,
          error: WellxColors.alertRed,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: WellxColors.background,
        cardTheme: CardThemeData(
          color: WellxColors.cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
            side: const BorderSide(color: WellxColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: WellxColors.background,
          foregroundColor: WellxColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: WellxTypography.heading,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WellxColors.flatCardFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WellxColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WellxColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WellxColors.deepPurple, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WellxSpacing.lg,
            vertical: WellxSpacing.md,
          ),
          hintStyle: WellxTypography.bodyText.copyWith(
            color: WellxColors.textTertiary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: WellxColors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: WellxSpacing.xl,
              vertical: WellxSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: WellxTypography.buttonLabel,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: WellxColors.deepPurple,
            textStyle: WellxTypography.buttonLabel.copyWith(
              color: WellxColors.deepPurple,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: WellxColors.inkPrimary,
          selectedItemColor: Colors.white,
          unselectedItemColor: WellxColors.textTertiary,
        ),
        dividerTheme: const DividerThemeData(
          color: WellxColors.border,
          thickness: 1,
          space: 0,
        ),
        textTheme: TextTheme(
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
