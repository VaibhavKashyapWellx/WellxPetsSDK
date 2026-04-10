import 'package:flutter/material.dart';

/// Wellx Pets "Digital Sanctuary" color palette.
///
/// Purple-forward premium palette with tonal layering.
class WellxColors {
  WellxColors._();

  // ── Brand Primary (Purple Spectrum) ──
  static const primary = Color(0xFF5C44D8);
  static const primaryDim = Color(0xFF5035CC);
  static const primaryContainer = Color(0xFFC2B9FF);
  static const primaryFixed = Color(0xFFC2B9FF);
  static const primaryFixedDim = Color(0xFFB4A9FF);
  static const onPrimary = Color(0xFFFCF7FF);
  static const onPrimaryContainer = Color(0xFF380FB6);
  static const onPrimaryFixedVariant = Color(0xFF4222BE);

  // ── Legacy aliases (keeping old code working) ──
  static const deepPurple = primary;
  static const midPurple = Color(0xFF6B4ECC);
  static const lightPurple = primaryContainer;
  static const lavender = Color(0xFFB8A9E8);
  static const aiPurple = Color(0xFF907EFF);
  static const aiPurpleSubtle = Color(0x1F7C5CE0);

  // ── Secondary ──
  static const secondary = Color(0xFF5F5C73);
  static const secondaryContainer = Color(0xFFE7E2FD);

  // ── Tertiary (Health / Vitality Green) ──
  static const tertiary = Color(0xFF006F28);
  static const tertiaryContainer = Color(0xFF6FFB85);
  static const tertiaryDim = Color(0xFF006122);

  // ── Surface Hierarchy (Tonal Layering) ──
  static const surface = Color(0xFFF8F9FB);
  static const surfaceBright = Color(0xFFF8F9FB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F6);
  static const surfaceContainer = Color(0xFFEBEEF1);
  static const surfaceContainerHigh = Color(0xFFE5E9EC);
  static const surfaceContainerHighest = Color(0xFFDEE3E7);
  static const surfaceDim = Color(0xFFD5DBDF);
  static const surfaceVariant = Color(0xFFDEE3E7);
  static const inverseSurface = Color(0xFF0C0F10);

  // ── Legacy surface aliases ──
  static const background = surface;
  static const cardSurface = surfaceContainerLowest;
  static const flatCardFill = surfaceContainerLow;

  // ── On-Surface ──
  static const onSurface = Color(0xFF2E3336);
  static const onSurfaceVariant = Color(0xFF5A6063);
  static const outline = Color(0xFF767B7F);
  static const outlineVariant = Color(0xFFADB3B6);

  // ── Legacy text aliases ──
  static const textPrimary = onSurface;
  static const textSecondary = onSurfaceVariant;
  static const textTertiary = outline;

  // ── Error / Alert ──
  static const error = Color(0xFFAC3149);
  static const errorContainer = Color(0xFFF76A80);
  static const onError = Color(0xFFFFF7F7);
  static const alertRed = error;
  static const alertOrange = Color(0xFFD98C26);
  static const alertGreen = tertiary;
  static const coral = Color(0xFFE65A4D);
  static const amberWatch = Color(0xFFD9A633);

  // ── Dark Ink (Hero Surfaces — nav bar, dark cards) ──
  static const inkPrimary = Color(0xFF1A1A2E);
  static const inkSecondary = Color(0xFF16162A);

  // ── Score Ring Colors ──
  static const scoreRed = Color(0xFFCC4033);
  static const scoreOrange = Color(0xFFD98C33);
  static const scoreGreen = Color(0xFF409959);
  static const scoreBlue = Color(0xFF3373B3);
  static const glowPurple = Color(0xFF9B66FF);

  // ── Health Pillar Domain Colors ──
  static const organStrength = Color(0xFFCC4033);
  static const inflammation = Color(0xFFD98C33);
  static const metabolic = Color(0xFFC4A34F);
  static const bodyActivity = Color(0xFF409959);
  static const wellnessDental = Color(0xFF409959);
  static const bloodImmunity = Color(0xFF8C66B3);
  static const hormonalHarmony = Color(0xFF809ABF);

  // ── Border (ghost borders only — 15% opacity) ──
  static const border = Color(0x26ADB3B6); // outlineVariant at 15%
  static const ghostBorder = Color(0x26ADB3B6);

  // ── Gradients ──
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [onPrimaryFixedVariant, primary],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, aiPurple],
  );

  static const inkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [inkPrimary, inkSecondary],
  );

  static const scoreGlowGradient = RadialGradient(
    colors: [glowPurple, Colors.transparent],
  );

  // ── Tonal Shadow (premium, not pure black) ──
  static List<BoxShadow> get tonalShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: onSurface.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Score color helper ──
  static Color scoreColor(int score) {
    if (score < 30) return scoreRed;
    if (score < 50) return scoreOrange;
    if (score < 75) return scoreGreen;
    return scoreBlue;
  }
}
