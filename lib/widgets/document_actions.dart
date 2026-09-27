import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import 'signature_actions.dart' show kDeleteRed;

/// Confirm, then remove the Hive record and the file on disk.
Future<bool> confirmAndDeleteDocument(
  BuildContext context,
  DocumentModel document,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        title: Text(
          'Delete this document?',
          style: AppTextStyles.titleMedium,
        ),
        content: Text(
          "This can't be undone.",
          style: AppTextStyles.secondary.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.secondary),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return false;
  await StorageService.deleteDocument(document.id);
  return true;
}

/// Same ⋮ → bottom-sheet pattern as My Signatures cards.
Future<void> showDocumentCardMenu(
  BuildContext context, {
  required DocumentModel document,
  required VoidCallback onShare,
  VoidCallback? onDeleted,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, AppSpacing.sm, 8, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.ios_share_rounded,
                  color: AppColors.accentPurple,
                ),
                title: Text('Share', style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context, 'share'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: kDeleteRed,
                ),
                title: Text(
                  'Delete',
                  style: AppTextStyles.bodyMedium.copyWith(color: kDeleteRed),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || action == null) return;
  switch (action) {
    case 'share':
      onShare();
    case 'delete':
      final deleted = await confirmAndDeleteDocument(context, document);
      if (deleted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${document.title} deleted')),
        );
        onDeleted?.call();
      }
  }
}
