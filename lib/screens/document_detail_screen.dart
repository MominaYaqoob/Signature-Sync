import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';

/// Full preview of a saved document: the real PDF (pinch-zoomable, all
/// pages) or image, plus working share/delete.
class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({
    super.key,
    required this.documentId,
    this.document,
  });

  final String documentId;
  final DocumentModel? document;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  PdfControllerPinch? _pdfController;
  DocumentModel? _doc;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _doc = widget.document ?? StorageService.getDocumentById(widget.documentId);
    final path = _doc?.filePath;
    if (_doc != null &&
        _doc!.isPdf &&
        path != null &&
        File(path).existsSync()) {
      _pdfController = PdfControllerPinch(document: PdfDocument.openFile(path));
    }
    _ready = true;
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final path = _doc?.filePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document file is missing on this device')),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: _doc?.title),
    );
  }

  Future<void> _confirmDelete() async {
    final doc = _doc;
    if (doc == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        title: Text('Delete document?', style: AppTextStyles.titleMedium),
        content: Text(
          'Remove “${doc.title}” from this device. This can’t be undone.',
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
      ),
    );
    if (confirmed != true || !mounted) return;
    await StorageService.deleteDocument(doc.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    final title = doc?.title ?? 'Document';
    final isPdf = doc?.isPdf ?? true;
    final tint = isPdf ? AppColors.accentBlue : AppColors.accentPurple;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: doc == null ? null : _share,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            onPressed: doc == null ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(child: _buildPreview(doc, tint)),
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
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: tint, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status: ${doc.statusLabel}'
                        '${doc.signerName != null ? ' · Signed by ${doc.signerName}' : ''}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 13,
                          color: tint,
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
    );
  }

  Widget _buildPreview(DocumentModel? doc, Color tint) {
    final path = doc?.filePath;
    final hasFile = path != null && path.isNotEmpty && File(path).existsSync();

    if (!_ready || doc == null || !hasFile) {
      return _placeholder(
        icon: doc?.isPdf ?? true
            ? Icons.picture_as_pdf_rounded
            : Icons.image_outlined,
        tint: tint,
        message: doc == null
            ? 'Document not found'
            : 'Document file is missing on this device',
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: doc.isPdf
          ? (_pdfController == null
              ? _placeholder(
                  icon: Icons.picture_as_pdf_rounded,
                  tint: tint,
                  message: 'Could not open this PDF',
                )
              : PdfViewPinch(controller: _pdfController!))
          : Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _placeholder(
                icon: Icons.image_outlined,
                tint: tint,
                message: 'Could not load image',
              ),
            ),
    );
  }

  Widget _placeholder({
    required IconData icon,
    required Color tint,
    required String message,
  }) {
    return Container(
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
            child: Icon(icon, color: tint, size: 34),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
