import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // pubspec.yaml's `version:` as a fallback while the real, installed
  // version/build number loads (and if the platform channel ever fails) —
  // this stays in sync with the app you actually ship, unlike a hardcoded
  // string that only reads correctly the day it was written.
  String _versionLabel = 'Version 1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLabel = 'Version ${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      // Keep the fallback label.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavyAppHeader(
                title: 'About',
                onBack: () => context.pop(),
                fontSize: 18,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: AppDecorations.card(
                  radius: AppRadii.lg,
                  prominent: true,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.violetGradient,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        boxShadow: AppShadows.elevated,
                      ),
                      child: const Icon(
                        Icons.gesture_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Signature: Sync',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _versionLabel,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sign documents privately on your device. '
                      'Create, save, and place signatures with a simple, '
                      'beautiful interface.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondary.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PressableScale(
                onTap: () => context.push('/privacy'),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Container(
                  padding: AppSpacing.cardPadding,
                  decoration: AppDecorations.card(radius: AppRadii.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.accentPurple,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Privacy policy',
                          style: AppTextStyles.bodyLarge,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
