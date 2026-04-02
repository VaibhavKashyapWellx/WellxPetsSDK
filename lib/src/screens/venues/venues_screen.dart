import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/venue_models.dart';
import '../../providers/venue_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import 'venue_detail_screen.dart';

/// Pet-friendly venue discovery: list with filter chips, search, city selector.
class VenuesScreen extends ConsumerStatefulWidget {
  const VenuesScreen({super.key});

  @override
  ConsumerState<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends ConsumerState<VenuesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(venueScreenProvider.notifier).loadVenues(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(venueScreenProvider);
    final notifier = ref.read(venueScreenProvider.notifier);
    final citiesAsync = ref.watch(venueCitiesProvider);

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: const Text('Pet-Friendly Places'),
        centerTitle: true,
        backgroundColor: WellxColors.background,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: WellxColors.deepPurple,
        onRefresh: () => notifier.loadVenues(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
          children: [
            // City selector
            _citySelector(state, citiesAsync, notifier),
            const SizedBox(height: WellxSpacing.md),

            // Search bar
            _searchBar(state, notifier),
            const SizedBox(height: WellxSpacing.md),

            // Category pills
            _categoryPills(state, notifier),
            const SizedBox(height: WellxSpacing.sm),

            // Filter toggles + sort
            _filtersRow(state, notifier),
            const SizedBox(height: WellxSpacing.md),

            // Stats header
            if (!state.isLoading && state.venues.isNotEmpty)
              _statsHeader(state),

            const SizedBox(height: WellxSpacing.md),

            // Venue list
            _venueList(context, state),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _citySelector(
    VenueScreenState state,
    AsyncValue<List<VenueCity>> citiesAsync,
    VenueScreenNotifier notifier,
  ) {
    return GestureDetector(
      onTap: () {
        citiesAsync.whenData((cities) {
          _showCityPicker(context, cities, notifier);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: WellxColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WellxColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.place,
                size: 16, color: WellxColors.deepPurple),
            const SizedBox(width: 8),
            Text(
              state.selectedCity,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: WellxColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: WellxColors.textPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.selectedCountryCode,
                style: WellxTypography.microLabel,
              ),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down,
                size: 18, color: WellxColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showCityPicker(
    BuildContext context,
    List<VenueCity> cities,
    VenueScreenNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WellxColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Select City', style: WellxTypography.heading),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return ListTile(
                      leading: const Icon(Icons.place,
                          color: WellxColors.deepPurple),
                      title: Text(city.city),
                      subtitle: Text(
                        '${city.countryCode} \u{00B7} ${city.venueCount ?? 0} venues',
                        style: WellxTypography.captionText,
                      ),
                      onTap: () {
                        notifier.selectCity(city);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _searchBar(VenueScreenState state, VenueScreenNotifier notifier) {
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
          hintText: 'Search venues or areas...',
          hintStyle: WellxTypography.inputText
              .copyWith(color: WellxColors.textTertiary),
          prefixIcon: const Icon(Icons.search,
              color: WellxColors.textTertiary, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _categoryPills(
      VenueScreenState state, VenueScreenNotifier notifier) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryChip('All', Icons.pets, null, state, notifier),
          const SizedBox(width: 8),
          ...VenueCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _categoryChip(
                  cat.displayName, cat.icon, cat, state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    String label,
    IconData icon,
    VenueCategory? category,
    VenueScreenState state,
    VenueScreenNotifier notifier,
  ) {
    final isSelected = state.selectedCategory == category;
    return GestureDetector(
      onTap: () => notifier.setCategory(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? WellxColors.inkPrimary : WellxColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: WellxColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: isSelected ? Colors.white : WellxColors.textPrimary),
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

  Widget _filtersRow(VenueScreenState state, VenueScreenNotifier notifier) {
    return Row(
      children: [
        _filterToggle(
          label: 'Verified',
          icon: Icons.verified,
          isOn: state.verifiedOnly,
          color: WellxColors.alertGreen,
          count: state.verifiedCount,
          onTap: notifier.toggleVerifiedOnly,
        ),
        const SizedBox(width: 8),
        _filterToggle(
          label: 'Indoor',
          icon: Icons.house,
          isOn: state.indoorOnly,
          color: WellxColors.midPurple,
          count: state.indoorCount,
          onTap: notifier.toggleIndoorOnly,
        ),
        const Spacer(),
        PopupMenuButton<VenueSortMode>(
          onSelected: notifier.setSortMode,
          itemBuilder: (context) => VenueSortMode.values
              .map((mode) => PopupMenuItem(
                    value: mode,
                    child: Row(
                      children: [
                        Icon(mode.icon, size: 16),
                        const SizedBox(width: 8),
                        Text(mode.label),
                        if (state.sortMode == mode)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check, size: 16),
                          ),
                      ],
                    ),
                  ))
              .toList(),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: WellxColors.flatCardFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: 12, color: WellxColors.textPrimary),
                const SizedBox(width: 4),
                Text(
                  state.sortMode.label,
                  style: WellxTypography.chipText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterToggle({
    required String label,
    required IconData icon,
    required bool isOn,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? color : WellxColors.flatCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOn ? color : WellxColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12, color: isOn ? Colors.white : WellxColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: WellxTypography.chipText.copyWith(
                fontWeight: FontWeight.w600,
                color: isOn ? Colors.white : WellxColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isOn
                      ? Colors.white.withOpacity(0.7)
                      : WellxColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statsHeader(VenueScreenState state) {
    final filtered = state.filteredVenues;
    return Row(
      children: [
        Text(
          '${filtered.length} of ${state.totalCount} venues',
          style: WellxTypography.chipText
              .copyWith(color: WellxColors.textSecondary),
        ),
        const Spacer(),
        if (state.verifiedCount > 0)
          Row(
            children: [
              Icon(Icons.verified,
                  size: 12, color: WellxColors.alertGreen),
              const SizedBox(width: 4),
              Text(
                '${state.verifiedCount} verified',
                style: WellxTypography.captionText
                    .copyWith(color: WellxColors.alertGreen),
              ),
            ],
          ),
      ],
    );
  }

  Widget _venueList(BuildContext context, VenueScreenState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: WellxColors.deepPurple),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline,
                size: 36, color: WellxColors.textTertiary),
            const SizedBox(height: 12),
            const Text('Could not load venues'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(venueScreenProvider.notifier).loadVenues(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = state.filteredVenues;
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.location_off,
                size: 36, color: WellxColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              state.searchText.isEmpty
                  ? 'No venues found'
                  : 'No matches for "${state.searchText}"',
              style: WellxTypography.inputText
                  .copyWith(color: WellxColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((venue) {
        return Padding(
          padding: const EdgeInsets.only(bottom: WellxSpacing.md),
          child: _venueCard(context, venue),
        );
      }).toList(),
    );
  }

  /// Returns a consistent picsum landscape photo seeded on the venue name.
  String _venueImageUrl(Venue venue) {
    final seed = venue.name.toLowerCase().replaceAll(' ', '-');
    return 'https://picsum.photos/seed/$seed/600/300';
  }

  Widget _venueCard(BuildContext context, Venue venue) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VenueDetailScreen(venue: venue),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: WellxColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WellxColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — use real URL if available, then picsum, then icon placeholder
            SizedBox(
              height: 160,
              width: double.infinity,
              child: venue.hasImage
                  ? Image.network(
                      venue.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _picsumPlaceholder(venue),
                    )
                  : _picsumPlaceholder(venue),
            ),

            Padding(
              padding: const EdgeInsets.all(WellxSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: WellxTypography.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (venue.isVerified)
                        Icon(Icons.verified,
                            size: 16, color: WellxColors.alertGreen),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Category + area
                  Row(
                    children: [
                      _miniChip(
                        venue.displayCategory.displayName,
                        venue.displayCategory.icon,
                        venue.displayCategory.color,
                      ),
                      if (venue.area != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.place,
                            size: 10, color: WellxColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(venue.area!,
                            style: WellxTypography.microLabel),
                      ],
                      const Spacer(),
                      if (venue.rating != null)
                        Row(
                          children: [
                            Icon(Icons.star,
                                size: 12, color: WellxColors.amberWatch),
                            const SizedBox(width: 2),
                            Text(
                              venue.rating!.toStringAsFixed(1),
                              style: WellxTypography.chipText
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Amenity chips
                  if (venue.dogFriendlyDetails?.hasAnyAmenity == true) ...[
                    const SizedBox(height: WellxSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (venue.dogFriendlyDetails?.indoorSeating == true)
                          _amenityChip('Indoor', Icons.house, true),
                        if (venue.dogFriendlyDetails?.outdoorSeating == true)
                          _amenityChip('Outdoor', Icons.wb_sunny, false),
                        if (venue.dogFriendlyDetails?.waterBowls == true)
                          _amenityChip('Water', Icons.water_drop, false),
                        if (venue.dogFriendlyDetails?.dogMenu == true)
                          _amenityChip('Dog Menu', Icons.menu_book, false),
                        if (venue.dogFriendlyDetails?.dogTreats == true)
                          _amenityChip('Treats', Icons.card_giftcard, false),
                        if (venue.dogFriendlyDetails?.offLeashArea == true)
                          _amenityChip('Off-Leash', Icons.directions_run, false),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Picsum-backed placeholder with a subtle category badge overlay.
  Widget _picsumPlaceholder(Venue venue) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _venueImageUrl(venue),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _categoryPlaceholder(venue),
        ),
        // Subtle tinted overlay to unify with the app's palette
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                venue.displayCategory.color.withOpacity(0.08),
                Colors.black.withOpacity(0.12),
              ],
            ),
          ),
        ),
        // Category badge in top-right corner
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: venue.displayCategory.color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(venue.displayCategory.icon,
                    size: 10, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  venue.displayCategory.displayName,
                  style: WellxTypography.microLabel
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryPlaceholder(Venue venue) {
    return Container(
      color: venue.displayCategory.color.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(venue.displayCategory.icon,
                size: 32, color: venue.displayCategory.color.withOpacity(0.4)),
            const SizedBox(height: 4),
            Text(
              venue.displayCategory.displayName,
              style: WellxTypography.chipText.copyWith(
                color: venue.displayCategory.color.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: WellxTypography.microLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _amenityChip(String label, IconData icon, bool highlighted) {
    final color = highlighted ? WellxColors.midPurple : WellxColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? WellxColors.midPurple.withOpacity(0.12)
            : WellxColors.flatCardFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: WellxTypography.microLabel.copyWith(color: color)),
        ],
      ),
    );
  }
}
