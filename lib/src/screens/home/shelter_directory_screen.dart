import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shelter_models.dart';
import '../../providers/shelter_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Grid of shelter profiles with photos, names, animal counts, mission statements.
class ShelterDirectoryScreen extends ConsumerWidget {
  const ShelterDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(shelterProfilesProvider);
    final screenState = ref.watch(shelterScreenProvider);
    final screenNotifier = ref.read(shelterScreenProvider.notifier);
    final poolAsync = ref.watch(communityPoolProvider);

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: const Text('Help Shelters'),
        centerTitle: true,
        backgroundColor: WellxColors.background,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: WellxColors.deepPurple,
        onRefresh: () async {
          ref.invalidate(shelterProfilesProvider);
          ref.invalidate(communityPoolProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(WellxSpacing.lg),
          children: [
            // Community pool card
            poolAsync.when(
              data: (pool) => _communityPoolCard(pool),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: WellxSpacing.lg),

            // Filter row
            _filterRow(screenState, screenNotifier),

            const SizedBox(height: WellxSpacing.lg),

            // Shelter grid
            profilesAsync.when(
              data: (profiles) {
                final filtered = screenState.filterProfiles(profiles);
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No shelters found',
                        style: TextStyle(color: WellxColors.textTertiary),
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _shelterCard(filtered[index]),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                      color: WellxColors.deepPurple),
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _communityPoolCard(CommunityPool pool) {
    return WellxCard(
      backgroundColor: WellxColors.deepPurple.withOpacity(0.04),
      borderColor: WellxColors.deepPurple.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.public,
                  size: 14, color: WellxColors.deepPurple),
              const SizedBox(width: 6),
              Text(
                pool.monthLabel.toUpperCase(),
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.deepPurple,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (pool.donorCount > 0)
                Text(
                  '${pool.donorCount} donors',
                  style: WellxTypography.microLabel.copyWith(
                    color: WellxColors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          const SizedBox(height: WellxSpacing.sm),

          Text(
            'Community Donation Pool',
            style: WellxTypography.heading.copyWith(fontSize: 18),
          ),

          const SizedBox(height: WellxSpacing.md),

          // Coin count
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.star, size: 22, color: WellxColors.amberWatch),
              const SizedBox(width: 8),
              Text(
                '${pool.totalCoins}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: WellxColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('coins this month',
                      style: WellxTypography.captionText),
                  Text(
                    '~AED ${pool.aedEquivalent}',
                    style: WellxTypography.captionText.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WellxColors.amberWatch,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: WellxSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pool.progress,
              minHeight: 10,
              backgroundColor: WellxColors.deepPurple.withOpacity(0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(WellxColors.deepPurple),
            ),
          ),

          const SizedBox(height: WellxSpacing.xs),

          Row(
            children: [
              if (pool.userContribution > 0)
                Text(
                  'You: ${pool.userContribution} coins',
                  style: WellxTypography.microLabel.copyWith(
                    color: WellxColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'Be the first to donate this month!',
                  style: WellxTypography.microLabel,
                ),
              const Spacer(),
              Text(
                'Goal: ${pool.monthGoal}',
                style: WellxTypography.microLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterRow(
      ShelterScreenState state, ShelterScreenNotifier notifier) {
    const filters = ['All', 'Dogs', 'Cats', 'Both'];
    return Row(
      children: [
        Text(
          'SHELTERS',
          style: WellxTypography.sectionLabel.copyWith(
            color: WellxColors.deepPurple,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        ...filters.map((f) {
          final isSelected = state.selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => notifier.setFilter(f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WellxColors.textPrimary
                      : WellxColors.flatCardFill,
                  borderRadius: BorderRadius.circular(12),
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

  Widget _shelterCard(ShelterProfile shelter) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WellxColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WellxColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo or placeholder
          SizedBox(
            height: 90,
            width: double.infinity,
            child: shelter.photoUrl != null
                ? Image.network(
                    shelter.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _shelterPlaceholder(shelter),
                  )
                : _shelterPlaceholder(shelter),
          ),

          Padding(
            padding: const EdgeInsets.all(WellxSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shelter.name,
                  style: WellxTypography.chipText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(shelter.animalIcon,
                        size: 10, color: shelter.animalColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${shelter.typeLabel} \u{00B7} ${shelter.location ?? ""}',
                        style: WellxTypography.microLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (shelter.animalsInCare != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${shelter.animalsInCare} animals in care',
                    style: WellxTypography.microLabel.copyWith(
                      color: WellxColors.deepPurple,
                    ),
                  ),
                ],
                if (shelter.mission != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    shelter.mission!,
                    style: WellxTypography.microLabel.copyWith(
                      color: WellxColors.textTertiary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shelterPlaceholder(ShelterProfile shelter) {
    return Container(
      color: shelter.animalColor.withOpacity(0.08),
      child: Center(
        child: Icon(
          shelter.animalIcon,
          size: 28,
          color: shelter.animalColor.withOpacity(0.3),
        ),
      ),
    );
  }
}
