import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/venue_models.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';

/// Venue detail: address, phone, hours, dog-friendly status, amenities, notes.
class VenueDetailScreen extends StatelessWidget {
  final Venue venue;

  const VenueDetailScreen({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WellxColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: WellxColors.background,
            foregroundColor: WellxColors.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: venue.hasImage
                  ? Image.network(
                      venue.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(WellxSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(venue.name, style: WellxTypography.heading),
                    ),
                    _statusBadge(),
                  ],
                ),

                const SizedBox(height: WellxSpacing.sm),

                // Category
                Row(
                  children: [
                    Icon(venue.displayCategory.icon,
                        size: 14, color: venue.displayCategory.color),
                    const SizedBox(width: 6),
                    Text(
                      venue.displayCategory.displayName,
                      style: WellxTypography.chipText.copyWith(
                        color: venue.displayCategory.color,
                      ),
                    ),
                    if (venue.rating != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.star,
                          size: 14, color: WellxColors.amberWatch),
                      const SizedBox(width: 2),
                      Text(
                        venue.rating!.toStringAsFixed(1),
                        style: WellxTypography.chipText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: WellxSpacing.xl),

                // Address
                if (venue.address != null)
                  _infoCard(
                    icon: Icons.place,
                    color: WellxColors.deepPurple,
                    title: 'Address',
                    content: venue.address!,
                  ),

                // Phone
                if (venue.phone != null)
                  _infoCard(
                    icon: Icons.phone,
                    color: WellxColors.alertGreen,
                    title: 'Phone',
                    content: venue.phone!,
                    onTap: () =>
                        launchUrl(Uri.parse('tel:${venue.phone}')),
                  ),

                // Dog-friendly details
                if (venue.dogFriendlyDetails != null)
                  _dogFriendlySection(),

                // Notes
                if (venue.dogFriendlyDetails?.notes != null &&
                    venue.dogFriendlyDetails!.notes!.isNotEmpty)
                  _infoCard(
                    icon: Icons.notes,
                    color: WellxColors.amberWatch,
                    title: 'Notes',
                    content: venue.dogFriendlyDetails!.notes!,
                  ),

                // Venue notes
                if (venue.notes != null && venue.notes!.isNotEmpty)
                  _infoCard(
                    icon: Icons.info_outline,
                    color: WellxColors.textTertiary,
                    title: 'Additional Info',
                    content: venue.notes!,
                  ),

                const SizedBox(height: WellxSpacing.lg),

                // Action buttons
                if (venue.googleMapsUrl != null)
                  WellxPrimaryButton(
                    label: 'Open in Google Maps',
                    icon: Icons.map,
                    onPressed: () =>
                        launchUrl(venue.googleMapsUrl!),
                  ),

                if (venue.website != null) ...[
                  const SizedBox(height: WellxSpacing.sm),
                  WellxSecondaryButton(
                    label: 'Visit Website',
                    icon: Icons.open_in_new,
                    onPressed: () =>
                        launchUrl(Uri.parse(venue.website!)),
                  ),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: venue.displayCategory.color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          venue.displayCategory.icon,
          size: 48,
          color: venue.displayCategory.color.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final status = venue.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.displayLabel,
            style: WellxTypography.chipText.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: WellxCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: WellxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: WellxTypography.microLabel
                          .copyWith(color: WellxColors.textTertiary),
                    ),
                    const SizedBox(height: 2),
                    Text(content, style: WellxTypography.bodyText),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    size: 18, color: WellxColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dogFriendlySection() {
    final details = venue.dogFriendlyDetails!;
    return Padding(
      padding: const EdgeInsets.only(bottom: WellxSpacing.md),
      child: WellxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, size: 16, color: WellxColors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Dog-Friendly Details',
                  style: WellxTypography.cardTitle.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: WellxSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (details.indoorSeating == true)
                  _detailChip('Indoor Seating', Icons.house, true),
                if (details.outdoorSeating == true)
                  _detailChip('Outdoor Seating', Icons.wb_sunny, false),
                if (details.waterBowls == true)
                  _detailChip('Water Bowls', Icons.water_drop, false),
                if (details.dogMenu == true)
                  _detailChip('Dog Menu', Icons.menu_book, false),
                if (details.dogTreats == true)
                  _detailChip('Dog Treats', Icons.card_giftcard, false),
                if (details.offLeashArea == true)
                  _detailChip('Off-Leash Area', Icons.directions_run, false),
                if (details.leashRequired == true)
                  _detailChip('Leash Required', Icons.link, false),
              ],
            ),
            if (details.sizeRestrictions != null) ...[
              const SizedBox(height: WellxSpacing.sm),
              Text(
                'Size restrictions: ${details.sizeRestrictions}',
                style: WellxTypography.captionText.copyWith(
                  color: WellxColors.coral,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, IconData icon, bool highlighted) {
    final color =
        highlighted ? WellxColors.midPurple : WellxColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? WellxColors.midPurple.withValues(alpha: 0.12)
            : WellxColors.flatCardFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: WellxTypography.chipText.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
