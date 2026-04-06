import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/travel_models.dart';
import '../../providers/travel_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Destination detail: entry requirements, quarantine info, documents,
/// vaccination requirements, banned breeds.
class DestinationDetailScreen extends ConsumerWidget {
  final TravelDestination destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider(destination.countryCode));

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: Text('${destination.flag} ${destination.countryName}'),
        centerTitle: true,
        backgroundColor: WellxColors.background,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        children: [
          // Friendliness score hero
          _scoreCard(),

          const SizedBox(height: WellxSpacing.lg),

          // Entry process summary
          if (destination.entryProcessSummary != null) ...[
            _sectionCard(
              title: 'Entry Process',
              icon: Icons.description,
              color: WellxColors.deepPurple,
              child: Text(
                destination.entryProcessSummary!,
                style: WellxTypography.bodyText
                    .copyWith(color: WellxColors.textSecondary),
              ),
            ),
            const SizedBox(height: WellxSpacing.md),
          ],

          // Quarantine info
          if (destination.isQuarantineRequired) ...[
            _sectionCard(
              title: 'Quarantine Required',
              icon: Icons.shield,
              color: WellxColors.coral,
              child: Text(
                destination.quarantineDays != null
                    ? '${destination.quarantineDays} days quarantine required upon arrival.'
                    : 'Quarantine is required. Check with authorities for duration.',
                style: WellxTypography.bodyText
                    .copyWith(color: WellxColors.textSecondary),
              ),
            ),
            const SizedBox(height: WellxSpacing.md),
          ],

          // Required documents
          if (destination.requiredDocuments != null &&
              destination.requiredDocuments!.isNotEmpty) ...[
            _documentsSection(),
            const SizedBox(height: WellxSpacing.md),
          ],

          // Vaccination requirements
          if (destination.vaccinationRequirements != null) ...[
            _vaccinationSection(),
            const SizedBox(height: WellxSpacing.md),
          ],

          // Banned breeds
          if (destination.hasBannedBreeds) ...[
            _bannedBreedsSection(),
            const SizedBox(height: WellxSpacing.md),
          ],

          // Climate notes
          if (destination.climateNotes != null) ...[
            _sectionCard(
              title: 'Climate Notes',
              icon: Icons.thermostat,
              color: WellxColors.amberWatch,
              child: Text(
                destination.climateNotes!,
                style: WellxTypography.bodyText
                    .copyWith(color: WellxColors.textSecondary),
              ),
            ),
            const SizedBox(height: WellxSpacing.md),
          ],

          // Routes
          routesAsync.when(
            data: (routes) {
              if (routes.isEmpty) return const SizedBox.shrink();
              return _routesSection(routes);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: WellxColors.deepPurple,
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _scoreCard() {
    return WellxCard(
      child: Row(
        children: [
          // Score ring
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: destination.friendlinessColor,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                '${destination.petFriendlinessScore ?? '?'}',
                style: WellxTypography.dataNumber.copyWith(
                  color: destination.friendlinessColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: WellxSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.friendlinessLevel,
                  style: WellxTypography.cardTitle.copyWith(
                    color: destination.friendlinessColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pet Friendliness Score',
                  style: WellxTypography.captionText,
                ),
                if (destination.isVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.verified,
                            size: 14, color: WellxColors.alertGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: WellxTypography.microLabel.copyWith(
                            color: WellxColors.alertGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: WellxTypography.cardTitle.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _documentsSection() {
    return _sectionCard(
      title: 'Required Documents (${destination.documentCount})',
      icon: Icons.folder,
      color: WellxColors.amberWatch,
      child: Column(
        children: destination.requiredDocuments!.map((doc) {
          return Padding(
            padding: const EdgeInsets.only(bottom: WellxSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: WellxColors.amberWatch,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: WellxSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: WellxTypography.chipText
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (doc.description.isNotEmpty)
                        Text(
                          doc.description,
                          style: WellxTypography.captionText,
                        ),
                      if (doc.leadTimeDays != null)
                        Text(
                          'Lead time: ${doc.leadTimeDays} days',
                          style: WellxTypography.microLabel
                              .copyWith(color: WellxColors.coral),
                        ),
                      if (doc.costEstimate != null)
                        Text(
                          'Est. cost: ${doc.costEstimate}',
                          style: WellxTypography.microLabel,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _vaccinationSection() {
    final vax = destination.vaccinationRequirements!;
    return _sectionCard(
      title: 'Vaccination Requirements',
      icon: Icons.vaccines,
      color: WellxColors.alertGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vax.rabiesValidityMonths != null)
            _infoRow('Rabies Validity', '${vax.rabiesValidityMonths} months'),
          if (vax.titerTestRequired == true)
            _infoRow('Titer Test', 'Required'),
          if (vax.microchipIso == true)
            _infoRow('ISO Microchip', 'Required'),
        ],
      ),
    );
  }

  Widget _bannedBreedsSection() {
    return _sectionCard(
      title: 'Banned Breeds',
      icon: Icons.block,
      color: WellxColors.coral,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: destination.bannedBreeds!.map((breed) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: WellxColors.coral.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              breed,
              style: WellxTypography.chipText
                  .copyWith(color: WellxColors.coral),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _routesSection(List<TravelRoute> routes) {
    return _sectionCard(
      title: 'Available Routes',
      icon: Icons.route,
      color: WellxColors.scoreBlue,
      child: Column(
        children: routes.map((route) {
          return Padding(
            padding: const EdgeInsets.only(bottom: WellxSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${route.originCountry} \u{2192} ${route.destinationCountry}',
                        style: WellxTypography.chipText
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (route.routeNotes != null)
                        Text(route.routeNotes!,
                            style: WellxTypography.captionText),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(route.costFormatted,
                        style: WellxTypography.chipText.copyWith(
                          fontWeight: FontWeight.bold,
                          color: WellxColors.deepPurple,
                        )),
                    Text(route.durationFormatted,
                        style: WellxTypography.microLabel),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: WellxTypography.captionText),
          Text(
            value,
            style: WellxTypography.chipText
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
