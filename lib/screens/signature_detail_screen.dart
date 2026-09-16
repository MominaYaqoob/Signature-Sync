import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/signature_model.dart';
import '../theme/theme.dart';
import '../widgets/pressable_scale.dart';

class SignatureDetailScreen extends StatelessWidget {
  const SignatureDetailScreen({
    super.key,
    required this.signature,
  });

  final SignatureModel signature;

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
                      'Signature',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
                    ),
                  ),
                  if (signature.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentMintGreen.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Default',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accentMintGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: AppDecorations.card(
                    radius: AppRadii.lg,
                    prominent: true,
                    color: AppColors.softPink,
                    borderColor: AppColors.accentPink.withValues(alpha: 0.22),
                  ),
                  child: Center(
                    child: Text(
                      signature.name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.signaturePreview(
                        color: AppColors.accentPink,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                signature.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${signature.styleLabel} signature',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary,
              ),
              const SizedBox(height: 24),
              _ActionRow(
                icon: Icons.edit_outlined,
                label: 'Rename',
                color: AppColors.accentPurple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rename (UI placeholder)')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionRow(
                icon: Icons.star_outline_rounded,
                label: 'Set as default',
                color: AppColors.accentMintGreen,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Set as default')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: AppColors.danger,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signature deleted')),
                  );
                  context.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.card(
          radius: AppRadii.md,
          borderColor: color.withValues(alpha: 0.18),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(color: color),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
