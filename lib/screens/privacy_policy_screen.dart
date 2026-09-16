import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Row(
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
                      'Privacy Policy',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  28,
                ),
                child: Container(
                  padding: AppSpacing.cardPadding,
                  decoration: AppDecorations.card(radius: AppRadii.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your privacy comes first',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Signature: Sync is designed to keep your signatures '
                        'and documents on your device. This page is a UI '
                        'placeholder and does not represent a final legal policy.',
                        style: AppTextStyles.secondary.copyWith(height: 1.55),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('What we store', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '• Signature previews and names you create in the app\n'
                        '• Document history shown in the Documents tab\n'
                        '• Local preferences such as default signature',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('What we don’t do', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '• No account login is required\n'
                        '• No cloud sync is enabled in this UI build\n'
                        '• We do not sell personal data',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Contact', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Questions about privacy can be sent to '
                        'privacy@signature-sync.app (placeholder).',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
