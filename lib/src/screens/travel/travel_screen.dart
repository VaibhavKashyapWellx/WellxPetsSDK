import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/travel_models.dart';
import '../../providers/travel_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import 'destination_detail_screen.dart';
import 'airline_comparison_screen.dart';

/// Main travel screen: search destinations, browse by region, see travel plans.
class TravelScreen extends ConsumerWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenState = ref.watch(travelScreenProvider);
    final screenNotifier = ref.read(travelScreenProvider.notifier);
    final destinationsAsync = ref.watch(destinationsProvider);
    final airlinesAsync = ref.watch(airlinesProvider);
    final plansAsync = ref.watch(userPlansProvider);

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: const Text('Pet Travel'),
        centerTitle: true,
        backgroundColor: WellxColors.background,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flight, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AirlineComparisonScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: WellxColors.deepPurple,
        onRefresh: () async {
          ref.invalidate(destinationsProvider);
          ref.invalidate(airlinesProvider);
          ref.invalidate(userPlansProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
          children: [
            // Hero header
            _heroHeader(),

            const SizedBox(height: WellxSpacing.lg),

            // Search bar
            _searchBar(screenState, screenNotifier),

            const SizedBox(height: WellxSpacing.md),

            // Region pills
            _regionPills(screenState, screenNotifier),

            const SizedBox(height: WellxSpacing.lg),

            // Stats row
            destinationsAsync.when(
              data: (destinations) {
                if (destinations.isEmpty) return const SizedBox.shrink();
                return _statsRow(
                  destinationCount: destinations.length,
                  airlineCount: airlinesAsync.valueOrNull?.length ?? 0,
                  planCount:
                      plansAsync.valueOrNull?.where((p) => p.status != 'completed').length ?? 0,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: WellxSpacing.lg),

            // My travel plans
            plansAsync.when(
              data: (plans) {
                if (plans.isEmpty) return const SizedBox.shrink();
                return _myPlansSection(context, plans, ref);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Destinations grid
            destinationsAsync.when(
              data: (destinations) {
                final filtered =
                    screenState.filterDestinations(destinations);
                if (filtered.isEmpty) return _emptyState(screenNotifier);
                return _destinationsGrid(context, filtered);
              },
              loading: () => _loadingState(),
              error: (error, _) => _errorState(error, ref),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WellxSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.flight_takeoff, size: 36, color: WellxColors.deepPurple),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            'Travel with Your Pet',
            style: WellxTypography.heading,
          ),
          const SizedBox(height: WellxSpacing.xs),
          Text(
            'Destination guides, airline comparison & travel checklists',
            style: WellxTypography.bodyText
                .copyWith(color: WellxColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _searchBar(
      TravelScreenState state, TravelScreenNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: WellxColors.flatCardFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        onChanged: notifier.setSearchText,
        style: WellxTypography.inputText,
        decoration: InputDecoration(
          hintText: 'Search countries...',
          hintStyle:
              WellxTypography.inputText.copyWith(color: WellxColors.textTertiary),
          prefixIcon:
              const Icon(Icons.search, color: WellxColors.textTertiary, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _regionPills(
      TravelScreenState state, TravelScreenNotifier notifier) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _regionChip('All', Icons.public, null, state, notifier),
          const SizedBox(width: 8),
          ...TravelRegion.values.map(
            (region) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _regionChip(
                region.label,
                region.icon,
                region,
                state,
                notifier,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _regionChip(
    String label,
    IconData icon,
    TravelRegion? region,
    TravelScreenState state,
    TravelScreenNotifier notifier,
  ) {
    final isSelected = state.selectedRegion == region;
    return GestureDetector(
      onTap: () => notifier.setSelectedRegion(region),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? WellxColors.inkPrimary : WellxColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: WellxColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? Colors.white : WellxColors.textPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: WellxTypography.chipText.copyWith(
                color: isSelected ? Colors.white : WellxColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow({
    required int destinationCount,
    required int airlineCount,
    required int planCount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _statBadge('$destinationCount', 'Destinations', Icons.public,
            WellxColors.deepPurple),
        const SizedBox(width: WellxSpacing.lg),
        _statBadge(
            '$airlineCount', 'Airlines', Icons.flight, WellxColors.scoreBlue),
        if (planCount > 0) ...[
          const SizedBox(width: WellxSpacing.lg),
          _statBadge('$planCount', 'Active Plans', Icons.checklist,
              WellxColors.amberWatch),
        ],
      ],
    );
  }

  Widget _statBadge(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(value, style: WellxTypography.dataNumber),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: WellxTypography.captionText
              .copyWith(color: WellxColors.textTertiary),
        ),
      ],
    );
  }

  Widget _myPlansSection(
      BuildContext context, List<TravelPlan> plans, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Travel Plans', style: WellxTypography.heading),
        const SizedBox(height: WellxSpacing.md),
        ...plans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
              child: _travelPlanCard(context, plan, ref),
            )),
        const SizedBox(height: WellxSpacing.lg),
      ],
    );
  }

  Widget _travelPlanCard(
      BuildContext context, TravelPlan plan, WidgetRef ref) {
    final status = plan.planStatus;
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.cardSurface,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(color: WellxColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, size: 20, color: status.color),
          ),
          const SizedBox(width: WellxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.destinationCountry,
                  style: WellxTypography.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  status.displayName,
                  style: WellxTypography.captionText.copyWith(color: status.color),
                ),
              ],
            ),
          ),
          if (plan.totalCount > 0)
            Text(
              '${plan.completedCount}/${plan.totalCount}',
              style: WellxTypography.chipText
                  .copyWith(color: WellxColors.textTertiary),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              size: 18, color: WellxColors.textTertiary),
        ],
      ),
    );
  }

  Widget _destinationsGrid(
      BuildContext context, List<TravelDestination> destinations) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: destinations.length,
      itemBuilder: (context, index) {
        final dest = destinations[index];
        return _destinationCard(context, dest);
      },
    );
  }

  Widget _destinationCard(BuildContext context, TravelDestination dest) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailScreen(destination: dest),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1B1F), Color(0xFF262830)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Flag emoji background
            Center(
              child: Text(
                dest.flag,
                style: const TextStyle(fontSize: 60),
              ),
            ),

            // Dark gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score badge
                  if (dest.petFriendlinessScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: dest.friendlinessColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dest.petFriendlinessScore}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Country name + flag
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          dest.countryName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(dest.flag, style: const TextStyle(fontSize: 14)),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Info tags
                  Row(
                    children: [
                      Text(
                        '${dest.documentCount} docs',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      if (dest.isQuarantineRequired) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: WellxColors.coral.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Quarantine',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: WellxColors.deepPurple),
            SizedBox(height: WellxSpacing.lg),
            Text(
              'Loading destinations...',
              style: TextStyle(
                fontSize: 14,
                color: WellxColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(Object error, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off,
              size: 36, color: WellxColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Could not load destinations',
            style: WellxTypography.chipText.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => ref.invalidate(destinationsProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: WellxColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(TravelScreenNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.flight,
              size: 40, color: WellxColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No destinations found',
            style: WellxTypography.bodyText
                .copyWith(color: WellxColors.textSecondary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              notifier.setSearchText('');
              notifier.setSelectedRegion(null);
            },
            child: Text(
              'Clear Filters',
              style: WellxTypography.chipText
                  .copyWith(color: WellxColors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }
}
