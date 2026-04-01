import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../providers/pet_provider.dart';

// ---------------------------------------------------------------------------
// Health Check Type
// ---------------------------------------------------------------------------

enum HealthCheckType {
  bcs,
  wellness,
  urineStrip;

  String get title {
    switch (this) {
      case HealthCheckType.bcs:
        return 'Body Condition';
      case HealthCheckType.wellness:
        return 'Breed Wellness';
      case HealthCheckType.urineStrip:
        return 'Urine Screening';
    }
  }

  String get subtitle {
    switch (this) {
      case HealthCheckType.bcs:
        return 'AI-powered body condition scoring from a photo';
      case HealthCheckType.wellness:
        return 'Breed-specific lifestyle assessment';
      case HealthCheckType.urineStrip:
        return 'At-home urine analysis with AI';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthCheckType.bcs:
        return Icons.camera_alt;
      case HealthCheckType.wellness:
        return Icons.favorite;
      case HealthCheckType.urineStrip:
        return Icons.water_drop;
    }
  }

  int get stepNumber {
    switch (this) {
      case HealthCheckType.bcs:
        return 1;
      case HealthCheckType.wellness:
        return 2;
      case HealthCheckType.urineStrip:
        return 3;
    }
  }

  int get coinReward {
    switch (this) {
      case HealthCheckType.bcs:
        return 10;
      case HealthCheckType.wellness:
        return 5;
      case HealthCheckType.urineStrip:
        return 10;
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case HealthCheckType.bcs:
        return [WellxColors.deepPurple, WellxColors.midPurple];
      case HealthCheckType.wellness:
        return [WellxColors.midPurple, WellxColors.lightPurple];
      case HealthCheckType.urineStrip:
        return [WellxColors.scoreBlue, const Color(0xFF4A8ED6)];
    }
  }

  Color get accentColor {
    switch (this) {
      case HealthCheckType.bcs:
        return WellxColors.deepPurple;
      case HealthCheckType.wellness:
        return WellxColors.midPurple;
      case HealthCheckType.urineStrip:
        return WellxColors.scoreBlue;
    }
  }

  String get routePath {
    switch (this) {
      case HealthCheckType.bcs:
        return '/bcs-check';
      case HealthCheckType.wellness:
        return '/wellness-check';
      case HealthCheckType.urineStrip:
        return '/urine-check';
    }
  }

  String ctaLabel({String? breed, bool isDone = false}) {
    if (isDone) return 'Check Again';
    switch (this) {
      case HealthCheckType.bcs:
        return 'Start BCS Check';
      case HealthCheckType.wellness:
        if (breed != null && breed.isNotEmpty) return 'Start $breed Check';
        return 'Start Survey';
      case HealthCheckType.urineStrip:
        return 'Scan Strip';
    }
  }
}

// ---------------------------------------------------------------------------
// Track Screen (Check Tab)
// ---------------------------------------------------------------------------

class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  // Track completion state locally (will be wired to real data later)
  final Set<HealthCheckType> _completed = {};
  int get _completedCount => _completed.length;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(selectedPetProvider);
    final petBreed = pet?.breed ?? '';
    final isBreedKnown =
        petBreed.isNotEmpty && petBreed != (pet?.species ?? 'Dog');

    return Scaffold(
      backgroundColor: WellxColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(child: _buildHeroHeader(pet, isBreedKnown)),

          // Health check cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: WellxSpacing.xl,
              vertical: WellxSpacing.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                for (final type in HealthCheckType.values) ...[
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildJourneyCard(
                      type,
                      isDone: _completed.contains(type),
                      breed: isBreedKnown ? petBreed : null,
                    ),
                  ),
                  const SizedBox(height: WellxSpacing.lg),
                ],
              ]),
            ),
          ),

          // Rewards section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildRewardsSection(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ---------- Hero Header ----------

  Widget _buildHeroHeader(dynamic pet, bool isBreedKnown) {
    final petName = pet?.name ?? 'Health Checks';
    final petBreed = pet?.breed ?? '';

    return Container(
      height: 200,
      decoration: const BoxDecoration(gradient: WellxColors.inkGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'HEALTH CHECKS',
                          style: WellxTypography.sectionLabel.copyWith(
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pet != null ? petName : 'Health Checks',
                          style: WellxTypography.screenTitle.copyWith(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pet != null
                              ? '${isBreedKnown ? "$petBreed \u00b7 " : ""}At-Home Monitoring'
                              : 'Know more. Catch early. Live longer.',
                          style: WellxTypography.captionText.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildProgressRing(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRing() {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 4,
            color: Colors.white.withValues(alpha: 0.2),
            backgroundColor: Colors.transparent,
          ),
          CircularProgressIndicator(
            value: _completedCount / 3.0,
            strokeWidth: 4,
            color: Colors.white,
            backgroundColor: Colors.transparent,
            strokeCap: StrokeCap.round,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_completedCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'of 3',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Journey Card ----------

  Widget _buildJourneyCard(
    HealthCheckType type, {
    required bool isDone,
    String? breed,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? type.accentColor.withValues(alpha: 0.2)
              : WellxColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient top strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDone
                    ? type.gradientColors
                        .map((c) => c.withValues(alpha: 0.7))
                        .toList()
                    : type.gradientColors,
              ),
            ),
            child: Row(
              children: [
                // Step number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check,
                            size: 13, color: type.gradientColors[0])
                        : Text(
                            '${type.stepNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == HealthCheckType.wellness && breed != null
                            ? '$breed Lifestyle'
                            : type.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Coin reward badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: isDone ? 0.1 : 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 9,
                        color: isDone
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '+${type.coinReward}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDone
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // White bottom section with CTA
          Container(
            color: WellxColors.cardSurface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // CTA Button
                SizedBox(
                  width: double.infinity,
                  child: isDone
                      ? OutlinedButton.icon(
                          onPressed: () => _navigateToFlow(type),
                          icon: const Icon(Icons.refresh, size: 13),
                          label: Text(type.ctaLabel(
                              breed: breed, isDone: true)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: WellxColors.textPrimary,
                            side:
                                const BorderSide(color: WellxColors.border, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: type.gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToFlow(type),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(type.icon,
                                        size: 13, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      type.ctaLabel(breed: breed),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  // ---------- Rewards Section ----------

  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'REWARDS',
              style: WellxTypography.sectionLabel.copyWith(
                color: WellxColors.midPurple,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            if (_completedCount == 3)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events,
                      size: 10, color: WellxColors.midPurple),
                  const SizedBox(width: 4),
                  Text(
                    'All Complete!',
                    style: WellxTypography.smallLabel.copyWith(
                      fontWeight: FontWeight.bold,
                      color: WellxColors.midPurple,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: WellxSpacing.md),
        Row(
          children: [
            Expanded(
              child: _rewardBadge(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${_completedCount > 0 ? _completedCount : 1}d',
                color: WellxColors.coral,
              ),
            ),
            const SizedBox(width: WellxSpacing.md),
            Expanded(
              child: _rewardBadge(
                icon: Icons.star,
                label: 'Earned',
                value: '${_completedCount * 8}',
                color: WellxColors.midPurple,
              ),
            ),
            const SizedBox(width: WellxSpacing.md),
            Expanded(
              child: _completedCount == 3
                  ? _rewardBadge(
                      icon: Icons.emoji_events,
                      label: 'Hattrick',
                      value: '+15',
                      color: WellxColors.scoreGreen,
                    )
                  : _rewardBadge(
                      icon: Icons.track_changes,
                      label: 'Goal',
                      value: '${3 - _completedCount} left',
                      color: WellxColors.textSecondary,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rewardBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: WellxColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: WellxColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: WellxTypography.microLabel,
          ),
        ],
      ),
    );
  }

  // ---------- Navigation ----------

  void _navigateToFlow(HealthCheckType type) {
    context.push(type.routePath);
  }
}
