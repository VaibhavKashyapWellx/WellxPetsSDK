import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/shelter_models.dart';
import '../../providers/shelter_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';

/// Full-screen shelter directory with user balance hero, community goal,
/// and shelter-in-need cards matching the "Help Shelters" design reference.
class ShelterDirectoryScreen extends ConsumerWidget {
  const ShelterDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(shelterProfilesProvider);
    final screenState = ref.watch(shelterScreenProvider);
    final screenNotifier = ref.read(shelterScreenProvider.notifier);
    final poolAsync = ref.watch(communityPoolProvider);

    return Scaffold(
      backgroundColor: WellxColors.surface,
      appBar: AppBar(
        title: Text(
          'Help Shelters',
          style: WellxTypography.heading,
        ),
        centerTitle: true,
        backgroundColor: WellxColors.surface,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        color: WellxColors.primary,
        onRefresh: () async {
          ref.invalidate(shelterProfilesProvider);
          ref.invalidate(communityPoolProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
          children: [
            const SizedBox(height: WellxSpacing.sm),

            // ── User Balance Hero Card ──
            _UserBalanceHero(),

            const SizedBox(height: WellxSpacing.xl),

            // ── Community Goal Section ──
            poolAsync.when(
              data: (pool) => _CommunityGoalSection(pool: pool),
              loading: () => const SizedBox(height: 120),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: WellxSpacing.xl),

            // ── Filter Row ──
            _FilterRow(
              state: screenState,
              notifier: screenNotifier,
            ),

            const SizedBox(height: WellxSpacing.lg),

            // ── Shelter Cards List ──
            profilesAsync.when(
              data: (profiles) {
                final filtered = screenState.filterProfiles(profiles);
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No shelters found',
                        style: WellxTypography.captionText.copyWith(
                          color: WellxColors.textTertiary,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: WellxSpacing.xl),
                  itemBuilder: (context, index) =>
                      _ShelterCard(shelter: filtered[index]),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: WellxColors.primary,
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: WellxColors.textTertiary),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(shelterProfilesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom padding for floating nav bar
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Balance Hero Card
// ─────────────────────────────────────────────────────────────────────────────

class _UserBalanceHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WellxColors.primaryFixedDim.withValues(alpha: 0.20),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(WellxSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Balance',
                  style: WellxTypography.smallLabel.copyWith(
                    color: WellxColors.onPrimary.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: WellxSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '2,450',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: WellxColors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: WellxSpacing.sm),
                          Icon(
                            Icons.generating_tokens,
                            color: WellxColors.tertiaryContainer,
                            size: 24,
                          ),
                          const SizedBox(width: WellxSpacing.xs),
                          Text(
                            'Coins',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: WellxColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: WellxSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: WellxColors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: WellxSpacing.sm),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Community Goal Section
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityGoalSection extends StatelessWidget {
  final CommunityPool pool;
  const _CommunityGoalSection({required this.pool});

  @override
  Widget build(BuildContext context) {
    final percent = (pool.progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Community Goal',
              style: WellxTypography.heading,
            ),
            Text(
              '$percent% Reached',
              style: WellxTypography.captionText.copyWith(
                fontWeight: FontWeight.w600,
                color: WellxColors.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(height: WellxSpacing.lg),

        // Card body
        Container(
          padding: const EdgeInsets.all(WellxSpacing.xl),
          decoration: BoxDecoration(
            color: WellxColors.surfaceContainer,
            borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
          ),
          child: Column(
            children: [
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 12,
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        decoration: BoxDecoration(
                          color: WellxColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      // Fill
                      FractionallySizedBox(
                        widthFactor: pool.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: WellxColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: WellxSpacing.lg),

              // Avatars + Target row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar stack
                  SizedBox(
                    height: 32,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _avatarCircle(0, WellxColors.primaryFixedDim),
                        _avatarCircle(1, WellxColors.secondaryContainer),
                        _avatarCircle(2, WellxColors.surfaceContainerHigh),
                        // +count badge
                        Positioned(
                          left: 3 * 22.0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: WellxColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+${_formatCompact(pool.donorCount)}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: WellxColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Target
                  Row(
                    children: [
                      Text(
                        'Target: ',
                        style: WellxTypography.captionText,
                      ),
                      Text(
                        _formatWithCommas(pool.monthGoal),
                        style: WellxTypography.captionText.copyWith(
                          fontWeight: FontWeight.w700,
                          color: WellxColors.onSurface,
                        ),
                      ),
                      Text(
                        ' coins',
                        style: WellxTypography.captionText,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: WellxSpacing.lg),

              // Motivational quote
              Text(
                '"Every coin fuels medical supplies and healthy meals for our furry friends in need."',
                style: WellxTypography.captionText.copyWith(
                  fontStyle: FontStyle.italic,
                  color: WellxColors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarCircle(int index, Color color) {
    return Positioned(
      left: index * 22.0,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: 16,
          color: WellxColors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _formatCompact(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
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

// ─────────────────────────────────────────────────────────────────────────────
// Filter Row
// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final ShelterScreenState state;
  final ShelterScreenNotifier notifier;
  const _FilterRow({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Dogs', 'Cats', 'Both'];
    return Row(
      children: [
        Flexible(
          child: Text(
            'Shelters in Need',
            style: WellxTypography.heading,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        ...filters.map((f) {
          final isSelected = state.selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => notifier.setFilter(f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WellxColors.onSurface
                      : WellxColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  f,
                  style: WellxTypography.microLabel.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : WellxColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shelter Card
// ─────────────────────────────────────────────────────────────────────────────

class _ShelterCard extends StatelessWidget {
  final ShelterProfile shelter;
  const _ShelterCard({required this.shelter});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image with tags ──
          SizedBox(
            height: 224,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(WellxSpacing.cardRadius),
                    topRight: Radius.circular(WellxSpacing.cardRadius),
                  ),
                  child: shelter.photoUrl != null
                      ? Image.network(
                          shelter.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _shelterPlaceholder(),
                        )
                      : _shelterPlaceholder(),
                ),
                // Category tags
                if (shelter.currentNeeds != null &&
                    shelter.currentNeeds!.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: shelter.currentNeeds!
                          .take(3)
                          .map((need) => _tagChip(need))
                          .toList(),
                    ),
                  )
                else if (shelter.shelterType != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _tagChip(shelter.typeLabel),
                  ),
              ],
            ),
          ),

          // ── Text content ──
          Padding(
            padding: const EdgeInsets.all(WellxSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shelter name
                Text(
                  shelter.name,
                  style: WellxTypography.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: WellxSpacing.xs),

                // Location
                if (shelter.location != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: WellxColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shelter.location!,
                          style: WellxTypography.captionText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: WellxSpacing.lg),

                // Description or mission
                if (shelter.description != null || shelter.mission != null)
                  Text(
                    shelter.description ?? shelter.mission ?? '',
                    style: WellxTypography.captionText.copyWith(
                      color: WellxColors.onSurfaceVariant,
                      height: 1.6,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: WellxSpacing.lg),

                // Donate button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: WellxColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Donate Coins',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: WellxColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: WellxSpacing.sm),
                      Icon(
                        Icons.volunteer_activism,
                        size: 18,
                        color: WellxColors.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WellxColors.tertiaryContainer.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: WellxColors.tertiaryDim,
        ),
      ),
    );
  }

  Widget _shelterPlaceholder() {
    return Container(
      color: WellxColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 40,
          color: WellxColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
