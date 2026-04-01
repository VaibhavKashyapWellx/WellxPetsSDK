import '../models/pet.dart';
import '../models/health_models.dart';

// ---------------------------------------------------------------------------
// Pet Health Context Builder
// ---------------------------------------------------------------------------
// Compiles all pet data into a clinically-organized context string that gives
// Claude maximum signal for veterinary reasoning.
// Ported from FureverApp's PetHealthContext.swift.

class PetHealthContext {
  PetHealthContext._();

  /// Build the full context string from all available pet data.
  static String build({
    required Pet pet,
    List<Biomarker> biomarkers = const [],
    List<Medication> medications = const [],
    List<HealthAlert> healthAlerts = const [],
    List<MedicalRecord> medicalRecords = const [],
    List<WalkSession> walkSessions = const [],
    List<PetDocument> documents = const [],
  }) {
    final sections = <String>[
      _buildProfileSection(pet),
      _buildBiomarkerSection(biomarkers),
      _buildMedicationSection(medications),
      _buildMedicalHistorySection(medicalRecords),
      _buildActivitySection(pet, walkSessions),
      _buildDocumentSection(documents),
      _buildAlertSection(healthAlerts),
      _buildBreedRiskProfile(pet),
    ];

    return sections.where((s) => s.isNotEmpty).join('\n\n');
  }

  // ── Pet Profile ──────────────────────────────────────────────────────────

  static String _buildProfileSection(Pet pet) {
    final lines = <String>['=== PET PROFILE ==='];
    lines.add('Name: ${pet.name}');
    lines.add('Species: ${pet.species ?? "Dog"}');
    lines.add('Breed: ${pet.breed}');
    if (pet.dateOfBirth != null && pet.dateOfBirth!.isNotEmpty) {
      lines.add('Date of Birth: ${pet.dateOfBirth} (Age: ${pet.displayAge})');
    }
    if (pet.gender != null) lines.add('Sex: ${pet.gender}');
    if (pet.isNeutered != null) {
      lines.add('Neutered/Spayed: ${pet.isNeutered! ? "Yes" : "No"}');
    }
    if (pet.weight != null) {
      lines.add('Weight: ${pet.weight!.toStringAsFixed(1)} kg');
    }
    if (pet.longevityScore != null) {
      lines.add('Longevity Score: ${pet.longevityScore}/100');
    }
    if (pet.microchip != null) lines.add('Microchip: ${pet.microchip}');
    if (pet.bloodType != null) lines.add('Blood Type: ${pet.bloodType}');
    return lines.join('\n');
  }

  // ── Biomarkers ───────────────────────────────────────────────────────────

  static String _buildBiomarkerSection(List<Biomarker> biomarkers) {
    if (biomarkers.isEmpty) {
      return '=== BIOMARKERS ===\nNo blood panel data on file. Recommend baseline blood work.';
    }

    final lines = <String>['=== RECENT BIOMARKERS ==='];

    final dates = biomarkers
        .map((b) => b.date)
        .where((d) => d != null)
        .cast<String>()
        .toList()
      ..sort();
    final latestDate = dates.isNotEmpty ? dates.last : 'Unknown';
    lines.add('Latest panel date: $latestDate');

    final flagged =
        biomarkers.where((b) => b.status == 'high' || b.status == 'low');
    final normal = biomarkers.where((b) => b.status == 'normal');

    if (flagged.isNotEmpty) {
      lines.add('\nFLAGGED VALUES (${flagged.length}):');
      for (final b in flagged) {
        var line = '  - ${b.name}: ${_fmtVal(b.value)} ${b.unit ?? ""}';
        if (b.referenceMin != null && b.referenceMax != null) {
          line +=
              ' [Ref: ${_fmtVal(b.referenceMin)}-${_fmtVal(b.referenceMax)}]';
        }
        line += ' -> STATUS: ${b.status.toUpperCase()}';
        if (b.pillar != null && b.pillar!.isNotEmpty) {
          line += ' (Pillar: ${b.pillar})';
        }
        if (b.trend != null && b.trend!.length > 1) {
          final values =
              b.trend!.map((t) => t.value).where((v) => v != null).toList();
          if (values.length >= 2) {
            final direction =
                values.last! > values.first! ? 'TRENDING UP' : 'TRENDING DOWN';
            line += ' $direction';
          }
        }
        lines.add(line);
      }
    } else {
      lines.add('All markers within reference ranges');
    }

    if (normal.isNotEmpty) {
      lines.add('\nNORMAL VALUES (${normal.length}):');
      for (final b in normal) {
        lines.add('  - ${b.name}: ${_fmtVal(b.value)} ${b.unit ?? ""}');
      }
    }

    return lines.join('\n');
  }

  // ── Medications ──────────────────────────────────────────────────────────

  static String _buildMedicationSection(List<Medication> medications) {
    if (medications.isEmpty) {
      return '=== MEDICATIONS ===\nNo current medications on file.';
    }

    final lines = <String>['=== CURRENT MEDICATIONS (${medications.length}) ==='];
    for (final med in medications) {
      var line = '  - ${med.name}';
      if (med.dosage != null) line += ' -- ${med.dosage}';
      if (med.instructions != null) line += ' (${med.instructions})';
      if (med.category != null) line += ' [Category: ${med.category}]';
      if (med.supplyTotal != null && med.supplyRemaining != null) {
        final pct = med.supplyTotal! > 0
            ? (med.supplyRemaining! / med.supplyTotal! * 100).round()
            : 0;
        if (pct < 25) {
          line += ' LOW SUPPLY: ${med.supplyRemaining} days remaining';
        } else {
          line += ' (Supply: ${med.supplyRemaining}/${med.supplyTotal} days)';
        }
      }
      if (med.refillDate != null) line += ' -- Refill by: ${med.refillDate}';
      lines.add(line);
    }
    return lines.join('\n');
  }

  // ── Medical History ──────────────────────────────────────────────────────

  static String _buildMedicalHistorySection(List<MedicalRecord> records) {
    if (records.isEmpty) return '';

    final lines = <String>['=== MEDICAL HISTORY ==='];
    for (final record in records.take(5)) {
      var line = '  - ${record.date}: ${record.title}';
      if (record.clinic != null) line += ' at ${record.clinic}';
      if (record.vetName != null) line += ' (Dr. ${record.vetName})';
      if (record.category != null) line += ' [${record.category}]';
      lines.add(line);

      if (record.diagnoses != null) {
        for (final dx in record.diagnoses!) {
          if (dx.name != null) {
            lines.add('    Diagnosis: ${dx.name}');
            if (dx.notes != null) lines.add('    Notes: ${dx.notes}');
          }
        }
      }

      if (record.prescribedMeds != null) {
        for (final rx in record.prescribedMeds!) {
          if (rx.name != null) {
            var rxLine = '    Prescribed: ${rx.name}';
            if (rx.dosage != null) rxLine += ' ${rx.dosage}';
            lines.add(rxLine);
          }
        }
      }
    }
    if (records.length > 5) {
      lines.add('  ... and ${records.length - 5} older records');
    }
    return lines.join('\n');
  }

  // ── Activity ─────────────────────────────────────────────────────────────

  static String _buildActivitySection(Pet pet, List<WalkSession> sessions) {
    if (sessions.isEmpty) return '';

    final lines = <String>['=== ACTIVITY (LAST 7 DAYS) ==='];
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = sessions.where((s) {
      final d = DateTime.tryParse(s.date);
      return d != null && d.isAfter(cutoff);
    }).toList();

    if (recent.isEmpty) {
      lines.add('  No walks logged in the past 7 days');
    } else {
      lines.add('  Walks this week: ${recent.length}');
      final durations =
          recent.map((s) => s.durationMin).where((d) => d != null).toList();
      if (durations.isNotEmpty) {
        final avg =
            durations.fold<int>(0, (sum, d) => sum + d!) ~/ durations.length;
        lines.add('  Average duration: $avg min');
      }
      final distances =
          recent.map((s) => s.distanceKm).where((d) => d != null).toList();
      if (distances.isNotEmpty) {
        final avg = distances.fold<double>(0, (sum, d) => sum + d!) /
            distances.length;
        lines.add('  Average distance: ${avg.toStringAsFixed(1)} km');
      }
    }
    return lines.join('\n');
  }

  // ── Documents ────────────────────────────────────────────────────────────

  static String _buildDocumentSection(List<PetDocument> documents) {
    if (documents.isEmpty) return '';

    final lines = <String>['=== DOCUMENTS ON FILE ==='];
    final grouped = <String, List<PetDocument>>{};
    for (final doc in documents) {
      final cat = doc.category ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(doc);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    for (final category in sortedKeys) {
      final docs = grouped[category]!;
      lines.add(
        '  $category: ${docs.length} document${docs.length == 1 ? "" : "s"}',
      );
      lines.add('    Latest: ${docs.first.title} (${docs.first.date})');
    }
    return lines.join('\n');
  }

  // ── Health Alerts ────────────────────────────────────────────────────────

  static String _buildAlertSection(List<HealthAlert> alerts) {
    final active = alerts.where((a) => a.isActive).toList();
    if (active.isEmpty) return '';

    final lines = <String>['=== ACTIVE HEALTH ALERTS ==='];
    for (final alert in active) {
      var line =
          '  [${alert.alertType?.toUpperCase() ?? "ALERT"}]';
      if (alert.marker != null) line += ' ${alert.marker}';
      if (alert.value != null) line += ': ${_fmtVal(alert.value)}';
      lines.add(line);
    }
    return lines.join('\n');
  }

  // ── Breed & Age Risk Profile ─────────────────────────────────────────────

  static String _buildBreedRiskProfile(Pet pet) {
    final breed = pet.breed.toLowerCase();
    final ageYears = _calculateAgeYears(pet.dateOfBirth);
    final risks = <String>[];

    // Dog breed predispositions
    if (breed.contains('golden retriever')) {
      risks.add(
        'Cancer predisposition (hemangiosarcoma, lymphoma) -- screening recommended after age 6',
      );
      risks.add('Hip/elbow dysplasia -- monitor mobility');
      risks.add('Hypothyroidism -- check T4 if energy changes noted');
      if (ageYears >= 8) {
        risks.add(
          'Senior Golden: annual full blood panel + chest X-ray recommended',
        );
      }
    } else if (breed.contains('french bulldog') || breed.contains('frenchie')) {
      risks.add(
        'BOAS (Brachycephalic Obstructive Airway Syndrome) -- monitor breathing',
      );
      risks.add('IVDD (Intervertebral Disc Disease) -- monitor back/mobility');
      risks.add(
        'Skin allergies -- monitor for chronic itching, ear infections',
      );
      risks.add('Heat sensitivity -- avoid exercise in temperatures above 25C');
    } else if (breed.contains('cavalier')) {
      risks.add(
        'MVD (Mitral Valve Disease) -- cardiac screening recommended annually from age 1',
      );
      risks.add(
        'Syringomyelia -- monitor for head scratching, neck pain',
      );
      if (ageYears >= 5) {
        risks.add('Cardiac echo strongly recommended at this age');
      }
    } else if (breed.contains('german shepherd')) {
      risks.add('Hip/elbow dysplasia -- monitor gait and mobility');
      risks.add(
        'Degenerative myelopathy -- watch for hind limb weakness',
      );
      risks.add(
        'EPI (Exocrine Pancreatic Insufficiency) -- monitor digestion and weight',
      );
      risks.add('Bloat/GDV risk -- avoid rapid eating, exercise after meals');
    } else if (breed.contains('labrador')) {
      risks.add('Obesity predisposition -- monitor weight closely');
      risks.add('Hip/elbow dysplasia -- monitor mobility');
      risks.add(
        'Exercise-induced collapse -- watch for weakness after intense activity',
      );
      if (ageYears >= 7) {
        risks.add(
          'Cancer screening recommended (mast cell tumours common)',
        );
      }
    } else if (breed.contains('dachshund')) {
      risks.add(
        'IVDD (Intervertebral Disc Disease) -- HIGH RISK, avoid jumping, monitor back',
      );
      risks.add('Obesity -- even small weight gain increases spinal stress');
    } else if (breed.contains('poodle') || breed.contains('doodle')) {
      risks.add(
        'Addison\'s disease -- monitor for lethargy, vomiting, weakness',
      );
      risks.add('Bloat/GDV risk (standard poodles)');
      risks.add('Ear infections -- regular ear cleaning recommended');
    } else if (breed.contains('bulldog') && !breed.contains('french')) {
      risks.add('BOAS -- monitor breathing, especially in heat');
      risks.add('Skin fold dermatitis -- regular cleaning of skin folds');
      risks.add('Hip dysplasia -- monitor mobility');
      risks.add('Cherry eye -- monitor for third eyelid protrusion');
    } else if (breed.contains('husky') || breed.contains('malamute')) {
      risks.add('Autoimmune conditions -- monitor skin and eyes');
      risks.add('Hip dysplasia -- monitor mobility');
      risks.add('Zinc-responsive dermatosis -- watch for skin/coat changes');
    } else if (breed.contains('boxer')) {
      risks.add(
        'Cardiomyopathy (Boxer cardiomyopathy) -- cardiac screening recommended',
      );
      risks.add('Cancer predisposition (mast cell tumours, lymphoma)');
      if (ageYears >= 6) {
        risks.add('Annual cardiac screening strongly recommended at this age');
      }
    } else if (breed.contains('rottweiler')) {
      risks.add(
        'Osteosarcoma risk -- monitor for limb swelling/pain, especially after age 7',
      );
      risks.add('Hip/elbow dysplasia');
      risks.add('Subaortic stenosis -- cardiac screening recommended');
    }

    // Cat breed predispositions
    if (breed.contains('persian')) {
      risks.add(
        'PKD (Polycystic Kidney Disease) -- monitor kidney values closely',
      );
      risks.add('Brachycephalic airway issues');
      risks.add('Eye/tear duct issues -- monitor for discharge');
    } else if (breed.contains('maine coon')) {
      risks.add(
        'HCM (Hypertrophic Cardiomyopathy) -- cardiac screening recommended',
      );
      risks.add(
        'Hip dysplasia (unusual for cats, but common in this breed)',
      );
      risks.add('Spinal muscular atrophy -- monitor mobility');
    } else if (breed.contains('siamese') || breed.contains('oriental')) {
      risks.add('Amyloidosis -- monitor liver and kidney values');
      risks.add('Asthma/respiratory issues');
      risks.add('Dental disease predisposition');
    } else if (breed.contains('bengal')) {
      risks.add('HCM -- cardiac screening recommended');
      risks.add('PRA (Progressive Retinal Atrophy) -- monitor vision');
    } else if (breed.contains('ragdoll')) {
      risks.add('HCM -- cardiac screening recommended annually');
      risks.add('Bladder stones -- monitor urination habits');
    }

    // Age-based screening
    final species = (pet.species ?? 'dog').toLowerCase();
    if (species == 'dog') {
      if (ageYears >= 7) {
        risks.add(
          'SENIOR DOG: Recommend biannual blood work, dental exam, urinalysis',
        );
      } else if (ageYears >= 1) {
        risks.add('ADULT DOG: Annual wellness exam + blood work recommended');
      }
    } else if (species == 'cat') {
      if (ageYears >= 10) {
        risks.add(
          'SENIOR CAT: Recommend biannual blood work, thyroid panel, blood pressure check',
        );
      } else if (ageYears >= 7) {
        risks.add(
          'MATURE CAT: Annual blood work with kidney values strongly recommended',
        );
      }
    }

    if (risks.isEmpty) return '';

    final lines = <String>[
      '=== BREED & AGE RISK PROFILE ===',
      'Breed: ${pet.breed} | Age: ${pet.displayAge}',
    ];
    for (final risk in risks) {
      lines.add('  - $risk');
    }
    return lines.join('\n');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _fmtVal(double? value) {
    if (value == null) return 'N/A';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static int _calculateAgeYears(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    final date = DateTime.tryParse(dob);
    if (date == null) return 0;
    final now = DateTime.now();
    int years = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }
}
