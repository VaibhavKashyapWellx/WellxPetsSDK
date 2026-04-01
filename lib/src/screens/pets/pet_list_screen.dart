import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pet.dart';
import '../../providers/pet_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/wellx_primary_button.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

/// Grid listing all of the user's pets.
class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsProvider);

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: Text('My Pets', style: WellxTypography.heading),
        backgroundColor: WellxColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: petsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: WellxColors.deepPurple),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(WellxSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: WellxColors.coral, size: 48),
                const SizedBox(height: WellxSpacing.lg),
                Text(
                  'Failed to load pets',
                  style: WellxTypography.heading,
                ),
                const SizedBox(height: WellxSpacing.sm),
                Text(
                  err.toString(),
                  style: WellxTypography.captionText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WellxSpacing.xl),
                WellxPrimaryButton(
                  label: 'Retry',
                  fullWidth: false,
                  onPressed: () => ref.invalidate(petsProvider),
                ),
              ],
            ),
          ),
        ),
        data: (pets) {
          if (pets.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildPetGrid(context, ref, pets);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WellxColors.deepPurple,
        onPressed: () => _navigateToAddPet(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WellxSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: WellxColors.flatCardFill,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.pets,
                  size: 40, color: WellxColors.lightPurple),
            ),
            const SizedBox(height: WellxSpacing.xl),
            Text('No pets yet', style: WellxTypography.heading),
            const SizedBox(height: WellxSpacing.sm),
            Text(
              'Add your first pet to get started with\nhealth tracking and wellness insights.',
              style: WellxTypography.bodyText.copyWith(
                color: WellxColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WellxSpacing.xl),
            WellxPrimaryButton(
              label: 'Add Your Pet',
              icon: Icons.add,
              fullWidth: false,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPetScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetGrid(
      BuildContext context, WidgetRef ref, List<Pet> pets) {
    return GridView.builder(
      padding: const EdgeInsets.all(WellxSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: WellxSpacing.lg,
        crossAxisSpacing: WellxSpacing.lg,
        childAspectRatio: 0.85,
      ),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return _PetGridCard(
          pet: pet,
          onTap: () {
            ref.read(selectedPetIdProvider.notifier).state = pet.id;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PetDetailScreen(pet: pet),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToAddPet(BuildContext context, WidgetRef ref) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddPetScreen()))
        .then((_) => ref.invalidate(petsProvider));
  }
}

class _PetGridCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const _PetGridCard({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WellxCard(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pet photo or placeholder
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: WellxColors.flatCardFill,
                borderRadius: BorderRadius.circular(36),
                image: pet.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(pet.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pet.photoUrl == null
                  ? Center(
                      child: Text(
                        pet.speciesEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: WellxSpacing.md),
            Text(
              pet.name,
              style: WellxTypography.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: WellxSpacing.xs),
            Text(
              pet.breed,
              style: WellxTypography.captionText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: WellxSpacing.xs),
            Text(
              pet.displayAge,
              style: WellxTypography.smallLabel,
            ),
          ],
        ),
      ),
    );
  }
}
