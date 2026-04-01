import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/venue_models.dart';
import '../services/venue_service.dart';

/// Venue service singleton.
final venueServiceProvider = Provider<VenueService>((ref) {
  return VenueService();
});

/// Available cities for the city picker.
final venueCitiesProvider = FutureProvider<List<VenueCity>>((ref) async {
  final service = ref.watch(venueServiceProvider);
  return service.getAvailableCities();
});

/// Venue screen state with filters.
class VenueScreenState {
  final String selectedCity;
  final String selectedCountryCode;
  final VenueCategory? selectedCategory;
  final VenueSortMode sortMode;
  final String searchText;
  final bool verifiedOnly;
  final bool indoorOnly;
  final List<Venue> venues;
  final bool isLoading;
  final String? errorMessage;

  const VenueScreenState({
    this.selectedCity = 'Dubai',
    this.selectedCountryCode = 'AE',
    this.selectedCategory,
    this.sortMode = VenueSortMode.rating,
    this.searchText = '',
    this.verifiedOnly = false,
    this.indoorOnly = false,
    this.venues = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  VenueScreenState copyWith({
    String? selectedCity,
    String? selectedCountryCode,
    VenueCategory? selectedCategory,
    bool clearCategory = false,
    VenueSortMode? sortMode,
    String? searchText,
    bool? verifiedOnly,
    bool? indoorOnly,
    List<Venue>? venues,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VenueScreenState(
      selectedCity: selectedCity ?? this.selectedCity,
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      sortMode: sortMode ?? this.sortMode,
      searchText: searchText ?? this.searchText,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      indoorOnly: indoorOnly ?? this.indoorOnly,
      venues: venues ?? this.venues,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Apply all filters and sorting.
  List<Venue> get filteredVenues {
    var result = venues.toList();

    // Category filter
    if (selectedCategory != null) {
      result = result
          .where((v) => v.displayCategory == selectedCategory)
          .toList();
    }

    // Search filter
    if (searchText.isNotEmpty) {
      final query = searchText.toLowerCase();
      result = result.where((v) {
        return v.name.toLowerCase().contains(query) ||
            (v.area?.toLowerCase().contains(query) ?? false) ||
            (v.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Verified only
    if (verifiedOnly) {
      result = result.where((v) => v.isVerified).toList();
    }

    // Indoor only
    if (indoorOnly) {
      result = result
          .where((v) => v.dogFriendlyDetails?.indoorSeating == true)
          .toList();
    }

    // Sort
    switch (sortMode) {
      case VenueSortMode.rating:
        result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case VenueSortMode.name:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case VenueSortMode.newest:
        result.sort(
            (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        break;
    }

    return result;
  }

  int get verifiedCount => venues.where((v) => v.isVerified).length;

  int get indoorCount =>
      venues.where((v) => v.dogFriendlyDetails?.indoorSeating == true).length;

  int get totalCount => venues.length;
}

class VenueScreenNotifier extends StateNotifier<VenueScreenState> {
  final VenueService _service;

  VenueScreenNotifier(this._service) : super(const VenueScreenState());

  Future<void> loadVenues() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final venues = await _service.getVenues(city: state.selectedCity);
      state = state.copyWith(venues: venues, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> selectCity(VenueCity city) async {
    state = state.copyWith(
      selectedCity: city.city,
      selectedCountryCode: city.countryCode,
    );
    await loadVenues();
  }

  void setSearchText(String text) =>
      state = state.copyWith(searchText: text);

  void setCategory(VenueCategory? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setSortMode(VenueSortMode mode) =>
      state = state.copyWith(sortMode: mode);

  void toggleVerifiedOnly() =>
      state = state.copyWith(verifiedOnly: !state.verifiedOnly);

  void toggleIndoorOnly() =>
      state = state.copyWith(indoorOnly: !state.indoorOnly);
}

final venueScreenProvider =
    StateNotifierProvider<VenueScreenNotifier, VenueScreenState>((ref) {
  final service = ref.watch(venueServiceProvider);
  return VenueScreenNotifier(service);
});
