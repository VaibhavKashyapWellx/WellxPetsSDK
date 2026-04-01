import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';

// ── Impact Milestone ──

class ImpactMilestone {
  final String id;
  final String title;
  final IconData icon;
  final int target;
  final int current;
  final Color color;

  const ImpactMilestone({
    required this.id,
    required this.title,
    required this.icon,
    required this.target,
    required this.current,
    required this.color,
  });

  double get progress {
    if (target <= 0) return 0;
    return min(1.0, current / target);
  }

  bool get isCompleted => current >= target;

  String get progressText => '$current/$target';
}

// ── Shelter Impact (global community metrics) ──

class ShelterImpact {
  final String id;
  final int dogsHelped;
  final int mealsProvided;
  final int sheltersPartnered;
  final int adoptionsFacilitated;
  final String? updatedAt;

  const ShelterImpact({
    required this.id,
    required this.dogsHelped,
    required this.mealsProvided,
    required this.sheltersPartnered,
    required this.adoptionsFacilitated,
    this.updatedAt,
  });

  static const empty = ShelterImpact(
    id: 'global',
    dogsHelped: 0,
    mealsProvided: 0,
    sheltersPartnered: 0,
    adoptionsFacilitated: 0,
  );

  factory ShelterImpact.fromJson(Map<String, dynamic> json) {
    return ShelterImpact(
      id: json['id'] as String? ?? 'global',
      dogsHelped: json['dogs_helped'] as int? ?? 0,
      mealsProvided: json['meals_provided'] as int? ?? 0,
      sheltersPartnered: json['shelters_partnered'] as int? ?? 0,
      adoptionsFacilitated: json['adoptions_facilitated'] as int? ?? 0,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dogs_helped': dogsHelped,
        'meals_provided': mealsProvided,
        'shelters_partnered': sheltersPartnered,
        'adoptions_facilitated': adoptionsFacilitated,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

// ── Shelter Profile ──

class ShelterProfile {
  final String id;
  final String name;
  final String? website;
  final String? location;
  final String? shelterType;
  final String? mission;
  final String? description;
  final String? animals;
  final String? photoUrl;
  final List<String>? currentNeeds;
  final String? donationUrl;
  final int? animalsInCare;
  final String? activeCampaign;
  final int? totalCoinsReceived;
  final int? totalDonors;
  final bool? isActive;

  const ShelterProfile({
    required this.id,
    required this.name,
    this.website,
    this.location,
    this.shelterType,
    this.mission,
    this.description,
    this.animals,
    this.photoUrl,
    this.currentNeeds,
    this.donationUrl,
    this.animalsInCare,
    this.activeCampaign,
    this.totalCoinsReceived,
    this.totalDonors,
    this.isActive,
  });

  String get typeLabel {
    switch (shelterType ?? 'rescue') {
      case 'shelter':
        return 'Shelter';
      case 'tnr':
        return 'TNR Program';
      case 'sanctuary':
        return 'Sanctuary';
      default:
        return 'Rescue';
    }
  }

  IconData get animalIcon {
    switch (animals ?? 'both') {
      case 'dogs':
        return Icons.pets;
      case 'cats':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  Color get animalColor {
    switch (animals ?? 'both') {
      case 'dogs':
        return WellxColors.scoreGreen;
      case 'cats':
        return WellxColors.hormonalHarmony;
      default:
        return WellxColors.alertGreen;
    }
  }

  factory ShelterProfile.fromJson(Map<String, dynamic> json) {
    return ShelterProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      website: json['website'] as String?,
      location: json['location'] as String?,
      shelterType: json['shelter_type'] as String?,
      mission: json['mission'] as String?,
      description: json['description'] as String?,
      animals: json['animals'] as String?,
      photoUrl: json['photo_url'] as String?,
      currentNeeds: (json['current_needs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      donationUrl: json['donation_url'] as String?,
      animalsInCare: json['animals_in_care'] as int?,
      activeCampaign: json['active_campaign'] as String?,
      totalCoinsReceived: json['total_coins_received'] as int?,
      totalDonors: json['total_donors'] as int?,
      isActive: json['is_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (website != null) 'website': website,
        if (location != null) 'location': location,
        if (shelterType != null) 'shelter_type': shelterType,
        if (mission != null) 'mission': mission,
        if (description != null) 'description': description,
        if (animals != null) 'animals': animals,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (currentNeeds != null) 'current_needs': currentNeeds,
        if (donationUrl != null) 'donation_url': donationUrl,
        if (animalsInCare != null) 'animals_in_care': animalsInCare,
        if (activeCampaign != null) 'active_campaign': activeCampaign,
        if (totalCoinsReceived != null)
          'total_coins_received': totalCoinsReceived,
        if (totalDonors != null) 'total_donors': totalDonors,
        if (isActive != null) 'is_active': isActive,
      };
}

// ── Coin Allocation ──

class CoinAllocation {
  final String id;
  final String ownerId;
  final String shelterProfileId;
  final int coinsAllocated;
  final String? status;
  final String? allocatedAt;
  final bool? autoAllocated;

  const CoinAllocation({
    required this.id,
    required this.ownerId,
    required this.shelterProfileId,
    required this.coinsAllocated,
    this.status,
    this.allocatedAt,
    this.autoAllocated,
  });

  factory CoinAllocation.fromJson(Map<String, dynamic> json) {
    return CoinAllocation(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      shelterProfileId: json['shelter_profile_id'] as String? ?? '',
      coinsAllocated: json['coins_allocated'] as int? ?? 0,
      status: json['status'] as String?,
      allocatedAt: json['allocated_at'] as String?,
      autoAllocated: json['auto_allocated'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'shelter_profile_id': shelterProfileId,
        'coins_allocated': coinsAllocated,
        if (status != null) 'status': status,
        if (allocatedAt != null) 'allocated_at': allocatedAt,
        if (autoAllocated != null) 'auto_allocated': autoAllocated,
      };
}

// ── Community Pool ──

class CommunityPool {
  final int totalCoins;
  final int donorCount;
  final String monthLabel;
  final int monthGoal;
  final int userContribution;

  const CommunityPool({
    required this.totalCoins,
    required this.donorCount,
    required this.monthLabel,
    required this.monthGoal,
    required this.userContribution,
  });

  double get progress {
    if (monthGoal <= 0) return 0;
    return min(1.0, totalCoins / monthGoal);
  }

  String get aedEquivalent {
    final aed = totalCoins / 10.0;
    if (aed >= 1000) return '${(aed / 1000).toStringAsFixed(1)}K';
    return aed.toStringAsFixed(0);
  }

  static const empty = CommunityPool(
    totalCoins: 0,
    donorCount: 0,
    monthLabel: '',
    monthGoal: 500,
    userContribution: 0,
  );
}

// ── Shelter Dog ──

class ShelterDog {
  final String id;
  final String name;
  final String? breed;
  final String? age;
  final String? shelterName;
  final String? photoUrl;
  final String? story;
  final bool? isFeatured;
  final String? createdAt;

  const ShelterDog({
    required this.id,
    required this.name,
    this.breed,
    this.age,
    this.shelterName,
    this.photoUrl,
    this.story,
    this.isFeatured,
    this.createdAt,
  });

  factory ShelterDog.fromJson(Map<String, dynamic> json) {
    return ShelterDog(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String?,
      age: json['age'] as String?,
      shelterName: json['shelter_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      story: json['story'] as String?,
      isFeatured: json['is_featured'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (breed != null) 'breed': breed,
        if (age != null) 'age': age,
        if (shelterName != null) 'shelter_name': shelterName,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (story != null) 'story': story,
        if (isFeatured != null) 'is_featured': isFeatured,
        if (createdAt != null) 'created_at': createdAt,
      };
}
