import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

/// Shell with persistent bottom navigation for the four main tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Single radius for the whole phone frame — avoids nested corner mismatch.
  static const double _frameRadius = 28;

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
      backgroundColor: AppColors.primaryBackground,
      body: ColoredBox(
        // White outer board — clean professional frame (no pink shell).
        color: AppColors.primaryBackground,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            padding.top + 8,
            10,
            bottomGap,
          ),
          child: Material(
            color: AppColors.primaryBackground,
            elevation: 0,
            shadowColor: Colors.transparent,
            borderRadius: BorderRadius.circular(_frameRadius),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(_frameRadius),
                border: Border.all(
                  color: AppColors.borderSoft.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      removeBottom: true,
                      child: ClipRRect(
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          border: Border(
                            top: BorderSide(
                              color: AppColors.borderSoft,
                              width: 1,
                            ),
                          ),
                        ),
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

/// White tab bar: rounded bordered pills + top partition.
class _NavPillButton extends StatelessWidget {
  const _NavPillButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  static const Color _active = AppColors.navy;
  static const Color _inactive = Color(0xFF9AA3AF);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _active : _inactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? _active.withValues(alpha: 0.08)
              : AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _active : AppColors.borderSoft,
            width: selected ? 1.4 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: color,
              size: selected ? 24 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
