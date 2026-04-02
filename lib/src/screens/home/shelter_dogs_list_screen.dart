import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shelter_models.dart';
import '../../providers/shelter_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
/// Featured shelter dogs: photo cards with name, breed, age, story.
class ShelterDogsListScreen extends ConsumerWidget {
  const ShelterDogsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dogsAsync = ref.watch(allDogsProvider);

    return Scaffold(
      backgroundColor: WellxColors.background,
      appBar: AppBar(
        title: const Text('Shelter Dogs'),
        centerTitle: true,
        backgroundColor: WellxColors.background,
        foregroundColor: WellxColors.textPrimary,
        elevation: 0,
      ),
      body: dogsAsync.when(
        data: (dogs) {
          if (dogs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, size: 48, color: WellxColors.textTertiary),
                  SizedBox(height: 12),
                  Text(
                    'No shelter dogs found',
                    style: TextStyle(color: WellxColors.textTertiary),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(WellxSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return _dogCard(context, dog);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: WellxColors.deepPurple),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: WellxColors.textTertiary),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(allDogsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dogCard(BuildContext context, ShelterDog dog) {
    return GestureDetector(
      onTap: () => _showDogDetail(context, dog),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: WellxColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WellxColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            SizedBox(
              height: 120,
              width: double.infinity,
              child: dog.photoUrl != null
                  ? Image.network(
                      dog.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _dogPlaceholder(),
                    )
                  : _dogPlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(WellxSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    dog.name,
                    style: WellxTypography.chipText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Breed
                  if (dog.breed != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      dog.breed!,
                      style: WellxTypography.microLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Age
                  if (dog.age != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: WellxColors.deepPurple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dog.age!,
                        style: WellxTypography.microLabel.copyWith(
                          color: WellxColors.deepPurple,
                        ),
                      ),
                    ),
                  ],

                  // Story snippet
                  if (dog.story != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      dog.story!,
                      style: WellxTypography.microLabel.copyWith(
                        color: WellxColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dogPlaceholder() {
    return Container(
      color: WellxColors.deepPurple.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 32,
          color: WellxColors.deepPurple.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  void _showDogDetail(BuildContext context, ShelterDog dog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WellxColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(WellxSpacing.lg),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WellxColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: WellxSpacing.lg),

              // Photo
              if (dog.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    dog.photoUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => SizedBox(
                      height: 200,
                      child: _dogPlaceholder(),
                    ),
                  ),
                ),

              const SizedBox(height: WellxSpacing.xl),

              // Name + age
              Row(
                children: [
                  Expanded(
                    child: Text(dog.name, style: WellxTypography.heading),
                  ),
                  if (dog.age != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: WellxColors.textPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dog.age!,
                        style: WellxTypography.chipText,
                      ),
                    ),
                ],
              ),

              if (dog.breed != null) ...[
                const SizedBox(height: 4),
                Text(dog.breed!, style: WellxTypography.bodyText),
              ],

              if (dog.shelterName != null) ...[
                const SizedBox(height: WellxSpacing.md),
                Row(
                  children: [
                    Icon(Icons.house,
                        size: 14, color: WellxColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      dog.shelterName!,
                      style: WellxTypography.bodyText
                          .copyWith(color: WellxColors.textSecondary),
                    ),
                  ],
                ),
              ],

              if (dog.story != null) ...[
                const SizedBox(height: WellxSpacing.lg),
                Text(
                  dog.story!,
                  style: WellxTypography.bodyText.copyWith(
                    color: WellxColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
