import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/document_model.dart';
import '../theme/theme.dart';

/// Placeholder document preview / detail shell.
class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({
    super.key,
    required this.documentId,
    this.document,
  });

  final String documentId;
  final DocumentModel? document;

  @override
  Widget build(BuildContext context) {
    final doc = document ?? DummyDocuments.byId(documentId);
    final title = doc?.title ?? 'Document';
    final isPdf = doc?.isPdf ?? true;
    final tint = isPdf ? AppColors.accentMintGreen : AppColors.accentPurple;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium,
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon')),
              );
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_outlined,
                        color: tint,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Preview placeholder',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Document viewer will appear here in a later phase.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (doc != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'Status: Signed',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 13,
                    color: AppColors.accentMintGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
