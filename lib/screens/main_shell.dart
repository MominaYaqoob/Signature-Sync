import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

/// Shell with persistent bottom navigation for the four main tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Single radius for the whole phone frame — avoids nested corner mismatch.
  static const double _frameRadius = 28;
  static const double _navPillRadius = 22;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final bottomGap = padding.bottom + 18;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        // Full-bleed backdrop (same family, slightly softer so frame edge is clean)
        decoration: const BoxDecoration(gradient: AppColors.shellGradient),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            padding.top + 8,
            10,
            bottomGap,
          ),
          // Rounded frame (top + bottom). Soft AA to avoid jagged pink/white edge.
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            borderRadius: BorderRadius.circular(_frameRadius),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppColors.shellGradient,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      removeBottom: true,
                      child: ClipRRect(
                        // Slightly tighter than frame so layers don't fight at corners
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(22),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ColoredBox(
                          color: AppColors.primaryBackground,
                          child: navigationShell,
                        ),
                      ),
                    ),
                  ),
                  TooltipVisibility(
                    visible: false,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: SafeArea(
                        top: false,
                        bottom: true,
                        minimum: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                          child: Row(
                            children: [
                              for (var i = 0; i < _tabs.length; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                Expanded(
                                  child: _NavPillButton(
                                    label: _tabs[i].label,
                                    icon: _tabs[i].icon,
                                    selectedIcon: _tabs[i].selectedIcon,
                                    selected:
                                        navigationShell.currentIndex == i,
                                    radius: _navPillRadius,
                                    onTap: () => _onTap(i),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = <_NavTab>[
  _NavTab(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  _NavTab(
    label: 'Signatures',
    icon: Icons.gesture_outlined,
    selectedIcon: Icons.gesture_rounded,
  ),
  _NavTab(
    label: 'Documents',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description_rounded,
  ),
  _NavTab(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];

/// Option B: active = gradient pill + white icon; inactive = plain.
class _NavPillButton extends StatelessWidget {
  const _NavPillButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.radius,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.purpleGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected
                    ? AppColors.textOnAccent
                    : Colors.white.withValues(alpha: 0.78),
                size: selected ? 23 : 21,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: selected ? 10.5 : 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.textOnAccent
                      : Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
