import '../models/travel_models.dart';
import 'supabase_client.dart';

/// Service for pet travel data: destinations, airlines, routes, and user plans.
class TravelService {
  static const _destinationColumns = '''
    id, country_code, country_name, region, flag_emoji,
    pet_import_allowed, quarantine_required, quarantine_days,
    required_documents, banned_breeds, vaccination_requirements,
    entry_process_summary, climate_notes, pet_friendliness_score,
    last_verified_at, source_urls, created_at, updated_at
  ''';

  static const _airlineColumns = '''
    id, name, iata_code, logo_url,
    allows_cabin, allows_cargo, allows_checked,
    cabin_max_weight_kg, cabin_carrier_dimensions, cargo_restrictions,
    breed_restrictions, pet_fee_cabin_usd, pet_fee_cargo_usd,
    booking_process, required_documents, temperature_embargo,
    embargo_months, pet_policy_url, last_verified_at, created_at, updated_at
  ''';

  static const _routeColumns = '''
    id, origin_country, destination_country, airline_id,
    direct_flight, typical_duration_hours,
    pet_cabin_available, pet_cargo_available,
    estimated_total_cost_usd, route_notes, popularity_rank
  ''';

  // ── Destinations ──

  Future<List<TravelDestination>> getDestinations() async {
    try {
      final result = await SupabaseManager.instance.client
          .from('travel_destinations')
          .select(_destinationColumns)
          .order('pet_friendliness_score', ascending: false, nullsFirst: false);
      return (result as List)
          .map((e) => TravelDestination.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw TravelServiceException('Failed to load destinations: $e');
    }
  }

  Future<TravelDestination?> getDestination(String countryCode) async {
    try {
      final result = await SupabaseManager.instance.client
          .from('travel_destinations')
          .select(_destinationColumns)
          .eq('country_code', countryCode)
          .limit(1);
      final list = result as List;
      if (list.isEmpty) return null;
      return TravelDestination.fromJson(list.first as Map<String, dynamic>);
    } catch (e) {
      throw TravelServiceException('Failed to load destination: $e');
    }
  }

  // ── Airlines ──

  Future<List<TravelAirline>> getAirlines() async {
    try {
      final result = await SupabaseManager.instance.client
          .from('travel_airlines')
          .select(_airlineColumns)
          .order('name');
      return (result as List)
          .map((e) => TravelAirline.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw TravelServiceException('Failed to load airlines: $e');
    }
  }

  Future<TravelAirline?> getAirline(String id) async {
    try {
      final result = await SupabaseManager.instance.client
          .from('travel_airlines')
          .select(_airlineColumns)
          .eq('id', id)
          .limit(1);
      final list = result as List;
      if (list.isEmpty) return null;
      return TravelAirline.fromJson(list.first as Map<String, dynamic>);
    } catch (e) {
      throw TravelServiceException('Failed to load airline: $e');
    }
  }

  // ── Routes ──

  Future<List<TravelRoute>> getRoutes(String destinationCountry) async {
    try {
      final result = await SupabaseManager.instance.client
          .from('travel_routes')
          .select(_routeColumns)
          .eq('destination_country', destinationCountry)
          .order('popularity_rank', ascending: true);
      return (result as List)
          .map((e) => TravelRoute.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw TravelServiceException('Failed to load routes: $e');
    }
  }

  // ── User Plans ──

  Future<List<TravelPlan>> getUserPlans(String ownerId) async {
    try {
      final result = await SupabaseManager.instance.client
          .from('travel_plans')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      return (result as List)
          .map((e) => TravelPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw TravelServiceException('Failed to load travel plans: $e');
    }
  }

  Future<void> savePlan(TravelPlan plan) async {
    try {
      await SupabaseManager.instance.client
          .from('travel_plans')
          .upsert(plan.toJson());
    } catch (e) {
      throw TravelServiceException('Failed to save travel plan: $e');
    }
  }

  Future<void> updatePlanChecklist(
    String planId,
    List<ChecklistItem> checklist,
  ) async {
    try {
      await SupabaseManager.instance.client
          .from('travel_plans')
          .update({
            'checklist': checklist.map((e) => e.toJson()).toList(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', planId);
    } catch (e) {
      throw TravelServiceException('Failed to update checklist: $e');
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      await SupabaseManager.instance.client
          .from('travel_plans')
          .delete()
          .eq('id', planId);
    } catch (e) {
      throw TravelServiceException('Failed to delete travel plan: $e');
    }
  }
}

/// Exception thrown by [TravelService] operations.
class TravelServiceException implements Exception {
  final String message;
  const TravelServiceException(this.message);

  @override
  String toString() => message;
}
