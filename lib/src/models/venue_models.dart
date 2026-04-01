import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';

// ── Dog-Friendly Status ──

enum DogFriendlyStatus {
  unknown,
  pendingVerification,
  verifiedFriendly,
  verifiedNotFriendly,
  callFailed,
  needsReview;

  String get jsonValue {
    switch (this) {
      case DogFriendlyStatus.unknown:
        return 'unknown';
      case DogFriendlyStatus.pendingVerification:
        return 'pending_verification';
      case DogFriendlyStatus.verifiedFriendly:
        return 'verified_friendly';
      case DogFriendlyStatus.verifiedNotFriendly:
        return 'verified_not_friendly';
      case DogFriendlyStatus.callFailed:
        return 'call_failed';
      case DogFriendlyStatus.needsReview:
        return 'needs_review';
    }
  }

  String get displayLabel {
    switch (this) {
      case DogFriendlyStatus.unknown:
        return 'Unknown';
      case DogFriendlyStatus.pendingVerification:
        return 'Pending';
      case DogFriendlyStatus.verifiedFriendly:
        return 'Verified';
      case DogFriendlyStatus.verifiedNotFriendly:
        return 'Not Pet-Friendly';
      case DogFriendlyStatus.callFailed:
        return 'Unverified';
      case DogFriendlyStatus.needsReview:
        return 'Under Review';
    }
  }

  Color get color {
    switch (this) {
      case DogFriendlyStatus.verifiedFriendly:
        return WellxColors.alertGreen;
      case DogFriendlyStatus.pendingVerification:
        return WellxColors.amberWatch;
      case DogFriendlyStatus.unknown:
      case DogFriendlyStatus.callFailed:
      case DogFriendlyStatus.needsReview:
        return WellxColors.textTertiary;
      case DogFriendlyStatus.verifiedNotFriendly:
        return WellxColors.coral;
    }
  }

  IconData get icon {
    switch (this) {
      case DogFriendlyStatus.verifiedFriendly:
        return Icons.verified;
      case DogFriendlyStatus.pendingVerification:
        return Icons.schedule;
      case DogFriendlyStatus.unknown:
      case DogFriendlyStatus.callFailed:
        return Icons.help_outline;
      case DogFriendlyStatus.needsReview:
        return Icons.warning_amber;
      case DogFriendlyStatus.verifiedNotFriendly:
        return Icons.cancel;
    }
  }

  static DogFriendlyStatus fromString(String? value) {
    switch (value) {
      case 'pending_verification':
        return DogFriendlyStatus.pendingVerification;
      case 'verified_friendly':
        return DogFriendlyStatus.verifiedFriendly;
      case 'verified_not_friendly':
        return DogFriendlyStatus.verifiedNotFriendly;
      case 'call_failed':
        return DogFriendlyStatus.callFailed;
      case 'needs_review':
        return DogFriendlyStatus.needsReview;
      default:
        return DogFriendlyStatus.unknown;
    }
  }
}

// ── Venue Category ──

enum VenueCategory {
  restaurant,
  cafe,
  park,
  hotel,
  bar,
  other;

  String get displayName {
    switch (this) {
      case VenueCategory.restaurant:
        return 'Restaurants';
      case VenueCategory.cafe:
        return 'Cafes';
      case VenueCategory.park:
        return 'Parks';
      case VenueCategory.hotel:
        return 'Hotels';
      case VenueCategory.bar:
        return 'Bars';
      case VenueCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case VenueCategory.restaurant:
        return Icons.restaurant;
      case VenueCategory.cafe:
        return Icons.coffee;
      case VenueCategory.park:
        return Icons.park;
      case VenueCategory.hotel:
        return Icons.hotel;
      case VenueCategory.bar:
        return Icons.wine_bar;
      case VenueCategory.other:
        return Icons.place;
    }
  }

  Color get color {
    switch (this) {
      case VenueCategory.restaurant:
        return WellxColors.amberWatch;
      case VenueCategory.cafe:
        return WellxColors.alertGreen;
      case VenueCategory.park:
        return WellxColors.scoreGreen;
      case VenueCategory.hotel:
        return WellxColors.midPurple;
      case VenueCategory.bar:
        return WellxColors.coral;
      case VenueCategory.other:
        return WellxColors.textTertiary;
    }
  }

  static VenueCategory fromString(String? value) {
    switch (value) {
      case 'restaurant':
        return VenueCategory.restaurant;
      case 'cafe':
        return VenueCategory.cafe;
      case 'park':
        return VenueCategory.park;
      case 'hotel':
        return VenueCategory.hotel;
      case 'bar':
        return VenueCategory.bar;
      default:
        return VenueCategory.other;
    }
  }
}

// ── Venue Sort Mode ──

enum VenueSortMode {
  rating,
  name,
  newest;

  String get label {
    switch (this) {
      case VenueSortMode.rating:
        return 'Rating';
      case VenueSortMode.name:
        return 'Name';
      case VenueSortMode.newest:
        return 'Newest';
    }
  }

  IconData get icon {
    switch (this) {
      case VenueSortMode.rating:
        return Icons.star;
      case VenueSortMode.name:
        return Icons.sort_by_alpha;
      case VenueSortMode.newest:
        return Icons.schedule;
    }
  }
}

// ── Dog-Friendly Details ──

class DogFriendlyDetails {
  final bool? indoorSeating;
  final bool? outdoorSeating;
  final bool? waterBowls;
  final bool? dogMenu;
  final bool? dogTreats;
  final bool? leashRequired;
  final String? sizeRestrictions;
  final bool? offLeashArea;
  final String? notes;

  const DogFriendlyDetails({
    this.indoorSeating,
    this.outdoorSeating,
    this.waterBowls,
    this.dogMenu,
    this.dogTreats,
    this.leashRequired,
    this.sizeRestrictions,
    this.offLeashArea,
    this.notes,
  });

  bool get hasAnyAmenity =>
      indoorSeating == true ||
      outdoorSeating == true ||
      waterBowls == true ||
      dogMenu == true ||
      dogTreats == true ||
      offLeashArea == true;

  factory DogFriendlyDetails.fromJson(Map<String, dynamic> json) {
    return DogFriendlyDetails(
      indoorSeating: json['indoor_seating'] as bool?,
      outdoorSeating: json['outdoor_seating'] as bool?,
      waterBowls: json['water_bowls'] as bool?,
      dogMenu: json['dog_menu'] as bool?,
      dogTreats: json['dog_treats'] as bool?,
      leashRequired: json['leash_required'] as bool?,
      sizeRestrictions: json['size_restrictions'] as String?,
      offLeashArea: json['off_leash_area'] as bool?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (indoorSeating != null) 'indoor_seating': indoorSeating,
        if (outdoorSeating != null) 'outdoor_seating': outdoorSeating,
        if (waterBowls != null) 'water_bowls': waterBowls,
        if (dogMenu != null) 'dog_menu': dogMenu,
        if (dogTreats != null) 'dog_treats': dogTreats,
        if (leashRequired != null) 'leash_required': leashRequired,
        if (sizeRestrictions != null) 'size_restrictions': sizeRestrictions,
        if (offLeashArea != null) 'off_leash_area': offLeashArea,
        if (notes != null) 'notes': notes,
      };
}

// ── Venue ──

class Venue {
  final String id;
  final String name;
  final String? phone;
  final String? whatsappNumber;
  final String? address;
  final String? area;
  final String? category;
  final String? website;
  final String? notes;
  final String? dogFriendlyStatusRaw;
  final DogFriendlyDetails? dogFriendlyDetails;
  final String? lastVerifiedAt;
  final String? verificationSource;
  final String? createdAt;
  final String? imageUrl;
  final double? rating;
  final double? latitude;
  final double? longitude;
  final String? googlePlaceId;
  final String? city;
  final String? countryCode;

  const Venue({
    required this.id,
    required this.name,
    this.phone,
    this.whatsappNumber,
    this.address,
    this.area,
    this.category,
    this.website,
    this.notes,
    this.dogFriendlyStatusRaw,
    this.dogFriendlyDetails,
    this.lastVerifiedAt,
    this.verificationSource,
    this.createdAt,
    this.imageUrl,
    this.rating,
    this.latitude,
    this.longitude,
    this.googlePlaceId,
    this.city,
    this.countryCode,
  });

  // Computed properties
  DogFriendlyStatus get status =>
      DogFriendlyStatus.fromString(dogFriendlyStatusRaw);

  bool get isVerified => status == DogFriendlyStatus.verifiedFriendly;

  VenueCategory get displayCategory => VenueCategory.fromString(category);

  bool get hasImage {
    final url = imageUrl;
    return url != null && url.isNotEmpty && url != 'none';
  }

  Uri? get imageUri {
    if (!hasImage) return null;
    return Uri.tryParse(imageUrl!);
  }

  Uri? get googleMapsUrl {
    if (latitude == null || longitude == null) return null;
    return Uri.parse('https://maps.google.com/?q=$latitude,$longitude');
  }

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      address: json['address'] as String?,
      area: json['area'] as String?,
      category: json['category'] as String?,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      dogFriendlyStatusRaw: json['dog_friendly_status'] as String?,
      dogFriendlyDetails: json['dog_friendly_details'] != null
          ? DogFriendlyDetails.fromJson(
              json['dog_friendly_details'] as Map<String, dynamic>)
          : null,
      lastVerifiedAt: json['last_verified_at'] as String?,
      verificationSource: json['verification_source'] as String?,
      createdAt: json['created_at'] as String?,
      imageUrl: json['image_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googlePlaceId: json['google_place_id'] as String?,
      city: json['city'] as String?,
      countryCode: json['country_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (phone != null) 'phone': phone,
        if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
        if (address != null) 'address': address,
        if (area != null) 'area': area,
        if (category != null) 'category': category,
        if (website != null) 'website': website,
        if (notes != null) 'notes': notes,
        if (dogFriendlyStatusRaw != null)
          'dog_friendly_status': dogFriendlyStatusRaw,
        if (dogFriendlyDetails != null)
          'dog_friendly_details': dogFriendlyDetails!.toJson(),
        if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
        if (verificationSource != null)
          'verification_source': verificationSource,
        if (createdAt != null) 'created_at': createdAt,
        if (imageUrl != null) 'image_url': imageUrl,
        if (rating != null) 'rating': rating,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (googlePlaceId != null) 'google_place_id': googlePlaceId,
        if (city != null) 'city': city,
        if (countryCode != null) 'country_code': countryCode,
      };
}

// ── Venue City ──

class VenueCity {
  final String id;
  final String city;
  final String countryCode;
  final double latitude;
  final double longitude;
  final int? venueCount;
  final String? lastDiscoveredAt;

  const VenueCity({
    required this.id,
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    this.venueCount,
    this.lastDiscoveredAt,
  });

  String get displayName => '$city, $countryCode';

  factory VenueCity.fromJson(Map<String, dynamic> json) {
    return VenueCity(
      id: json['id'] as String,
      city: json['city'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      venueCount: json['venue_count'] as int?,
      lastDiscoveredAt: json['last_discovered_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'city': city,
        'country_code': countryCode,
        'latitude': latitude,
        'longitude': longitude,
        if (venueCount != null) 'venue_count': venueCount,
        if (lastDiscoveredAt != null) 'last_discovered_at': lastDiscoveredAt,
      };
}
