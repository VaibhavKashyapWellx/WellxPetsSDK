import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/health_models.dart';
import '../models/pet.dart';

// ---------------------------------------------------------------------------
// Score Models
// ---------------------------------------------------------------------------

/// Individual pillar score within the overall health score.
@immutable
class PillarScore {
  final String name;
  final int score;
  final String icon;
  final String color;

  const PillarScore({
    required this.name,
    required this.score,
    required this.icon,
    required this.color,
  });

  String get id => name;

  double get percent => score / 100.0;
}

/// Aggregate health score comprising weighted pillar scores.
@immutable
class HealthScore {
  final int overall;
  final List<PillarScore> pillars;
  final String updatedDate;

  const HealthScore({
    required this.overall,
    required this.pillars,
    required this.updatedDate,
  });

  /// Returns the weakest pillar (lowest score), useful for driving
  /// recommendations.
  PillarScore? get weakestPillar {
    if (pillars.isEmpty) return null;
    return pillars.reduce((a, b) => a.score < b.score ? a : b);
  }

  /// Pillars scoring below a threshold (default 60), sorted weakest first.
  List<PillarScore> pillarsNeedingAttention({int threshold = 60}) {
    final filtered = pillars.where((p) => p.score < threshold).toList();
    filtered.sort((a, b) => a.score.compareTo(b.score));
    return filtered;
  }
}

// ---------------------------------------------------------------------------
// Score Calculator
// ---------------------------------------------------------------------------

/// Calculates a 0-100 health score from biomarkers, walk sessions, wellness
/// survey results, and optional pet context for breed/size-adjusted scoring.
///
/// Port of the Swift ScoreCalculator with identical pillar definitions,
/// severity-graded biomarker scoring, trend adjustments, and blending logic.
class ScoreCalculator {
  ScoreCalculator._();

  // ---- Pillar Definitions -------------------------------------------------

  static const List<_PillarDefinition> _pillarDefinitions = [
    _PillarDefinition(
      name: 'Organ Strength',
      icon: 'heart.fill',
      color: 'red',
      weight: 0.30,
      keywords: [
        'kidney', 'liver', 'albumin', 'creatinine', 'bun', 'sdma', 'alt',
        'ast', 'ggt',
      ],
      wellnessCategories: ['APPETITE'],
    ),
    _PillarDefinition(
      name: 'Inflammation',
      icon: 'flame.fill',
      color: 'orange',
      weight: 0.20,
      keywords: ['crp', 'inflam', 'wbc', 'neutrophil'],
      wellnessCategories: ['COAT'],
    ),
    _PillarDefinition(
      name: 'Metabolic',
      icon: 'bolt.fill',
      color: 'gold',
      weight: 0.20,
      keywords: ['glucose', 'thyroid', 't4', 'cholesterol', 'triglyceride'],
      wellnessCategories: ['APPETITE'],
    ),
    _PillarDefinition(
      name: 'Body & Activity',
      icon: 'figure.walk',
      color: 'green',
      weight: 0.15,
      keywords: ['weight', 'bcs', 'body'],
      wellnessCategories: ['ACTIVITY', 'MOBILITY', 'EXERCISE'],
    ),
    _PillarDefinition(
      name: 'Wellness & Dental',
      icon: 'mouth.fill',
      color: 'blue',
      weight: 0.15,
      keywords: [],
      wellnessCategories: [
        'DENTAL', 'COAT', 'APPETITE', 'ENVIRONMENT', 'ENRICHMENT',
      ],
    ),
  ];

  // ---- Main Calculate Method ----------------------------------------------

  /// Calculate health score with optional pet context for breed/size-adjusted
  /// scoring.
  static HealthScore calculate({
    required List<Biomarker> biomarkers,
    List<WalkSession> walkSessions = const [],
    WellnessSurveyResult? wellnessResult,
    Pet? pet,
  }) {
    final pillarScores = <PillarScore>[];

    for (final definition in _pillarDefinitions) {
      final matching = biomarkers
          .where((b) => _matchesPillar(b, definition))
          .toList();

      // Severity-graded biomarker scoring
      int? biomarkerScore;
      if (matching.isNotEmpty) {
        final scores = matching.map(_severityGradedScore).toList();
        biomarkerScore =
            (scores.reduce((a, b) => a + b) / scores.length).round();
      }

      // Wellness score for this pillar
      final wellnessScore =
          _calculateWellnessScore(definition, wellnessResult);

      // Activity score for Body & Activity pillar (breed-adjusted)
      int? activityScore;
      if (definition.name == 'Body & Activity' && walkSessions.isNotEmpty) {
        activityScore = _calculateActivityScore(walkSessions, pet);
      }

      // Blend scores based on what data is available
      final finalScore = _blendScores(
        biomarkerScore: biomarkerScore,
        wellnessScore: wellnessScore,
        activityScore: activityScore,
        pillarName: definition.name,
      );

      pillarScores.add(PillarScore(
        name: definition.name,
        score: finalScore.clamp(0, 100),
        icon: definition.icon,
        color: definition.color,
      ));
    }

    // Weighted overall score
    var weightedSum = 0.0;
    for (var i = 0; i < pillarScores.length; i++) {
      weightedSum += pillarScores[i].score * _pillarDefinitions[i].weight;
    }
    final overall = weightedSum.round().clamp(0, 100);

    final now = DateTime.now();
    final updatedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return HealthScore(
      overall: overall,
      pillars: pillarScores,
      updatedDate: updatedDate,
    );
  }

  // ---- Severity-Graded Biomarker Scoring ----------------------------------

  /// Scores a biomarker on a gradient based on how far from the reference
  /// range it is.
  ///
  /// Normal = 85-100, slightly out = 65, moderately out = 40, severely out = 15.
  /// Also applies a trend penalty/bonus if trend data exists.
  static int _severityGradedScore(Biomarker biomarker) {
    final val = biomarker.value;
    final refMin = biomarker.referenceMin;
    final refMax = biomarker.referenceMax;
    if (val == null || refMin == null || refMax == null) return 50;

    final rangeSpan = refMax - refMin;
    if (rangeSpan <= 0) return 50;

    int baseScore;

    if (val >= refMin && val <= refMax) {
      // Normal -- score 85-100 based on how centered the value is
      final midpoint = (refMin + refMax) / 2.0;
      final distFromCenter = (val - midpoint).abs() / (rangeSpan / 2.0);
      baseScore = (100 - distFromCenter * 15).round();
    } else if (val < refMin) {
      // Low -- severity based on how far below minimum
      final deviation = (refMin - val) / rangeSpan;
      if (deviation < 0.2) {
        baseScore = 65; // Slightly low
      } else if (deviation < 0.5) {
        baseScore = 40; // Moderately low
      } else {
        baseScore = 15; // Severely low
      }
    } else {
      // High -- severity based on how far above maximum
      final deviation = (val - refMax) / rangeSpan;
      if (deviation < 0.2) {
        baseScore = 65; // Slightly high
      } else if (deviation < 0.5) {
        baseScore = 40; // Moderately high
      } else {
        baseScore = 15; // Severely high
      }
    }

    // Apply trend adjustment
    baseScore += _trendAdjustment(biomarker);

    return baseScore.clamp(0, 100);
  }

  /// Returns a score adjustment based on the biomarker's trend direction.
  ///
  /// Deteriorating = penalty, improving = bonus, stable = no change.
  static int _trendAdjustment(Biomarker biomarker) {
    final trend = biomarker.trend;
    final currentVal = biomarker.value;
    if (trend == null || trend.length < 2 || currentVal == null) return 0;

    final previousValues =
        trend.map((t) => t.value).whereType<double>().toList();
    if (previousValues.length < 2) return 0;

    // Second-to-last value
    final previousVal = previousValues[previousValues.length - 2];
    if (previousVal <= 0) return 0;

    final changePercent = (currentVal - previousVal) / previousVal * 100;

    // Determine if the change is good or bad based on status
    final isCurrentlyNormal = biomarker.status == 'normal';

    bool isMovingTowardNormal = false;
    final refMin = biomarker.referenceMin;
    final refMax = biomarker.referenceMax;
    if (refMin != null && refMax != null) {
      final midpoint = (refMin + refMax) / 2.0;
      final currentDist = (currentVal - midpoint).abs();
      final prevDist = (previousVal - midpoint).abs();
      isMovingTowardNormal = currentDist < prevDist;
    }

    if (isCurrentlyNormal && changePercent.abs() < 10) {
      return 5; // Stable and normal -- small bonus
    } else if (isMovingTowardNormal && changePercent.abs() > 10) {
      return 8; // Improving -- moderate bonus
    } else if (!isMovingTowardNormal && changePercent.abs() > 15) {
      return -10; // Deteriorating -- penalty
    }

    return 0;
  }

  // ---- Blending Logic -----------------------------------------------------

  static int _blendScores({
    int? biomarkerScore,
    int? wellnessScore,
    int? activityScore,
    required String pillarName,
  }) {
    final components = <_ScoreComponent>[];

    if (biomarkerScore != null) {
      components.add(_ScoreComponent(biomarkerScore, 0.5));
    }
    if (wellnessScore != null) {
      components.add(_ScoreComponent(wellnessScore, 0.3));
    }
    if (activityScore != null) {
      components.add(_ScoreComponent(activityScore, 0.2));
    }

    // If no data at all, return default
    if (components.isEmpty) return 50;

    // Normalize weights to sum to 1.0
    final totalWeight =
        components.fold<double>(0.0, (sum, c) => sum + c.weight);
    final blended = components.fold<double>(
      0.0,
      (sum, c) => sum + c.score * (c.weight / totalWeight),
    );

    return blended.round();
  }

  // ---- Wellness Score for Pillar ------------------------------------------

  static int? _calculateWellnessScore(
    _PillarDefinition definition,
    WellnessSurveyResult? result,
  ) {
    if (result == null || definition.wellnessCategories.isEmpty) return null;

    final scores = definition.wellnessCategories
        .map((cat) => result.scoreForCategory(cat))
        .whereType<int>()
        .toList();

    if (scores.isEmpty) return null;

    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  // ---- Pillar Matching Helper ---------------------------------------------

  static bool _matchesPillar(Biomarker biomarker, _PillarDefinition def) {
    final p = biomarker.pillar;
    if (p != null && p.isNotEmpty) {
      final pl = p.toLowerCase();
      final dl = def.name.toLowerCase();
      if (pl == dl || pl.contains(dl) || dl.contains(pl)) return true;
    }
    final nl = biomarker.name.toLowerCase();
    return def.keywords.any((kw) => nl.contains(kw));
  }

  // ---- Breed-Size Activity Targets ----------------------------------------

  static _ActivityTarget _activityTarget(Pet? pet) {
    final weight = pet?.weight;
    if (weight == null) {
      return const _ActivityTarget(
        idealDurationMin: 30,
        idealDistanceKm: 2.0,
        idealWalksPerWeek: 5,
      );
    }
    if (weight < 10) {
      // Small breeds (Chihuahua, Yorkie, Pomeranian)
      return const _ActivityTarget(
        idealDurationMin: 20,
        idealDistanceKm: 1.5,
        idealWalksPerWeek: 5,
      );
    } else if (weight < 25) {
      // Medium breeds (Beagle, Cocker Spaniel)
      return const _ActivityTarget(
        idealDurationMin: 30,
        idealDistanceKm: 3.0,
        idealWalksPerWeek: 5,
      );
    } else if (weight < 45) {
      // Large breeds (Lab, Golden Retriever, German Shepherd)
      return const _ActivityTarget(
        idealDurationMin: 45,
        idealDistanceKm: 5.0,
        idealWalksPerWeek: 6,
      );
    } else {
      // Giant breeds (Great Dane, Mastiff) -- moderate intensity
      return const _ActivityTarget(
        idealDurationMin: 35,
        idealDistanceKm: 3.5,
        idealWalksPerWeek: 5,
      );
    }
  }

  /// Breed-adjusted activity scoring based on last 7 days of walk sessions.
  static int _calculateActivityScore(
    List<WalkSession> walkSessions,
    Pet? pet,
  ) {
    if (walkSessions.isEmpty) return 50;
    final target = _activityTarget(pet);

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));

    final recent = walkSessions.where((ws) {
      final d = DateTime.tryParse(ws.date);
      return d != null && !d.isBefore(cutoff);
    }).toList();

    if (recent.isEmpty) return 40;

    // Frequency: scored against breed-specific target
    final freq =
        math.min(100, recent.length * 100 ~/ target.idealWalksPerWeek);

    // Duration: scored against breed-specific ideal
    final durations =
        recent.map((ws) => ws.durationMin).whereType<int>().toList();
    final avgDur =
        durations.isEmpty ? 0 : durations.reduce((a, b) => a + b) ~/ durations.length;
    final dur = math.min(100, avgDur * 100 ~/ target.idealDurationMin);

    // Distance: scored against breed-specific ideal
    final dists =
        recent.map((ws) => ws.distanceKm).whereType<double>().toList();
    final avgDist =
        dists.isEmpty ? 0.0 : dists.reduce((a, b) => a + b) / dists.length;
    final dist = math.min(100, (avgDist * 100.0 / target.idealDistanceKm).round());

    return (freq * 0.4 + dur * 0.35 + dist * 0.25).round().clamp(0, 100);
  }
}

// ---------------------------------------------------------------------------
// Private helper types
// ---------------------------------------------------------------------------

class _PillarDefinition {
  final String name;
  final String icon;
  final String color;
  final double weight;
  final List<String> keywords;
  final List<String> wellnessCategories;

  const _PillarDefinition({
    required this.name,
    required this.icon,
    required this.color,
    required this.weight,
    required this.keywords,
    required this.wellnessCategories,
  });
}

class _ActivityTarget {
  final int idealDurationMin;
  final double idealDistanceKm;
  final int idealWalksPerWeek;

  const _ActivityTarget({
    required this.idealDurationMin,
    required this.idealDistanceKm,
    required this.idealWalksPerWeek,
  });
}

class _ScoreComponent {
  final int score;
  final double weight;
  const _ScoreComponent(this.score, this.weight);
}
