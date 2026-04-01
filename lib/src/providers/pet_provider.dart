import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import 'auth_provider.dart';

final petServiceProvider = Provider((ref) => PetService());

final petsProvider = FutureProvider<List<Pet>>((ref) async {
  final auth = ref.watch(currentAuthProvider);
  if (!auth.isAuthenticated || auth.userId == null) return [];
  final service = ref.watch(petServiceProvider);
  return service.getPets(auth.userId!);
});

final selectedPetIdProvider = StateProvider<String?>((ref) => null);

final selectedPetProvider = Provider<Pet?>((ref) {
  final pets = ref.watch(petsProvider).valueOrNull ?? [];
  final selectedId = ref.watch(selectedPetIdProvider);
  if (selectedId != null) {
    return pets.where((p) => p.id == selectedId).firstOrNull;
  }
  return pets.firstOrNull;
});
