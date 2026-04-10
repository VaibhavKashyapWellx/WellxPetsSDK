import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wellx_colors.dart';

/// Typography scale for Wellx Pets "Digital Sanctuary".
///
/// Dual-font strategy:
/// - Plus Jakarta Sans: Display & Headlines ("Editorial" voice)
/// - Inter: Body & Labels ("Functional" voice)
class WellxTypography {
  WellxTypography._();

  // ── Headline & Display (Plus Jakarta Sans) ──
  static TextStyle get heroDisplay => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: WellxColors.onSurface,
      );

  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: WellxColors.onSurface,
      );

  static TextStyle get heading => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: WellxColors.onSurface,
      );

  static TextStyle get dataNumber => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: WellxColors.onSurface,
      );

  // ── Card & UI (Plus Jakarta Sans — Bold) ──
  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: WellxColors.onSurface,
      );

  static TextStyle get buttonLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: Colors.white,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        height: 1.6,
        color: WellxColors.outline,
      );

  static TextStyle get microLabel => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        height: 1.6,
        color: WellxColors.outline,
      );

  // ── Body & Reading (Inter) ──
  static TextStyle get bodyText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: WellxColors.onSurface,
      );

  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: WellxColors.onSurface,
      );

  static TextStyle get chipText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: WellxColors.onSurface,
      );

  static TextStyle get captionText => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: WellxColors.onSurfaceVariant,
      );

  static TextStyle get smallLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: WellxColors.onSurfaceVariant,
      );
}
