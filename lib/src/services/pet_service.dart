import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/pet.dart';
import 'supabase_client.dart';

/// Service for CRUD operations on the "pets" table.
class PetService {
  /// Admin panel API base URL (has service role key for storage uploads).
  static const _adminBaseURL = 'https://admin-panel-ruddy-seven.vercel.app';

  /// Fetch all pets belonging to the given owner.
  Future<List<Pet>> getPets(String ownerId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('pets')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Pet.fromJson(e)).toList();
    } catch (e) {
      throw PetServiceException('Failed to fetch pets: $e');
    }
  }

  /// Fetch a single pet by ID.
  Future<Pet> getPet(String id) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('pets')
          .select()
          .eq('id', id)
          .single();
      return Pet.fromJson(response);
    } catch (e) {
      throw PetServiceException('Failed to fetch pet: $e');
    }
  }

  /// Create a new pet.
  Future<Pet> createPet(PetCreate pet) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('pets')
          .insert(pet.toJson())
          .select()
          .single();
      return Pet.fromJson(response);
    } catch (e) {
      throw PetServiceException('Failed to create pet: $e');
    }
  }

  /// Update an existing pet. Returns the updated pet.
  Future<Pet> updatePet(String id, PetUpdate updates) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('pets')
          .update(updates.toJson())
          .eq('id', id)
          .select()
          .single();
      return Pet.fromJson(response);
    } catch (e) {
      throw PetServiceException('Failed to update pet: $e');
    }
  }

  /// Delete a pet by ID.
  Future<void> deletePet(String id) async {
    try {
      await SupabaseManager.instance.client
          .from('pets')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw PetServiceException('Failed to delete pet: $e');
    }
  }

  /// Upload a pet photo via admin API and update the pet record.
  ///
  /// Uses the admin panel endpoint which holds the service role key
  /// server-side to bypass storage RLS.
  Future<Pet> uploadAndSetPhoto(String petId, Uint8List imageData) async {
    // Get the user's JWT for auth
    final session = SupabaseManager.instance.client.auth.currentSession;
    if (session == null) {
      throw PetServiceException('Not signed in. Please sign in and try again.');
    }

    final uri = Uri.parse('$_adminBaseURL/api/pets/upload-photo');

    // Build multipart form data
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..fields['pet_id'] = petId
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        imageData,
        filename: 'photo.jpg',
      ));

    try {
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        throw PetServiceException(
          'Upload failed (${streamedResponse.statusCode}): $responseBody',
        );
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final petJson = decoded['pet'] as Map<String, dynamic>;
      return Pet.fromJson(petJson);
    } catch (e) {
      if (e is PetServiceException) rethrow;
      throw PetServiceException('Network error during upload: $e');
    }
  }
}

/// Exception thrown by [PetService] operations.
class PetServiceException implements Exception {
  final String message;
  const PetServiceException(this.message);

  @override
  String toString() => message;
}
