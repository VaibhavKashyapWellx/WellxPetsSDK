import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import 'auth_provider.dart';

/// Convenience provider for the current owner ID.
final currentOwnerIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(currentAuthProvider);
  return auth.isAuthenticated ? auth.userId : null;
});

/// Travel service singleton.
final travelServiceProvider = Provider<TravelService>((ref) {
  return TravelService();
});

/// All travel destinations, sorted by pet-friendliness score.
final destinationsProvider =
    FutureProvider<List<TravelDestination>>((ref) async {
  final service = ref.watch(travelServiceProvider);
  return service.getDestinations();
});

/// Single destination by country code.
final destinationProvider =
    FutureProvider.family<TravelDestination?, String>((ref, countryCode) async {
  final service = ref.watch(travelServiceProvider);
  return service.getDestination(countryCode);
});

/// All pet-friendly airlines.
final airlinesProvider = FutureProvider<List<TravelAirline>>((ref) async {
  final service = ref.watch(travelServiceProvider);
  return service.getAirlines();
});

/// Single airline by ID.
final airlineProvider =
    FutureProvider.family<TravelAirline?, String>((ref, id) async {
  final service = ref.watch(travelServiceProvider);
  return service.getAirline(id);
});

/// Routes for a given destination country.
final routesProvider =
    FutureProvider.family<List<TravelRoute>, String>((ref, countryCode) async {
  final service = ref.watch(travelServiceProvider);
  return service.getRoutes(countryCode);
});

/// Current user's travel plans.
final userPlansProvider = FutureProvider<List<TravelPlan>>((ref) async {
  final service = ref.watch(travelServiceProvider);
  final ownerId = ref.watch(currentOwnerIdProvider);
  if (ownerId == null) return [];
  return service.getUserPlans(ownerId);
});

/// Notifier for travel screen state: search text, selected region, filtering.
class TravelScreenNotifier extends StateNotifier<TravelScreenState> {
  TravelScreenNotifier() : super(const TravelScreenState());

  void setSearchText(String text) =>
      state = state.copyWith(searchText: text);

  void setSelectedRegion(TravelRegion? region) =>
      state = state.copyWith(
        selectedRegion: region,
        clearRegion: region == null,
      );
}

class TravelScreenState {
  final String searchText;
  final TravelRegion? selectedRegion;

  const TravelScreenState({
    this.searchText = '',
    this.selectedRegion,
  });

  TravelScreenState copyWith({
    String? searchText,
    TravelRegion? selectedRegion,
    bool clearRegion = false,
  }) {
    return TravelScreenState(
      searchText: searchText ?? this.searchText,
      selectedRegion: clearRegion ? null : (selectedRegion ?? this.selectedRegion),
    );
  }

  /// Filter destinations by search text and region.
  List<TravelDestination> filterDestinations(
      List<TravelDestination> destinations) {
    var filtered = destinations;

    if (selectedRegion != null) {
      filtered = filtered
          .where((d) => d.travelRegion == selectedRegion)
          .toList();
    }

    if (searchText.isNotEmpty) {
      final query = searchText.toLowerCase();
      filtered = filtered.where((d) {
        return d.countryName.toLowerCase().contains(query) ||
            d.countryCode.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }
}

final travelScreenProvider =
    StateNotifierProvider<TravelScreenNotifier, TravelScreenState>((ref) {
  return TravelScreenNotifier();
});
