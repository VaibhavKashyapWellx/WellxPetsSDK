import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/wellx_colors.dart';
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
    final petName = pet?.name ?? 'Your Pet';
    final isBreedKnown =
        petBreed.isNotEmpty && petBreed != (pet?.species ?? 'Dog');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // Glass blur app bar
          SliverToBoxAdapter(child: _buildGlassAppBar(context, pet)),

          // Hero section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.xl, WellxSpacing.lg, WellxSpacing.xl, 0),
              child: _buildHeroCard(context, petName),
            ),
          ),

          // "Daily Wellness Tasks" heading
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WellxSpacing.xl, WellxSpacing.xl, WellxSpacing.xl, WellxSpacing.lg),
              child: Text(
                'Daily Wellness Tasks',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),

          // Task cards
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: WellxSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Card A — Body Condition
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildTaskCard(
                    context: context,
                    categoryLabel: 'VITALITY',
                    categoryIcon: Icons.fitness_center,
                    categoryBgColor:
                        cs.primaryContainer.withValues(alpha: 0.3),
                    categoryTextColor: cs.onPrimaryContainer,
                    heading: 'Body Condition',
                    description:
                        'AI-powered body condition scoring via photo analysis for accurate weight tracking.',
                    placeholderIcon: null,
                    ctaLabel: _completed.contains(HealthCheckType.bcs)
                        ? 'Check Again'
                        : 'Start BCS Check',
                    onTap: () => _navigateToFlow(HealthCheckType.bcs),
                  ),
                ),
                const SizedBox(height: WellxSpacing.lg),

                // Card B — [Breed] Lifestyle
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildTaskCard(
                    context: context,
                    categoryLabel: 'BREED SPECIFIC',
                    categoryIcon: Icons.pets,
                    categoryBgColor:
                        cs.tertiaryContainer.withValues(alpha: 0.3),
                    categoryTextColor: cs.onTertiaryContainer,
                    heading: isBreedKnown
                        ? '$petBreed Lifestyle'
                        : 'Breed Lifestyle',
                    description: isBreedKnown
                        ? 'Breed-specific lifestyle assessment to optimize $petName\'s specific energy and joint needs.'
                        : 'Breed-specific lifestyle assessment to optimize your pet\'s specific energy and joint needs.',
                    placeholderIcon: null,
                    ctaLabel: _completed.contains(HealthCheckType.wellness)
                        ? 'Check Again'
                        : isBreedKnown
                            ? 'Start $petBreed Check'
                            : 'Start Survey',
                    onTap: () => _navigateToFlow(HealthCheckType.wellness),
                  ),
                ),
                const SizedBox(height: WellxSpacing.lg),

                // Card C — Urine Screening
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildTaskCard(
                    context: context,
                    categoryLabel: 'CLINICAL',
                    categoryIcon: Icons.biotech,
                    categoryBgColor: cs.secondaryContainer,
                    categoryTextColor: cs.onSecondaryContainer,
                    heading: 'Urine Screening',
                    description:
                        'At-home urine analysis with AI recognition for early detection of kidney markers.',
                    placeholderIcon: Icons.science,
                    ctaLabel:
                        _completed.contains(HealthCheckType.urineStrip)
                            ? 'Check Again'
                            : 'Scan Strip',
                    onTap: () =>
                        _navigateToFlow(HealthCheckType.urineStrip),
                  ),
                ),

                // Bottom padding for floating nav bar
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Glass App Bar ----------

  Widget _buildGlassAppBar(BuildContext context, dynamic pet) {
    final cs = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: cs.surface.withValues(alpha: 0.8),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: WellxSpacing.xl, vertical: WellxSpacing.md),
              child: Row(
                children: [
                  // Pet avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primaryContainer,
                        width: 2,
                      ),
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                    ),
                    child: pet?.photoUrl != null && pet!.photoUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              pet.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => Icon(
                                Icons.pets,
                                size: 20,
                                color: cs.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.pets,
                            size: 20,
                            color: cs.primary,
                          ),
                  ),
                  const SizedBox(width: WellxSpacing.md),

                  // Title
                  Text(
                    'Health Checks',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),

                  const Spacer(),

                  // Notification bell
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: cs.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Hero Card ----------

  Widget _buildHeroCard(BuildContext context, String petName) {
    final cs = Theme.of(context).colorScheme;
    final ringProgress = _completedCount / 3.0;

    return Container(
      decoration: BoxDecoration(
        color: WellxColors.onPrimaryFixedVariant,
        borderRadius: BorderRadius.circular(20),
        boxShadow: WellxColors.tonalShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative blur orb (top-right)
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(WellxSpacing.xl),
            child: Row(
              children: [
                // Left side — name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'At-Home Monitoring',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side — progress ring
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(
                      progress: ringProgress,
                      trackColor: Colors.white.withValues(alpha: 0.1),
                      fillColor: WellxColors.tertiaryContainer,
                      strokeWidth: 5,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_completedCount/3',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
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

  // ---------- Task Card ----------

  Widget _buildTaskCard({
    required BuildContext context,
    required String categoryLabel,
    required IconData categoryIcon,
    required Color categoryBgColor,
    required Color categoryTextColor,
    required String heading,
    required String description,
    required IconData? placeholderIcon,
    required String ctaLabel,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: WellxColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(WellxSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: category pill + image placeholder
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: categoryBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(categoryIcon,
                                size: 12, color: categoryTextColor),
                            const SizedBox(width: 4),
                            Text(
                              categoryLabel,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: categoryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: WellxSpacing.md),

                      // Heading
                      Text(
                        heading,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: WellxSpacing.sm),

                      // Description
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: WellxSpacing.lg),

                // 96x96 image placeholder
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: placeholderIcon != null
                      ? Center(
                          child: Icon(
                            placeholderIcon,
                            size: 40,
                            color: cs.primary.withValues(alpha: 0.4),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: cs.outline.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ],
            ),

            const SizedBox(height: WellxSpacing.lg),

            // Full-width CTA pill button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        ctaLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Navigation ----------

  void _navigateToFlow(HealthCheckType type) {
    context.push(type.routePath);
  }
}

// ---------------------------------------------------------------------------
// Progress Ring Painter
// ---------------------------------------------------------------------------

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Fill arc
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
