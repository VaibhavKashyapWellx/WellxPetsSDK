import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shelter_models.dart';
import '../../providers/shelter_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import 'shelter_directory_screen.dart';
import 'shelter_dogs_list_screen.dart';

/// Section in HomeScreen showing community impact with donation CTA.
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

    return Container(
      decoration: BoxDecoration(
        color: WellxColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WellxColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: How it works
          _howItWorksSection(),

          _sectionDivider(),

          // Section 2: Impact stats
          impactAsync.when(
            data: (impact) => _impactStatsSection(impact),
            loading: () => const SizedBox(height: 80),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Section 3: Featured dogs
          dogsAsync.when(
            data: (dogs) {
              if (dogs.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  _sectionDivider(),
                  _shelterDogsSection(context, dogs),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Section 4: Help shelter CTA
          _sectionDivider(),
          _helpShelterCTA(context),
        ],
      ),
    );
  }

  Widget _howItWorksSection() {
    return Padding(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.autorenew,
                  size: 14, color: WellxColors.deepPurple),
              const SizedBox(width: 6),
              Text(
                'YOUR IMPACT',
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: WellxSpacing.lg),

          // 3 step bubbles
          Row(
            children: [
              _stepBubble(Icons.favorite, 'Track\nHealth', WellxColors.coral),
              _dashedConnector(),
              _stepBubble(Icons.star, 'Earn\nCoins', WellxColors.amberWatch),
              _dashedConnector(),
              _stepBubble(
                  Icons.pets, 'Help\nDogs', WellxColors.scoreGreen),
            ],
          ),

          const SizedBox(height: WellxSpacing.md),

          Text(
            'Every health check you complete earns coins that help shelter dogs',
            style: WellxTypography.captionText,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: WellxSpacing.sm),

          // Real impact badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: WellxColors.deepPurple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified,
                    size: 12, color: WellxColors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  'Real donations \u{2014} every coin feeds shelter dogs',
                  style: WellxTypography.microLabel.copyWith(
                    color: WellxColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBubble(IconData icon, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            label,
            style: WellxTypography.microLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _dashedConnector() {
    return SizedBox(
      width: 24,
      child: CustomPaint(
        size: const Size(24, 1),
        painter: _DashedLinePainter(
          color: WellxColors.textTertiary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _impactStatsSection(ShelterImpact impact) {
    return Padding(
      padding: const EdgeInsets.all(WellxSpacing.lg),
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
                color: WellxColors.deepPurple,
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
                    backgroundColor: WellxColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            _formatNumber(value),
            style: WellxTypography.dataNumber,
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

  Widget _shelterDogsSection(BuildContext context, List<ShelterDog> dogs) {
    return Padding(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Dogs you\'re helping',
                style: WellxTypography.captionText
                    .copyWith(fontWeight: FontWeight.w500),
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
                        color: WellxColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        size: 12, color: WellxColors.textPrimary),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: WellxSpacing.md),

          // Horizontal scroll of dog cards
          SizedBox(
            height: 170,
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
      ),
    );
  }

  Widget _shelterDogCard(ShelterDog dog) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 140,
              height: 100,
              child: dog.photoUrl != null
                  ? Image.network(
                      dog.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _dogPlaceholder(),
                    )
                  : _dogPlaceholder(),
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            dog.name,
            style: WellxTypography.chipText
                .copyWith(fontWeight: FontWeight.w600),
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
    );
  }

  Widget _dogPlaceholder() {
    return Container(
      color: WellxColors.deepPurple.withValues(alpha: 0.06),
      child: Center(
        child: Icon(Icons.pets,
            size: 24, color: WellxColors.deepPurple.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _helpShelterCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ShelterDirectoryScreen(),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WellxColors.deepPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite,
                  size: 16, color: WellxColors.deepPurple),
            ),
            const SizedBox(width: WellxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donate Your Coins',
                    style: WellxTypography.chipText
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.coinsBalance > 0
                        ? 'You have ${widget.coinsBalance} coins = ${widget.coinsBalance} meals for shelter dogs'
                        : 'Earn coins through daily care to help shelter dogs',
                    style: WellxTypography.microLabel
                        .copyWith(color: WellxColors.textTertiary),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: WellxColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
      child: Divider(
        color: WellxColors.border.withValues(alpha: 0.3),
        height: 1,
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(min(startX + dashWidth, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
