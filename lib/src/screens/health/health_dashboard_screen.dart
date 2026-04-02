import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/health_models.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/score_calculator.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import 'biomarker_arc_gauge.dart';

/// Full health dashboard with tabbed segments.
class HealthDashboardScreen extends ConsumerStatefulWidget {
  final String petId;

  const HealthDashboardScreen({super.key, required this.petId});

  @override
  ConsumerState<HealthDashboardScreen> createState() =>
      _HealthDashboardScreenState();
}

class _HealthDashboardScreenState
    extends ConsumerState<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Rebuild when tab index changes so FAB shows/hides correctly
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showAddMedicationDialog(
      BuildContext context, String petId) async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    int? supplyCount;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Add Medication'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Medication name *',
                      hintText: 'e.g. Apoquel',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: 'e.g. 5mg twice daily',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: freqCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Instructions',
                      hintText: 'e.g. Give with food',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Supply count (pills/doses)',
                      hintText: 'e.g. 30',
                    ),
                    onChanged: (v) => supplyCount = int.tryParse(v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: WellxColors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        setDialogState(() => saving = true);
                        try {
                          await ref
                              .read(healthServiceProvider)
                              .addMedication(MedicationCreate(
                                id: const Uuid().v4(),
                                petId: petId,
                                name: name,
                                dosage: dosageCtrl.text.trim().isEmpty
                                    ? null
                                    : dosageCtrl.text.trim(),
                                instructions: freqCtrl.text.trim().isEmpty
                                    ? null
                                    : freqCtrl.text.trim(),
                                supplyTotal: supplyCount,
                                supplyRemaining: supplyCount,
                              ));
                          ref.invalidate(medicationsProvider(petId));
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Failed to add: $e')),
                            );
                          }
                        }
                      },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final petId = widget.petId;
    final pet = ref.watch(selectedPetProvider);
    final biomarkersAsync = ref.watch(biomarkersProvider(petId));
    final medicationsAsync = ref.watch(medicationsProvider(petId));
    final recordsAsync = ref.watch(medicalRecordsProvider(petId));
    final walksAsync = ref.watch(walkSessionsProvider(petId));
    final alertsAsync = ref.watch(healthAlertsProvider(petId));
    final wellnessAsync = ref.watch(wellnessSurveyProvider(petId));

    final biomarkers = biomarkersAsync.valueOrNull ?? [];
    final medications = medicationsAsync.valueOrNull ?? [];
    final records = recordsAsync.valueOrNull ?? [];
    final walks = walksAsync.valueOrNull ?? [];
    final alerts = alertsAsync.valueOrNull ?? [];
    final wellness = wellnessAsync.valueOrNull;

    final healthScore = (biomarkers.isNotEmpty || wellness != null)
        ? ScoreCalculator.calculate(
            biomarkers: biomarkers,
            walkSessions: walks,
            wellnessResult: wellness,
            pet: pet,
          )
        : null;

    // Persist health score whenever biomarkers reload (non-fatal side effect)
    ref.listen(biomarkersProvider(petId), (_, next) {
      if (next.hasValue && next.value!.isNotEmpty) {
        final score = ScoreCalculator.calculate(
          biomarkers: next.value!,
          walkSessions: ref.read(walkSessionsProvider(petId)).valueOrNull ?? [],
          wellnessResult:
              ref.read(wellnessSurveyProvider(petId)).valueOrNull,
          pet: ref.read(selectedPetProvider),
        );
        ref.read(healthServiceProvider).saveHealthScore(
          petId,
          score.overall,
          {for (final p in score.pillars) p.name: p.score},
        );
      }
    });

    return Scaffold(
      backgroundColor: WellxColors.background,
      // FAB only visible on the Medications tab (index 2)
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              backgroundColor: WellxColors.deepPurple,
              foregroundColor: Colors.white,
              onPressed: () => _showAddMedicationDialog(context, petId),
              child: const Icon(Icons.add),
            )
          : null,
      appBar: AppBar(
        backgroundColor: WellxColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(pet?.name ?? 'Health'),
        titleTextStyle: WellxTypography.cardTitle,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: WellxColors.deepPurple,
          labelColor: WellxColors.deepPurple,
          unselectedLabelColor: WellxColors.textTertiary,
          labelStyle: WellxTypography.chipText
              .copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: WellxTypography.chipText,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Biomarkers'),
            Tab(text: 'Medications'),
            Tab(text: 'Records'),
            Tab(text: 'Walks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview
          _OverviewTab(
            healthScore: healthScore,
            alerts: alerts,
          ),

          // Biomarkers
          _BiomarkersTab(biomarkers: biomarkers),

          // Medications
          _MedicationsTab(medications: medications),

          // Records
          _RecordsTab(records: records),

          // Walks
          _WalksTab(walks: walks),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  final HealthScore? healthScore;
  final List<HealthAlert> alerts;

  const _OverviewTab({this.healthScore, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (healthScore != null) ...[
            // Score ring
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: healthScore!.overall / 100.0,
                        strokeWidth: 8,
                        backgroundColor: WellxColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          WellxColors.scoreColor(healthScore!.overall),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${healthScore!.overall}',
                          style: WellxTypography.heroDisplay.copyWith(
                            fontSize: 36,
                            color: WellxColors.scoreColor(
                                healthScore!.overall),
                          ),
                        ),
                        Text('/ 100',
                            style: WellxTypography.captionText),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: WellxSpacing.xl),

            // Pillar cards grid
            Text(
              'HEALTH PILLARS',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: healthScore!.pillars.map((pillar) {
                return _PillarCard(pillar: pillar);
              }).toList(),
            ),
          ] else ...[
            WellxCard(
              padding: const EdgeInsets.all(WellxSpacing.xxl),
              backgroundColor: WellxColors.inkPrimary,
              borderColor: Colors.transparent,
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.favorite,
                        color: Colors.white54, size: 36),
                    const SizedBox(height: WellxSpacing.lg),
                    Text(
                      'Complete a health check to see your overview',
                      textAlign: TextAlign.center,
                      style: WellxTypography.heading
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Recent alerts
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: WellxSpacing.xl),
            Text(
              'RECENT ALERTS',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.coral,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.md),
            ...alerts.take(5).map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
                child: WellxCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: WellxColors.coral.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber,
                            size: 14, color: WellxColors.coral),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.marker ?? 'Health Alert',
                              style: WellxTypography.chipText.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (alert.alertType != null)
                              Text(alert.alertType!,
                                  style: WellxTypography.captionText),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final PillarScore pillar;

  const _PillarCard({required this.pillar});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _pillarIcon(pillar.name),
                size: 14,
                color: _pillarColor(pillar.color),
              ),
              const Spacer(),
              Text(
                '${pillar.score}',
                style: WellxTypography.dataNumber.copyWith(
                  color: WellxColors.scoreColor(pillar.score),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            pillar.name,
            style: WellxTypography.captionText.copyWith(
              fontWeight: FontWeight.w600,
              color: WellxColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pillar.percent,
              minHeight: 4,
              backgroundColor: WellxColors.border,
              valueColor: AlwaysStoppedAnimation(
                WellxColors.scoreColor(pillar.score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _pillarIcon(String name) {
    switch (name) {
      case 'Organ Strength':
        return Icons.favorite;
      case 'Inflammation':
        return Icons.local_fire_department;
      case 'Metabolic':
        return Icons.bolt;
      case 'Body & Activity':
        return Icons.directions_walk;
      case 'Wellness & Dental':
        return Icons.mood;
      default:
        return Icons.circle;
    }
  }

  Color _pillarColor(String color) {
    switch (color) {
      case 'red':
        return WellxColors.organStrength;
      case 'orange':
        return WellxColors.inflammation;
      case 'gold':
        return WellxColors.metabolic;
      case 'green':
        return WellxColors.bodyActivity;
      case 'blue':
        return WellxColors.wellnessDental;
      default:
        return WellxColors.textTertiary;
    }
  }
}

// ---------------------------------------------------------------------------
// Biomarkers Tab
// ---------------------------------------------------------------------------

class _BiomarkersTab extends StatelessWidget {
  final List<Biomarker> biomarkers;

  const _BiomarkersTab({required this.biomarkers});

  @override
  Widget build(BuildContext context) {
    if (biomarkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.science, size: 36, color: WellxColors.textTertiary),
            const SizedBox(height: WellxSpacing.lg),
            Text('No biomarkers yet', style: WellxTypography.chipText),
            const SizedBox(height: 4),
            Text(
              'Upload lab results to see biomarker data',
              style: WellxTypography.captionText,
            ),
          ],
        ),
      );
    }

    // Group by pillar
    final grouped = <String, List<Biomarker>>{};
    for (final b in biomarkers) {
      final pillar = b.pillar ?? 'Other';
      grouped.putIfAbsent(pillar, () => []).add(b);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arc gauge summary
          Center(
            child: BiomarkerArcGauge(
              total: biomarkers.length,
              inRange: biomarkers.where((b) => b.status == 'normal').length,
            ),
          ),
          const SizedBox(height: WellxSpacing.xl),

          // Grouped biomarker list
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: WellxTypography.sectionLabel.copyWith(
                    color: WellxColors.deepPurple,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: WellxSpacing.sm),
                ...entry.value.map(
                  (bio) => Padding(
                    padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
                    child: _BiomarkerDetailRow(biomarker: bio),
                  ),
                ),
                const SizedBox(height: WellxSpacing.lg),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BiomarkerDetailRow extends StatelessWidget {
  final Biomarker biomarker;

  const _BiomarkerDetailRow({required this.biomarker});

  @override
  Widget build(BuildContext context) {
    final val = biomarker.value;
    final refMin = biomarker.referenceMin;
    final refMax = biomarker.referenceMax;

    Color statusColor;
    switch (biomarker.status) {
      case 'high':
        statusColor = WellxColors.coral;
        break;
      case 'low':
        statusColor = WellxColors.amberWatch;
        break;
      default:
        statusColor = WellxColors.scoreGreen;
    }

    // Calculate position in range for mini gauge
    double gaugePosition = 0.5;
    if (val != null && refMin != null && refMax != null && refMax > refMin) {
      gaugePosition = ((val - refMin) / (refMax - refMin)).clamp(0.0, 1.0);
    }

    return WellxCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biomarker.name,
                      style: WellxTypography.chipText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (refMin != null && refMax != null)
                      Text(
                        'Ref: ${refMin.toStringAsFixed(1)} - ${refMax.toStringAsFixed(1)} ${biomarker.unit ?? ''}',
                        style: WellxTypography.microLabel,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${val?.toStringAsFixed(1) ?? 'N/A'} ${biomarker.unit ?? ''}',
                    style: WellxTypography.chipText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (biomarker.status != 'unknown')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        biomarker.status.toUpperCase(),
                        style: WellxTypography.microLabel.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.sm),
          // Mini range bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        WellxColors.amberWatch.withValues(alpha: 0.3),
                        WellxColors.scoreGreen.withValues(alpha: 0.3),
                        WellxColors.scoreGreen.withValues(alpha: 0.3),
                        WellxColors.coral.withValues(alpha: 0.3),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Value indicator
                Positioned(
                  left: (MediaQuery.of(context).size.width - 80) *
                      gaugePosition,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medications Tab
// ---------------------------------------------------------------------------

class _MedicationsTab extends StatelessWidget {
  final List<Medication> medications;

  const _MedicationsTab({required this.medications});

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication,
                size: 36, color: WellxColors.textTertiary),
            const SizedBox(height: WellxSpacing.lg),
            Text('No medications', style: WellxTypography.chipText),
            const SizedBox(height: 4),
            Text(
              'Medications will appear here from vet records',
              style: WellxTypography.captionText,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final med = medications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
          child: WellxCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: WellxColors.deepPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication,
                      size: 18, color: WellxColors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: WellxTypography.chipText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (med.dosage != null)
                        Text(med.dosage!, style: WellxTypography.captionText),
                      if (med.instructions != null)
                        Text(
                          med.instructions!,
                          style: WellxTypography.microLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (med.supplyTotal != null && med.supplyTotal! > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: med.supplyPercentage,
                              strokeWidth: 3,
                              backgroundColor: WellxColors.border,
                              valueColor: AlwaysStoppedAnimation(
                                med.supplyPercentage > 0.3
                                    ? WellxColors.scoreGreen
                                    : WellxColors.coral,
                              ),
                            ),
                            Text(
                              '${(med.supplyPercentage * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (med.refillDate != null)
                        Text(
                          'Refill ${med.refillDate}',
                          style: WellxTypography.microLabel,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Records Tab
// ---------------------------------------------------------------------------

class _RecordsTab extends StatelessWidget {
  final List<MedicalRecord> records;

  const _RecordsTab({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open,
                size: 36, color: WellxColors.textTertiary),
            const SizedBox(height: WellxSpacing.lg),
            Text('No records', style: WellxTypography.chipText),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
          child: WellxCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: WellxColors.deepPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description,
                      size: 14, color: WellxColors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: WellxTypography.chipText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          if (record.category != null)
                            Text(
                              record.category!,
                              style: WellxTypography.microLabel.copyWith(
                                color: WellxColors.deepPurple,
                              ),
                            ),
                          if (record.category != null &&
                              record.clinic != null)
                            Text(' \u{2022} ',
                                style: WellxTypography.microLabel),
                          if (record.clinic != null)
                            Expanded(
                              child: Text(
                                record.clinic!,
                                style: WellxTypography.captionText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(record.date, style: WellxTypography.captionText),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Walks Tab
// ---------------------------------------------------------------------------

class _WalksTab extends StatelessWidget {
  final List<WalkSession> walks;

  const _WalksTab({required this.walks});

  @override
  Widget build(BuildContext context) {
    if (walks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk,
                size: 36, color: WellxColors.textTertiary),
            const SizedBox(height: WellxSpacing.lg),
            Text('No walks recorded', style: WellxTypography.chipText),
            const SizedBox(height: 4),
            Text(
              'Track walks to see activity history',
              style: WellxTypography.captionText,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      itemCount: walks.length,
      itemBuilder: (context, index) {
        final walk = walks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
          child: WellxCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: WellxColors.bodyActivity.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_walk,
                      size: 18, color: WellxColors.bodyActivity),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walk.date,
                        style: WellxTypography.chipText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        walk.durationDisplay,
                        style: WellxTypography.captionText,
                      ),
                    ],
                  ),
                ),
                // Stats
                Row(
                  children: [
                    if (walk.steps != null)
                      _WalkStat(
                        icon: Icons.directions_walk,
                        value: '${walk.steps}',
                        label: 'steps',
                      ),
                    if (walk.distanceKm != null) ...[
                      const SizedBox(width: WellxSpacing.md),
                      _WalkStat(
                        icon: Icons.straighten,
                        value: '${walk.distanceKm!.toStringAsFixed(1)}',
                        label: 'km',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WalkStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WalkStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: WellxTypography.chipText.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: WellxTypography.microLabel),
      ],
    );
  }
}
