import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_model.dart';
import '../services/document_signer.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';

/// SCREEN D — builds the signed file (stamping the chosen signature onto
/// the page placed in the previous screen), saves it as a Document, and
/// lets the user share or save it.
class SignSuccessScreen extends StatefulWidget {
  const SignSuccessScreen({super.key});

  @override
  State<SignSuccessScreen> createState() => _SignSuccessScreenState();
}

enum _Status { working, error, done }

class _SignSuccessScreenState extends State<SignSuccessScreen> {
  _Status _status = _Status.working;
  String? _error;
  DocumentModel? _document;
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _run();
  }

  Future<void> _run() async {
    final extra = GoRouterState.of(context).extra;
    final data = extra is Map ? extra : const <Object?, Object?>{};

    final filePath = data['filePath'] as String? ?? '';
    final fileType = data['fileType'] as String? ?? 'pdf';
    final pageIndex = (data['pageIndex'] as num?)?.toInt() ?? 0;
    final pageCount = (data['pageCount'] as num?)?.toInt() ?? 1;
    final signatureId = data['signatureId'] as String? ?? '';
    final stampRaw = data['stamp'];

    if (filePath.isEmpty || !File(filePath).existsSync()) {
      setState(() {
        _status = _Status.error;
        _error = 'The original document could not be found.';
      });
      return;
    }
    final signature = StorageService.getSignatureById(signatureId);
    if (signature == null) {
      setState(() {
        _status = _Status.error;
        _error = 'The selected signature could not be found.';
      });
      return;
    }
    if (stampRaw is! Map) {
      setState(() {
        _status = _Status.error;
        _error = 'Signature placement was lost — please place it again.';
      });
      return;
    }

    try {
      final placement = StampPlacement.fromMap(
        stampRaw.cast<Object?, Object?>(),
        pageIndex,
      );
      final result = await buildSignedDocument(
        sourcePath: filePath,
        fileType: fileType,
        pageCount: pageCount,
        placement: placement,
        signature: signature,
      );

      final title = filePath
          .split(Platform.pathSeparator)
          .last
          .replaceAll(RegExp(r'\.[^.]+$'), '');
      final document = DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: title.isEmpty ? 'Signed document' : title,
        status: DocumentStatus.signed,
        updatedAt: DateTime.now(),
        pageCount: pageCount,
        signerName: signature.name,
        fileType:
            fileType == 'pdf' ? DocumentFileType.pdf : DocumentFileType.image,
        filePath: result.filePath,
      );
      await StorageService.saveDocument(document);

      if (!mounted) return;
      setState(() {
        _document = document;
        _status = _Status.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _error = 'Could not create the signed file: $e';
      });
    }
  }

  Future<void> _share() async {
    final path = _document?.filePath;
    if (path == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: _document?.title,
      ),
    );
  }

  Future<void> _saveToDevice() async {
    final path = _document?.filePath;
    if (path == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Choose "Save to Files" (or "Save to Photos") next'),
      ),
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: _document?.title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: switch (_status) {
            _Status.working => const _WorkingView(),
            _Status.error => _ErrorView(message: _error!),
            _Status.done => _DoneView(
                document: _document!,
                onShare: _share,
                onSaveToDevice: _saveToDevice,
              ),
          },
        ),
      ),
    );
  }
}

class _WorkingView extends StatelessWidget {
  const _WorkingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.accentPurple),
        const SizedBox(height: 20),
        Text('Signing your document…', style: AppTextStyles.bodyLarge),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.danger,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.document,
    required this.onShare,
    required this.onSaveToDevice,
  });

  final DocumentModel document;
  final VoidCallback onShare;
  final VoidCallback onSaveToDevice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.accentBlue,
            size: 52,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Document signed successfully!',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Your file is ready to share or save locally.',
          textAlign: TextAlign.center,
          style: AppTextStyles.secondary.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (document.hasFile)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 160,
              child: document.isPdf
                  ? const _PdfBadge()
                  : Image.file(
                      File(document.filePath!),
                      fit: BoxFit.contain,
                    ),
            ),
          ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.violetGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onShare,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Text(
                    'Share',
                    style: AppTextStyles.onAccentLabel.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: Material(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onSaveToDevice,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Text(
                  'Save to device',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/home'),
          child: Text('Done', style: AppTextStyles.secondary),
        ),
      ],
    );
  }
}

/// PDFs are rendered page images internally; showing the page 1:1 here is
/// unnecessarily heavy, so the "done" screen shows a simple badge instead —
/// the real preview lives in the document detail screen.
class _PdfBadge extends StatelessWidget {
  const _PdfBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(
          Icons.picture_as_pdf_rounded,
          color: AppColors.accentBlue,
          size: 48,
        ),
      ),
    );
  }
}
