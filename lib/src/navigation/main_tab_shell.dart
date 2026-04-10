import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wellx_colors.dart';
import '../theme/wellx_spacing.dart';

/// The 5-tab shell that wraps all main screens.
///
/// "Digital Sanctuary" floating glass island navigation bar.
/// Tabs: Home, Reports, Layla (center hero), Check, Records.
class MainTabShell extends StatelessWidget {
  final Widget child;

  const MainTabShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(path: '/home', icon: Icons.home_rounded, label: 'Home'),
    _TabItem(path: '/reports', icon: Icons.description_outlined, label: 'Reports'),
    _TabItem(path: '/vet', icon: Icons.auto_awesome_rounded, label: 'Layla', isCenter: true),
    _TabItem(path: '/track', icon: Icons.crop_free_rounded, label: 'Check'),
    _TabItem(path: '/wallet', icon: Icons.folder_rounded, label: 'Records'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _FloatingTabBar(
        currentIndex: currentIndex,
        onTap: (index) => context.go(_tabs[index].path),
        tabs: _tabs,
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final String label;
  final bool isCenter;

  const _TabItem({
    required this.path,
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}

/// Floating glass "island" navigation bar — signature Digital Sanctuary element.
///
/// Glassmorphism: surface-container-highest at 80% opacity with heavy backdrop blur.
/// Detached from screen edges.
class _FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  const _FloatingTabBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomPadding + 8,
        left: WellxSpacing.xl,
        right: WellxSpacing.xl,
        top: WellxSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: WellxColors.surfaceContainerHighest.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: WellxColors.onSurface.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isSelected = index == currentIndex;

                if (tab.isCenter) {
                  return _CenterTabButton(
                    icon: tab.icon,
                    isSelected: isSelected,
                    onTap: () => onTap(index),
                  );
                }

                return _TabButton(
                  icon: tab.icon,
                  label: tab.label,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? WellxColors.primary
                  : WellxColors.onSurfaceVariant.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? WellxColors.primary
                    : WellxColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Center hero button (Layla AI) with gradient when active.
class _CenterTabButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterTabButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected ? WellxColors.accentGradient : null,
          color: isSelected ? null : WellxColors.surfaceContainer,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: WellxColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : WellxColors.onSurfaceVariant,
          size: 22,
        ),
      ),
    );
  }
}
