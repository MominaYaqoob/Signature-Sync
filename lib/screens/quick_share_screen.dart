import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document_model.dart';
import '../models/signature_model.dart';
import '../theme/theme.dart';
import '../widgets/accent_title.dart';
import '../widgets/pressable_scale.dart';

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

class QuickShareScreen extends StatelessWidget {
  const QuickShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signatures = DummySignatures.seed();
    final defaultSig = signatures.firstWhere(
      (s) => s.isDefault,
      orElse: () => signatures.first,
    );
    final documents = DummyDocuments.seed();

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
                    child: AccentTitle(
                      title: 'Quick Share',
                      accent: AppColors.accentPink,
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  24,
                ),
                children: [
                  Text(
                    'Default signature',
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: AppDecorations.card(
                      radius: AppRadii.md,
                      prominent: true,
                      color: AppColors.softPink,
                      borderColor:
                          AppColors.accentPink.withValues(alpha: 0.22),
                    ),
                    child: Column(
                      children: [
                        Text(
                          defaultSig.name,
                          style: AppTextStyles.signaturePreview(
                            color: AppColors.accentPink,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Ready to apply',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accentMintGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Apply to a recent document',
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a document to apply your default signature (UI only).',
                    style: AppTextStyles.secondary.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...documents.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ShareDocumentTile(
                        document: doc,
                        onTap: () {
                          context.push(
                            '/quick-share/success',
                            extra: <String, Object>{
                              'document': doc,
                              'signature': defaultSig,
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareDocumentTile extends StatelessWidget {
  const _ShareDocumentTile({
    required this.document,
    required this.onTap,
  });

  final DocumentModel document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = document.isPdf
        ? AppColors.accentMintGreen
        : AppColors.accentPurple;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.card(
          radius: AppRadii.md,
          borderColor: tint.withValues(alpha: 0.22),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                document.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_outlined,
                color: tint,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.tileLabel.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Signed · ${_shortDate(document.updatedAt)}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accentMintGreen,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.send_rounded,
              color: AppColors.accentPink,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickShareSuccessScreen extends StatelessWidget {
  const QuickShareSuccessScreen({
    super.key,
    this.document,
    this.signature,
  });

  final DocumentModel? document;
  final SignatureModel? signature;

  @override
  Widget build(BuildContext context) {
    final docTitle = document?.title ?? 'Document';
    final sigName = signature?.name ?? 'Signature';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: AppDecorations.card(
                  radius: AppRadii.xl,
                  prominent: true,
                  color: AppColors.softGreen,
                  borderColor: AppColors.accentMintGreen.withValues(alpha: 0.25),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.accentMintGreen.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.accentMintGreen,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Signature applied',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '“$sigName” was applied to\n$docTitle',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: PressableScale(
                  onTap: () => context.go('/home'),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: DecoratedBox(
                    decoration: AppDecorations.purpleButton(
                      radius: AppRadii.sm,
                    ),
                    child: Center(
                      child: Text(
                        'Back to Home',
                        style: AppTextStyles.onAccentLabel.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 48,
                child: PressableScale(
                  onTap: () => context.go('/documents'),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Center(
                    child: Text(
                      'View documents',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentPurple,
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
