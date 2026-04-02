import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';
import '../theme/wellx_spacing.dart';
import 'shimmer_loading.dart';

// ---------------------------------------------------------------------------
// WellxLoadingWidget — skeleton shimmer with configurable layout
// ---------------------------------------------------------------------------

class WellxLoadingWidget extends StatelessWidget {
  final int cardCount;
  final double cardHeight;

  const WellxLoadingWidget({
    super.key,
    this.cardCount = 3,
    this.cardHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        children: List.generate(cardCount, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: WellxSpacing.md),
            child: ShimmerCard(height: cardHeight),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WellxInlineLoader — small spinner for inline use
// ---------------------------------------------------------------------------

class WellxInlineLoader extends StatelessWidget {
  final String? message;

  const WellxInlineLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: WellxColors.deepPurple,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: WellxSpacing.sm),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 13,
                color: WellxColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WellxErrorWidget — friendly error with retry button
// ---------------------------------------------------------------------------

class WellxErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const WellxErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WellxSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: WellxColors.alertRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: WellxColors.alertRed),
            ),
            const SizedBox(height: WellxSpacing.lg),
            Text(
              message ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: WellxColors.textPrimary,
              ),
            ),
            const SizedBox(height: WellxSpacing.xs),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: WellxColors.textTertiary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: WellxSpacing.xl),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WellxSpacing.xl,
                    vertical: WellxSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: WellxColors.inkPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WellxEmptyWidget — empty state with illustration + CTA
// ---------------------------------------------------------------------------

class WellxEmptyWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const WellxEmptyWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WellxSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: WellxColors.flatCardFill,
                shape: BoxShape.circle,
                border: Border.all(color: WellxColors.border),
              ),
              child: Icon(icon, size: 36, color: WellxColors.textTertiary),
            ),
            const SizedBox(height: WellxSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WellxColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: WellxSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: WellxColors.textTertiary,
                  height: 1.5,
                ),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: WellxSpacing.xl),
              GestureDetector(
                onTap: onCta,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WellxSpacing.xl,
                    vertical: WellxSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: WellxColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ctaLabel!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
