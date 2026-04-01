import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';
import '../theme/wellx_typography.dart';
import '../theme/wellx_spacing.dart';

/// Toast notification for coin rewards.
class CoinEarnedToast extends StatelessWidget {
  final int coins;
  final VoidCallback? onDismiss;

  const CoinEarnedToast({
    super.key,
    required this.coins,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WellxSpacing.lg,
        vertical: WellxSpacing.md,
      ),
      decoration: BoxDecoration(
        color: WellxColors.inkPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: WellxSpacing.sm),
          Text(
            '+$coins xCoins',
            style: WellxTypography.cardTitle.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
