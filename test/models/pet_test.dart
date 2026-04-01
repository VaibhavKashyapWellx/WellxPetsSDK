import 'package:flutter_test/flutter_test.dart';
import 'package:wellx_pets_sdk/src/models/pet.dart';

void main() {
  group('Pet', () {
    const petJson = {
      'id': 'pet-1',
      'name': 'Buddy',
      'breed': 'Golden Retriever',
      'species': 'dog',
      'date_of_birth': '2022-01-15',
      'gender': 'Male',
      'is_neutered': true,
      'weight': 30.5,
      'photo_url': 'https://example.com/buddy.jpg',
      'longevity_score': 85,
      'owner_id': 'user-1',
      'microchip': 'MC-123',
      'dubai_licence': 'DL-456',
      'blood_type': 'DEA 1.1+',
      'created_at': '2023-01-01T00:00:00Z',
      'updated_at': '2023-06-01T00:00:00Z',
    };

    test('fromJson parses all fields correctly', () {
      final pet = Pet.fromJson(petJson);

      expect(pet.id, 'pet-1');
      expect(pet.name, 'Buddy');
      expect(pet.breed, 'Golden Retriever');
      expect(pet.species, 'dog');
      expect(pet.dateOfBirth, '2022-01-15');
      expect(pet.gender, 'Male');
      expect(pet.isNeutered, true);
      expect(pet.weight, 30.5);
      expect(pet.photoUrl, 'https://example.com/buddy.jpg');
      expect(pet.longevityScore, 85);
      expect(pet.ownerId, 'user-1');
      expect(pet.microchip, 'MC-123');
      expect(pet.dubaiLicence, 'DL-456');
      expect(pet.bloodType, 'DEA 1.1+');
    });

    test('toJson produces correct snake_case keys', () {
      final pet = Pet.fromJson(petJson);
      final json = pet.toJson();

      expect(json['id'], 'pet-1');
      expect(json['name'], 'Buddy');
      expect(json['date_of_birth'], '2022-01-15');
      expect(json['is_neutered'], true);
      expect(json['photo_url'], 'https://example.com/buddy.jpg');
      expect(json['longevity_score'], 85);
      expect(json['owner_id'], 'user-1');
      expect(json['blood_type'], 'DEA 1.1+');
    });

    test('fromJson → toJson round-trips correctly', () {
      final pet = Pet.fromJson(petJson);
      final json = pet.toJson();
      final pet2 = Pet.fromJson(json);

      expect(pet2.id, pet.id);
      expect(pet2.name, pet.name);
      expect(pet2.breed, pet.breed);
      expect(pet2.weight, pet.weight);
    });

    test('fromJson handles null optional fields', () {
      final pet = Pet.fromJson({
        'id': 'pet-2',
        'name': 'Max',
        'breed': 'Poodle',
      });

      expect(pet.species, isNull);
      expect(pet.dateOfBirth, isNull);
      expect(pet.weight, isNull);
      expect(pet.longevityScore, isNull);
    });

    test('fromJson casts weight from int to double', () {
      final pet = Pet.fromJson({
        'id': 'pet-3',
        'name': 'Luna',
        'breed': 'Husky',
        'weight': 25,
      });
      expect(pet.weight, 25.0);
      expect(pet.weight, isA<double>());
    });

    group('displayAge', () {
      test('returns "Unknown" when dateOfBirth is null', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B');
        expect(pet.displayAge, 'Unknown');
      });

      test('returns "Unknown" when dateOfBirth is empty', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B', dateOfBirth: '');
        expect(pet.displayAge, 'Unknown');
      });

      test('returns "Unknown" when dateOfBirth is unparseable', () {
        const pet =
            Pet(id: '1', name: 'A', breed: 'B', dateOfBirth: 'not-a-date');
        expect(pet.displayAge, 'Unknown');
      });

      test('returns years for pets older than 1 year', () {
        final twoYearsAgo = DateTime.now().subtract(const Duration(days: 800));
        final dob =
            '${twoYearsAgo.year}-${twoYearsAgo.month.toString().padLeft(2, '0')}-${twoYearsAgo.day.toString().padLeft(2, '0')}';
        final pet = Pet(id: '1', name: 'A', breed: 'B', dateOfBirth: dob);
        expect(pet.displayAge, contains('year'));
      });

      test('returns months for pets under 1 year', () {
        final threeMonthsAgo =
            DateTime.now().subtract(const Duration(days: 90));
        final dob =
            '${threeMonthsAgo.year}-${threeMonthsAgo.month.toString().padLeft(2, '0')}-${threeMonthsAgo.day.toString().padLeft(2, '0')}';
        final pet = Pet(id: '1', name: 'A', breed: 'B', dateOfBirth: dob);
        expect(pet.displayAge, contains('month'));
      });
    });

    group('speciesEmoji', () {
      test('returns dog emoji for dog species', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B', species: 'dog');
        expect(pet.speciesEmoji, '\u{1F415}');
      });

      test('returns cat emoji for cat species', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B', species: 'cat');
        expect(pet.speciesEmoji, '\u{1F408}');
      });

      test('returns bird emoji for bird species', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B', species: 'bird');
        expect(pet.speciesEmoji, '\u{1F426}');
      });

      test('defaults to dog emoji when species is null', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B');
        expect(pet.speciesEmoji, '\u{1F415}');
      });

      test('returns paw prints for unknown species', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B', species: 'lizard');
        expect(pet.speciesEmoji, '\u{1F43E}');
      });

      test('is case-insensitive', () {
        const pet = Pet(id: '1', name: 'A', breed: 'B', species: 'Cat');
        expect(pet.speciesEmoji, '\u{1F408}');
      });
    });

    group('equality', () {
      test('two pets with same id are equal', () {
        const pet1 = Pet(id: 'x', name: 'Buddy', breed: 'Lab');
        const pet2 = Pet(id: 'x', name: 'Max', breed: 'Poodle');
        expect(pet1, equals(pet2));
      });

      test('two pets with different id are not equal', () {
        const pet1 = Pet(id: 'x', name: 'Buddy', breed: 'Lab');
        const pet2 = Pet(id: 'y', name: 'Buddy', breed: 'Lab');
        expect(pet1, isNot(equals(pet2)));
      });

      test('hashCode is consistent with equality', () {
        const pet1 = Pet(id: 'x', name: 'A', breed: 'B');
        const pet2 = Pet(id: 'x', name: 'C', breed: 'D');
        expect(pet1.hashCode, pet2.hashCode);
      });
    });
  });

  group('PetCreate', () {
    test('fromJson and toJson round-trip', () {
      const json = {
        'id': 'pc-1',
        'name': 'Rex',
        'breed': 'Bulldog',
        'species': 'dog',
        'date_of_birth': '2023-05-10',
      };
      final pc = PetCreate.fromJson(json);
      expect(pc.id, 'pc-1');
      expect(pc.name, 'Rex');

      final out = pc.toJson();
      expect(out['id'], 'pc-1');
      expect(out['date_of_birth'], '2023-05-10');
    });
  });

  group('PetUpdate', () {
    test('toJson only includes non-null fields', () {
      const update = PetUpdate(name: 'NewName', weight: 12.0);
      final json = update.toJson();

      expect(json['name'], 'NewName');
      expect(json['weight'], 12.0);
      expect(json.containsKey('breed'), false);
      expect(json.containsKey('species'), false);
      expect(json.containsKey('longevity_score'), false);
    });

    test('toJson returns empty map when all fields are null', () {
      const update = PetUpdate();
      expect(update.toJson(), isEmpty);
    });

    test('fromJson parses correctly', () {
      final update = PetUpdate.fromJson({
        'name': 'Updated',
        'weight': 15.5,
      });
      expect(update.name, 'Updated');
      expect(update.weight, 15.5);
      expect(update.breed, isNull);
    });
  });
}
