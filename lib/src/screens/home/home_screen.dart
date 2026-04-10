import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/credit_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/pet_provider.dart';
import '../../services/score_calculator.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';
import '../../widgets/shimmer_loading.dart';
import 'daily_plan_card.dart';
import 'furever_impact_section.dart';

/// Home tab — wellness score hero, Dr. Layla, daily plan, records, shelter impact.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scoreAnimController;
  late final Animation<double> _scoreAnim;
  int _lastScore = 0;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scoreAnim = CurvedAnimation(
      parent: _scoreAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  void _triggerScoreAnimation(int score) {
    if (score != _lastScore && score > 0) {
      _lastScore = score;
      _scoreAnimController.forward(from: 0);
    }
  }

  Future<void> _onRefresh() async {
    final selectedPet = ref.read(selectedPetProvider);
    if (selectedPet != null) {
      ref.invalidate(biomarkersProvider(selectedPet.id));
      ref.invalidate(walkSessionsProvider(selectedPet.id));
    }
    ref.invalidate(petsProvider);
    ref.invalidate(balanceStreamProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
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

    // Calculate score from biomarkers if available, or generate a baseline
    // from walks/pet data so the score card is always visible for active users.
    final healthScore = biomarkers.isNotEmpty
        ? ScoreCalculator.calculate(
            biomarkers: biomarkers,
            walkSessions: walks,
            pet: selectedPet,
          )
        : (selectedPet != null
            ? ScoreCalculator.calculate(
                biomarkers: const [],
                walkSessions: walks,
                pet: selectedPet,
              )
            : null);

    final isScoreUnlocked = healthScore != null;
    final hasPets = pets.isNotEmpty;
    final isLoading = biomarkersAsync?.isLoading == true;

    // Trigger score ring animation when score changes
    if (healthScore != null) {
      _triggerScoreAnimation(healthScore.overall);
    }

    return Scaffold(
      backgroundColor: WellxColors.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: WellxColors.surface.withValues(alpha: 0.8),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WellxSpacing.lg,
                    vertical: WellxSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Pet avatar with primary-container ring
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: WellxColors.primaryContainer,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Container(
                                color: WellxColors.surfaceContainerLow,
                                child: Center(
                                  child: Text(
                                    selectedPet?.speciesEmoji ?? '🐾',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Wellx Pet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: WellxColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: WellxColors.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: WellxColors.primary,
        displacement: 40,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: WellxSpacing.lg,
            right: WellxSpacing.lg,
            top: 88,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet selector (shown when multiple pets)
              if (pets.length > 1) ...[
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? WellxColors.primary
                                  : WellxColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? WellxColors.tonalShadow
                                  : WellxColors.subtleShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(pet.speciesEmoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  pet.name,
                                  style: WellxTypography.chipText.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : WellxColors.onSurface,
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
              ],

              // ── Wellness Score Hero Card ──
              if (!hasPets)
                _AddFirstPetCard(onTap: () => context.push('/add-pet'))
              else if (isLoading)
                const ShimmerCard(height: 200)
              else if (isScoreUnlocked)
                _WellnessScoreHeroCard(
                  score: healthScore,
                  petName: selectedPet?.name,
                  animation: _scoreAnim,
                )
              else
                _LockedScoreCard(onTap: () => context.go('/track')),

              const SizedBox(height: WellxSpacing.xl),

              // ── Ask Dr. Layla Section ──
              _AskDrLaylaCard(
                onTap: () => context.push('/vet'),
              ),

              const SizedBox(height: WellxSpacing.xl),

              // ── Today's Plan Section ──
              DailyPlanCard(petName: selectedPet?.name ?? 'Your pet'),

              const SizedBox(height: WellxSpacing.xl),

              // ── Recent Records Section ──
              _RecentRecordsSection(
                petId: petId,
                onViewAll: () => context.push('/wallet'),
              ),

              const SizedBox(height: WellxSpacing.xl),

              // ── Shelter Impact Section ──
              FureverImpactSection(
                coinsBalance: balance?.coinsBalance ?? 0,
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wellness Score Hero Card (Purple gradient)
// ---------------------------------------------------------------------------

class _WellnessScoreHeroCard extends StatelessWidget {
  final HealthScore score;
  final String? petName;
  final Animation<double> animation;

  const _WellnessScoreHeroCard({
    required this.score,
    this.petName,
    required this.animation,
  });

  String _scoreLabel(int s) {
    if (s >= 80) return 'Excellent';
    if (s >= 65) return 'Good';
    if (s >= 50) return 'Fair';
    return 'Needs Attention';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final animatedScore = (score.overall * animation.value).round();
        final progress = (score.overall / 100.0) * animation.value;
        final label = _scoreLabel(score.overall);

        return Container(
          padding: const EdgeInsets.all(WellxSpacing.xxl),
          decoration: BoxDecoration(
            gradient: WellxColors.primaryGradient,
            borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: WellxColors.primary.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Decorative blur orbs
              Positioned(
                top: -48,
                right: -48,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WellxColors.primaryFixedDim.withValues(alpha: 0.20),
                  ),
                ),
              ),
              Positioned(
                bottom: -32,
                left: -32,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        WellxColors.secondaryContainer.withValues(alpha: 0.10),
                  ),
                ),
              ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: label + badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELLNESS SCORE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: WellxColors.primaryFixedDim,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$animatedScore',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '/100',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Excellent badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: WellxColors.tertiaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: WellxSpacing.xl),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        // Fill with glow
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: WellxColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: WellxColors.tertiaryContainer
                                      .withValues(alpha: 0.5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: WellxSpacing.lg),

                  // Description
                  Text(
                    petName != null
                        ? '$petName is in ${label.toLowerCase()} condition! ${score.weakestPillar != null ? 'Focus area: ${score.weakestPillar!.name}.' : ''}'
                        : 'Your pet is doing well! Keep up the great care routine.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Ask Dr. Layla Card
// ---------------------------------------------------------------------------

class _AskDrLaylaCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AskDrLaylaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E0FF), // indigo-100
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: WellxColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ask Dr. Layla',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: WellxColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WellxSpacing.md),
          Text(
            'Worried about a symptom or need diet advice?',
            style: WellxTypography.bodyText.copyWith(
              color: WellxColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: WellxSpacing.lg),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: WellxColors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Chat',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: WellxColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: WellxColors.onPrimary,
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

// ---------------------------------------------------------------------------
// Recent Records Section
// ---------------------------------------------------------------------------

class _RecentRecordsSection extends StatelessWidget {
  final String? petId;
  final VoidCallback onViewAll;

  const _RecentRecordsSection({
    this.petId,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Records',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: WellxColors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: WellxColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: WellxColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: WellxSpacing.lg),

        // Horizontal scrollable record cards
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _RecordCard(
                icon: Icons.vaccines,
                iconColor: WellxColors.primary.withValues(alpha: 0.7),
                category: 'VACCINATION',
                title: 'Rabies Booster',
                date: 'Last recorded',
              ),
              const SizedBox(width: WellxSpacing.lg),
              _RecordCard(
                icon: Icons.monitor_weight,
                iconColor: WellxColors.tertiaryContainer,
                category: 'VITAL SIGN',
                title: 'Weight Check',
                date: 'Last recorded',
              ),
              const SizedBox(width: WellxSpacing.lg),
              _RecordCard(
                icon: Icons.history_edu,
                iconColor: WellxColors.alertOrange,
                category: 'JOURNAL',
                title: 'Health Notes',
                date: 'Last recorded',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String category;
  final String title;
  final String date;

  const _RecordCard({
    required this.icon,
    required this.iconColor,
    required this.category,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      padding: const EdgeInsets.all(WellxSpacing.xl),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: WellxSpacing.md),
            Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: WellxColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: WellxColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              date,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: WellxColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add First Pet Card
// ---------------------------------------------------------------------------

class _AddFirstPetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFirstPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(WellxSpacing.xxl),
      decoration: BoxDecoration(
        gradient: WellxColors.primaryGradient,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: WellxColors.primary.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 32),
            ),
            const SizedBox(height: WellxSpacing.lg),
            Text(
              'Add your first pet\nto get started',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: WellxSpacing.sm),
            Text(
              'Track health, chat with Dr. Layla,\nand unlock your pet\'s wellness score.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
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
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline,
                        size: 18, color: WellxColors.primary),
                    const SizedBox(width: WellxSpacing.sm),
                    Text(
                      'Add a Pet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: WellxColors.primary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(WellxSpacing.xxl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
          gradient: WellxColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: WellxColors.primary.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative blur orbs
            Positioned(
              top: -48,
              right: -48,
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.primaryFixedDim.withValues(alpha: 0.20),
                ),
              ),
            ),
            Positioned(
              bottom: -32,
              left: -32,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WellxColors.secondaryContainer.withValues(alpha: 0.10),
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                children: [
                  // Lock icon in a glowing circle
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: WellxColors.primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: WellxSpacing.lg),
                  Text(
                    'Health Score Locked',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: WellxSpacing.xs),
                  Text(
                    'Complete a body scan to unlock\nyour pet\'s personalised wellness score.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: WellxSpacing.xl),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WellxSpacing.xl,
                      vertical: WellxSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: WellxColors.primary,
                        ),
                        const SizedBox(width: WellxSpacing.sm),
                        Text(
                          'Take a Body Photo',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: WellxColors.primary,
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
      ),
    );
  }
}
