import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document_model.dart';
import '../models/signature_model.dart';
import '../services/ads_service.dart';
import '../services/document_signer.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/signature_actions.dart' show kDeleteRed;
import '../widgets/signature_visual.dart';

String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}

class QuickShareScreen extends StatefulWidget {
  const QuickShareScreen({super.key, this.initialDocument});

  /// When set (e.g. from a home/documents card share icon), skip the
  /// document-picker list and go straight to applying the default signature.
  final DocumentModel? initialDocument;

  @override
  State<QuickShareScreen> createState() => _QuickShareScreenState();
}

class _QuickShareScreenState extends State<QuickShareScreen> {
  /// True once we've attempted the preselected handoff (success or fallback).
  var _preselectedHandled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocument != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _preselectedHandled) return;
        _launchPreselected(widget.initialDocument!);
      });
    }
  }

  void _launchPreselected(DocumentModel doc) {
    debugPrint(
      '[QuickShare] preselected launch id=${doc.id} '
      'path=${doc.filePath} title=${doc.title}',
    );

    final path = doc.filePath;
    if (path == null || path.isEmpty) {
      setState(() => _preselectedHandled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This document has no file to share'),
        ),
      );
      return;
    }
    if (!File(path).existsSync()) {
      setState(() => _preselectedHandled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document file is missing — it may have been deleted',
          ),
        ),
      );
      return;
    }

    final signatures = StorageService.getAllSignatures();
    final defaultSig = StorageService.getDefaultSignature() ??
        (signatures.isNotEmpty ? signatures.first : null);
    if (defaultSig == null) {
      // Fall back to the picker UI so the user isn't stuck on a spinner.
      setState(() => _preselectedHandled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a signature first')),
      );
      return;
    }

    try {
      _preselectedHandled = true;
      // Replace so Back from success returns to Home/Documents, not the picker.
      context.pushReplacement(
        '/quick-share/success',
        extra: <String, Object>{
          'document': doc,
          'signature': defaultSig,
        },
      );
      debugPrint('[QuickShare] navigated to success for ${doc.id}');
    } catch (e, st) {
      debugPrint('[QuickShare] preselected navigation failed: $e\n$st');
      if (!mounted) return;
      setState(() => _preselectedHandled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Quick Share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when a document is saved/deleted elsewhere in the app.
    return ValueListenableBuilder(
      valueListenable: StorageService.documentsListenable,
      builder: (context, _, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final signatures = StorageService.getAllSignatures();
    final defaultSig = StorageService.getDefaultSignature() ??
        (signatures.isNotEmpty ? signatures.first : null);
    final documents = StorageService.getAllDocuments();

    // Brief placeholder while we hand off a pre-selected document — avoids
    // flashing the full picker for one frame.
    if (widget.initialDocument != null && !_preselectedHandled) {
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
                  title: 'Quick Share',
                  onBack: () => AdsService.instance.showInterstitial(
                    onComplete: () {
                      if (context.mounted) context.pop();
                    },
                  ),
                  fontSize: 22,
                ),
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                title: 'Quick Share',
                onBack: () => AdsService.instance.showInterstitial(
                  onComplete: () {
                    if (context.mounted) context.pop();
                  },
                ),
                fontSize: 22,
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
                      color: AppColors.softBlue,
                      borderColor:
                          AppColors.accentBlue.withValues(alpha: 0.22),
                    ),
                    child: Column(
                      children: [
                        if (defaultSig == null)
                          Text(
                            'No signature yet',
                            style: AppTextStyles.signaturePreview(
                              color: AppColors.accentBlue,
                              size: 40,
                            ),
                          )
                        else
                          SizedBox(
                            height: 56,
                            child: SignatureVisual.fromModel(
                              defaultSig,
                              color: AppColors.accentBlue,
                              fontSize: 40,
                              showTransparencyGrid: true,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          defaultSig == null
                              ? 'Create a signature first'
                              : 'Ready to apply',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: defaultSig == null
                                ? AppColors.textSecondary
                                : AppColors.accentBlue,
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
                    'Tap a document to stamp your default signature onto '
                    'it near the bottom-right corner.',
                    style: AppTextStyles.secondary.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...documents.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ShareDocumentTile(
                        document: doc,
                        onTap: () {
                          if (defaultSig == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Create a signature first'),
                              ),
                            );
                            return;
                          }
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
        ? AppColors.accentBlue
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
                      color: AppColors.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.send_rounded,
              color: AppColors.accentPurple,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Re-stamps [signature] onto [document] near the bottom-right corner (a
/// fixed placement, since there's no Place-screen step in this shortcut)
/// and saves the result as a new signed document.
class QuickShareSuccessScreen extends StatefulWidget {
  const QuickShareSuccessScreen({
    super.key,
    this.document,
    this.signature,
  });

  final DocumentModel? document;
  final SignatureModel? signature;

  @override
  State<QuickShareSuccessScreen> createState() =>
      _QuickShareSuccessScreenState();
}

enum _QuickShareStatus { working, error, done }

/// Fixed bottom-right placement used since this shortcut has no drag/resize
/// step of its own.
const _quickShareStamp = StampPlacement(
  pageIndex: 0,
  xFrac: 0.55,
  yFrac: 0.80,
  widthFrac: 0.35,
  heightFrac: 0.10,
  rotationRadians: 0,
);

class _QuickShareSuccessScreenState extends State<QuickShareSuccessScreen> {
  _QuickShareStatus _status = _QuickShareStatus.working;
  String? _error;
  bool _ready = false;

  /// End of the Quick Share flow — same pattern as Scan Signature back /
  /// Save Signature. One interstitial, then navigate.
  void _finish(String route) {
    AdsService.instance.showInterstitial(
      onComplete: () {
        if (context.mounted) context.go(route);
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    _run();
  }

  Future<void> _run() async {
    final document = widget.document;
    final signature = widget.signature;
    final path = document?.filePath;
    if (document == null ||
        signature == null ||
        path == null ||
        path.isEmpty ||
        !File(path).existsSync()) {
      setState(() {
        _status = _QuickShareStatus.error;
        _error = 'This document or signature is no longer available.';
      });
      return;
    }

    try {
      final result = await buildSignedDocument(
        sourcePath: path,
        fileType: document.fileType.name,
        pageCount: document.pageCount,
        placement: _quickShareStamp,
        signature: signature,
      );
      final updated = DocumentModel(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        title: document.title,
        status: DocumentStatus.signed,
        updatedAt: DateTime.now(),
        pageCount: document.pageCount,
        signerName: signature.name,
        fileType: document.fileType,
        filePath: result.filePath,
      );
      await StorageService.saveDocument(updated);
      if (!mounted) return;
      setState(() => _status = _QuickShareStatus.done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _QuickShareStatus.error;
        _error = 'Could not apply the signature: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final docTitle = widget.document?.title ?? 'Document';
    final sigName = widget.signature?.name ?? 'Signature';

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
                  onPressed: () => _finish('/home'),
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
                  color: _status == _QuickShareStatus.error
                      ? AppColors.softDanger
                      : AppColors.softBlue,
                  borderColor: (_status == _QuickShareStatus.error
                          ? kDeleteRed
                          : AppColors.accentBlue)
                      .withValues(alpha: 0.25),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: (_status == _QuickShareStatus.error
                                ? kDeleteRed
                                : AppColors.accentBlue)
                            .withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: _status == _QuickShareStatus.working
                          ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.accentBlue,
                              ),
                            )
                          : Icon(
                              _status == _QuickShareStatus.error
                                  ? Icons.error_outline_rounded
                                  : Icons.check_rounded,
                              color: _status == _QuickShareStatus.error
                                  ? kDeleteRed
                                  : AppColors.accentBlue,
                              size: 34,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      switch (_status) {
                        _QuickShareStatus.working => 'Applying signature…',
                        _QuickShareStatus.error => 'Could not apply signature',
                        _QuickShareStatus.done => 'Signature applied',
                      },
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _status == _QuickShareStatus.error
                          ? (_error ?? 'Something went wrong.')
                          : '“$sigName” was applied to\n$docTitle',
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
                  onTap: () => _finish('/home'),
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
                  onTap: _status == _QuickShareStatus.done
                      ? () => _finish('/documents')
                      : () {},
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Center(
                    child: Text(
                      'View documents',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _status == _QuickShareStatus.done
                            ? AppColors.accentPurple
                            : AppColors.textSecondary,
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
