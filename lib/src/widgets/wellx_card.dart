import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';
import '../theme/wellx_spacing.dart';

/// Standard card — "Digital Sanctuary" style.
///
/// No borders (no-line rule). Hierarchy via tonal shifts and ambient shadows.
class WellxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const WellxCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(WellxSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(
          borderRadius ?? WellxSpacing.cardRadius,
        ),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: WellxColors.subtleShadow,
      ),
      child: child,
    );
  }
}

/// Flat card variant (tonal fill, no shadow).
class WellxFlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const WellxFlatCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(WellxSpacing.cardPadding),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      child: child,
    );
  }
}

/// Glass card — frosted glass effect for floating elements.
class WellxGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? borderRadius;

  const WellxGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        borderRadius ?? WellxSpacing.cardRadius,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(WellxSpacing.cardPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(
              borderRadius ?? WellxSpacing.cardRadius,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
