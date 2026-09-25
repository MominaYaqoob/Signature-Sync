import 'package:flutter/material.dart';

import '../models/signature_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';

/// Real red for destructive actions (`AppColors.danger` is aliased to blue).
const kDeleteRed = Color(0xFFE53935);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "21 Sep 2026"
String formatSignatureDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// "Drawn · 21 Sep 2026"
String signatureMeta(SignatureModel signature) =>
    '${signature.styleLabel} · ${formatSignatureDate(signature.createdAt)}';

/// Deletes [signature] right away and offers Undo in a snackbar.
/// The PNG on disk is only removed once the snackbar closes without Undo.
Future<void> deleteSignatureWithUndo(
  ScaffoldMessengerState messenger,
  SignatureModel signature,
) async {
  await StorageService.deleteSignature(signature.id, keepFile: true);

  messenger.hideCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text('“${signature.name}” deleted'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: AppColors.accentGreenLight,
        onPressed: () => StorageService.restoreSignature(signature),
      ),
    ),
  );

  final reason = await controller.closed;
  if (reason != SnackBarClosedReason.action) {
    await StorageService.deleteSignatureFile(signature.imagePath);
  }
}
