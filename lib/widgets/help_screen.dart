import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'navy_app_header.dart';

/// One step in a [HelpScreen]'s numbered walkthrough.
class HelpStep {
  const HelpStep({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// A full "How to use" page for one feature: an intro line, a numbered
/// walkthrough, and optional quick tips. Reused by Draw, Scan and Place
/// Signature — the three screens people get stuck on most.
class HelpScreen extends StatelessWidget {
  const HelpScreen({
    super.key,
    required this.title,
    required this.intro,
    required this.steps,
    this.tips = const [],
  });

  final String title;
  final String intro;
  final List<HelpStep> steps;
  final List<String> tips;

  /// Opens this help page as a full-screen route.
  static Future<void> show(BuildContext context, HelpScreen screen) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
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
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavyAppHeader(
                title: 'How to use $title',
                onBack: () => Navigator.of(context).pop(),
                fontSize: 15,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intro,
                        style: AppTextStyles.secondary.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      for (var i = 0; i < steps.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        _StepTile(index: i + 1, step: steps[i]),
                      ],
                      if (tips.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 18,
                                    color: AppColors.accentBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tips',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontSize: 14,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              for (final tip in tips)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '•  $tip',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step});

  final int index;
  final HelpStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(step.icon, size: 18, color: AppColors.accentPurple),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. ${step.title}',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                step.body,
                style: AppTextStyles.bodySmall.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small (i) button for a screen header's `trailing` slot.
class HelpButton extends StatelessWidget {
  const HelpButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'How to use this',
      onPressed: onTap,
      icon: const Icon(
        Icons.help_outline_rounded,
        color: AppColors.textOnAccent,
      ),
    );
  }
}
