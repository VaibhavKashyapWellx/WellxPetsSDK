import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/credit_provider.dart';
import '../../sdk/xcoin_delegate.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Shows all ways to earn xCoins.
class EarnCoinsScreen extends ConsumerWidget {
  const EarnCoinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final balance = balanceAsync.valueOrNull;

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Earn Coins'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            WellxCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Coins',
                          style: WellxTypography.captionText,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: WellxColors.amberWatch),
                            const SizedBox(width: 6),
                            Text(
                              '${balance?.coinsBalance ?? 0}',
                              style: WellxTypography.dataNumber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total earned: ${balance?.totalCoinsEarned ?? 0}',
                          style: WellxTypography.smallLabel,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: WellxColors.amberWatch.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded,
                        size: 28, color: WellxColors.amberWatch),
                  ),
                ],
              ),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Section header
            Text(
              'WAYS TO EARN',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.md),

            // Earn action cards grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.95,
              children: WellxCoinAction.values.map((action) {
                return _EarnActionCard(action: action);
              }).toList(),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Info section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: WellxColors.amberWatch.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb,
                          size: 12, color: WellxColors.amberWatch),
                      const SizedBox(width: 6),
                      Text(
                        'How Coins Work',
                        style: WellxTypography.chipText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: WellxSpacing.sm),
                  Text(
                    'Coins reward you for caring for your pet. Every coin earned through daily care helps feed a shelter dog.',
                    style: WellxTypography.captionText.copyWith(
                      color: WellxColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: WellxSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Earn Action Card
// ---------------------------------------------------------------------------

class _EarnActionCard extends StatelessWidget {
  final WellxCoinAction action;

  const _EarnActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.cardSurface,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(color: WellxColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _actionColor(action).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _actionIcon(action),
              size: 20,
              color: _actionColor(action),
            ),
          ),

          const Spacer(),

          // Action name
          Text(
            action.displayName,
            style: WellxTypography.chipText.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Coin reward
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WellxColors.amberWatch.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+${action.defaultCoins}',
                      style: WellxTypography.chipText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WellxColors.amberWatch,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.star,
                        size: 10, color: WellxColors.amberWatch),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _isRepeatable(action) ? 'Daily' : 'One-time',
                style: WellxTypography.microLabel.copyWith(
                  color: WellxColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _actionIcon(WellxCoinAction action) {
    switch (action) {
      case WellxCoinAction.dailyLogin:
        return Icons.login;
      case WellxCoinAction.completePetProfile:
        return Icons.pets;
      case WellxCoinAction.uploadDocument:
        return Icons.upload_file;
      case WellxCoinAction.logWalk:
        return Icons.directions_walk;
      case WellxCoinAction.chatDrLayla:
        return Icons.medical_services;
      case WellxCoinAction.healthCheck:
        return Icons.favorite;
      case WellxCoinAction.logSymptom:
        return Icons.edit_note;
    }
  }

  Color _actionColor(WellxCoinAction action) {
    switch (action) {
      case WellxCoinAction.dailyLogin:
        return WellxColors.deepPurple;
      case WellxCoinAction.completePetProfile:
        return WellxColors.scoreGreen;
      case WellxCoinAction.uploadDocument:
        return WellxColors.textPrimary;
      case WellxCoinAction.logWalk:
        return WellxColors.bodyActivity;
      case WellxCoinAction.chatDrLayla:
        return WellxColors.hormonalHarmony;
      case WellxCoinAction.healthCheck:
        return WellxColors.coral;
      case WellxCoinAction.logSymptom:
        return WellxColors.amberWatch;
    }
  }

  bool _isRepeatable(WellxCoinAction action) {
    switch (action) {
      case WellxCoinAction.dailyLogin:
      case WellxCoinAction.logWalk:
      case WellxCoinAction.chatDrLayla:
      case WellxCoinAction.healthCheck:
      case WellxCoinAction.logSymptom:
      case WellxCoinAction.uploadDocument:
        return true;
      case WellxCoinAction.completePetProfile:
        return false;
    }
  }
}
