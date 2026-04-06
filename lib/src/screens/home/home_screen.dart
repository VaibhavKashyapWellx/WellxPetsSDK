import 'dart:math' as math;
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
import '../../widgets/shimmer_loading.dart';
import 'daily_plan_card.dart';
import 'furever_impact_section.dart';

/// Home tab — health score, daily plan, shelter impact.
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

    final healthScore = biomarkers.isNotEmpty
        ? ScoreCalculator.calculate(
            biomarkers: biomarkers,
            walkSessions: walks,
            pet: selectedPet,
          )
        : null;

    final isScoreUnlocked = healthScore != null;
    final hasPets = pets.isNotEmpty;
    final isLoading = biomarkersAsync?.isLoading == true;

    // Trigger score ring animation when score changes
    if (healthScore != null) {
      _triggerScoreAnimation(healthScore.overall);
    }

    return SafeArea(
      child: RefreshIndicator(
        color: WellxColors.deepPurple,
        displacement: 40,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
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
                                Text(pet.speciesEmoji,
                                    style: const TextStyle(fontSize: 20)),
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
              else if (isLoading)
                const ShimmerCard(height: 160)
              else if (isScoreUnlocked)
                _AnimatedScoreCard(
                  score: healthScore,
                  petName: selectedPet?.name,
                  animation: _scoreAnim,
                )
              else
                _LockedScoreCard(onTap: () => context.go('/track')),

              const SizedBox(height: WellxSpacing.xl),

              // Domain pillar cards
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
              DailyPlanCard(petName: selectedPet?.name ?? 'Your pet'),

              const SizedBox(height: WellxSpacing.xl),

              // Quick access — Explore section
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
                      color: WellxColors.scoreBlue,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Score Card with CustomPainter ring
// ---------------------------------------------------------------------------

class _AnimatedScoreCard extends StatelessWidget {
  final HealthScore score;
  final String? petName;
  final Animation<double> animation;

  const _AnimatedScoreCard({
    required this.score,
    this.petName,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return WellxCard(
      backgroundColor: WellxColors.inkPrimary,
      borderColor: Colors.transparent,
      child: Row(
        children: [
          // Animated score ring
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final progress = (score.overall / 100.0) * animation.value;
              return SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _ScoreRingPainter(
                        progress: progress,
                        color: WellxColors.scoreColor(score.overall),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        strokeWidth: 7,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(score.overall * animation.value).round()}',
                          style: WellxTypography.heroDisplay.copyWith(
                            fontSize: 30,
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
              );
            },
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
                // Score label badge
                _scoreBadge(score.overall),
                const SizedBox(height: WellxSpacing.xs),
                // Weakest pillar
                if (score.weakestPillar != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
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

  Widget _scoreBadge(int score) {
    final String label;
    final Color color;
    if (score >= 80) {
      label = 'Excellent';
      color = WellxColors.scoreGreen;
    } else if (score >= 65) {
      label = 'Good';
      color = WellxColors.scoreBlue;
    } else if (score >= 50) {
      label = 'Fair';
      color = WellxColors.scoreOrange;
    } else {
      label = 'Needs Attention';
      color = WellxColors.scoreRed;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Score Ring Painter (matches iOS circular arc style)
// ---------------------------------------------------------------------------

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  const _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at top
      2 * math.pi * progress,
      false,
      fgPaint,
    );

    // Glow effect at tip
    if (progress > 0.02) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + sweepAngle - 0.15,
        0.15,
        false,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// Add First Pet Card
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
                color: Colors.white.withValues(alpha: 0.12),
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
// Locked Score Card with elegant gradient + lock icon
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WellxColors.inkPrimary, Color(0xFF2D1B6B)],
          ),
        ),
        child: Center(
          child: Column(
            children: [
              // Lock icon in a glowing circle
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: WellxColors.deepPurple.withValues(alpha: 0.4),
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
                style: WellxTypography.heading.copyWith(color: Colors.white),
              ),
              const SizedBox(height: WellxSpacing.xs),
              Text(
                'Complete a body scan to unlock\nyour pet\'s personalised health score.',
                textAlign: TextAlign.center,
                style: WellxTypography.captionText.copyWith(
                  color: Colors.white60,
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
                  borderRadius: BorderRadius.circular(16),
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
                      color: WellxColors.inkPrimary,
                    ),
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
            ],
          ),
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
                  color: _pillarColor(pillar.color).withValues(alpha: 0.12),
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

class _ExploreCard extends StatefulWidget {
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
  State<_ExploreCard> createState() => _ExploreCardState();
}

class _ExploreCardState extends State<_ExploreCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.93,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.reverse(),
      onTapUp: (_) {
        _pressController.forward();
        widget.onTap();
      },
      onTapCancel: () => _pressController.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
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
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: WellxSpacing.sm),
              Text(
                widget.label,
                style: WellxTypography.captionText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
