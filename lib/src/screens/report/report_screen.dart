import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/health_models.dart';
import '../../models/pet.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/score_calculator.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

// ---------------------------------------------------------------------------
// PDF Export
// ---------------------------------------------------------------------------

// WellX brand colors for PDF
const _pdfNavy = PdfColor.fromInt(0xFF1A1A2E);
const _pdfPurple = PdfColor.fromInt(0xFF4D33B3);
const _pdfTeal = PdfColor.fromInt(0xFF00BFA6);
const _pdfLightGrey = PdfColor.fromInt(0xFFF5F4FA);
const _pdfBorder = PdfColor.fromInt(0xFFE8E6F0);

PdfColor _pillarBarColor(int score) {
  if (score >= 75) return const PdfColor.fromInt(0xFF409959);
  if (score >= 50) return const PdfColor.fromInt(0xFFD98C33);
  return const PdfColor.fromInt(0xFFCC4033);
}

PdfColor _statusColor(String status) {
  if (status == 'high') return const PdfColor.fromInt(0xFFE65A4D);
  if (status == 'low') return const PdfColor.fromInt(0xFFD9A633);
  return const PdfColor.fromInt(0xFF4DA659);
}

/// Generate and share a WellX branded health report PDF.
Future<void> _exportHealthReport({
  required BuildContext context,
  required Pet? pet,
  required HealthScore? score,
  required List<Biomarker> biomarkers,
  required List<MedicalRecord> records,
  required List<Medication> medications,
}) async {
  try {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final watchMarkers =
        biomarkers.where((b) => b.status == 'high' || b.status == 'low').toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        // -- Branded header --
        header: (_) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: _pdfNavy,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 24,
                      height: 24,
                      decoration: pw.BoxDecoration(
                        color: _pdfTeal,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'WellX',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      'Pet Health Report',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Text(
                    pet != null ? '${pet.name}\'s Health Summary' : 'Health Summary',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfNavy,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'Generated $dateStr',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Divider(color: _pdfBorder, height: 12),
            ],
          ),
        ),
        // -- Footer --
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: _pdfBorder, height: 8),
            pw.Row(
              children: [
                pw.Text(
                  'WellX Pet Health Report — $dateStr',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'This report is for informational purposes only and is not a substitute for professional veterinary advice.',
              style: const pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey400,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
        build: (_) => [
          // -- Pet info card --
          if (pet != null) ...[
            _sectionHeader('PET INFORMATION', _pdfPurple),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _pdfLightGrey,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _pdfBorder),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _infoRow('Name', pet.name),
                  if (pet.breed != null) _infoRow('Breed', pet.breed!),
                  if (pet.species != null)
                    _infoRow('Species', pet.species!.toUpperCase()),
                  if (pet.weight != null)
                    _infoRow('Weight', '${pet.weight!.toStringAsFixed(1)} kg'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // -- Health score section --
          if (score != null) ...[
            _sectionHeader('HEALTH SCORE', _pdfPurple),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _pdfNavy,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Score circle
                  pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [
                      pw.Container(
                        width: 72,
                        height: 72,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                            color: _pdfTeal,
                            width: 5,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${score.overall}',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Overall Health Score',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          score.overall >= 80
                              ? 'Excellent — keep it up!'
                              : score.overall >= 65
                                  ? 'Good — minor areas to improve'
                                  : score.overall >= 50
                                      ? 'Fair — some attention needed'
                                      : 'Needs Attention — consult your vet',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _pdfTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Pillar breakdown with colored bars
            ...score.pillars.map((p) {
              final barColor = _pillarBarColor(p.score);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 7),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 140,
                          child: pw.Text(
                            p.name,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.ClipRRect(
                            horizontalRadius: 3,
                            verticalRadius: 3,
                            child: pw.LinearProgressIndicator(
                              value: p.percent,
                              valueColor: barColor,
                              backgroundColor: _pdfBorder,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          '${p.score}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 16),
          ],

          // -- Biomarkers to watch --
          if (watchMarkers.isNotEmpty) ...[
            _sectionHeader('BIOMARKERS TO WATCH', const PdfColor.fromInt(0xFFD98C33)),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
              },
              border: pw.TableBorder.all(color: _pdfBorder, width: 0.5),
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: _pdfLightGrey),
                  children: [
                    _tableCell('Biomarker', bold: true),
                    _tableCell('Value', bold: true),
                    _tableCell('Status', bold: true),
                  ],
                ),
                ...watchMarkers.map((b) {
                  final color = _statusColor(b.status);
                  return pw.TableRow(
                    children: [
                      _tableCell(b.name),
                      _tableCell(
                        '${b.value?.toStringAsFixed(1) ?? 'N/A'}'
                        '${b.unit != null ? ' ${b.unit}' : ''}',
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          b.status.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // -- Medications --
          if (medications.isNotEmpty) ...[
            _sectionHeader('CURRENT MEDICATIONS', _pdfPurple),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _pdfLightGrey,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _pdfBorder),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: medications
                    .map((m) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 6,
                                height: 6,
                                decoration: pw.BoxDecoration(
                                  color: _pdfPurple,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                m.name,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (m.dosage != null) ...[
                                pw.Text(
                                  ' — ${m.dosage}',
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // -- Medical records --
          if (records.isNotEmpty) ...[
            _sectionHeader('RECENT MEDICAL RECORDS', _pdfPurple),
            pw.SizedBox(height: 8),
            ...records.take(10).map(
                  (r) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          decoration: pw.BoxDecoration(
                            color: _pdfPurple,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          r.date,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            r.title,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        if (r.clinic != null)
                          pw.Text(
                            r.clinic!,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );

    final petName = (pet?.name ?? 'pet').replaceAll(' ', '_');
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'wellx_${petName}_health_report_$dateStr.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export report. Please try again.'),
        ),
      );
    }
  }
}

// Helper widgets for PDF

pw.Widget _sectionHeader(String text, PdfColor color) {
  return pw.Row(
    children: [
      pw.Container(width: 3, height: 14, color: color),
      pw.SizedBox(width: 8),
      pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}

pw.Widget _infoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}

pw.Widget _tableCell(String text, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Report Screen
// ---------------------------------------------------------------------------

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

    final medicationsAsync =
        petId != null ? ref.watch(medicationsProvider(petId)) : null;
    final medications = medicationsAsync?.valueOrNull ?? [];

    final wellnessAsync =
        petId != null ? ref.watch(wellnessSurveyProvider(petId)) : null;
    final wellness = wellnessAsync?.valueOrNull;

    final healthScore = (biomarkers.isNotEmpty || wellness != null)
        ? ScoreCalculator.calculate(
            biomarkers: biomarkers,
            walkSessions: walks,
            wellnessResult: wellness,
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

          // ── Hero Section ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(WellxSpacing.lg),
              child: healthScore != null
                  ? _HeroScoreCard(
                      score: healthScore,
                      onDownloadPdf: () => _exportHealthReport(
                        context: context,
                        pet: selectedPet,
                        score: healthScore,
                        biomarkers: biomarkers,
                        records: records,
                        medications: medications,
                      ),
                      onCompare: petId != null
                          ? () => context.push('/health-dashboard/$petId')
                          : null,
                    )
                  : _NoScoreCard(),
            ),
          ),

          // ── Biometric Bento Grid ──────────────────────────────────────
          if (biomarkers.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.lg),
                child: _BiometricBentoGrid(
                  biomarkers: biomarkers,
                  watchBiomarkers: watchBiomarkers,
                  healthScore: healthScore,
                ),
              ),
            ),

          // ── Markers to Watch ──────────────────────────────────────────
          if (watchBiomarkers.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.lg, WellxSpacing.xl, WellxSpacing.lg, 0,
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

          // ── Collective Impact Section ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WellxSpacing.lg, WellxSpacing.xl, WellxSpacing.lg, 0,
              ),
              child: _CollectiveImpactSection(),
            ),
          ),

          // ── Recent Records ────────────────────────────────────────────
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

          // ── Deep Dive Section ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WellxSpacing.lg, 0, WellxSpacing.lg, 0,
              ),
              child: _DeepDiveSection(
                petId: petId,
                onTapGenetics: petId != null
                    ? () => context.push('/health-dashboard/$petId')
                    : null,
                onTapCardio: petId != null
                    ? () => context.push('/health-dashboard/$petId')
                    : null,
              ),
            ),
          ),

          // Bottom padding for floating nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Score Card (Vitality Report)
// ---------------------------------------------------------------------------

class _HeroScoreCard extends StatelessWidget {
  final HealthScore score;
  final VoidCallback onDownloadPdf;
  final VoidCallback? onCompare;

  const _HeroScoreCard({
    required this.score,
    required this.onDownloadPdf,
    this.onCompare,
  });

  String _scoreLabel(int overall) {
    if (overall >= 80) return 'Excellent Health\nStability';
    if (overall >= 65) return 'Good Health\nStatus';
    if (overall >= 50) return 'Fair Health\nCondition';
    return 'Needs\nAttention';
  }

  String _scoreDescription(int overall) {
    if (overall >= 80) {
      return 'Your companion\'s biometrics show strong restorative recovery this month.';
    }
    if (overall >= 65) {
      return 'Overall health is good with minor areas for improvement.';
    }
    if (overall >= 50) {
      return 'Some health markers need attention. Consider a vet visit.';
    }
    return 'Multiple markers are out of range. Please consult your veterinarian.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WellxColors.onPrimaryFixedVariant,
            WellxColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: WellxColors.primary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative blur orbs
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WellxColors.tertiaryContainer.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(WellxSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VITALITY REPORT',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: WellxColors.primaryFixedDim
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _scoreLabel(score.overall),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _scoreDescription(score.overall),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                              color: WellxColors.primaryFixedDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Score ring
                    _ScoreRingGauge(score: score.overall),
                  ],
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    GestureDetector(
                      onTap: onDownloadPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: WellxColors.primaryContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Download PDF',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: WellxColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onCompare,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'Compare',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
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
// Score Ring Gauge (SVG-like ring)
// ---------------------------------------------------------------------------

class _ScoreRingGauge extends StatelessWidget {
  final int score;

  const _ScoreRingGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _ScoreRingPainter(score: score),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              Text(
                'SCORE',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final int score;

  _ScoreRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..color = WellxColors.tertiaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) =>
      oldDelegate.score != score;
}

// ---------------------------------------------------------------------------
// No Score Card
// ---------------------------------------------------------------------------

class _NoScoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WellxColors.onPrimaryFixedVariant,
            WellxColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
      ),
      padding: const EdgeInsets.all(WellxSpacing.xxl),
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
// Biometric Bento Grid
// ---------------------------------------------------------------------------

class _BiometricBentoGrid extends StatelessWidget {
  final List<Biomarker> biomarkers;
  final List<Biomarker> watchBiomarkers;
  final HealthScore? healthScore;

  const _BiometricBentoGrid({
    required this.biomarkers,
    required this.watchBiomarkers,
    this.healthScore,
  });

  @override
  Widget build(BuildContext context) {
    // Derive pillar data from the health score
    final pillars = healthScore?.pillars ?? [];

    // Find specific pillars for the bento cards
    final organPillar = pillars.where((p) =>
        p.name.toLowerCase().contains('organ')).firstOrNull;
    final inflammPillar = pillars.where((p) =>
        p.name.toLowerCase().contains('inflamm')).firstOrNull;
    final metabolicPillar = pillars.where((p) =>
        p.name.toLowerCase().contains('metabol')).firstOrNull;
    final sleepPillar = pillars.where((p) =>
        p.name.toLowerCase().contains('sleep') ||
        p.name.toLowerCase().contains('restorat') ||
        p.name.toLowerCase().contains('activity')).firstOrNull;

    final normalCount = biomarkers.where((b) => b.status == 'normal').length;
    final isOptimal = normalCount > biomarkers.length * 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: WellxSpacing.md),
        Row(
          children: [
            Text(
              'BIOMETRICS',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.deepPurple,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: WellxSpacing.md),
        // Row 1: Organ Strength (tall) + Inflammation + Metabolic
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Organ Strength - large vertical card
              Expanded(
                flex: 1,
                child: _BentoOrganCard(
                  pillar: organPillar,
                  isOptimal: isOptimal,
                ),
              ),
              const SizedBox(width: 12),
              // Right column: Inflammation + Metabolic stacked
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Inflammation card
                    _BentoInflammationCard(
                      pillar: inflammPillar,
                      watchBiomarkers: watchBiomarkers,
                    ),
                    const SizedBox(height: 12),
                    // Metabolic card
                    _BentoMetabolicCard(pillar: metabolicPillar),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Row 2: Restorative Sleep - wide card
        _BentoSleepCard(pillar: sleepPillar),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bento: Organ Strength Card
// ---------------------------------------------------------------------------

class _BentoOrganCard extends StatelessWidget {
  final PillarScore? pillar;
  final bool isOptimal;

  const _BentoOrganCard({this.pillar, required this.isOptimal});

  @override
  Widget build(BuildContext context) {
    final scoreVal = pillar?.score ?? 0;
    // Generate bar heights based on score
    final barHeights = [
      0.4 + (scoreVal / 100) * 0.2,
      0.5 + (scoreVal / 100) * 0.3,
      0.45 + (scoreVal / 100) * 0.2,
      0.6 + (scoreVal / 100) * 0.35,
      0.55 + (scoreVal / 100) * 0.3,
      0.4 + (scoreVal / 100) * 0.15,
    ];

    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(
          color: WellxColors.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: WellxColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: WellxColors.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      size: 20,
                      color: WellxColors.primary,
                    ),
                  ),
                  if (isOptimal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: WellxColors.tertiaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'OPTIMAL',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: WellxColors.tertiary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Organ Strength',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: WellxColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                pillar != null
                    ? 'Score: ${pillar!.score}/100'
                    : 'Awaiting data',
                style: WellxTypography.captionText,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final isHighlight = i == 3;
                return Container(
                  width: 6,
                  height: 80 * barHeights[i].clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: isHighlight
                        ? WellxColors.primary
                        : WellxColors.primaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((d) => Text(
                      d,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: WellxColors.outline,
                        letterSpacing: -0.5,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bento: Inflammation Card
// ---------------------------------------------------------------------------

class _BentoInflammationCard extends StatelessWidget {
  final PillarScore? pillar;
  final List<Biomarker> watchBiomarkers;

  const _BentoInflammationCard({
    this.pillar,
    required this.watchBiomarkers,
  });

  @override
  Widget build(BuildContext context) {
    final scoreVal = pillar?.score ?? 0;
    final statusLabel = scoreVal >= 75
        ? 'Low'
        : scoreVal >= 50
            ? 'Moderate'
            : 'High';
    final barFraction = scoreVal / 100.0;

    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainer,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(
          color: WellxColors.outlineVariant.withValues(alpha: 0.1),
        ),
        boxShadow: WellxColors.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inflammation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: WellxColors.onSurface,
                ),
              ),
              Icon(
                Icons.error_outline,
                size: 20,
                color: scoreVal < 50
                    ? WellxColors.error
                    : WellxColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                statusLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: WellxColors.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${pillar?.score ?? '--'}/100',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: WellxColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gauge bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 6,
              color: WellxColors.surfaceContainerHighest,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: barFraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: WellxColors.tertiary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
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
// Bento: Metabolic Card
// ---------------------------------------------------------------------------

class _BentoMetabolicCard extends StatelessWidget {
  final PillarScore? pillar;

  const _BentoMetabolicCard({this.pillar});

  @override
  Widget build(BuildContext context) {
    final scoreVal = pillar?.score ?? 0;
    final statusLabel = scoreVal >= 65 ? 'Active' : 'Low';

    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(
          color: WellxColors.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: WellxColors.subtleShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metabolic',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: WellxColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: WellxColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pillar?.score ?? '--'}/100 basal',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: WellxColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Animated ring indicator
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: scoreVal / 100.0,
              strokeWidth: 4,
              backgroundColor:
                  WellxColors.primary.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(WellxColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bento: Sleep Card (wide, spans 2 columns)
// ---------------------------------------------------------------------------

class _BentoSleepCard extends StatelessWidget {
  final PillarScore? pillar;

  const _BentoSleepCard({this.pillar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(
          color: WellxColors.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: WellxColors.subtleShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restorative Sleep',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: WellxColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pillar != null
                      ? 'Score: ${pillar!.score}/100 consistency'
                      : 'Awaiting sleep data',
                  style: WellxTypography.captionText,
                ),
              ],
            ),
          ),
          // Icon badges
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.primaryContainer,
                  border: Border.all(
                    color: WellxColors.surfaceContainerLowest,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.bedtime_outlined,
                  size: 16,
                  color: WellxColors.onPrimaryContainer,
                ),
              ),
              Transform.translate(
                offset: const Offset(-8, 0),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WellxColors.secondaryContainer,
                    border: Border.all(
                      color: WellxColors.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: WellxColors.secondary,
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
// Collective Impact Section
// ---------------------------------------------------------------------------

class _CollectiveImpactSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collective Impact',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: WellxColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your pet\'s health milestones power real-world change.',
                  style: WellxTypography.captionText,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: WellxSpacing.lg),
        Row(
          children: [
            // Trees planted
            Expanded(
              child: _ImpactCard(
                icon: Icons.forest,
                iconColor: WellxColors.tertiary,
                bgIconData: Icons.nature,
                title: 'Trees Planted',
                value: '12,482',
                subtitle: '+124 this month',
              ),
            ),
            const SizedBox(width: 12),
            // Meals donated
            Expanded(
              child: _ImpactCard(
                icon: Icons.favorite,
                iconColor: WellxColors.error,
                bgIconData: Icons.volunteer_activism,
                title: 'Meals Donated',
                value: '85,200',
                subtitle: 'To local shelters',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final IconData bgIconData;
  final String title;
  final String value;
  final String subtitle;

  const _ImpactCard({
    required this.icon,
    required this.iconColor,
    required this.bgIconData,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(
          color: WellxColors.outlineVariant.withValues(alpha: 0.1),
        ),
        boxShadow: WellxColors.subtleShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background decorative icon
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(
              bgIconData,
              size: 72,
              color: iconColor.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: WellxColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: WellxColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: WellxColors.onSurfaceVariant,
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
// Deep Dive Section
// ---------------------------------------------------------------------------

class _DeepDiveSection extends StatelessWidget {
  final String? petId;
  final VoidCallback? onTapGenetics;
  final VoidCallback? onTapCardio;

  const _DeepDiveSection({
    this.petId,
    this.onTapGenetics,
    this.onTapCardio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deep Dive',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: WellxColors.onSurface,
          ),
        ),
        const SizedBox(height: WellxSpacing.md),
        _DeepDiveRow(
          icon: Icons.biotech,
          iconBgColor: WellxColors.primaryContainer.withValues(alpha: 0.4),
          iconColor: WellxColors.primary,
          title: 'Genetic Predisposition Report',
          subtitle: 'Updated recently',
          onTap: onTapGenetics,
        ),
        const SizedBox(height: WellxSpacing.sm),
        _DeepDiveRow(
          icon: Icons.monitor_heart,
          iconBgColor: WellxColors.tertiaryContainer.withValues(alpha: 0.3),
          iconColor: WellxColors.tertiary,
          title: 'Cardiovascular Performance',
          subtitle: 'Annual trend analysis',
          onTap: onTapCardio,
        ),
      ],
    );
  }
}

class _DeepDiveRow extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DeepDiveRow({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        decoration: BoxDecoration(
          color: WellxColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WellxColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: WellxColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: WellxColors.outline,
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
              color: color.withValues(alpha: 0.12),
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
                  color: color.withValues(alpha: 0.12),
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
