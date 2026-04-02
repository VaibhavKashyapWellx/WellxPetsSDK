import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import 'supabase_client.dart';

/// Service for BCS (Body Condition Score) data operations via Supabase.
///
/// Persists results to the `bcs_records` table with fields:
/// id, pet_id, owner_id, score (1-9), image_url, body_fat_percentage,
/// muscle_condition, notes, created_at
class BCSService {
  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// Save a BCS result to Supabase and return the created record.
  Future<Map<String, dynamic>> saveBCSResult({
    required String petId,
    required String ownerId,
    required int score,
    String? imageUrl,
    double? bodyFatPercentage,
    String? muscleCondition,
    String? notes,
  }) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('bcs_records')
          .insert({
            'pet_id': petId,
            'owner_id': ownerId,
            'score': score,
            'image_url': imageUrl,
            'body_fat_percentage': bodyFatPercentage,
            'muscle_condition': muscleCondition,
            'notes': notes,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();
      return response as Map<String, dynamic>;
    } catch (e) {
      throw BCSServiceException('Failed to save BCS result: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Fetch all BCS records for a pet, ordered newest first.
  Future<List<Map<String, dynamic>>> getBCSHistory(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('bcs_records')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw BCSServiceException('Failed to fetch BCS history: $e');
    }
  }

  /// Get the single most-recent BCS record for a pet, or null if none.
  Future<Map<String, dynamic>?> getLatestBCS(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('bcs_records')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw BCSServiceException('Failed to fetch latest BCS: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------

  /// Upload a BCS photo to Supabase storage and return its public URL.
  Future<String> uploadBCSPhoto({
    required String petId,
    required Uint8List photoData,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$petId/bcs_${timestamp}_$fileName';
      const bucket = 'pet-documents';

      await SupabaseManager.instance.client.storage
          .from(bucket)
          .uploadBinary(
            path,
            photoData,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return SupabaseManager.instance.client.storage
          .from(bucket)
          .getPublicUrl(path);
    } catch (e) {
      throw BCSServiceException('Failed to upload BCS photo: $e');
    }
  }
}

/// Exception thrown by [BCSService] operations.
class BCSServiceException implements Exception {
  final String message;
  const BCSServiceException(this.message);

  @override
  String toString() => 'BCSServiceException: $message';
}
