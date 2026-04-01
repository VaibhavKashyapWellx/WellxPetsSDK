import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shelter_models.dart';
import '../../providers/shelter_provider.dart';
import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';
import '../../widgets/wellx_card.dart';

/// Impact metrics card: dogs helped, meals provided, shelters partnered,
/// adoptions. Uses animated counters.
class ShelterImpactCard extends ConsumerStatefulWidget {
  const ShelterImpactCard({super.key});

  @override
  ConsumerState<ShelterImpactCard> createState() =>
      _ShelterImpactCardState();
}

class _ShelterImpactCardState extends ConsumerState<ShelterImpactCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
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
    final impactAsync = ref.watch(shelterImpactProvider);

    return impactAsync.when(
      data: (impact) => _buildCard(impact),
      loading: () => const WellxCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(color: WellxColors.deepPurple),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(ShelterImpact impact) {
    return WellxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 14, color: WellxColors.deepPurple),
              const SizedBox(width: 6),
              Text(
                'COMMUNITY IMPACT',
                style: WellxTypography.sectionLabel.copyWith(
                  color: WellxColors.deepPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: WellxSpacing.lg),

          // Impact rings row
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return Row(
                children: [
                  _impactRing(
                    value: impact.dogsHelped,
                    maxValue: max(impact.dogsHelped, 50),
                    label: 'Dogs\nHelped',
                    icon: Icons.pets,
                    color: WellxColors.scoreGreen,
                    progress: _progressAnimation.value,
                  ),
                  _impactRing(
                    value: impact.mealsProvided,
                    maxValue: max(impact.mealsProvided, 500),
                    label: 'Meals\nProvided',
                    icon: Icons.restaurant,
                    color: WellxColors.amberWatch,
                    progress: _progressAnimation.value,
                  ),
                  _impactRing(
                    value: impact.sheltersPartnered,
                    maxValue: max(impact.sheltersPartnered, 20),
                    label: 'Partner\nShelters',
                    icon: Icons.house,
                    color: WellxColors.deepPurple,
                    progress: _progressAnimation.value,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _impactRing({
    required int value,
    required int maxValue,
    required String label,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    final ringProgress =
        maxValue > 0 ? min(1.0, value / maxValue) * progress : 0.0;

    return Expanded(
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(
              painter: _RingPainter(
                progress: ringProgress,
                color: color,
                trackColor: WellxColors.border,
              ),
              child: Center(
                child: Icon(icon, size: 16, color: color),
              ),
            ),
          ),
          const SizedBox(height: WellxSpacing.sm),
          Text(
            _formatNumber(value),
            style: WellxTypography.dataNumber,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: WellxTypography.microLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeWidth = 4.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
