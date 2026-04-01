import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/travel_models.dart';
import '../../providers/travel_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Compare pet-friendly airlines: cabin/cargo, weight limits, fees, restrictions.
class AirlineComparisonScreen extends ConsumerWidget {
  const AirlineComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final airlinesAsync = ref.watch(airlinesProvider);

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: const Text('Pet-Friendly Airlines'),
        centerTitle: true,
        backgroundColor: WellxColors.background,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
      ),
      body: airlinesAsync.when(
        data: (airlines) {
          if (airlines.isEmpty) {
            return const Center(
              child: Text(
                'No airlines found',
                style: TextStyle(color: WellxColors.textTertiary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(WellxSpacing.lg),
            itemCount: airlines.length,
            itemBuilder: (context, index) =>
                _airlineCard(airlines[index]),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: WellxColors.deepPurple),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 36, color: WellxColors.textTertiary),
              const SizedBox(height: 12),
              Text('Failed to load airlines',
                  style: WellxTypography.bodyText),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(airlinesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _airlineCard(TravelAirline airline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
      child: WellxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WellxColors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flight,
                      size: 20, color: WellxColors.deepPurple),
                ),
                const SizedBox(width: WellxSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(airline.name, style: WellxTypography.cardTitle),
                      Text(
                        airline.displayCode,
                        style: WellxTypography.captionText,
                      ),
                    ],
                  ),
                ),
                if (airline.hasEmbargoNow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: WellxColors.coral.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber,
                            size: 12, color: WellxColors.coral),
                        const SizedBox(width: 4),
                        Text(
                          'Embargo',
                          style: WellxTypography.microLabel
                              .copyWith(color: WellxColors.coral),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: WellxSpacing.lg),

            // Travel type badges
            Row(
              children: [
                _travelTypeBadge(
                  'Cabin',
                  Icons.airline_seat_recline_normal,
                  airline.cabinAvailable,
                ),
                const SizedBox(width: 8),
                _travelTypeBadge(
                  'Cargo',
                  Icons.inventory_2,
                  airline.cargoAvailable,
                ),
                const SizedBox(width: 8),
                _travelTypeBadge(
                  'Checked',
                  Icons.luggage,
                  airline.allowsChecked ?? false,
                ),
              ],
            ),

            const SizedBox(height: WellxSpacing.md),

            // Fee row
            Row(
              children: [
                Expanded(
                  child: _feeColumn(
                      'Cabin Fee', airline.cabinFeeFormatted),
                ),
                Expanded(
                  child:
                      _feeColumn('Cargo Fee', airline.cargoFeeFormatted),
                ),
                if (airline.cabinMaxWeightKg != null)
                  Expanded(
                    child: _feeColumn(
                      'Max Weight',
                      '${airline.cabinMaxWeightKg!.toInt()} kg',
                    ),
                  ),
              ],
            ),

            // Carrier dimensions
            if (airline.cabinCarrierDimensions != null) ...[
              const SizedBox(height: WellxSpacing.sm),
              Text(
                'Carrier: ${airline.cabinCarrierDimensions}',
                style: WellxTypography.captionText
                    .copyWith(color: WellxColors.textTertiary),
              ),
            ],

            // Breed restrictions
            if (airline.breedRestrictions != null &&
                airline.breedRestrictions!.isNotEmpty) ...[
              const SizedBox(height: WellxSpacing.md),
              Row(
                children: [
                  Icon(Icons.block,
                      size: 14, color: WellxColors.coral),
                  const SizedBox(width: 6),
                  Text(
                    'Breed Restrictions',
                    style: WellxTypography.chipText.copyWith(
                      fontWeight: FontWeight.w600,
                      color: WellxColors.coral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: airline.breedRestrictions!.map((breed) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: WellxColors.coral.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      breed,
                      style: WellxTypography.microLabel
                          .copyWith(color: WellxColors.coral),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Booking process
            if (airline.bookingProcess != null) ...[
              const SizedBox(height: WellxSpacing.md),
              Text(
                airline.bookingProcess!,
                style: WellxTypography.captionText
                    .copyWith(color: WellxColors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _travelTypeBadge(String label, IconData icon, bool available) {
    final color = available ? WellxColors.alertGreen : WellxColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: WellxTypography.microLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _feeColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              WellxTypography.microLabel.copyWith(color: WellxColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: WellxTypography.chipText.copyWith(
            fontWeight: FontWeight.bold,
            color: WellxColors.deepPurple,
          ),
        ),
      ],
    );
  }
}
