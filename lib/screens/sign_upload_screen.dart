import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';

/// SCREEN A — Upload Document
class SignUploadScreen extends StatefulWidget {
  const SignUploadScreen({super.key});

  @override
  State<SignUploadScreen> createState() => _SignUploadScreenState();
}

class _SignUploadScreenState extends State<SignUploadScreen> {
  bool _busy = false;

  String _fileTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'pdf';
    return 'image';
  }

  Future<String> _persistFile(String sourcePath, String originalName) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/documents');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final ext = originalName.contains('.')
        ? originalName.split('.').last.toLowerCase()
        : sourcePath.split('.').last.toLowerCase();
    final id = 'doc_${DateTime.now().millisecondsSinceEpoch}';
    final dest = File('${dir.path}/$id.$ext');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  Future<void> _goToPreview({
    required String filePath,
    required String fileType,
  }) async {
    if (!mounted) return;
    await context.push(
      '/sign-document/preview',
      extra: <String, String>{
        'filePath': filePath,
        'fileType': fileType,
      },
    );
  }

  Future<void> _pickFile() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final path = file.path;
      if (path == null || path.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected file')),
        );
        return;
      }

      final persisted = await _persistFile(path, file.name);
      final type = _fileTypeFromPath(persisted);
      await _goToPreview(filePath: persisted, fileType: type);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanWithCamera() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (photo == null) return;

      final persisted = await _persistFile(photo.path, photo.name);
      await _goToPreview(filePath: persisted, fileType: 'image');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture document: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRecent(DocumentModel doc) async {
    final path = doc.filePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document file is missing on this device')),
      );
      return;
    }
    final type = doc.isPdf ? 'pdf' : 'image';
    await _goToPreview(filePath: path, fileType: type);
  }

  @override
  Widget build(BuildContext context) {
    final recent = StorageService.getAllDocuments()
        .where((d) => d.hasFile)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: NavyAppHeader(
                title: 'Sign Document',
                onBack: () => context.pop(),
                fontSize: 15,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  const SizedBox(height: 12),
                  _UploadCard(
                    onTap: _busy ? () {} : _pickFile,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryAction(
                          icon: Icons.folder_open_outlined,
                          label: 'Choose file',
                          onTap: _busy ? () {} : _pickFile,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SecondaryAction(
                          icon: Icons.photo_camera_outlined,
                          label: 'Scan with camera',
                          onTap: _busy ? () {} : _scanWithCamera,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'RECENT',
                    style: AppTextStyles.eyebrow.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    Text(
                      'No recent documents yet',
                      style: AppTextStyles.bodySmall,
                    )
                  else
                    ...recent.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentDocTile(
                          title: doc.title,
                          isPdf: doc.isPdf,
                          onTap: () => _openRecent(doc),
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

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: Colors.white.withValues(alpha: 0.22),
        radius: 18,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.accentPurple,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to upload a PDF or image',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'PDF, JPG, or PNG',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accentBlue, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.tileLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDocTile extends StatelessWidget {
  const _RecentDocTile({
    required this.title,
    required this.onTap,
    this.isPdf = true,
  });

  final String title;
  final VoidCallback onTap;
  final bool isPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card(radius: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isPdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_outlined,
                    color: AppColors.accentBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
