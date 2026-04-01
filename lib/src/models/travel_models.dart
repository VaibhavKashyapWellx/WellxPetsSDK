import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';

// ── Travel Region ──

enum TravelRegion {
  middleEast('Middle East'),
  europe('Europe'),
  asia('Asia'),
  americas('Americas'),
  africa('Africa'),
  oceania('Oceania');

  final String label;
  const TravelRegion(this.label);

  String get jsonValue {
    switch (this) {
      case TravelRegion.middleEast:
        return 'Middle East';
      case TravelRegion.europe:
        return 'Europe';
      case TravelRegion.asia:
        return 'Asia';
      case TravelRegion.americas:
        return 'Americas';
      case TravelRegion.africa:
        return 'Africa';
      case TravelRegion.oceania:
        return 'Oceania';
    }
  }

  IconData get icon {
    switch (this) {
      case TravelRegion.middleEast:
        return Icons.public;
      case TravelRegion.europe:
        return Icons.public;
      case TravelRegion.asia:
        return Icons.public;
      case TravelRegion.americas:
        return Icons.public;
      case TravelRegion.africa:
        return Icons.public;
      case TravelRegion.oceania:
        return Icons.public;
    }
  }

  Color get color {
    switch (this) {
      case TravelRegion.middleEast:
        return WellxColors.amberWatch;
      case TravelRegion.europe:
        return WellxColors.scoreBlue;
      case TravelRegion.asia:
        return WellxColors.coral;
      case TravelRegion.americas:
        return WellxColors.alertGreen;
      case TravelRegion.africa:
        return WellxColors.scoreGreen;
      case TravelRegion.oceania:
        return WellxColors.deepPurple;
    }
  }

  static TravelRegion? fromString(String? value) {
    if (value == null) return null;
    for (final region in TravelRegion.values) {
      if (region.jsonValue == value) return region;
    }
    return null;
  }
}

// ── Travel Type ──

enum TravelType {
  cabin,
  cargo,
  checked;

  String get displayName {
    switch (this) {
      case TravelType.cabin:
        return 'In-Cabin';
      case TravelType.cargo:
        return 'Cargo';
      case TravelType.checked:
        return 'Checked Baggage';
    }
  }

  String get description {
    switch (this) {
      case TravelType.cabin:
        return 'Pet travels in the cabin with you in an approved carrier under the seat.';
      case TravelType.cargo:
        return 'Pet travels in a pressurized, climate-controlled cargo hold.';
      case TravelType.checked:
        return 'Pet is checked in as oversized baggage at the counter.';
    }
  }

  IconData get icon {
    switch (this) {
      case TravelType.cabin:
        return Icons.person;
      case TravelType.cargo:
        return Icons.inventory_2;
      case TravelType.checked:
        return Icons.luggage;
    }
  }

  Color get color {
    switch (this) {
      case TravelType.cabin:
        return WellxColors.alertGreen;
      case TravelType.cargo:
        return WellxColors.amberWatch;
      case TravelType.checked:
        return WellxColors.scoreBlue;
    }
  }

  static TravelType? fromString(String? value) {
    if (value == null) return null;
    for (final t in TravelType.values) {
      if (t.name == value) return t;
    }
    return null;
  }
}

// ── Travel Plan Status ──

enum TravelPlanStatus {
  planning,
  booked,
  inProgress,
  completed;

  String get jsonValue {
    switch (this) {
      case TravelPlanStatus.planning:
        return 'planning';
      case TravelPlanStatus.booked:
        return 'booked';
      case TravelPlanStatus.inProgress:
        return 'in_progress';
      case TravelPlanStatus.completed:
        return 'completed';
    }
  }

  String get displayName {
    switch (this) {
      case TravelPlanStatus.planning:
        return 'Planning';
      case TravelPlanStatus.booked:
        return 'Booked';
      case TravelPlanStatus.inProgress:
        return 'In Progress';
      case TravelPlanStatus.completed:
        return 'Completed';
    }
  }

  IconData get icon {
    switch (this) {
      case TravelPlanStatus.planning:
        return Icons.edit_note;
      case TravelPlanStatus.booked:
        return Icons.check_circle;
      case TravelPlanStatus.inProgress:
        return Icons.flight;
      case TravelPlanStatus.completed:
        return Icons.flag;
    }
  }

  Color get color {
    switch (this) {
      case TravelPlanStatus.planning:
        return WellxColors.amberWatch;
      case TravelPlanStatus.booked:
        return WellxColors.scoreBlue;
      case TravelPlanStatus.inProgress:
        return WellxColors.alertGreen;
      case TravelPlanStatus.completed:
        return WellxColors.scoreGreen;
    }
  }

  static TravelPlanStatus fromString(String? value) {
    switch (value) {
      case 'planning':
        return TravelPlanStatus.planning;
      case 'booked':
        return TravelPlanStatus.booked;
      case 'in_progress':
        return TravelPlanStatus.inProgress;
      case 'completed':
        return TravelPlanStatus.completed;
      default:
        return TravelPlanStatus.planning;
    }
  }
}

// ── Required Document ──

class RequiredDocument {
  final String name;
  final String description;
  final int? leadTimeDays;
  final String? costEstimate;

  const RequiredDocument({
    required this.name,
    required this.description,
    this.leadTimeDays,
    this.costEstimate,
  });

  factory RequiredDocument.fromJson(Map<String, dynamic> json) {
    return RequiredDocument(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      leadTimeDays: json['lead_time_days'] as int?,
      costEstimate: json['cost_estimate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        if (leadTimeDays != null) 'lead_time_days': leadTimeDays,
        if (costEstimate != null) 'cost_estimate': costEstimate,
      };
}

// ── Vaccination Requirements ──

class VaccinationRequirements {
  final int? rabiesValidityMonths;
  final bool? titerTestRequired;
  final bool? microchipIso;

  const VaccinationRequirements({
    this.rabiesValidityMonths,
    this.titerTestRequired,
    this.microchipIso,
  });

  factory VaccinationRequirements.fromJson(Map<String, dynamic> json) {
    return VaccinationRequirements(
      rabiesValidityMonths: json['rabies_validity_months'] as int?,
      titerTestRequired: json['titer_test_required'] as bool?,
      microchipIso: json['microchip_iso'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (rabiesValidityMonths != null)
          'rabies_validity_months': rabiesValidityMonths,
        if (titerTestRequired != null) 'titer_test_required': titerTestRequired,
        if (microchipIso != null) 'microchip_iso': microchipIso,
      };
}

// ── Travel Destination ──

class TravelDestination {
  final String id;
  final String countryCode;
  final String countryName;
  final String? region;
  final String? flagEmoji;
  final bool? petImportAllowed;
  final bool? quarantineRequired;
  final int? quarantineDays;
  final List<RequiredDocument>? requiredDocuments;
  final List<String>? bannedBreeds;
  final VaccinationRequirements? vaccinationRequirements;
  final String? entryProcessSummary;
  final String? climateNotes;
  final int? petFriendlinessScore;
  final String? lastVerifiedAt;
  final List<String>? sourceUrls;
  final String? confidenceLevel;
  final String? verificationStatus;
  final String? createdAt;
  final String? updatedAt;

  const TravelDestination({
    required this.id,
    required this.countryCode,
    required this.countryName,
    this.region,
    this.flagEmoji,
    this.petImportAllowed,
    this.quarantineRequired,
    this.quarantineDays,
    this.requiredDocuments,
    this.bannedBreeds,
    this.vaccinationRequirements,
    this.entryProcessSummary,
    this.climateNotes,
    this.petFriendlinessScore,
    this.lastVerifiedAt,
    this.sourceUrls,
    this.confidenceLevel,
    this.verificationStatus,
    this.createdAt,
    this.updatedAt,
  });

  // Computed properties
  int get documentCount => requiredDocuments?.length ?? 0;
  bool get hasBannedBreeds => bannedBreeds != null && bannedBreeds!.isNotEmpty;
  bool get isQuarantineRequired => quarantineRequired ?? false;
  String get flag => flagEmoji ?? '\u{1F30D}';

  String get friendlinessLevel {
    final score = petFriendlinessScore;
    if (score == null) return 'Unknown';
    if (score >= 80) return 'Very Friendly';
    if (score >= 60) return 'Friendly';
    if (score >= 40) return 'Moderate';
    return 'Restrictive';
  }

  Color get friendlinessColor {
    final score = petFriendlinessScore;
    if (score == null) return WellxColors.textTertiary;
    if (score >= 80) return WellxColors.alertGreen;
    if (score >= 60) return WellxColors.scoreGreen;
    if (score >= 40) return WellxColors.amberWatch;
    return WellxColors.coral;
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get hasConflict => verificationStatus == 'conflict';

  TravelRegion? get travelRegion => TravelRegion.fromString(region);

  factory TravelDestination.fromJson(Map<String, dynamic> json) {
    return TravelDestination(
      id: json['id'] as String,
      countryCode: json['country_code'] as String? ?? '',
      countryName: json['country_name'] as String? ?? '',
      region: json['region'] as String?,
      flagEmoji: json['flag_emoji'] as String?,
      petImportAllowed: json['pet_import_allowed'] as bool?,
      quarantineRequired: json['quarantine_required'] as bool?,
      quarantineDays: json['quarantine_days'] as int?,
      requiredDocuments: (json['required_documents'] as List<dynamic>?)
          ?.map((e) => RequiredDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      bannedBreeds: (json['banned_breeds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      vaccinationRequirements: json['vaccination_requirements'] != null
          ? VaccinationRequirements.fromJson(
              json['vaccination_requirements'] as Map<String, dynamic>)
          : null,
      entryProcessSummary: json['entry_process_summary'] as String?,
      climateNotes: json['climate_notes'] as String?,
      petFriendlinessScore: json['pet_friendliness_score'] as int?,
      lastVerifiedAt: json['last_verified_at'] as String?,
      sourceUrls: (json['source_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      confidenceLevel: json['confidence_level'] as String?,
      verificationStatus: json['verification_status'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'country_code': countryCode,
        'country_name': countryName,
        if (region != null) 'region': region,
        if (flagEmoji != null) 'flag_emoji': flagEmoji,
        if (petImportAllowed != null) 'pet_import_allowed': petImportAllowed,
        if (quarantineRequired != null)
          'quarantine_required': quarantineRequired,
        if (quarantineDays != null) 'quarantine_days': quarantineDays,
        if (requiredDocuments != null)
          'required_documents': requiredDocuments!.map((e) => e.toJson()).toList(),
        if (bannedBreeds != null) 'banned_breeds': bannedBreeds,
        if (vaccinationRequirements != null)
          'vaccination_requirements': vaccinationRequirements!.toJson(),
        if (entryProcessSummary != null)
          'entry_process_summary': entryProcessSummary,
        if (climateNotes != null) 'climate_notes': climateNotes,
        if (petFriendlinessScore != null)
          'pet_friendliness_score': petFriendlinessScore,
        if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
        if (sourceUrls != null) 'source_urls': sourceUrls,
        if (confidenceLevel != null) 'confidence_level': confidenceLevel,
        if (verificationStatus != null)
          'verification_status': verificationStatus,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

// ── Travel Airline ──

class TravelAirline {
  final String id;
  final String name;
  final String? iataCode;
  final String? logoUrl;
  final bool? allowsCabin;
  final bool? allowsCargo;
  final bool? allowsChecked;
  final double? cabinMaxWeightKg;
  final String? cabinCarrierDimensions;
  final String? cargoRestrictions;
  final List<String>? breedRestrictions;
  final double? petFeeCabinUsd;
  final double? petFeeCargoUsd;
  final String? bookingProcess;
  final List<RequiredDocument>? requiredDocuments;
  final bool? temperatureEmbargo;
  final List<int>? embargoMonths;
  final String? petPolicyUrl;
  final String? lastVerifiedAt;
  final String? createdAt;
  final String? updatedAt;

  const TravelAirline({
    required this.id,
    required this.name,
    this.iataCode,
    this.logoUrl,
    this.allowsCabin,
    this.allowsCargo,
    this.allowsChecked,
    this.cabinMaxWeightKg,
    this.cabinCarrierDimensions,
    this.cargoRestrictions,
    this.breedRestrictions,
    this.petFeeCabinUsd,
    this.petFeeCargoUsd,
    this.bookingProcess,
    this.requiredDocuments,
    this.temperatureEmbargo,
    this.embargoMonths,
    this.petPolicyUrl,
    this.lastVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  // Computed properties
  bool get cabinAvailable => allowsCabin ?? false;
  bool get cargoAvailable => allowsCargo ?? false;
  String get displayCode => iataCode ?? '\u{2014}';

  String get cabinFeeFormatted {
    final fee = petFeeCabinUsd;
    if (fee == null) return 'N/A';
    return '\$${fee.toInt()}';
  }

  String get cargoFeeFormatted {
    final fee = petFeeCargoUsd;
    if (fee == null) return 'N/A';
    return '\$${fee.toInt()}';
  }

  bool get hasEmbargoNow {
    if (temperatureEmbargo != true || embargoMonths == null) return false;
    final currentMonth = DateTime.now().month;
    return embargoMonths!.contains(currentMonth);
  }

  factory TravelAirline.fromJson(Map<String, dynamic> json) {
    return TravelAirline(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      iataCode: json['iata_code'] as String?,
      logoUrl: json['logo_url'] as String?,
      allowsCabin: json['allows_cabin'] as bool?,
      allowsCargo: json['allows_cargo'] as bool?,
      allowsChecked: json['allows_checked'] as bool?,
      cabinMaxWeightKg: (json['cabin_max_weight_kg'] as num?)?.toDouble(),
      cabinCarrierDimensions: json['cabin_carrier_dimensions'] as String?,
      cargoRestrictions: json['cargo_restrictions'] as String?,
      breedRestrictions: (json['breed_restrictions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      petFeeCabinUsd: (json['pet_fee_cabin_usd'] as num?)?.toDouble(),
      petFeeCargoUsd: (json['pet_fee_cargo_usd'] as num?)?.toDouble(),
      bookingProcess: json['booking_process'] as String?,
      requiredDocuments: (json['required_documents'] as List<dynamic>?)
          ?.map((e) => RequiredDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      temperatureEmbargo: json['temperature_embargo'] as bool?,
      embargoMonths: (json['embargo_months'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      petPolicyUrl: json['pet_policy_url'] as String?,
      lastVerifiedAt: json['last_verified_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (iataCode != null) 'iata_code': iataCode,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (allowsCabin != null) 'allows_cabin': allowsCabin,
        if (allowsCargo != null) 'allows_cargo': allowsCargo,
        if (allowsChecked != null) 'allows_checked': allowsChecked,
        if (cabinMaxWeightKg != null) 'cabin_max_weight_kg': cabinMaxWeightKg,
        if (cabinCarrierDimensions != null)
          'cabin_carrier_dimensions': cabinCarrierDimensions,
        if (cargoRestrictions != null) 'cargo_restrictions': cargoRestrictions,
        if (breedRestrictions != null) 'breed_restrictions': breedRestrictions,
        if (petFeeCabinUsd != null) 'pet_fee_cabin_usd': petFeeCabinUsd,
        if (petFeeCargoUsd != null) 'pet_fee_cargo_usd': petFeeCargoUsd,
        if (bookingProcess != null) 'booking_process': bookingProcess,
        if (requiredDocuments != null)
          'required_documents':
              requiredDocuments!.map((e) => e.toJson()).toList(),
        if (temperatureEmbargo != null)
          'temperature_embargo': temperatureEmbargo,
        if (embargoMonths != null) 'embargo_months': embargoMonths,
        if (petPolicyUrl != null) 'pet_policy_url': petPolicyUrl,
        if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

// ── Travel Route ──

class TravelRoute {
  final String id;
  final String originCountry;
  final String destinationCountry;
  final String? airlineId;
  final bool? directFlight;
  final double? typicalDurationHours;
  final bool? petCabinAvailable;
  final bool? petCargoAvailable;
  final double? estimatedTotalCostUsd;
  final String? routeNotes;
  final int? popularityRank;

  const TravelRoute({
    required this.id,
    required this.originCountry,
    required this.destinationCountry,
    this.airlineId,
    this.directFlight,
    this.typicalDurationHours,
    this.petCabinAvailable,
    this.petCargoAvailable,
    this.estimatedTotalCostUsd,
    this.routeNotes,
    this.popularityRank,
  });

  String get costFormatted {
    final cost = estimatedTotalCostUsd;
    if (cost == null) return 'TBD';
    return '\$${cost.toInt()}';
  }

  String get durationFormatted {
    final hours = typicalDurationHours;
    if (hours == null) return '\u{2014}';
    return '${hours.toInt()}h';
  }

  factory TravelRoute.fromJson(Map<String, dynamic> json) {
    return TravelRoute(
      id: json['id'] as String,
      originCountry: json['origin_country'] as String? ?? '',
      destinationCountry: json['destination_country'] as String? ?? '',
      airlineId: json['airline_id'] as String?,
      directFlight: json['direct_flight'] as bool?,
      typicalDurationHours:
          (json['typical_duration_hours'] as num?)?.toDouble(),
      petCabinAvailable: json['pet_cabin_available'] as bool?,
      petCargoAvailable: json['pet_cargo_available'] as bool?,
      estimatedTotalCostUsd:
          (json['estimated_total_cost_usd'] as num?)?.toDouble(),
      routeNotes: json['route_notes'] as String?,
      popularityRank: json['popularity_rank'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'origin_country': originCountry,
        'destination_country': destinationCountry,
        if (airlineId != null) 'airline_id': airlineId,
        if (directFlight != null) 'direct_flight': directFlight,
        if (typicalDurationHours != null)
          'typical_duration_hours': typicalDurationHours,
        if (petCabinAvailable != null) 'pet_cabin_available': petCabinAvailable,
        if (petCargoAvailable != null) 'pet_cargo_available': petCargoAvailable,
        if (estimatedTotalCostUsd != null)
          'estimated_total_cost_usd': estimatedTotalCostUsd,
        if (routeNotes != null) 'route_notes': routeNotes,
        if (popularityRank != null) 'popularity_rank': popularityRank,
      };
}

// ── Checklist Item ──

class ChecklistItem {
  final String id;
  final String task;
  final String category; // documents, health, carrier, booking
  final String? dueDate;
  bool completed;

  ChecklistItem({
    String? id,
    required this.task,
    required this.category,
    this.dueDate,
    this.completed = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  IconData get categoryIcon {
    switch (category) {
      case 'documents':
        return Icons.description;
      case 'health':
        return Icons.favorite;
      case 'carrier':
        return Icons.shopping_bag;
      case 'booking':
        return Icons.flight;
      default:
        return Icons.check_circle;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'documents':
        return WellxColors.amberWatch;
      case 'health':
        return WellxColors.alertGreen;
      case 'carrier':
        return WellxColors.scoreBlue;
      case 'booking':
        return WellxColors.coral;
      default:
        return WellxColors.textSecondary;
    }
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String?,
      task: json['task'] as String? ?? '',
      category: json['category'] as String? ?? 'documents',
      dueDate: json['due_date'] as String?,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'category': category,
        if (dueDate != null) 'due_date': dueDate,
        'completed': completed,
      };
}

// ── Travel Plan ──

class TravelPlan {
  final String id;
  final String ownerId;
  final String? petId;
  String destinationCountry;
  String? travelDate;
  String? returnDate;
  String? airlineId;
  String? travelType;
  List<ChecklistItem>? checklist;
  String status;
  String? notes;
  final String? createdAt;
  final String? updatedAt;

  TravelPlan({
    required this.id,
    required this.ownerId,
    this.petId,
    required this.destinationCountry,
    this.travelDate,
    this.returnDate,
    this.airlineId,
    this.travelType,
    this.checklist,
    this.status = 'planning',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  TravelPlanStatus get planStatus => TravelPlanStatus.fromString(status);

  double get checklistProgress {
    final items = checklist;
    if (items == null || items.isEmpty) return 0;
    final completed = items.where((i) => i.completed).length;
    return completed / items.length;
  }

  int get completedCount =>
      checklist?.where((i) => i.completed).length ?? 0;
  int get totalCount => checklist?.length ?? 0;

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    return TravelPlan(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      petId: json['pet_id'] as String?,
      destinationCountry: json['destination_country'] as String? ?? '',
      travelDate: json['travel_date'] as String?,
      returnDate: json['return_date'] as String?,
      airlineId: json['airline_id'] as String?,
      travelType: json['travel_type'] as String?,
      checklist: (json['checklist'] as List<dynamic>?)
          ?.map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'planning',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        if (petId != null) 'pet_id': petId,
        'destination_country': destinationCountry,
        if (travelDate != null) 'travel_date': travelDate,
        if (returnDate != null) 'return_date': returnDate,
        if (airlineId != null) 'airline_id': airlineId,
        if (travelType != null) 'travel_type': travelType,
        if (checklist != null)
          'checklist': checklist!.map((e) => e.toJson()).toList(),
        'status': status,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}
