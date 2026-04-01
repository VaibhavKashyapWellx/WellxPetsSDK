import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shelter_models.dart';
import '../services/shelter_service.dart';
import 'travel_provider.dart' show currentOwnerIdProvider;

/// Shelter service singleton.
final shelterServiceProvider = Provider<ShelterService>((ref) {
  return ShelterService();
});

/// Global impact metrics.
final shelterImpactProvider = FutureProvider<ShelterImpact>((ref) async {
  final service = ref.watch(shelterServiceProvider);
  return service.getGlobalImpact();
});

/// Featured shelter dogs.
final featuredDogsProvider = FutureProvider<List<ShelterDog>>((ref) async {
  final service = ref.watch(shelterServiceProvider);
  return service.getFeaturedDogs();
});

/// All shelter dogs.
final allDogsProvider = FutureProvider<List<ShelterDog>>((ref) async {
  final service = ref.watch(shelterServiceProvider);
  return service.getAllDogs();
});

/// Active shelter profiles.
final shelterProfilesProvider =
    FutureProvider<List<ShelterProfile>>((ref) async {
  final service = ref.watch(shelterServiceProvider);
  return service.getShelterProfiles();
});

/// Community donation pool for current month.
final communityPoolProvider = FutureProvider<CommunityPool>((ref) async {
  final service = ref.watch(shelterServiceProvider);
  final ownerId = ref.watch(currentOwnerIdProvider);
  return service.getCommunityPool(ownerId);
});

/// Shelter directory screen state.
class ShelterScreenState {
  final String selectedFilter; // 'All', 'Dogs', 'Cats', 'Both'
  final bool isAllocating;
  final String? errorMessage;

  const ShelterScreenState({
    this.selectedFilter = 'All',
    this.isAllocating = false,
    this.errorMessage,
  });

  ShelterScreenState copyWith({
    String? selectedFilter,
    bool? isAllocating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShelterScreenState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isAllocating: isAllocating ?? this.isAllocating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  List<ShelterProfile> filterProfiles(List<ShelterProfile> profiles) {
    if (selectedFilter == 'All') return profiles;
    final key = selectedFilter.toLowerCase();
    return profiles.where((p) => (p.animals ?? 'both') == key).toList();
  }
}

class ShelterScreenNotifier extends StateNotifier<ShelterScreenState> {
  final ShelterService _service;

  ShelterScreenNotifier(this._service) : super(const ShelterScreenState());

  void setFilter(String filter) =>
      state = state.copyWith(selectedFilter: filter);

  Future<bool> allocateCoins({
    required String ownerId,
    required String shelterProfileId,
    required int coins,
  }) async {
    state = state.copyWith(isAllocating: true, clearError: true);
    try {
      final success = await _service.allocateCoins(
        ownerId: ownerId,
        shelterProfileId: shelterProfileId,
        coins: coins,
      );
      state = state.copyWith(isAllocating: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isAllocating: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final shelterScreenProvider =
    StateNotifierProvider<ShelterScreenNotifier, ShelterScreenState>((ref) {
  final service = ref.watch(shelterServiceProvider);
  return ShelterScreenNotifier(service);
});
