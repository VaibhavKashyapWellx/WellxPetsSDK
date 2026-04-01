import 'package:flutter/foundation.dart';

/// Pet model — maps to the "pets" table.
@immutable
class Pet {
  final String id;
  final String name;
  final String breed;
  final String? species;
  final String? dateOfBirth;
  final String? gender;
  final bool? isNeutered;
  final double? weight;
  final String? photoUrl;
  final int? longevityScore;
  final String? ownerId;
  final String? microchip;
  final String? dubaiLicence;
  final String? bloodType;
  final String? createdAt;
  final String? updatedAt;

  const Pet({
    required this.id,
    required this.name,
    required this.breed,
    this.species,
    this.dateOfBirth,
    this.gender,
    this.isNeutered,
    this.weight,
    this.photoUrl,
    this.longevityScore,
    this.ownerId,
    this.microchip,
    this.dubaiLicence,
    this.bloodType,
    this.createdAt,
    this.updatedAt,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String,
      species: json['species'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      isNeutered: json['is_neutered'] as bool?,
      weight: (json['weight'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      longevityScore: json['longevity_score'] as int?,
      ownerId: json['owner_id'] as String?,
      microchip: json['microchip'] as String?,
      dubaiLicence: json['dubai_licence'] as String?,
      bloodType: json['blood_type'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'species': species,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'is_neutered': isNeutered,
      'weight': weight,
      'photo_url': photoUrl,
      'longevity_score': longevityScore,
      'owner_id': ownerId,
      'microchip': microchip,
      'dubai_licence': dubaiLicence,
      'blood_type': bloodType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Human-readable age string computed from [dateOfBirth].
  String get displayAge {
    final dob = dateOfBirth;
    if (dob == null || dob.isEmpty) return 'Unknown';
    final date = DateTime.tryParse(dob);
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    int years = now.year - date.year;
    int months = now.month - date.month;
    if (now.day < date.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years > 0) {
      return '$years year${years == 1 ? '' : 's'}';
    }
    return '$months month${months == 1 ? '' : 's'}';
  }

  /// Emoji representing the pet's species.
  String get speciesEmoji {
    switch ((species ?? 'dog').toLowerCase()) {
      case 'dog':
        return '\u{1F415}'; // dog
      case 'cat':
        return '\u{1F408}'; // cat
      case 'bird':
        return '\u{1F426}'; // bird
      case 'rabbit':
        return '\u{1F407}'; // rabbit
      case 'fish':
        return '\u{1F41F}'; // fish
      case 'hamster':
        return '\u{1F439}'; // hamster
      default:
        return '\u{1F43E}'; // paw prints
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Pet && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Payload for creating a new pet.
@immutable
class PetCreate {
  final String id;
  final String name;
  final String breed;
  final String? species;
  final String? dateOfBirth;
  final String? gender;
  final bool? isNeutered;
  final double? weight;
  final String? photoUrl;
  final String? ownerId;
  final String? microchip;
  final String? dubaiLicence;
  final String? bloodType;

  const PetCreate({
    required this.id,
    required this.name,
    required this.breed,
    this.species,
    this.dateOfBirth,
    this.gender,
    this.isNeutered,
    this.weight,
    this.photoUrl,
    this.ownerId,
    this.microchip,
    this.dubaiLicence,
    this.bloodType,
  });

  factory PetCreate.fromJson(Map<String, dynamic> json) {
    return PetCreate(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String,
      species: json['species'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      isNeutered: json['is_neutered'] as bool?,
      weight: (json['weight'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      ownerId: json['owner_id'] as String?,
      microchip: json['microchip'] as String?,
      dubaiLicence: json['dubai_licence'] as String?,
      bloodType: json['blood_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'species': species,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'is_neutered': isNeutered,
      'weight': weight,
      'photo_url': photoUrl,
      'owner_id': ownerId,
      'microchip': microchip,
      'dubai_licence': dubaiLicence,
      'blood_type': bloodType,
    };
  }
}

/// Payload for updating an existing pet. All fields are optional.
@immutable
class PetUpdate {
  final String? name;
  final String? breed;
  final String? species;
  final String? dateOfBirth;
  final String? gender;
  final bool? isNeutered;
  final double? weight;
  final String? photoUrl;
  final int? longevityScore;
  final String? microchip;
  final String? dubaiLicence;
  final String? bloodType;

  const PetUpdate({
    this.name,
    this.breed,
    this.species,
    this.dateOfBirth,
    this.gender,
    this.isNeutered,
    this.weight,
    this.photoUrl,
    this.longevityScore,
    this.microchip,
    this.dubaiLicence,
    this.bloodType,
  });

  factory PetUpdate.fromJson(Map<String, dynamic> json) {
    return PetUpdate(
      name: json['name'] as String?,
      breed: json['breed'] as String?,
      species: json['species'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      isNeutered: json['is_neutered'] as bool?,
      weight: (json['weight'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      longevityScore: json['longevity_score'] as int?,
      microchip: json['microchip'] as String?,
      dubaiLicence: json['dubai_licence'] as String?,
      bloodType: json['blood_type'] as String?,
    );
  }

  /// Returns only non-null fields for a partial update.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (breed != null) map['breed'] = breed;
    if (species != null) map['species'] = species;
    if (dateOfBirth != null) map['date_of_birth'] = dateOfBirth;
    if (gender != null) map['gender'] = gender;
    if (isNeutered != null) map['is_neutered'] = isNeutered;
    if (weight != null) map['weight'] = weight;
    if (photoUrl != null) map['photo_url'] = photoUrl;
    if (longevityScore != null) map['longevity_score'] = longevityScore;
    if (microchip != null) map['microchip'] = microchip;
    if (dubaiLicence != null) map['dubai_licence'] = dubaiLicence;
    if (bloodType != null) map['blood_type'] = bloodType;
    return map;
  }
}
