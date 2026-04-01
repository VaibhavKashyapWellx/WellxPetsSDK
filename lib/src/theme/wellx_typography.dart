import 'package:flutter/material.dart';
import 'wellx_colors.dart';

/// Typography scale for Wellx Pets.
///
/// Three font families mirroring FureverApp:
/// - Serif design: hero scores, screen titles, headings
/// - Rounded design: card titles, buttons, labels
/// - Default sans: body text, inputs, captions
class WellxTypography {
  WellxTypography._();

  // ── Headline & Display (Serif) ──
  static const heroDisplay = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.1,
    color: WellxColors.textPrimary,
  );

  static const screenTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: WellxColors.textPrimary,
  );

  static const heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: WellxColors.textPrimary,
  );

  static const dataNumber = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: WellxColors.textPrimary,
  );

  // ── Card & UI (Rounded) ──
  static const cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: WellxColors.textPrimary,
  );

  static const buttonLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Colors.white,
  );

  static const sectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.6,
    color: WellxColors.textTertiary,
  );

  static const microLabel = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.6,
    color: WellxColors.textTertiary,
  );

  // ── Body & Reading (Default) ──
  static const bodyText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: WellxColors.textPrimary,
  );

  static const inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: WellxColors.textPrimary,
  );

  static const chipText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: WellxColors.textPrimary,
  );

  static const captionText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: WellxColors.textSecondary,
  );

  static const smallLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: WellxColors.textSecondary,
  );
}
