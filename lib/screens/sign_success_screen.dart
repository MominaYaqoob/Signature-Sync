import 'dart:io';
import 'dart:typed_data';

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

enum _Status { naming, working, error, done }

class _SignSuccessScreenState extends State<SignSuccessScreen> {
  _Status _status = _Status.naming;
  String? _error;
  DocumentModel? _document;
  Uint8List? _previewPng;
  bool _ready = false;
  final _nameController = TextEditingController();
  String _fileType = 'pdf';
  String _sourcePath = '';
  int _pageIndex = 0;
  int _pageCount = 1;
  String _signatureId = '';
  Map<Object?, Object?>? _stampRaw;
  Map<Object?, Object?>? _dateStampRaw;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _prepareNaming();
  }

  void _prepareNaming() {
    final extra = GoRouterState.of(context).extra;
    final data = extra is Map ? extra : const <Object?, Object?>{};

    _sourcePath = data['filePath'] as String? ?? '';
    _fileType = data['fileType'] as String? ?? 'pdf';
    _pageIndex = (data['pageIndex'] as num?)?.toInt() ?? 0;
    _pageCount = (data['pageCount'] as num?)?.toInt() ?? 1;
    _signatureId = data['signatureId'] as String? ?? '';
    final stampRaw = data['stamp'];
    _stampRaw = stampRaw is Map ? stampRaw.cast<Object?, Object?>() : null;
    final dateRaw = data['dateStamp'];
    _dateStampRaw = dateRaw is Map ? dateRaw.cast<Object?, Object?>() : null;

    final stem = _sourcePath
        .split(Platform.pathSeparator)
        .last
        .replaceAll(RegExp(r'\.[^.]+$'), '');
    final defaultName =
        stem.isEmpty ? 'Signed document' : '$stem - Signed';
    _nameController.text = defaultName;

    if (_sourcePath.isEmpty || !File(_sourcePath).existsSync()) {
      setState(() {
        _status = _Status.error;
        _error = 'The original document could not be found.';
      });
      return;
    }
    if (StorageService.getSignatureById(_signatureId) == null) {
      setState(() {
        _status = _Status.error;
        _error = 'The selected signature could not be found.';
      });
      return;
    }
    if (_stampRaw == null) {
      setState(() {
        _status = _Status.error;
        _error = 'Signature placement was lost — please place it again.';
      });
      return;
    }
    setState(() => _status = _Status.naming);
  }

  Future<void> _confirmNameAndSign() async {
    if (_status == _Status.working) return;
    setState(() => _status = _Status.working);

    final signature = StorageService.getSignatureById(_signatureId);
    final stampRaw = _stampRaw;
    if (signature == null || stampRaw == null) {
      setState(() {
        _status = _Status.error;
        _error = 'Something went wrong — please try signing again.';
      });
      return;
    }

    try {
      final placement = StampPlacement.fromMap(stampRaw, _pageIndex);
      final datePlacement = _dateStampRaw == null
          ? null
          : DateStampPlacement.fromMap(_dateStampRaw!, _pageIndex);
      final preferred = _nameController.text.trim();
      final result = await buildSignedDocument(
        sourcePath: _sourcePath,
        fileType: _fileType,
        pageCount: _pageCount,
        placement: placement,
        signature: signature,
        preferredBaseName: preferred.isEmpty ? null : preferred,
        datePlacement: datePlacement,
      );

      // Display name: user text if provided, else file stem / fallback.
      final sanitized = sanitizeFileBaseName(preferred);
      final fileStem = File(result.filePath)
          .uri
          .pathSegments
          .last
          .replaceAll(RegExp(r'\.[^.]+$'), '');
      final title = sanitized.isNotEmpty
          ? sanitized
          : (fileStem.isEmpty ? 'Signed document' : fileStem);

      final document = DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        status: DocumentStatus.signed,
        updatedAt: DateTime.now(),
        pageCount: _pageCount,
        signerName: signature.name,
        fileType: _fileType == 'pdf'
            ? DocumentFileType.pdf
            : DocumentFileType.image,
        filePath: result.filePath,
      );
      await StorageService.saveDocument(document);

      if (!mounted) return;
      setState(() {
        _document = document;
        _previewPng = result.previewPng;
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

  String get _shareLabel {
    final title = _document?.title ?? 'Signed document';
    return 'Signed document: $title';
  }

  String _shareFileName() {
    final doc = _document;
    if (doc == null) return 'signed.bin';
    final ext = doc.isPdf ? '.pdf' : '.png';
    final base = sanitizeFileBaseName(doc.title);
    return '${base.isEmpty ? 'Signed document' : base}$ext';
  }

  Future<void> _shareFile() async {
    final path = _document?.filePath;
    if (path == null) return;
    final label = _shareLabel;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            path,
            name: _shareFileName(),
            mimeType: _document!.isPdf ? 'application/pdf' : 'image/png',
          ),
        ],
        subject: label,
        text: label,
      ),
    );
  }

  Future<void> _shareAsImage() async {
    final doc = _document;
    if (doc == null) return;
    final label = _shareLabel;
    Uint8List? bytes = _previewPng;
    if (bytes == null && doc.hasFile && !doc.isPdf) {
      bytes = await File(doc.filePath!).readAsBytes();
    }
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image preview is not available')),
      );
      return;
    }
    final dir = await Directory.systemTemp.createTemp('sigsync_share');
    final base = sanitizeFileBaseName(doc.title);
    final out = File(
      '${dir.path}/${base.isEmpty ? 'Signed document' : base}.png',
    );
    await out.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(out.path, name: '${base.isEmpty ? 'Signed document' : base}.png', mimeType: 'image/png')],
        subject: label,
        text: label,
      ),
    );
  }

  Future<void> _showShareSheet() async {
    if (_document == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.attach_file_rounded,
                      color: AppColors.accentPurple),
                  title: const Text('Share file'),
                  subtitle: Text(
                    _document!.isPdf ? 'PDF document' : 'Signed image',
                    style: AppTextStyles.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareFile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined,
                      color: AppColors.accentBlue),
                  title: const Text('Share as image'),
                  subtitle: Text(
                    'Quick preview-quality PNG',
                    style: AppTextStyles.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareAsImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
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
    final label = _shareLabel;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            path,
            name: _shareFileName(),
            mimeType: _document!.isPdf ? 'application/pdf' : 'image/png',
          ),
        ],
        subject: label,
        text: label,
      ),
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
            _Status.naming => _NamingView(
                controller: _nameController,
                extension: _fileType == 'pdf' ? '.pdf' : '.png',
                onContinue: _confirmNameAndSign,
              ),
            _Status.working => const _WorkingView(),
            _Status.error => _ErrorView(message: _error!),
            _Status.done => _DoneView(
                document: _document!,
                onShare: _showShareSheet,
                onSaveToDevice: _saveToDevice,
              ),
          },
        ),
      ),
    );
  }
}

class _NamingView extends StatelessWidget {
  const _NamingView({
    required this.controller,
    required this.extension,
    required this.onContinue,
  });

  final TextEditingController controller;
  final String extension;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          'Name your signed file',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Leave blank to use an automatic name. Extension $extension '
          'is added for you.',
          textAlign: TextAlign.center,
          style: AppTextStyles.secondary.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onContinue(),
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: 'File name',
            hintText: 'My contract - Signed',
            suffixText: extension,
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.accentPurple, width: 1.5),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.violetGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onContinue,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Text(
                    'Continue & sign',
                    style: AppTextStyles.onAccentLabel.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
          document.title,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
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
