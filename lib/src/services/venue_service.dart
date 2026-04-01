import '../models/venue_models.dart';
import 'supabase_client.dart';

/// Service for pet-friendly venue data.
class VenueService {
  static const _listColumns = '''
    id, name, phone, address, area, category, latitude, longitude,
    rating, dog_friendly_status, dog_friendly_details, image_url,
    whatsapp_number, website, last_verified_at, verification_source,
    google_place_id, city, country_code
  ''';

  /// Fetch venues, optionally filtered by city and/or category and/or country.
  Future<List<Venue>> getVenues({
    String? city,
    String? category,
    String? countryCode,
  }) async {
    try {
      var query = SupabaseManager.instance.client
          .from('venues')
          .select(_listColumns)
          .inFilter('dog_friendly_status', [
        'verified_friendly',
        'pending_verification',
        'needs_review',
      ]);

      if (city != null) {
        query = query.eq('city', city);
      }
      if (category != null) {
        query = query.eq('category', category);
      }
      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }

      final result = await query.order('rating',
          ascending: false, nullsFirst: false);
      return (result as List)
          .map((e) => Venue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw VenueServiceException('Failed to load venues: $e');
    }
  }

  /// Search venues by name or area.
  Future<List<Venue>> searchVenues(String query, {String? city}) async {
    try {
      var dbQuery = SupabaseManager.instance.client
          .from('venues')
          .select(_listColumns)
          .or('name.ilike.%$query%,area.ilike.%$query%');

      if (city != null) {
        dbQuery = dbQuery.eq('city', city);
      }

      final result = await dbQuery.order('rating',
          ascending: false, nullsFirst: false);
      return (result as List)
          .map((e) => Venue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw VenueServiceException('Failed to search venues: $e');
    }
  }

  /// Fetch available cities with venue counts.
  Future<List<VenueCity>> getAvailableCities() async {
    try {
      final result = await SupabaseManager.instance.client
          .from('venue_cities')
          .select()
          .order('venue_count', ascending: false);
      return (result as List)
          .map((e) => VenueCity.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw VenueServiceException('Failed to load cities: $e');
    }
  }
}

/// Exception thrown by [VenueService] operations.
class VenueServiceException implements Exception {
  final String message;
  const VenueServiceException(this.message);

  @override
  String toString() => 'VenueServiceException: $message';
}
