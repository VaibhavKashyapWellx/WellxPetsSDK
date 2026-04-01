import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';
import '../theme/wellx_spacing.dart';

/// Standard card wrapper matching FureverApp's FureverCardModifier.
///
/// White background, 20pt corners, 1pt border, 16pt padding.
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
        color: backgroundColor ?? WellxColors.cardSurface,
        borderRadius: BorderRadius.circular(
          borderRadius ?? WellxSpacing.cardRadius,
        ),
        border: Border.all(
          color: borderColor ?? WellxColors.border,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Flat card variant (no border, subtle fill).
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
        color: WellxColors.flatCardFill,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      child: child,
    );
  }
}
