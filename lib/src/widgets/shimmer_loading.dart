import 'package:flutter/material.dart';
import '../theme/wellx_colors.dart';
import '../theme/wellx_spacing.dart';

/// Skeleton loading card (shimmer placeholder).
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;

  const ShimmerCard({
    super.key,
    this.height = 56,
    this.width,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WellxSpacing.cardRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                WellxColors.flatCardFill,
                WellxColors.border,
                WellxColors.flatCardFill,
              ],
            ),
          ),
        );
      },
    );
  }
}
