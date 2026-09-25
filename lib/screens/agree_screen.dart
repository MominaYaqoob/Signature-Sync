import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/pressable_scale.dart';

/// Shown once, right after onboarding: a lightweight consent gate so the
/// user has actually seen and agreed to the Privacy Policy before the app
/// is used. Marks onboarding complete on continue, so Splash skips straight
/// to Home on every later launch.
class AgreeScreen extends StatefulWidget {
  const AgreeScreen({super.key});

  @override
  State<AgreeScreen> createState() => _AgreeScreenState();
}

class _AgreeScreenState extends State<AgreeScreen> {
  bool _agreed = false;
  bool _continuing = false;

  Future<void> _continue() async {
    if (!_agreed || _continuing) return;
    setState(() => _continuing = true);
    await StorageService.setOnboardingComplete();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.violetGradient,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  boxShadow: AppShadows.elevated,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Before you start',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Signature: Sync keeps your signatures and documents on '
                'this device — no account, no cloud sync. Please review how '
                'your data is handled before continuing.',
                style: AppTextStyles.secondary.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You can delete everything you\'ve created at any '
                        'time from Settings → Clear all data.',
                        style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PressableScale(
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Container(
                  padding: AppSpacing.cardPadding,
                  decoration: AppDecorations.card(
                    radius: AppRadii.md,
                    borderColor: _agreed
                        ? AppColors.accentPurple.withValues(alpha: 0.45)
                        : AppColors.borderSoft,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: AppColors.accentPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.accentPurple,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.push('/privacy'),
                                ),
                                const TextSpan(
                                  text: ' and how my signatures and '
                                      'documents are stored on this device.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: PressableScale(
                  onTap: _continue,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Opacity(
                    opacity: _agreed ? 1 : 0.5,
                    child: DecoratedBox(
                      decoration: AppDecorations.purpleButton(
                        radius: AppRadii.sm,
                      ),
                      child: Center(
                        child: _continuing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.textOnAccent,
                                ),
                              )
                            : Text(
                                'Continue',
                                style: AppTextStyles.onAccentLabel.copyWith(
                                  fontSize: 14,
                                ),
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
    );
  }
}
