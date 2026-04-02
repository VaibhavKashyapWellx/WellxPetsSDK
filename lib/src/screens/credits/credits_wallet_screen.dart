import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/credit_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../services/credit_service.dart';
import '../../providers/sdk_providers.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Provider for transaction history.
final _transactionsProvider =
    FutureProvider.family<List<CreditTransaction>, String>((ref, ownerId) {
  final delegate = ref.watch(xCoinDelegateProvider);
  final service = CreditService(delegate);
  return service.getTransactions(ownerId);
});

/// Dedicated xCoins wallet view.
class CreditsWalletScreen extends ConsumerWidget {
  const CreditsWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final balance = balanceAsync.valueOrNull;
    final ownerAsync = ref.watch(currentOwnerProvider);
    final owner = ownerAsync.valueOrNull;
    final auth = ref.watch(currentAuthProvider);

    final transactionsAsync = auth.userId != null
        ? ref.watch(_transactionsProvider(auth.userId!))
        : null;
    final transactions = transactionsAsync?.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Your Coins'),
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
            // Balance hero card with ink gradient
            _BalanceHeroCard(
              coinsBalance: balance?.coinsBalance ?? 0,
              ownerName: owner?.fullName ?? 'Pet Parent',
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Shelter donation CTA
            GestureDetector(
              onTap: () => context.push('/shelter-directory'),
              child: WellxCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: WellxColors.scoreGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          size: 16, color: WellxColors.scoreGreen),
                    ),
                    const SizedBox(width: WellxSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help Shelter Dogs',
                            style: WellxTypography.inputText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose a shelter to donate your coins to',
                            style: WellxTypography.captionText,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 12, color: WellxColors.textTertiary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: WellxSpacing.lg),

            // Earn coins button
            GestureDetector(
              onTap: () => context.push('/earn-coins'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: WellxColors.textPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Earn Coins', style: WellxTypography.buttonLabel),
                  ],
                ),
              ),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Transaction history
            Text(
              'TRANSACTION HISTORY',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.md),

            if (transactions.isEmpty)
              WellxCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(Icons.history,
                            size: 28, color: WellxColors.textTertiary),
                        const SizedBox(height: WellxSpacing.sm),
                        Text(
                          'No transactions yet',
                          style: WellxTypography.chipText.copyWith(
                            color: WellxColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Earn coins by caring for your pet',
                          style: WellxTypography.captionText,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              WellxCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int i = 0; i < transactions.length; i++) ...[
                      _TransactionRow(tx: transactions[i]),
                      if (i < transactions.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 52),
                          child: Divider(
                            height: 1,
                            color: WellxColors.border,
                          ),
                        ),
                    ],
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
// Balance Hero Card
// ---------------------------------------------------------------------------

class _BalanceHeroCard extends StatelessWidget {
  final int coinsBalance;
  final String ownerName;

  const _BalanceHeroCard({
    required this.coinsBalance,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: WellxColors.inkGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Debit label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Debit',
              style: WellxTypography.microLabel.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),

          // Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'YOUR COINS',
                style: WellxTypography.smallLabel.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$coinsBalance',
            style: WellxTypography.heroDisplay.copyWith(color: Colors.white),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            ownerName,
            style: WellxTypography.captionText.copyWith(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: WellxSpacing.lg),

          // Impact pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ImpactPill(
                icon: Icons.restaurant,
                value: '$coinsBalance',
                label: 'meals funded',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImpactPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            value,
            style: WellxTypography.chipText.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: WellxTypography.smallLabel.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction Row
// ---------------------------------------------------------------------------

class _TransactionRow extends StatelessWidget {
  final CreditTransaction tx;

  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncoming = tx.isIncoming;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isIncoming ? WellxColors.scoreGreen : WellxColors.coral)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncoming ? Icons.star : Icons.shopping_bag,
              size: 14,
              color: isIncoming ? WellxColors.scoreGreen : WellxColors.coral,
            ),
          ),
          const SizedBox(width: 12),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.typeLabel,
                  style: WellxTypography.chipText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (tx.description != null && tx.description!.isNotEmpty)
                  Text(
                    tx.description!,
                    style: WellxTypography.smallLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncoming ? '+' : '-'}${tx.amount}',
                style: WellxTypography.inputText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isIncoming
                      ? WellxColors.scoreGreen
                      : WellxColors.coral,
                ),
              ),
              Text(
                tx.currency,
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
