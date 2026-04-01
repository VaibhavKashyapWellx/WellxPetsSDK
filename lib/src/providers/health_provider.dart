import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_models.dart';
import '../services/health_service.dart';

final healthServiceProvider = Provider((ref) => HealthService());

final biomarkersProvider = FutureProvider.family<List<Biomarker>, String>((ref, petId) async {
  return ref.watch(healthServiceProvider).getBiomarkers(petId);
});

final medicationsProvider = FutureProvider.family<List<Medication>, String>((ref, petId) async {
  return ref.watch(healthServiceProvider).getMedications(petId);
});

final medicalRecordsProvider = FutureProvider.family<List<MedicalRecord>, String>((ref, petId) async {
  return ref.watch(healthServiceProvider).getMedicalRecords(petId);
});

final walkSessionsProvider = FutureProvider.family<List<WalkSession>, String>((ref, petId) async {
  return ref.watch(healthServiceProvider).getWalkSessions(petId);
});

final symptomsProvider = FutureProvider.family<List<SymptomLog>, String>((ref, petId) async {
  return ref.watch(healthServiceProvider).getSymptoms(petId);
});

final documentsProvider = FutureProvider.family<List<PetDocument>, String>((ref, petId) async {
  return ref.watch(healthServiceProvider).getDocuments(petId);
});

final healthAlertsProvider = FutureProvider.family<List<HealthAlert>, String>((ref, petId) async {
  return ref.watch(healthServiceProvider).getHealthAlerts(petId);
});
