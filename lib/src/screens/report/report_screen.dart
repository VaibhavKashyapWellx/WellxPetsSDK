import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../health/biomarker_arc_gauge.dart';

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
        // ── Branded header ────────────────────────────────────────────────
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
        // ── Footer ────────────────────────────────────────────────────────
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
          // ── Pet info card ───────────────────────────────────────────────
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

          // ── Health score section ────────────────────────────────────────
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

          // ── Biomarkers to watch ─────────────────────────────────────────
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

          // ── Medications ─────────────────────────────────────────────────
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

          // ── Medical records ─────────────────────────────────────────────
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
              child: GestureDetector(
                onTap: () => _exportHealthReport(
                  context: context,
                  pet: selectedPet,
                  score: healthScore,
                  biomarkers: biomarkers,
                  records: records,
                  medications: medications,
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
