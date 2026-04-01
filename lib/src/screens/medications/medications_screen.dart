import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/health_models.dart';
import '../../providers/health_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Medications management screen for a specific pet.
class MedicationsScreen extends ConsumerWidget {
  final String petId;

  const MedicationsScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider(petId));

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: Text('Medications', style: WellxTypography.heading),
        backgroundColor: WellxColors.background,
        elevation: 0,
        foregroundColor: WellxColors.textPrimary,
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(WellxSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medication_rounded,
                    size: 48, color: WellxColors.textTertiary),
                const SizedBox(height: WellxSpacing.lg),
                Text('Could not load medications',
                    style: WellxTypography.bodyText),
                const SizedBox(height: WellxSpacing.sm),
                Text('$e',
                    style: WellxTypography.captionText
                        .copyWith(color: WellxColors.textTertiary)),
              ],
            ),
          ),
        ),
        data: (meds) {
          if (meds.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medication_rounded,
                      size: 56, color: WellxColors.textTertiary),
                  const SizedBox(height: WellxSpacing.lg),
                  Text('No medications yet',
                      style: WellxTypography.heading
                          .copyWith(color: WellxColors.textSecondary)),
                  const SizedBox(height: WellxSpacing.sm),
                  Text(
                    'Medications from vet visits and\nprescription scans will appear here.',
                    textAlign: TextAlign.center,
                    style: WellxTypography.captionText
                        .copyWith(color: WellxColors.textTertiary),
                  ),
                ],
              ),
            );
          }

          final active =
              meds.where((m) => (m.urgency ?? '').toLowerCase() != 'completed').toList();
          final completed =
              meds.where((m) => (m.urgency ?? '').toLowerCase() == 'completed').toList();

          return ListView(
            padding: const EdgeInsets.all(WellxSpacing.lg),
            children: [
              if (active.isNotEmpty) ...[
                Text(
                  'ACTIVE MEDICATIONS',
                  style: WellxTypography.sectionLabel.copyWith(
                    color: WellxColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: WellxSpacing.md),
                ...active.map((med) => Padding(
                      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
                      child: _MedicationCard(medication: med),
                    )),
                const SizedBox(height: WellxSpacing.lg),
              ],
              if (completed.isNotEmpty) ...[
                Text(
                  'COMPLETED',
                  style: WellxTypography.sectionLabel.copyWith(
                    color: WellxColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: WellxSpacing.md),
                ...completed.map((med) => Padding(
                      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
                      child: _MedicationCard(medication: med, dimmed: true),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final bool dimmed;

  const _MedicationCard({required this.medication, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final urgencyCol = _urgencyColor(medication.urgencyColor);

    return WellxCard(
      child: Opacity(
        opacity: dimmed ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: urgencyCol.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication_rounded,
                      color: urgencyCol, size: 20),
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name,
                          style: WellxTypography.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (medication.dosage != null)
                        Text(medication.dosage!,
                            style: WellxTypography.captionText
                                .copyWith(color: WellxColors.textSecondary)),
                    ],
                  ),
                ),
                if (medication.urgency != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyCol.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medication.urgency!,
                      style: WellxTypography.microLabel.copyWith(
                        color: urgencyCol,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (medication.supplyTotal != null &&
                medication.supplyTotal! > 0) ...[
              const SizedBox(height: WellxSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: medication.supplyPercentage,
                        minHeight: 6,
                        backgroundColor: WellxColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          medication.supplyPercentage > 0.3
                              ? WellxColors.scoreGreen
                              : WellxColors.coral,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: WellxSpacing.md),
                  Text(
                    '${medication.supplyRemaining ?? 0} / ${medication.supplyTotal} left',
                    style: WellxTypography.microLabel
                        .copyWith(color: WellxColors.textTertiary),
                  ),
                ],
              ),
            ],
            if (medication.instructions != null) ...[
              const SizedBox(height: WellxSpacing.sm),
              Text(medication.instructions!,
                  style: WellxTypography.captionText
                      .copyWith(color: WellxColors.textTertiary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  Color _urgencyColor(String color) {
    switch (color) {
      case 'red':
        return WellxColors.coral;
      case 'orange':
        return WellxColors.inflammation;
      default:
        return WellxColors.scoreGreen;
    }
  }
}
