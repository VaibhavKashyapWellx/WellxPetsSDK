import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// BCS View Quality
// ---------------------------------------------------------------------------

@immutable
class BCSViewQuality {
  final String lateral; // "good" | "partial" | "none"
  final String dorsal; // "good" | "partial" | "none"
  final String posterior; // "good" | "partial" | "none"

  const BCSViewQuality({
    required this.lateral,
    required this.dorsal,
    required this.posterior,
  });

  factory BCSViewQuality.fromJson(Map<String, dynamic> json) {
    return BCSViewQuality(
      lateral: json['lateral'] as String,
      dorsal: json['dorsal'] as String,
      posterior: json['posterior'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lateral': lateral,
      'dorsal': dorsal,
      'posterior': posterior,
    };
  }

  /// True when at least one view is good quality.
  bool get hasGoodView =>
      lateral == 'good' || dorsal == 'good' || posterior == 'good';

  /// Summary string for display.
  String get summary {
    final views = <String, String>{
      'Side': lateral,
      'Top': dorsal,
      'Rear': posterior,
    };
    final good = views.entries
        .where((e) => e.value == 'good')
        .map((e) => e.key)
        .toList();
    if (good.isEmpty) return 'Limited views';
    return '${good.join(', ')} view${good.length > 1 ? 's' : ''}';
  }
}

// ---------------------------------------------------------------------------
// BCS Record — persisted assessment
// ---------------------------------------------------------------------------

@immutable
class BCSRecord {
  final String id;
  final DateTime date;
  final int score;
  final String label;
  final double confidence;
  final String onLineSummary;
  final List<String> keyObservations;
  final List<String> healthFlags;
  final String dietaryRecommendation;
  final String speciesDetected;
  final String breedDetected;
  final int recheckWeeks;
  final BCSViewQuality viewQuality;
  final String? photoFilename;

  const BCSRecord({
    required this.id,
    required this.date,
    required this.score,
    required this.label,
    required this.confidence,
    required this.onLineSummary,
    required this.keyObservations,
    required this.healthFlags,
    required this.dietaryRecommendation,
    required this.speciesDetected,
    required this.breedDetected,
    required this.recheckWeeks,
    required this.viewQuality,
    this.photoFilename,
  });

  factory BCSRecord.fromJson(Map<String, dynamic> json) {
    return BCSRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      score: json['score'] as int,
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      onLineSummary: json['one_line_summary'] as String,
      keyObservations: (json['key_observations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      healthFlags: (json['health_flags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dietaryRecommendation: json['dietary_recommendation'] as String,
      speciesDetected: json['species_detected'] as String,
      breedDetected: json['breed_detected'] as String,
      recheckWeeks: json['recheck_weeks'] as int,
      viewQuality: BCSViewQuality.fromJson(
          json['view_quality'] as Map<String, dynamic>),
      photoFilename: json['photo_filename'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'score': score,
      'label': label,
      'confidence': confidence,
      'one_line_summary': onLineSummary,
      'key_observations': keyObservations,
      'health_flags': healthFlags,
      'dietary_recommendation': dietaryRecommendation,
      'species_detected': speciesDetected,
      'breed_detected': breedDetected,
      'recheck_weeks': recheckWeeks,
      'view_quality': viewQuality.toJson(),
      'photo_filename': photoFilename,
    };
  }

  /// True when the BCS score is outside the ideal range (4-5).
  bool get isOutOfRange => score < 4 || score > 5;

  /// Human-readable score category.
  String get category {
    if (score >= 1 && score <= 3) return 'Underweight';
    if (score >= 4 && score <= 5) return 'Ideal';
    if (score >= 6 && score <= 7) return 'Overweight';
    if (score >= 8 && score <= 9) return 'Obese';
    return 'Unknown';
  }

  /// Color name for UI theming.
  String get statusColorName {
    if (score >= 1 && score <= 2) return 'red';
    if (score == 3) return 'orange';
    if (score >= 4 && score <= 5) return 'green';
    if (score == 6) return 'orange';
    if (score >= 7 && score <= 9) return 'red';
    return 'gray';
  }
}

// ---------------------------------------------------------------------------
// BCS API Response — raw response from Claude vision
// ---------------------------------------------------------------------------

@immutable
class BCSAPIResponse {
  final int bcsScore;
  final String label;
  final double confidence;
  final String speciesDetected;
  final String breedDetected;
  final String oneLineSummary;
  final List<String> keyObservations;
  final BCSViewQuality viewQuality;
  final List<String> healthFlags;
  final String dietaryRecommendation;
  final int recheckWeeks;

  const BCSAPIResponse({
    required this.bcsScore,
    required this.label,
    required this.confidence,
    required this.speciesDetected,
    required this.breedDetected,
    required this.oneLineSummary,
    required this.keyObservations,
    required this.viewQuality,
    required this.healthFlags,
    required this.dietaryRecommendation,
    required this.recheckWeeks,
  });

  factory BCSAPIResponse.fromJson(Map<String, dynamic> json) {
    return BCSAPIResponse(
      bcsScore: json['bcs_score'] as int,
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      speciesDetected: json['species_detected'] as String,
      breedDetected: json['breed_detected'] as String,
      oneLineSummary: json['one_line_summary'] as String,
      keyObservations: (json['key_observations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      viewQuality: BCSViewQuality.fromJson(
          json['view_quality'] as Map<String, dynamic>),
      healthFlags: (json['health_flags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dietaryRecommendation: json['dietary_recommendation'] as String,
      recheckWeeks: json['recheck_weeks'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bcs_score': bcsScore,
      'label': label,
      'confidence': confidence,
      'species_detected': speciesDetected,
      'breed_detected': breedDetected,
      'one_line_summary': oneLineSummary,
      'key_observations': keyObservations,
      'view_quality': viewQuality.toJson(),
      'health_flags': healthFlags,
      'dietary_recommendation': dietaryRecommendation,
      'recheck_weeks': recheckWeeks,
    };
  }
}
