import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../widgets/pressable_scale.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'About',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
                    ),
                  ),
                ],
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
                        gradient: AppColors.purpleGradient,
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
                      'Version 1.0.0',
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
