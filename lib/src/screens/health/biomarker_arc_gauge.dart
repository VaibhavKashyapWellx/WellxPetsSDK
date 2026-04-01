import 'dart:math';
import 'package:flutter/material.dart';

import '../../theme/wellx_colors.dart';
import '../../theme/wellx_typography.dart';
import '../../theme/wellx_spacing.dart';

/// Custom painted arc gauge showing biomarkers in range vs out of range.
///
/// Green/yellow/red zones on a semicircular arc. Center displays the
/// in-range count vs total.
class BiomarkerArcGauge extends StatelessWidget {
  final int total;
  final int inRange;
  final double size;

  const BiomarkerArcGauge({
    super.key,
    required this.total,
    required this.inRange,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? inRange / total : 0.0;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size * 0.6,
          child: CustomPaint(
            painter: _ArcGaugePainter(
              ratio: ratio,
              total: total,
              inRange: inRange,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$inRange/$total',
                      style: WellxTypography.dataNumber.copyWith(
                        color: _scoreColor(ratio),
                      ),
                    ),
                    Text(
                      'in range',
                      style: WellxTypography.captionText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: WellxSpacing.md),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: WellxColors.scoreGreen, label: 'In Range'),
            const SizedBox(width: WellxSpacing.lg),
            _LegendDot(color: WellxColors.amberWatch, label: 'Watch'),
            const SizedBox(width: WellxSpacing.lg),
            _LegendDot(color: WellxColors.coral, label: 'Out of Range'),
          ],
        ),
      ],
    );
  }

  Color _scoreColor(double ratio) {
    if (ratio >= 0.85) return WellxColors.scoreGreen;
    if (ratio >= 0.6) return WellxColors.amberWatch;
    return WellxColors.coral;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: WellxTypography.microLabel),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Arc Gauge Painter
// ---------------------------------------------------------------------------

class _ArcGaugePainter extends CustomPainter {
  final double ratio;
  final int total;
  final int inRange;

  _ArcGaugePainter({
    required this.ratio,
    required this.total,
    required this.inRange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 12;
    const strokeWidth = 12.0;

    // Background arc (full semicircle)
    final bgPaint = Paint()
      ..color = WellxColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // start angle
      pi, // sweep angle (semicircle)
      false,
      bgPaint,
    );

    if (total == 0) return;

    // Green zone (in range)
    final greenSweep = ratio * pi;
    final greenPaint = Paint()
      ..color = WellxColors.scoreGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      greenSweep,
      false,
      greenPaint,
    );

    // Red/yellow zone (out of range)
    if (inRange < total) {
      final outRatio = (total - inRange) / total;
      final isWarning = outRatio < 0.3;
      final outPaint = Paint()
        ..color = isWarning ? WellxColors.amberWatch : WellxColors.coral
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi + greenSweep,
        pi - greenSweep,
        false,
        outPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter oldDelegate) =>
      ratio != oldDelegate.ratio ||
      total != oldDelegate.total ||
      inRange != oldDelegate.inRange;
}
