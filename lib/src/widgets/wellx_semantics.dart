import 'package:flutter/material.dart';

/// Accessibility helpers for the WellX Pets SDK.
///
/// Wrap interactive elements with these helpers to meet WCAG 2.1 AA:
/// - [WellxTappable] — a GestureDetector with minimum 48×48 touch target and
///   full Semantics (button role, label, enabled state).
/// - [WellxImageSemantics] — wraps an image with a semantic label.
/// - [excludeFromSemantics] — convenience for decoration-only widgets.

class WellxTappable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool isButton;
  /// Optional minimum tap target size (defaults to Material minimum 48×48).
  final double minTargetSize;

  const WellxTappable({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.isButton = true,
    this.minTargetSize = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isButton,
      label: semanticLabel,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTargetSize,
            minHeight: minTargetSize,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps a network/asset image with a required semantic label.
class WellxImageSemantics extends StatelessWidget {
  final Widget child;
  final String label;
  final bool excludeFromSemantics;

  const WellxImageSemantics({
    super.key,
    required this.child,
    required this.label,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeFromSemantics) {
      return ExcludeSemantics(child: child);
    }
    return Semantics(
      image: true,
      label: label,
      child: child,
    );
  }
}

/// Marks a widget as decoration-only (excluded from the semantics tree).
class WellxDecorationOnly extends StatelessWidget {
  final Widget child;

  const WellxDecorationOnly({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: child);
}

/// Wraps a section in a [FocusTraversalGroup] so screen readers traverse
/// children in the correct reading order.
class WellxFocusGroup extends StatelessWidget {
  final Widget child;

  const WellxFocusGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: child,
    );
  }
}
