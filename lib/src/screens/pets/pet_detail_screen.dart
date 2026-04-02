import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';
import 'edit_pet_screen.dart';

/// Pet profile screen showing details and action buttons.
class PetDetailScreen extends ConsumerWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for updates — use the live provider if available, else fall back
    // to the pet passed in.
    final livePet = ref.watch(selectedPetProvider) ?? pet;

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: Text(livePet.name, style: WellxTypography.heading),
        backgroundColor: WellxColors.background,
        elevation: 0,
        foregroundColor: WellxColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        child: Column(
          children: [
            // Hero card with photo, name, breed
            WellxCard(
              padding: const EdgeInsets.all(WellxSpacing.xl),
              child: Column(
                children: [
                  // Pet photo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: WellxColors.flatCardFill,
                      borderRadius: BorderRadius.circular(50),
                      image: livePet.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(livePet.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: livePet.photoUrl == null
                        ? Center(
                            child: Text(
                              livePet.speciesEmoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: WellxSpacing.lg),
                  Text(livePet.name, style: WellxTypography.screenTitle),
                  const SizedBox(height: WellxSpacing.xs),
                  Text(livePet.breed, style: WellxTypography.captionText),
                  if (livePet.longevityScore != null) ...[
                    const SizedBox(height: WellxSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WellxSpacing.lg,
                        vertical: WellxSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: WellxColors.scoreColor(livePet.longevityScore!)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Health Score: ${livePet.longevityScore}',
                        style: WellxTypography.chipText.copyWith(
                          color: WellxColors.scoreColor(
                              livePet.longevityScore!),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: WellxSpacing.lg),

            // Info grid
            WellxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DETAILS', style: WellxTypography.sectionLabel),
                  const SizedBox(height: WellxSpacing.lg),
                  _buildInfoRow('Age', livePet.displayAge),
                  _buildDivider(),
                  _buildInfoRow('Species',
                      (livePet.species ?? 'Unknown').capitalize()),
                  _buildDivider(),
                  _buildInfoRow('Gender',
                      (livePet.gender ?? 'Unknown').capitalize()),
                  _buildDivider(),
                  _buildInfoRow(
                    'Weight',
                    livePet.weight != null
                        ? '${livePet.weight} kg'
                        : 'Not set',
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    'Neutered',
                    livePet.isNeutered == true ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
            const SizedBox(height: WellxSpacing.lg),

            // Action buttons
            WellxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIONS', style: WellxTypography.sectionLabel),
                  const SizedBox(height: WellxSpacing.lg),
                  _buildActionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditPetScreen(pet: livePet),
                        ),
                      );
                      if (updated == true) {
                        ref.invalidate(petsProvider);
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Health Dashboard',
                    onTap: () {
                      context.push('/health-dashboard/${livePet.id}');
                    },
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    icon: Icons.folder_outlined,
                    label: 'Documents',
                    onTap: () {
                      // Set the selected pet so wallet shows the right documents
                      ref.read(selectedPetIdProvider.notifier).state = livePet.id;
                      context.go('/wallet');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: WellxSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WellxSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: WellxTypography.captionText),
          Text(value, style: WellxTypography.bodyText),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: WellxSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WellxColors.flatCardFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: WellxColors.deepPurple, size: 20),
            ),
            const SizedBox(width: WellxSpacing.md),
            Expanded(
              child: Text(label, style: WellxTypography.bodyText),
            ),
            const Icon(Icons.chevron_right,
                color: WellxColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: WellxColors.border,
      height: 1,
    );
  }
}

extension _StringCap on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
