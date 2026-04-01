import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/health_models.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/score_calculator.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../health/biomarker_arc_gauge.dart';

/// Reports tab -- health score, biomarker trends, medical records.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id;

    final biomarkersAsync =
        petId != null ? ref.watch(biomarkersProvider(petId)) : null;
    final biomarkers = biomarkersAsync?.valueOrNull ?? [];

    final recordsAsync =
        petId != null ? ref.watch(medicalRecordsProvider(petId)) : null;
    final records = recordsAsync?.valueOrNull ?? [];

    final walkSessionsAsync =
        petId != null ? ref.watch(walkSessionsProvider(petId)) : null;
    final walks = walkSessionsAsync?.valueOrNull ?? [];

    final healthScore = biomarkers.isNotEmpty
        ? ScoreCalculator.calculate(
            biomarkers: biomarkers,
            walkSessions: walks,
            pet: selectedPet,
          )
        : null;

    final watchBiomarkers =
        biomarkers.where((b) => b.status == 'high' || b.status == 'low').toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WellxSpacing.lg, WellxSpacing.lg, WellxSpacing.lg, 0,
              ),
              child: Text('Reports', style: WellxTypography.screenTitle),
            ),
          ),

          // Pet selector
          if (pets.length > 1)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.lg,
                  vertical: WellxSpacing.md,
                ),
                child: Row(
                  children: pets.map((pet) {
                    final isSelected = selectedPet?.id == pet.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(selectedPetIdProvider.notifier)
                            .state = pet.id,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? WellxColors.textPrimary
                                : WellxColors.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : WellxColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                pet.speciesEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                pet.name,
                                style: WellxTypography.chipText.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : WellxColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Health score summary card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WellxSpacing.lg),
              child: healthScore != null
                  ? _HealthScoreCard(score: healthScore)
                  : _NoScoreCard(),
            ),
          ),

          // Biomarker trends
          if (biomarkers.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.lg,
                ),
                child: Row(
                  children: [
                    Text(
                      'BIOMARKERS',
                      style: WellxTypography.sectionLabel.copyWith(
                        color: WellxColors.deepPurple,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (petId != null) {
                          context.push('/health-dashboard/$petId');
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: WellxTypography.captionText.copyWith(
                              fontWeight: FontWeight.w600,
                              color: WellxColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right,
                              size: 12, color: WellxColors.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Biomarker arc gauge
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(WellxSpacing.lg),
                child: WellxCard(
                  child: BiomarkerArcGauge(
                    total: biomarkers.length,
                    inRange:
                        biomarkers.where((b) => b.status == 'normal').length,
                  ),
                ),
              ),
            ),

            // Watch markers
            if (watchBiomarkers.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WellxSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 11, color: WellxColors.amberWatch),
                          const SizedBox(width: 6),
                          Text(
                            'MARKERS TO WATCH',
                            style: WellxTypography.sectionLabel.copyWith(
                              color: WellxColors.amberWatch,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: WellxSpacing.md),
                      ...watchBiomarkers.map(
                        (bio) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: WellxSpacing.sm),
                          child: _WatchBiomarkerRow(biomarker: bio),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          // Recent medical records
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WellxSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT RECORDS',
                    style: WellxTypography.sectionLabel.copyWith(
                      color: WellxColors.deepPurple,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: WellxSpacing.md),
                  if (records.isEmpty)
                    WellxCard(
                      child: Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No medical records yet',
                            style: WellxTypography.captionText,
                          ),
                        ),
                      ),
                    )
                  else
                    ...records.take(5).map(
                      (record) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: WellxSpacing.sm),
                        child: _MedicalRecordRow(record: record),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Export button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WellxSpacing.lg, 0, WellxSpacing.lg, 100,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: WellxColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.ios_share, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Export Health Report',
                        style: WellxTypography.buttonLabel),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Health Score Card
// ---------------------------------------------------------------------------

class _HealthScoreCard extends StatelessWidget {
  final HealthScore score;

  const _HealthScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      child: Column(
        children: [
          // Score ring + number
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: score.overall / 100.0,
                        strokeWidth: 6,
                        backgroundColor: WellxColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          WellxColors.scoreColor(score.overall),
                        ),
                      ),
                    ),
                    Text(
                      '${score.overall}',
                      style: WellxTypography.dataNumber.copyWith(
                        color: WellxColors.scoreColor(score.overall),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WellxSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: WellxTypography.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Updated ${score.updatedDate}',
                      style: WellxTypography.captionText,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: WellxSpacing.lg),

          // Pillar breakdown
          ...score.pillars.map(
            (pillar) => Padding(
              padding: const EdgeInsets.only(bottom: WellxSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      pillar.name,
                      style: WellxTypography.captionText.copyWith(
                        color: WellxColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pillar.percent,
                        minHeight: 6,
                        backgroundColor: WellxColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          WellxColors.scoreColor(pillar.score),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: WellxSpacing.sm),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${pillar.score}',
                      textAlign: TextAlign.end,
                      style: WellxTypography.chipText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: WellxColors.scoreColor(pillar.score),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoScoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WellxCard(
      padding: const EdgeInsets.all(WellxSpacing.xxl),
      backgroundColor: WellxColors.inkPrimary,
      borderColor: Colors.transparent,
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.bar_chart_rounded,
                color: Colors.white54, size: 36),
            const SizedBox(height: WellxSpacing.lg),
            Text(
              'Upload lab results to\ngenerate your health report',
              textAlign: TextAlign.center,
              style: WellxTypography.heading.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Watch Biomarker Row
// ---------------------------------------------------------------------------

class _WatchBiomarkerRow extends StatelessWidget {
  final Biomarker biomarker;

  const _WatchBiomarkerRow({required this.biomarker});

  @override
  Widget build(BuildContext context) {
    final isHigh = biomarker.status == 'high';
    final color = isHigh ? WellxColors.coral : WellxColors.amberWatch;

    return WellxCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHigh ? Icons.arrow_upward : Icons.arrow_downward,
              size: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biomarker.name,
                  style: WellxTypography.inputText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (biomarker.pillar != null)
                  Text(biomarker.pillar!, style: WellxTypography.captionText),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${biomarker.value?.toStringAsFixed(1) ?? 'N/A'} ${biomarker.unit ?? ''}',
                style: WellxTypography.chipText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  biomarker.status.toUpperCase(),
                  style: WellxTypography.microLabel.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medical Record Row
// ---------------------------------------------------------------------------

class _MedicalRecordRow extends StatelessWidget {
  final MedicalRecord record;

  const _MedicalRecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: WellxColors.deepPurple.withOpacity(0.12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.clinic != null)
                  Text(record.clinic!, style: WellxTypography.captionText),
              ],
            ),
          ),
          Text(
            _formatDate(record.date),
            style: WellxTypography.captionText,
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
