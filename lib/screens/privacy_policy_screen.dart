import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';

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
              child: NavyAppHeader(
                title: 'Privacy Policy',
                onBack: () => context.pop(),
                fontSize: 18,
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
                        'and documents on your device. Nothing you create is '
                        'uploaded anywhere unless you choose to share or '
                        'save a file yourself.',
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
                        '• No account or login is required\n'
                        '• No cloud sync — everything stays on this device\n'
                        '• We do not sell personal data',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Your control', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '• Deleting a signature or document also deletes '
                        'its file from your device, not just its listing\n'
                        '• Settings → Clear all data removes everything at '
                        'once\n'
                        '• Uninstalling the app erases all of its data',
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Contact', style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Questions about privacy can be sent to '
                        'privacy@signature-sync.app.',
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
