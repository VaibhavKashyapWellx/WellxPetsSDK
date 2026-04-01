import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';
import '../theme/wellx_typography.dart';
import '../theme/wellx_spacing.dart';

/// Primary action button with Wellx purple gradient.
class WellxPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const WellxPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: onPressed != null ? WellxColors.primaryGradient : null,
          color: onPressed == null ? WellxColors.textTertiary : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WellxSpacing.xl,
                vertical: WellxSpacing.lg,
              ),
              child: Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: WellxSpacing.sm),
                  ] else if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: WellxSpacing.sm),
                  ],
                  Text(label, style: WellxTypography.buttonLabel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outline button.
class WellxSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const WellxSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: WellxColors.deepPurple,
        side: const BorderSide(color: WellxColors.deepPurple),
        padding: const EdgeInsets.symmetric(
          horizontal: WellxSpacing.xl,
          vertical: WellxSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: WellxSpacing.sm),
          ],
          Text(label),
        ],
      ),
    );
  }
}
