import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/credit_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/score_calculator.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import 'daily_plan_card.dart';
import 'furever_impact_section.dart';

/// Home tab — health score, daily plan, shelter impact.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).valueOrNull ?? [];
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id;

    final biomarkersAsync =
        petId != null ? ref.watch(biomarkersProvider(petId)) : null;
    final biomarkers = biomarkersAsync?.valueOrNull ?? [];

    final walksAsync =
        petId != null ? ref.watch(walkSessionsProvider(petId)) : null;
    final walks = walksAsync?.valueOrNull ?? [];

    final balanceAsync = ref.watch(balanceStreamProvider);
    final balance = balanceAsync.valueOrNull;

    final healthScore = biomarkers.isNotEmpty
        ? ScoreCalculator.calculate(
            biomarkers: biomarkers,
            walkSessions: walks,
            pet: selectedPet,
          )
        : null;

    final isScoreUnlocked = healthScore != null;
    final hasPets = pets.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WellxSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: WellxSpacing.lg),

            // Title bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Wellx Pets', style: WellxTypography.screenTitle),
                Row(
                  children: [
                    if (hasPets)
                      GestureDetector(
                        onTap: () => context.push('/add-pet'),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: WellxColors.cardSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: WellxColors.border),
                          ),
                          child: const Icon(Icons.add,
                              color: WellxColors.textSecondary, size: 16),
                        ),
                      ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: const Icon(Icons.settings_outlined,
                          color: WellxColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: WellxSpacing.lg),

            // Pet selector (shown when multiple pets)
            if (pets.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
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

            const SizedBox(height: WellxSpacing.xl),

            // Health score card
            if (!hasPets)
              _AddFirstPetCard(onTap: () => context.push('/add-pet'))
            else if (isScoreUnlocked)
              _ScoreCard(score: healthScore, petName: selectedPet?.name)
            else
              _LockedScoreCard(
                onTap: () => context.go('/track'),
              ),

            const SizedBox(height: WellxSpacing.xl),

            // Domain pillar cards (only when score is unlocked)
            if (isScoreUnlocked) ...[
              Text(
                'HEALTH DOMAINS',
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.deepPurple,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: WellxSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: healthScore.pillars.map((pillar) {
                  return _DomainPillarCard(pillar: pillar);
                }).toList(),
              ),
              const SizedBox(height: WellxSpacing.xl),
            ],

            // Today's Plan
            Text(
              "TODAY'S PLAN",
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.sm),
            DailyPlanCard(
              petName: selectedPet?.name ?? 'Your pet',
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Quick access
            Text(
              'EXPLORE',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: WellxSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ExploreCard(
                    icon: Icons.place_rounded,
                    label: 'Venues',
                    color: WellxColors.bodyActivity,
                    onTap: () => context.push('/venues'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExploreCard(
                    icon: Icons.flight_rounded,
                    label: 'Travel',
                    color: WellxColors.wellnessDental,
                    onTap: () => context.push('/travel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExploreCard(
                    icon: Icons.medication_rounded,
                    label: 'Meds',
                    color: WellxColors.inflammation,
                    onTap: () {
                      final id = selectedPet?.id;
                      if (id != null) context.push('/medications/$id');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: WellxSpacing.xl),

            // Shelter impact section
            FureverImpactSection(
              coinsBalance: balance?.coinsBalance ?? 0,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Score Card (Unlocked)
// ---------------------------------------------------------------------------

class _ScoreCard extends StatelessWidget {
  final HealthScore score;
  final String? petName;

  const _ScoreCard({required this.score, this.petName});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      backgroundColor: WellxColors.inkPrimary,
      borderColor: Colors.transparent,
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score.overall / 100.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(
                      WellxColors.scoreColor(score.overall),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${score.overall}',
                      style: WellxTypography.heroDisplay.copyWith(
                        fontSize: 28,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: WellxTypography.microLabel.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
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
                  style: WellxTypography.cardTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (petName != null)
                  Text(
                    petName!,
                    style: WellxTypography.captionText.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                const SizedBox(height: WellxSpacing.sm),
                // Weakest pillar indicator
                if (score.weakestPillar != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Focus: ${score.weakestPillar!.name}',
                      style: WellxTypography.microLabel.copyWith(
                        color: Colors.white70,
                      ),
                    ),
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
// Add First Pet Card (no pets yet)
// ---------------------------------------------------------------------------

class _AddFirstPetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFirstPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      padding: const EdgeInsets.all(WellxSpacing.xxl),
      backgroundColor: WellxColors.inkPrimary,
      borderColor: Colors.transparent,
      child: Center(
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 32),
            ),
            const SizedBox(height: WellxSpacing.lg),
            Text(
              'Add your first pet\nto get started',
              textAlign: TextAlign.center,
              style: WellxTypography.heading.copyWith(color: Colors.white),
            ),
            const SizedBox(height: WellxSpacing.sm),
            Text(
              'Track health, chat with Dr. Layla,\nand unlock your pet\'s health score.',
              textAlign: TextAlign.center,
              style: WellxTypography.captionText.copyWith(
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: WellxSpacing.xl),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.xl,
                  vertical: WellxSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18),
                    const SizedBox(width: WellxSpacing.sm),
                    Text(
                      'Add a Pet',
                      style: WellxTypography.buttonLabel.copyWith(
                        color: WellxColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Locked Score Card
// ---------------------------------------------------------------------------

class _LockedScoreCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LockedScoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      padding: const EdgeInsets.all(WellxSpacing.xxl),
      backgroundColor: WellxColors.inkPrimary,
      borderColor: Colors.transparent,
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 36),
            const SizedBox(height: WellxSpacing.lg),
            Text(
              'Complete a health check\nto unlock your score',
              textAlign: TextAlign.center,
              style: WellxTypography.heading.copyWith(color: Colors.white),
            ),
            const SizedBox(height: WellxSpacing.lg),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.xl,
                  vertical: WellxSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 18),
                    const SizedBox(width: WellxSpacing.sm),
                    Text(
                      'Take a Body Photo',
                      style: WellxTypography.buttonLabel.copyWith(
                        color: WellxColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Domain Pillar Card
// ---------------------------------------------------------------------------

class _DomainPillarCard extends StatelessWidget {
  final PillarScore pillar;

  const _DomainPillarCard({required this.pillar});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _pillarColor(pillar.color).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _pillarIcon(pillar.name),
                  size: 13,
                  color: _pillarColor(pillar.color),
                ),
              ),
              const Spacer(),
              Text(
                '${pillar.score}',
                style: WellxTypography.dataNumber.copyWith(
                  fontSize: 18,
                  color: WellxColors.scoreColor(pillar.score),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            pillar.name,
            style: WellxTypography.captionText.copyWith(
              fontWeight: FontWeight.w600,
              color: WellxColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pillar.percent,
              minHeight: 4,
              backgroundColor: WellxColors.border,
              valueColor: AlwaysStoppedAnimation(
                WellxColors.scoreColor(pillar.score),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _pillarIcon(String name) {
    switch (name) {
      case 'Organ Strength':
        return Icons.favorite;
      case 'Inflammation':
        return Icons.local_fire_department;
      case 'Metabolic':
        return Icons.bolt;
      case 'Body & Activity':
        return Icons.directions_walk;
      case 'Wellness & Dental':
        return Icons.mood;
      default:
        return Icons.circle;
    }
  }

  Color _pillarColor(String color) {
    switch (color) {
      case 'red':
        return WellxColors.organStrength;
      case 'orange':
        return WellxColors.inflammation;
      case 'gold':
        return WellxColors.metabolic;
      case 'green':
        return WellxColors.bodyActivity;
      case 'blue':
        return WellxColors.wellnessDental;
      default:
        return WellxColors.textTertiary;
    }
  }
}

// ---------------------------------------------------------------------------
// Explore Card
// ---------------------------------------------------------------------------

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExploreCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WellxCard(
        padding: const EdgeInsets.symmetric(
          vertical: WellxSpacing.lg,
          horizontal: WellxSpacing.md,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: WellxSpacing.sm),
            Text(
              label,
              style: WellxTypography.captionText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
