import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../models/health_models.dart';
import 'supabase_client.dart';

/// Service for all health-related data operations via Supabase.
class HealthService {
  // ---------------------------------------------------------------------------
  // Biomarkers
  // ---------------------------------------------------------------------------

  /// Fetch all biomarkers for a pet, ordered by most recent first.
  Future<List<Biomarker>> getBiomarkers(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('biomarkers')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Biomarker.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch biomarkers: $e');
    }
  }

  /// Add a new biomarker reading.
  Future<Biomarker> addBiomarker(BiomarkerCreate biomarker) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('biomarkers')
          .insert(biomarker.toJson())
          .select()
          .single();
      return Biomarker.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to add biomarker: $e');
    }
  }

  /// Delete a biomarker by ID.
  Future<void> deleteBiomarker(String id) async {
    try {
      await SupabaseManager.instance.client
          .from('biomarkers')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw HealthServiceException('Failed to delete biomarker: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Medications
  // ---------------------------------------------------------------------------

  /// Fetch all medications for a pet, ordered by most recent first.
  Future<List<Medication>> getMedications(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('medications')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch medications: $e');
    }
  }

  /// Add a new medication.
  Future<Medication> addMedication(MedicationCreate medication) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('medications')
          .insert(medication.toJson())
          .select()
          .single();
      return Medication.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to add medication: $e');
    }
  }

  /// Delete a medication by ID.
  Future<void> deleteMedication(String id) async {
    try {
      await SupabaseManager.instance.client
          .from('medications')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw HealthServiceException('Failed to delete medication: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Medical Records
  // ---------------------------------------------------------------------------

  /// Fetch all medical records for a pet, ordered by date descending.
  Future<List<MedicalRecord>> getMedicalRecords(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('medical_records')
          .select()
          .eq('pet_id', petId)
          .order('date', ascending: false);
      return (response as List)
          .map((e) => MedicalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch medical records: $e');
    }
  }

  /// Add a new medical record.
  Future<MedicalRecord> addMedicalRecord(MedicalRecordCreate record) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('medical_records')
          .insert(record.toJson())
          .select()
          .single();
      return MedicalRecord.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to add medical record: $e');
    }
  }

  /// Delete a medical record by ID.
  Future<void> deleteMedicalRecord(String id) async {
    try {
      await SupabaseManager.instance.client
          .from('medical_records')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw HealthServiceException('Failed to delete medical record: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Walk Sessions
  // ---------------------------------------------------------------------------

  /// Fetch all walk sessions for a pet, ordered by date descending.
  Future<List<WalkSession>> getWalkSessions(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('walk_sessions')
          .select()
          .eq('pet_id', petId)
          .order('date', ascending: false);
      return (response as List)
          .map((e) => WalkSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch walk sessions: $e');
    }
  }

  /// Add a new walk session.
  Future<WalkSession> addWalkSession(WalkSessionCreate session) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('walk_sessions')
          .insert(session.toJson())
          .select()
          .single();
      return WalkSession.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to add walk session: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Insurance Claims
  // ---------------------------------------------------------------------------

  /// Fetch all insurance claims for a pet, ordered by most recent first.
  Future<List<InsuranceClaim>> getInsuranceClaims(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('insurance_claims')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => InsuranceClaim.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch insurance claims: $e');
    }
  }

  /// Add a new insurance claim.
  Future<InsuranceClaim> addInsuranceClaim(InsuranceClaimCreate claim) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('insurance_claims')
          .insert(claim.toJson())
          .select()
          .single();
      return InsuranceClaim.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to add insurance claim: $e');
    }
  }

  /// Update the status of an insurance claim.
  Future<InsuranceClaim> updateInsuranceClaim(
    String id,
    String status,
  ) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('insurance_claims')
          .update({'status': status})
          .eq('id', id)
          .select()
          .single();
      return InsuranceClaim.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to update insurance claim: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Health Alerts
  // ---------------------------------------------------------------------------

  /// Fetch all health alerts for a pet, ordered by most recent first.
  Future<List<HealthAlert>> getHealthAlerts(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('health_alerts')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => HealthAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch health alerts: $e');
    }
  }

  /// Resolve a health alert by setting status to "resolved".
  Future<void> resolveHealthAlert(String id) async {
    try {
      await SupabaseManager.instance.client.from('health_alerts').update({
        'status': 'resolved',
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw HealthServiceException('Failed to resolve health alert: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Documents
  // ---------------------------------------------------------------------------

  /// Fetch all documents for a pet, ordered by most recent first.
  Future<List<PetDocument>> getDocuments(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('documents')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => PetDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch documents: $e');
    }
  }

  /// Add a new document record.
  Future<PetDocument> addDocument(DocumentCreate doc) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('documents')
          .insert(doc.toJson())
          .select()
          .single();
      return PetDocument.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to add document: $e');
    }
  }

  /// Upload a document file to Supabase storage and return the public URL.
  Future<String> uploadDocument({
    required String petId,
    required String fileName,
    required Uint8List fileData,
    required String contentType,
  }) async {
    try {
      final client = SupabaseManager.instance.client;
      final userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw HealthServiceException(
            'Not authenticated — sign in before uploading');
      }

      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      // Path starts with auth.uid() to satisfy storage RLS policies
      final path = '$userId/$petId/${uuid}_$fileName';
      const bucket = 'pet-documents';

      await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            fileData,
            fileOptions: FileOptions(contentType: contentType),
          );

      final publicUrl = SupabaseManager.instance.client.storage
          .from(bucket)
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw HealthServiceException('Failed to upload document: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Symptoms (health_events where event_type = 'symptom')
  // ---------------------------------------------------------------------------

  /// Fetch all symptoms for a pet, ordered by event date descending.
  Future<List<SymptomLog>> getSymptoms(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('health_events')
          .select()
          .eq('pet_id', petId)
          .eq('event_type', 'symptom')
          .order('event_date', ascending: false);
      return (response as List)
          .map((e) => SymptomLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw HealthServiceException('Failed to fetch symptoms: $e');
    }
  }

  /// Add a new symptom log.
  Future<SymptomLog> addSymptom(SymptomLogCreate symptom) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('health_events')
          .insert(symptom.toJson())
          .select()
          .single();
      return SymptomLog.fromJson(response);
    } catch (e) {
      throw HealthServiceException('Failed to add symptom: $e');
    }
  }

  /// Resolve a symptom by setting its status to "resolved".
  Future<void> resolveSymptom(String id) async {
    try {
      await SupabaseManager.instance.client
          .from('health_events')
          .update({'status': 'resolved'}).eq('id', id);
    } catch (e) {
      throw HealthServiceException('Failed to resolve symptom: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Health Score History
  // ---------------------------------------------------------------------------

  /// Upsert a health score snapshot for trend tracking.
  Future<void> saveHealthScore(
    String petId,
    int score,
    Map<String, int> breakdown,
  ) async {
    try {
      await SupabaseManager.instance.client.from('health_scores').upsert({
        'pet_id': petId,
        'score': score,
        'breakdown': breakdown,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Non-fatal — score history is a nice-to-have
    }
  }

  // ---------------------------------------------------------------------------
  // Wellness Survey
  // ---------------------------------------------------------------------------

  /// Save (upsert) a wellness survey result for a pet.
  Future<void> saveWellnessSurvey({
    required String petId,
    required String ownerId,
    required Map<String, int> answers,
  }) async {
    try {
      await SupabaseManager.instance.client.from('wellness_surveys').upsert({
        'pet_id': petId,
        'owner_id': ownerId,
        'answers': answers,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      throw HealthServiceException('Failed to save wellness survey: $e');
    }
  }

  /// Fetch the most recent wellness survey for a pet, or null if none exists.
  Future<WellnessSurveyResult?> getLatestWellnessSurvey(String petId) async {
    try {
      final response = await SupabaseManager.instance.client
          .from('wellness_surveys')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      final data = Map<String, dynamic>.from(response as Map);
      final rawAnswers = (data['answers'] as Map?)?.cast<String, dynamic>() ?? {};
      final answers = rawAnswers.map((k, v) => MapEntry(k, (v as num).toInt()));
      return WellnessSurveyResult(
        petId: petId,
        date: (data['created_at'] as String?) ?? DateTime.now().toIso8601String(),
        answers: answers,
      );
    } catch (e) {
      throw HealthServiceException('Failed to fetch wellness survey: $e');
    }
  }
}

/// Exception thrown by [HealthService] operations.
class HealthServiceException implements Exception {
  final String message;
  const HealthServiceException(this.message);

  @override
  String toString() => 'HealthServiceException: $message';
}
