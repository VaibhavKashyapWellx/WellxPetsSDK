import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Biomarker
// ---------------------------------------------------------------------------

@immutable
class TrendPoint {
  final String? date;
  final double? value;

  const TrendPoint({this.date, this.value});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String?,
      value: (json['value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'date': date, 'value': value};
}

/// A single biomarker reading for a pet.
@immutable
class Biomarker {
  final String id;
  final String? petId;
  final String name;
  final double? value;
  final String? unit;
  final double? referenceMin;
  final double? referenceMax;
  final String? pillar;
  final String? date;
  final List<TrendPoint>? trend;
  final String? source;
  final String? createdAt;

  const Biomarker({
    required this.id,
    required this.name,
    this.petId,
    this.value,
    this.unit,
    this.referenceMin,
    this.referenceMax,
    this.pillar,
    this.date,
    this.trend,
    this.source,
    this.createdAt,
  });

  factory Biomarker.fromJson(Map<String, dynamic> json) {
    return Biomarker(
      id: json['id'] as String,
      name: json['name'] as String,
      petId: json['pet_id'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      referenceMin: (json['reference_min'] as num?)?.toDouble(),
      referenceMax: (json['reference_max'] as num?)?.toDouble(),
      pillar: json['pillar'] as String?,
      date: json['date'] as String?,
      trend: (json['trend'] as List<dynamic>?)
          ?.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      source: json['source'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pet_id': petId,
      'value': value,
      'unit': unit,
      'reference_min': referenceMin,
      'reference_max': referenceMax,
      'pillar': pillar,
      'date': date,
      'trend': trend?.map((t) => t.toJson()).toList(),
      'source': source,
      'created_at': createdAt,
    };
  }

  /// Computed status based on value vs reference range.
  String get status {
    final val = value;
    final min = referenceMin;
    final max = referenceMax;
    if (val == null || min == null || max == null) return 'unknown';
    if (val < min) return 'low';
    if (val > max) return 'high';
    return 'normal';
  }
}

/// Payload for creating a new biomarker.
@immutable
class BiomarkerCreate {
  final String id;
  final String petId;
  final String name;
  final double value;
  final String unit;
  final double? referenceMin;
  final double? referenceMax;
  final String? pillar;
  final String? date;
  final String? source;

  const BiomarkerCreate({
    required this.id,
    required this.petId,
    required this.name,
    required this.value,
    required this.unit,
    this.referenceMin,
    this.referenceMax,
    this.pillar,
    this.date,
    this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'name': name,
      'value': value,
      'unit': unit,
      'reference_min': referenceMin,
      'reference_max': referenceMax,
      'pillar': pillar,
      'date': date,
      'source': source,
    };
  }
}

// ---------------------------------------------------------------------------
// Medication
// ---------------------------------------------------------------------------

/// A medication prescribed to a pet.
@immutable
class Medication {
  final String id;
  final String? petId;
  final String name;
  final String? dosage;
  final String? category;
  final int? supplyTotal;
  final int? supplyRemaining;
  final String? urgency;
  final String? refillDate;
  final String? instructions;
  final String? createdAt;

  const Medication({
    required this.id,
    required this.name,
    this.petId,
    this.dosage,
    this.category,
    this.supplyTotal,
    this.supplyRemaining,
    this.urgency,
    this.refillDate,
    this.instructions,
    this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      petId: json['pet_id'] as String?,
      dosage: json['dosage'] as String?,
      category: json['category'] as String?,
      supplyTotal: json['supply_total'] as int?,
      supplyRemaining: json['supply_remaining'] as int?,
      urgency: json['urgency'] as String?,
      refillDate: json['refill_date'] as String?,
      instructions: json['instructions'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pet_id': petId,
      'dosage': dosage,
      'category': category,
      'supply_total': supplyTotal,
      'supply_remaining': supplyRemaining,
      'urgency': urgency,
      'refill_date': refillDate,
      'instructions': instructions,
      'created_at': createdAt,
    };
  }

  double get supplyPercentage {
    final total = supplyTotal;
    final remaining = supplyRemaining;
    if (total == null || total <= 0 || remaining == null) return 0;
    return remaining / total;
  }

  String get urgencyColor {
    switch ((urgency ?? 'Low').toLowerCase()) {
      case 'high':
        return 'red';
      case 'medium':
        return 'orange';
      default:
        return 'green';
    }
  }
}

/// Payload for creating a new medication.
@immutable
class MedicationCreate {
  final String id;
  final String petId;
  final String name;
  final String? dosage;
  final String? category;
  final int? supplyTotal;
  final int? supplyRemaining;
  final String? urgency;
  final String? refillDate;
  final String? instructions;

  const MedicationCreate({
    required this.id,
    required this.petId,
    required this.name,
    this.dosage,
    this.category,
    this.supplyTotal,
    this.supplyRemaining,
    this.urgency,
    this.refillDate,
    this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'name': name,
      'dosage': dosage,
      'category': category,
      'supply_total': supplyTotal,
      'supply_remaining': supplyRemaining,
      'urgency': urgency,
      'refill_date': refillDate,
      'instructions': instructions,
    };
  }
}

// ---------------------------------------------------------------------------
// Medical Record
// ---------------------------------------------------------------------------

@immutable
class Diagnosis {
  final String? name;
  final String? notes;

  const Diagnosis({this.name, this.notes});

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      name: json['name'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'notes': notes};
}

@immutable
class PrescribedMed {
  final String? name;
  final String? dosage;

  const PrescribedMed({this.name, this.dosage});

  factory PrescribedMed.fromJson(Map<String, dynamic> json) {
    return PrescribedMed(
      name: json['name'] as String?,
      dosage: json['dosage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'dosage': dosage};
}

/// A medical record / vet visit entry.
@immutable
class MedicalRecord {
  final String id;
  final String? petId;
  final String title;
  final String date;
  final String? clinic;
  final String? vetName;
  final String? category;
  final String? notes;
  final List<Diagnosis>? diagnoses;
  final List<PrescribedMed>? prescribedMeds;
  final String? createdAt;

  const MedicalRecord({
    required this.id,
    required this.title,
    required this.date,
    this.petId,
    this.clinic,
    this.vetName,
    this.category,
    this.notes,
    this.diagnoses,
    this.prescribedMeds,
    this.createdAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      petId: json['pet_id'] as String?,
      clinic: json['clinic'] as String?,
      vetName: json['vet_name'] as String?,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      diagnoses: (json['diagnoses'] as List<dynamic>?)
          ?.map((e) => Diagnosis.fromJson(e as Map<String, dynamic>))
          .toList(),
      prescribedMeds: (json['prescribed_meds'] as List<dynamic>?)
          ?.map((e) => PrescribedMed.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'pet_id': petId,
      'clinic': clinic,
      'vet_name': vetName,
      'category': category,
      'notes': notes,
      'diagnoses': diagnoses?.map((d) => d.toJson()).toList(),
      'prescribed_meds': prescribedMeds?.map((m) => m.toJson()).toList(),
      'created_at': createdAt,
    };
  }
}

/// Payload for creating a new medical record.
@immutable
class MedicalRecordCreate {
  final String id;
  final String petId;
  final String title;
  final String date;
  final String? clinic;
  final String? vetName;
  final String? category;
  final String? notes;

  const MedicalRecordCreate({
    required this.id,
    required this.petId,
    required this.title,
    required this.date,
    this.clinic,
    this.vetName,
    this.category,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'date': date,
      'clinic': clinic,
      'vet_name': vetName,
      'category': category,
      'notes': notes,
    };
  }
}

// ---------------------------------------------------------------------------
// Walk Session
// ---------------------------------------------------------------------------

/// A walk session for a pet.
@immutable
class WalkSession {
  final String id;
  final String? petId;
  final String date;
  final int? steps;
  final double? distanceKm;
  final int? durationMin;
  final int? avgCadence;
  final String? createdAt;

  const WalkSession({
    required this.id,
    required this.date,
    this.petId,
    this.steps,
    this.distanceKm,
    this.durationMin,
    this.avgCadence,
    this.createdAt,
  });

  factory WalkSession.fromJson(Map<String, dynamic> json) {
    return WalkSession(
      id: json['id'] as String,
      date: json['date'] as String,
      petId: json['pet_id'] as String?,
      steps: json['steps'] as int?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      durationMin: json['duration_min'] as int?,
      avgCadence: json['avg_cadence'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'pet_id': petId,
      'steps': steps,
      'distance_km': distanceKm,
      'duration_min': durationMin,
      'avg_cadence': avgCadence,
      'created_at': createdAt,
    };
  }

  String get durationDisplay {
    final min = durationMin;
    if (min == null) return 'N/A';
    if (min < 60) return '$min min';
    return '${min ~/ 60}h ${min % 60}m';
  }
}

/// Payload for creating a new walk session.
@immutable
class WalkSessionCreate {
  final String id;
  final String petId;
  final String date;
  final int? steps;
  final double? distanceKm;
  final int? durationMin;
  final int? avgCadence;

  const WalkSessionCreate({
    required this.id,
    required this.petId,
    required this.date,
    this.steps,
    this.distanceKm,
    this.durationMin,
    this.avgCadence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'date': date,
      'steps': steps,
      'distance_km': distanceKm,
      'duration_min': durationMin,
      'avg_cadence': avgCadence,
    };
  }
}

// ---------------------------------------------------------------------------
// Insurance Claim
// ---------------------------------------------------------------------------

/// An insurance claim for a pet.
@immutable
class InsuranceClaim {
  final String id;
  final String? petId;
  final String title;
  final double? amount;
  final String? status;
  final String date;
  final String? category;
  final String? createdAt;

  const InsuranceClaim({
    required this.id,
    required this.title,
    required this.date,
    this.petId,
    this.amount,
    this.status,
    this.category,
    this.createdAt,
  });

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      petId: json['pet_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      category: json['category'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'pet_id': petId,
      'amount': amount,
      'status': status,
      'category': category,
      'created_at': createdAt,
    };
  }

  String get statusColor {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return 'green';
      case 'denied':
      case 'rejected':
        return 'red';
      case 'submitted':
      case 'pending':
        return 'orange';
      default:
        return 'gray';
    }
  }
}

/// Payload for creating a new insurance claim.
@immutable
class InsuranceClaimCreate {
  final String id;
  final String petId;
  final String title;
  final double? amount;
  final String status;
  final String date;
  final String? category;

  const InsuranceClaimCreate({
    required this.id,
    required this.petId,
    required this.title,
    required this.status,
    required this.date,
    this.amount,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'amount': amount,
      'status': status,
      'date': date,
      'category': category,
    };
  }
}

// ---------------------------------------------------------------------------
// Health Alert
// ---------------------------------------------------------------------------

/// A health alert for a pet.
@immutable
class HealthAlert {
  final String id;
  final String? petId;
  final String? alertType;
  final String? marker;
  final double? value;
  final String? status;
  final String? createdAt;
  final String? resolvedAt;

  const HealthAlert({
    required this.id,
    this.petId,
    this.alertType,
    this.marker,
    this.value,
    this.status,
    this.createdAt,
    this.resolvedAt,
  });

  factory HealthAlert.fromJson(Map<String, dynamic> json) {
    return HealthAlert(
      id: json['id'] as String,
      petId: json['pet_id'] as String?,
      alertType: json['alert_type'] as String?,
      marker: json['marker'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      resolvedAt: json['resolved_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'alert_type': alertType,
      'marker': marker,
      'value': value,
      'status': status,
      'created_at': createdAt,
      'resolved_at': resolvedAt,
    };
  }

  bool get isActive => (status ?? 'active').toLowerCase() == 'active';

  String get severityColor {
    switch ((alertType ?? '').toLowerCase()) {
      case 'critical':
        return 'red';
      case 'warning':
        return 'orange';
      default:
        return 'blue';
    }
  }
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------

/// An uploaded document for a pet.
@immutable
class PetDocument {
  final String id;
  final String? petId;
  final String title;
  final String date;
  final String? fileType;
  final String? category;
  final String? fileUrl;
  final String? createdAt;

  const PetDocument({
    required this.id,
    required this.title,
    required this.date,
    this.petId,
    this.fileType,
    this.category,
    this.fileUrl,
    this.createdAt,
  });

  factory PetDocument.fromJson(Map<String, dynamic> json) {
    return PetDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      petId: json['pet_id'] as String?,
      fileType: json['file_type'] as String?,
      category: json['category'] as String?,
      fileUrl: json['file_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'pet_id': petId,
      'file_type': fileType,
      'category': category,
      'file_url': fileUrl,
      'created_at': createdAt,
    };
  }
}

/// Payload for creating a new document.
@immutable
class DocumentCreate {
  final String id;
  final String petId;
  final String title;
  final String date;
  final String? fileType;
  final String? category;
  final String? fileUrl;

  const DocumentCreate({
    required this.id,
    required this.petId,
    required this.title,
    required this.date,
    this.fileType,
    this.category,
    this.fileUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'title': title,
      'date': date,
      'file_type': fileType,
      'category': category,
      'file_url': fileUrl,
    };
  }
}

// ---------------------------------------------------------------------------
// Symptom Log (stored in health_events table with event_type = 'symptom')
// ---------------------------------------------------------------------------

/// A logged symptom entry from the health_events table.
@immutable
class SymptomLog {
  final String id;
  final String? petId;
  final String? userId;
  final String eventType;
  final String source;
  final String? rawText;
  final String? codedTerm;
  final String? severity;
  final String status;
  final String eventDate;
  final Map<String, String>? metadata;
  final String? createdAt;

  const SymptomLog({
    required this.id,
    required this.eventType,
    required this.source,
    required this.status,
    required this.eventDate,
    this.petId,
    this.userId,
    this.rawText,
    this.codedTerm,
    this.severity,
    this.metadata,
    this.createdAt,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'] as String,
      eventType: json['event_type'] as String,
      source: json['source'] as String,
      status: json['status'] as String,
      eventDate: json['event_date'] as String,
      petId: json['pet_id'] as String?,
      userId: json['user_id'] as String?,
      rawText: json['raw_text'] as String?,
      codedTerm: json['coded_term'] as String?,
      severity: json['severity'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'source': source,
      'status': status,
      'event_date': eventDate,
      'pet_id': petId,
      'user_id': userId,
      'raw_text': rawText,
      'coded_term': codedTerm,
      'severity': severity,
      'metadata': metadata,
      'created_at': createdAt,
    };
  }

  String get symptomName => codedTerm ?? rawText ?? 'Unknown symptom';

  bool get isActive => status == 'active';

  String get severityLabel {
    final s = severity ?? 'mild';
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Payload for creating a new symptom log.
@immutable
class SymptomLogCreate {
  final String id;
  final String petId;
  final String userId;
  final String eventType;
  final String source;
  final String? rawText;
  final String codedTerm;
  final String severity;
  final String status;
  final String eventDate;
  final Map<String, String>? metadata;

  const SymptomLogCreate({
    required this.id,
    required this.petId,
    required this.userId,
    required this.eventType,
    required this.source,
    required this.codedTerm,
    required this.severity,
    required this.status,
    required this.eventDate,
    this.rawText,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'event_type': eventType,
      'source': source,
      'raw_text': rawText,
      'coded_term': codedTerm,
      'severity': severity,
      'status': status,
      'event_date': eventDate,
      'metadata': metadata,
    };
  }
}

// ---------------------------------------------------------------------------
// Wellness Survey Result (used by ScoreCalculator)
// ---------------------------------------------------------------------------

/// Persisted wellness survey answers for a pet.
@immutable
class WellnessSurveyResult {
  final String petId;
  final String date;

  /// category -> option index (0=best, 3=worst)
  final Map<String, int> answers;

  /// True when saved by onboarding -- does NOT count as a qualifying unlock action.
  final bool? isFromOnboarding;

  const WellnessSurveyResult({
    required this.petId,
    required this.date,
    required this.answers,
    this.isFromOnboarding,
  });

  /// Compute score from 0-100 for a given category.
  int? scoreForCategory(String category) {
    final answer = answers[category];
    if (answer == null) return null;
    switch (answer) {
      case 0:
        return 100;
      case 1:
        return 70;
      case 2:
        return 40;
      case 3:
        return 10;
      default:
        return 50;
    }
  }

  /// Overall wellness score (average of all answered categories).
  int get overallScore {
    if (answers.isEmpty) return 50;
    final scores = answers.values.map((answer) {
      switch (answer) {
        case 0:
          return 100;
        case 1:
          return 70;
        case 2:
          return 40;
        case 3:
          return 10;
        default:
          return 50;
      }
    });
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }
}
