import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wellx_colors.dart';
import '../theme/wellx_spacing.dart';

/// The 5-tab shell that wraps all main screens.
///
/// Mirrors FureverApp's MainTabView with a dark floating pill tab bar.
/// Tabs: Home, Reports, Layla (center hero), Check, Records.
class MainTabShell extends StatelessWidget {
  final Widget child;

  const MainTabShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(path: '/home', icon: Icons.home_rounded, label: 'Home'),
    _TabItem(path: '/reports', icon: Icons.description_outlined, label: 'Reports'),
    _TabItem(path: '/vet', icon: Icons.favorite_rounded, label: 'Layla', isCenter: true),
    _TabItem(path: '/track', icon: Icons.crop_free_rounded, label: 'Check'),
    _TabItem(path: '/wallet', icon: Icons.inbox_rounded, label: 'Records'),
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

/// Dark floating pill tab bar (matches FureverApp's ink tab bar).
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: WellxSpacing.lg,
        right: WellxSpacing.lg,
        top: WellxSpacing.sm,
      ),
      color: Colors.transparent,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: WellxColors.inkGradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: WellxColors.inkPrimary.withValues(alpha: 0.3),
              blurRadius: 20,
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
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Center hero button (Layla AI Vet) with glowing circle when active.
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
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [WellxColors.midPurple, WellxColors.deepPurple],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: WellxColors.deepPurple.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
