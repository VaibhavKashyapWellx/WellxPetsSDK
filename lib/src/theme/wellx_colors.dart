import 'package:flutter/material.dart';

/// Wellx Pets color palette.
///
/// Mapped from FureverApp's gold/cream/green theme to Wellx purple/white.
class WellxColors {
  WellxColors._();

  // ── Brand Primary ──
  static const deepPurple = Color(0xFF4D33B3);
  static const midPurple = Color(0xFF6B4ECC);
  static const lightPurple = Color(0xFF9B85E0);
  static const lavender = Color(0xFFB8A9E8);

  // ── Dark Ink (Hero Surfaces — tab bar, wallet card, score ring bg) ──
  static const inkPrimary = Color(0xFF1A1A2E);
  static const inkSecondary = Color(0xFF16162A);

  // ── Surface Colors (Off-white base) ──
  static const background = Color(0xFFF7F7FA);
  static const cardSurface = Colors.white;
  static const flatCardFill = Color(0xFFF5F4FA);

  // ── Border ──
  static const border = Color(0xFFE8E6F0);

  // ── AI Accent ──
  static const aiPurple = Color(0xFF7C5CE0);
  static const aiPurpleSubtle = Color(0x1F7C5CE0); // 12% opacity

  // ── Text Colors ──
  static const textPrimary = Color(0xFF17181A);
  static const textSecondary = Color(0xFF57595B);
  static const textTertiary = Color(0xFF858789);

  // ── Status & Alert (semantic — same across themes) ──
  static const coral = Color(0xFFE65A4D);
  static const amberWatch = Color(0xFFD9A633);
  static const alertRed = Color(0xFFBF3326);
  static const alertOrange = Color(0xFFD98C26);
  static const alertGreen = Color(0xFF4DA659);

  // ── Score Ring Colors ──
  static const scoreRed = Color(0xFFCC4033);
  static const scoreOrange = Color(0xFFD98C33);
  static const scoreGreen = Color(0xFF409959);
  static const scoreBlue = Color(0xFF3373B3);
  static const glowPurple = Color(0xFF9B66FF);

  // ── Health Pillar Domain Colors (semantic — preserved) ──
  static const organStrength = Color(0xFFCC4033);
  static const inflammation = Color(0xFFD98C33);
  static const metabolic = Color(0xFFC4A34F);
  static const bodyActivity = Color(0xFF409959);
  static const wellnessDental = Color(0xFF409959);
  static const bloodImmunity = Color(0xFF8C66B3);
  static const hormonalHarmony = Color(0xFF809ABF);

  // ── Gradients ──
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepPurple, midPurple],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [midPurple, aiPurple],
  );

  static const inkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [inkPrimary, inkSecondary],
  );

  static const scoreGlowGradient = RadialGradient(
    colors: [glowPurple, Colors.transparent],
  );

  // ── Score color helper ──
  static Color scoreColor(int score) {
    if (score < 30) return scoreRed;
    if (score < 50) return scoreOrange;
    if (score < 75) return scoreGreen;
    return scoreBlue;
  }
}
