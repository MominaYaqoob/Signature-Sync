import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';

/// SCREEN B — Document Preview
class SignPreviewScreen extends StatefulWidget {
  const SignPreviewScreen({super.key});

  @override
  State<SignPreviewScreen> createState() => _SignPreviewScreenState();
}

class _SignPreviewScreenState extends State<SignPreviewScreen> {
  PdfControllerPinch? _pdfController;
  String _filePath = '';
  String _fileType = 'pdf';
  int _pageCount = 1;
  String? _error;
  bool _ready = false;

  Map<String, String> _readExtra() {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, String>) return extra;
    if (extra is Map) {
      return extra.map((k, v) => MapEntry('$k', '${v ?? ''}'));
    }
    return {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;

    final data = _readExtra();
    _filePath = data['filePath'] ?? '';
    _fileType = (data['fileType'] ?? 'pdf').toLowerCase();

    if (_filePath.isEmpty || !File(_filePath).existsSync()) {
      _error = 'Document file not found';
      _ready = true;
      return;
    }

    if (_fileType == 'pdf') {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(_filePath),
      );
      _pageCount = 1;
    } else {
      _pageCount = 1;
    }
    _ready = true;
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_filePath.isEmpty) return;

    var pages = _pageCount;
    if (_fileType == 'pdf') {
      try {
        final doc = await PdfDocument.openFile(_filePath);
        pages = doc.pagesCount;
        await doc.close();
      } catch (_) {
        pages = _pageCount;
      }
    } else {
      pages = 1;
    }

    if (!mounted) return;
    await context.push(
      '/sign-document/place',
      extra: <String, String>{
        'filePath': _filePath,
        'fileType': _fileType,
        'pageCount': '$pages',
      },
    );
  }

  Widget _buildPreviewBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    if (_fileType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(_filePath),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              'Could not load image',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }

    final controller = _pdfController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: PdfViewPinch(
        controller: controller,
        onDocumentLoaded: (document) {
          if (!mounted) return;
          setState(() => _pageCount = document.pagesCount);
        },
        onDocumentError: (error) {
          if (!mounted) return;
          setState(() => _error = 'Could not open PDF');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _filePath.isEmpty
        ? 'Document'
        : _filePath.split(Platform.pathSeparator).last;
    final meta = _fileType == 'pdf'
        ? 'Page 1 of $_pageCount'
        : 'Image · 1 page';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: NavyAppHeader(
                title: 'Preview',
                onBack: () => context.pop(),
                fontSize: 15,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  meta,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontSize: 11,
                                    color: Colors.black.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: _buildPreviewBody(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              child: SizedBox(
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
                      onTap: _error != null ? null : _continue,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Text(
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
            ),
          ],
        ),
      ),
    );
  }
}
