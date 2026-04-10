import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/shelter_models.dart';
import '../../providers/shelter_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import 'shelter_directory_screen.dart';
import 'shelter_dogs_list_screen.dart';

/// Compact community impact section for the HomeScreen.
///
/// Shows a condensed balance card, community progress, featured dogs,
/// and a CTA to the full shelter directory. Matches the "Help Shelters"
/// design language in compact form.
class FureverImpactSection extends ConsumerStatefulWidget {
  final int coinsBalance;

  const FureverImpactSection({
    super.key,
    this.coinsBalance = 0,
  });

  @override
  ConsumerState<FureverImpactSection> createState() =>
      _FureverImpactSectionState();
}

class _FureverImpactSectionState extends ConsumerState<FureverImpactSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ringAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final impactAsync = ref.watch(shelterImpactProvider);
    final dogsAsync = ref.watch(featuredDogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Compact Balance + CTA Card ──
        _compactBalanceCard(context),

        const SizedBox(height: WellxSpacing.lg),

        // ── Impact Stats ──
        impactAsync.when(
          data: (impact) => _impactStatsRow(impact),
          loading: () => const SizedBox(height: 80),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // ── Featured Dogs ──
        dogsAsync.when(
          data: (dogs) {
            if (dogs.isEmpty) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: WellxSpacing.lg),
                _shelterDogsSection(context, dogs),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: WellxSpacing.lg),

        // ── Help Shelter CTA ──
        _helpShelterCTA(context),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Compact Balance Card (dark hero style)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _compactBalanceCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WellxColors.onPrimaryFixedVariant,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative blur orb
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WellxColors.primaryFixedDim.withValues(alpha: 0.20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(WellxSpacing.cardPadding),
            child: Row(
              children: [
                // Balance info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Balance',
                        style: WellxTypography.smallLabel.copyWith(
                          color:
                              WellxColors.onPrimary.withValues(alpha: 0.80),
                        ),
                      ),
                      const SizedBox(height: WellxSpacing.xs),
                      Row(
                        children: [
                          Text(
                            widget.coinsBalance > 0
                                ? _formatWithCommas(widget.coinsBalance)
                                : '0',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: WellxColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: WellxSpacing.sm),
                          Icon(
                            Icons.generating_tokens,
                            color: WellxColors.tertiaryContainer,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Earn More pill
                GestureDetector(
                  onTap: () {
                    // Navigate to earn more (could be home/daily tasks)
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: WellxColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Earn More',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: WellxColors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: WellxColors.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Impact Stats Row (animated rings)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _impactStatsRow(ShelterImpact impact) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.cardPadding),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: WellxColors.subtleShadow,
      ),
      child: AnimatedBuilder(
        animation: _ringAnimation,
        builder: (context, _) {
          return Row(
            children: [
              _impactRing(
                value: impact.dogsHelped,
                maxValue: max(impact.dogsHelped, 50),
                label: 'Dogs\nHelped',
                icon: Icons.pets,
                color: WellxColors.scoreGreen,
              ),
              _impactRing(
                value: impact.mealsProvided,
                maxValue: max(impact.mealsProvided, 500),
                label: 'Meals\nProvided',
                icon: Icons.restaurant,
                color: WellxColors.amberWatch,
              ),
              _impactRing(
                value: impact.sheltersPartnered,
                maxValue: max(impact.sheltersPartnered, 20),
                label: 'Partner\nShelters',
                icon: Icons.house,
                color: WellxColors.primary,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _impactRing({
    required int value,
    required int maxValue,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final progress = maxValue > 0
        ? min(1.0, value / maxValue) * _ringAnimation.value
        : 0.0;

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor:
                        WellxColors.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            _formatNumber(value),
            style: WellxTypography.dataNumber.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: WellxTypography.microLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Featured Dogs Horizontal Scroll
  // ─────────────────────────────────────────────────────────────────────────

  Widget _shelterDogsSection(BuildContext context, List<ShelterDog> dogs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Dogs you\'re helping',
              style: WellxTypography.chipText
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ShelterDogsListScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: WellxTypography.chipText.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WellxColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward,
                      size: 12, color: WellxColors.primary),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: WellxSpacing.md),

        // Horizontal scroll of dog cards
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: min(6, dogs.length),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: WellxSpacing.md),
                child: _shelterDogCard(dogs[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _shelterDogCard(ShelterDog dog) {
    return Container(
      width: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: WellxColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          SizedBox(
            width: 140,
            height: 100,
            child: dog.photoUrl != null
                ? Image.network(
                    dog.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _dogPlaceholder(),
                  )
                : _dogPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(WellxSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dog.name,
                  style: WellxTypography.chipText
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (dog.breed != null)
                  Text(
                    dog.breed!,
                    style: WellxTypography.microLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (dog.story != null)
                  Text(
                    dog.story!,
                    style: WellxTypography.microLabel
                        .copyWith(color: WellxColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dogPlaceholder() {
    return Container(
      color: WellxColors.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.pets,
            size: 24,
            color: WellxColors.outlineVariant.withValues(alpha: 0.4)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Help Shelter CTA
  // ─────────────────────────────────────────────────────────────────────────

  Widget _helpShelterCTA(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ShelterDirectoryScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(WellxSpacing.cardPadding),
        decoration: BoxDecoration(
          color: WellxColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
          boxShadow: WellxColors.subtleShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: WellxColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism,
                size: 20,
                color: WellxColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: WellxSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donate Your Coins',
                    style: WellxTypography.chipText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.coinsBalance > 0
                        ? '${widget.coinsBalance} coins = ${widget.coinsBalance} meals for shelter dogs'
                        : 'Earn coins through daily care to help shelter dogs',
                    style: WellxTypography.captionText.copyWith(
                      color: WellxColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: WellxColors.outlineVariant),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }

  String _formatWithCommas(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
