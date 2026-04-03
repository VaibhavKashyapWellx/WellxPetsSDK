import 'package:flutter/material.dart';
import 'wellx_colors.dart';

/// Typography scale for Wellx Pets using the Inter font family.
///
/// Inter is a humanist sans-serif optimised for screen legibility.
/// Font files must be present in assets/fonts/ (see assets/fonts/FONTS.md).
///
/// All styles fall back to the system sans-serif when Inter is not installed.
class WellxTypography {
  WellxTypography._();

  static const _fontFamily = 'Inter';

  // ── Headline & Display ──────────────────────────────────────────────────

  static const heroDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: WellxColors.textPrimary,
  );

  static const screenTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: WellxColors.textPrimary,
  );

  static const heading = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: WellxColors.textPrimary,
  );

  static const dataNumber = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: WellxColors.textPrimary,
  );

  // ── Card & UI ───────────────────────────────────���───────────────────────��

  static const cardTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: WellxColors.textPrimary,
  );

  static const buttonLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Colors.white,
  );

  static const sectionLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.6,
    color: WellxColors.textTertiary,
  );

  static const microLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.6,
    color: WellxColors.textTertiary,
  );

  // ── Body & Reading ───────────────���─────────────────────────────��──────────

  static const bodyText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: WellxColors.textPrimary,
  );

  static const inputText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: WellxColors.textPrimary,
  );

  static const chipText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: WellxColors.textPrimary,
  );

  static const captionText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: WellxColors.textSecondary,
  );

  static const smallLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: WellxColors.textSecondary,
  );
}
