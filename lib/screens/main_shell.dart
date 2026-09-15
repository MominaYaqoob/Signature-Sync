import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

/// Shell with persistent bottom navigation for the four main tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.shellGradient),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            MediaQuery.paddingOf(context).top + 8,
            10,
            0,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(29),
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ColoredBox(
                color: AppColors.primaryBackground,
                child: navigationShell,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.shellGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white.withValues(alpha: 0.22),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.gesture_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.gesture_rounded, color: Colors.white),
                label: 'Signatures',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined, color: Colors.white70),
                selectedIcon:
                    Icon(Icons.description_rounded, color: Colors.white),
                label: 'Documents',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.settings_rounded, color: Colors.white),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
