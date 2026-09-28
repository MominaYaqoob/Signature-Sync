import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ads_service.dart';
import '../services/signature_image_store.dart';
import '../theme/theme.dart';
import '../widgets/help_screen.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';
import 'adjust_signature_background_screen.dart';

class ScanSignatureScreen extends StatefulWidget {
  const ScanSignatureScreen({super.key});

  @override
  State<ScanSignatureScreen> createState() => _ScanSignatureScreenState();
}

class _ScanSignatureScreenState extends State<ScanSignatureScreen> {
  static const _previewBg = Color(0xFF17181C);

  bool _busy = false;

  /// True after we've attempted the initial auto-open scan once.
  var _initialScanStarted = false;

  @override
  void initState() {
    super.initState();
    // Open the live scanner as soon as this route is on screen — no extra
    // tap. Cancel keeps this UI as retry (Gallery / Scan again / shutter).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialScanStarted || _busy) return;
      _initialScanStarted = true;
      _startLiveScan();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    debugPrint('[ScanSignature] ERROR: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Preferred path: Google ML Kit Document Scanner (auto-capture, edges,
  /// crop UI). Android-only; falls back to image_picker camera elsewhere or
  /// if the scanner fails to start.
  Future<void> _startLiveScan() async {
    if (_busy) return;

    if (!kIsWeb && Platform.isAndroid) {
      final ok = await _scanWithMlKit();
      if (ok || !mounted) return;
      debugPrint('[ScanSignature] ML Kit unavailable — falling back to camera');
    }

    await _captureAndCrop(source: ImageSource.camera);
  }

  /// Returns `true` if the flow completed or the user cancelled cleanly.
  /// Returns `false` when the scanner itself failed and we should fall back.
  Future<bool> _scanWithMlKit() async {
    setState(() => _busy = true);
    DocumentScanner? scanner;
    try {
      debugPrint('[ScanSignature] starting ML Kit document scanner');
      scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: const {DocumentFormat.jpeg},
          mode: ScannerMode.base,
          pageLimit: 1,
          isGalleryImport: false,
        ),
      );

      final DocumentScanningResult result;
      try {
        result = await scanner.scanDocument();
      } on PlatformException catch (e) {
        final code = e.code.toLowerCase();
        final msg = (e.message ?? '').toLowerCase();
        if (code.contains('cancel') ||
            msg.contains('cancel') ||
            msg.contains('user')) {
          debugPrint('[ScanSignature] ML Kit cancelled by user');
          return true;
        }
        debugPrint('[ScanSignature] ML Kit PlatformException: $e');
        return false;
      } catch (e) {
        // Null / unexpected result (often user dismiss) — treat as cancel.
        debugPrint('[ScanSignature] ML Kit scanDocument error: $e');
        if (e.toString().toLowerCase().contains('null')) return true;
        return false;
      }

      final images = result.images;
      if (images == null || images.isEmpty) {
        debugPrint('[ScanSignature] ML Kit returned no images (cancel)');
        return true;
      }

      final path = images.first;
      debugPrint('[ScanSignature] ML Kit capture done: $path');
      if (!mounted) return true;

      try {
        await _processCapturedPath(path);
      } catch (e, st) {
        debugPrint('[ScanSignature] post-scan pipeline failed: $e\n$st');
        _showError('Could not process signature image: $e');
      }
      return true;
    } catch (e, st) {
      debugPrint('[ScanSignature] ML Kit failed to start: $e\n$st');
      return false;
    } finally {
      try {
        await scanner?.close();
      } catch (_) {}
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captureAndCrop({
    ImageSource source = ImageSource.camera,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    debugPrint('[ScanSignature] capture started source=$source');

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (photo == null) {
        debugPrint('[ScanSignature] pick cancelled by user');
        return;
      }
      debugPrint('[ScanSignature] capture done: ${photo.path}');
      if (!mounted) return;

      await _processCapturedPath(photo.path);
    } catch (e, st) {
      debugPrint('[ScanSignature] capture/crop failed: $e\n$st');
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission') ||
          msg.contains('access') ||
          msg.contains('denied') ||
          msg.contains('camera_access')) {
        _showError(
          source == ImageSource.gallery
              ? 'Photo access is required to pick a signature. '
                  'Enable it in Settings and try again.'
              : 'Camera permission is required to scan a signature. '
                  'Enable it in Settings and try again.',
        );
      } else {
        _showError('Could not process signature image: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Shared crop → background adjust → save pipeline for any capture source.
  Future<void> _processCapturedPath(String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop signature',
          toolbarColor: AppColors.navy,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.accentPurple,
          backgroundColor: _previewBg,
          cropFrameColor: AppColors.accentBlue,
          cropGridColor: AppColors.accentBlue.withValues(alpha: 0.45),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
        IOSUiSettings(
          title: 'Crop signature',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
      ],
    );
    if (cropped == null) {
      debugPrint('[ScanSignature] crop cancelled by user');
      return;
    }
    debugPrint('[ScanSignature] crop done: ${cropped.path}');
    if (!mounted) return;

    final croppedBytes = await XFile(cropped.path).readAsBytes();
    debugPrint('[ScanSignature] cropped bytes=${croppedBytes.length}');

    if (!mounted) return;
    final processed = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AdjustSignatureBackgroundScreen(sourceBytes: croppedBytes),
      ),
    );
    if (processed == null || processed.isEmpty) {
      debugPrint('[ScanSignature] background adjust cancelled by user');
      return;
    }

    final id = 'sig_${DateTime.now().millisecondsSinceEpoch}';
    final imageRef = await SignatureImageStore.save(id, processed);
    debugPrint('[ScanSignature] image stored (${processed.length} bytes)');

    if (!mounted) return;
    debugPrint('[ScanSignature] navigating to /save-signature');
    await context.push(
      '/save-signature',
      extra: <String, String>{
        'name': '',
        'style': 'Scanned',
        'source': 'scan',
        'imagePath': imageRef,
        'id': id,
      },
    );
    debugPrint('[ScanSignature] returned from save-signature');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _previewBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  const Color(0xFF2A2C32),
                  _previewBg,
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: NavyAppHeader(
                    title: 'Scan Signature',
                    onBack: () => AdsService.instance.showInterstitial(
                      onComplete: () {
                        if (context.mounted) context.pop();
                      },
                    ),
                    trailing: HelpButton(
                      onTap: () => HelpScreen.show(context, const HelpScreen(
                        title: 'Scan Signature',
                        intro: 'Sign on paper with a pen, then capture it — '
                            'the paper background is removed '
                            'automatically, leaving just your ink.',
                        steps: [
                          HelpStep(
                            icon: Icons.edit_note_rounded,
                            title: 'Sign on plain white paper',
                            body: 'A dark pen on plain white paper (no '
                                'lines) gives the cleanest result.',
                          ),
                          HelpStep(
                            icon: Icons.document_scanner_outlined,
                            title: 'Hold steady over the signature',
                            body: 'The scanner captures automatically when '
                                'it sees the paper — or tap the shutter / '
                                'pick from Gallery.',
                          ),
                          HelpStep(
                            icon: Icons.crop_rounded,
                            title: 'Crop to the signature',
                            body: 'Trim the photo down to just the '
                                'signature area.',
                          ),
                          HelpStep(
                            icon: Icons.tune_rounded,
                            title: 'Adjust the background removal',
                            body: 'Drag the slider until only your ink is '
                                'left on the checkered (transparent) '
                                'background.',
                          ),
                          HelpStep(
                            icon: Icons.save_outlined,
                            title: 'Save',
                            body: 'Name it and add it to My Signatures.',
                          ),
                        ],
                        tips: [
                          'Avoid shadows across the paper — even lighting '
                              'gives the cleanest cut-out.',
                          'A phone photo usually works better than a '
                              'scanner app export.',
                        ],
                      )),
                    ),
                    fontSize: 15,
                  ),
                ),
                const Spacer(flex: 2),
                const _ScanFrameArea(width: 280, height: 168),
                const SizedBox(height: 18),
                Text(
                  _busy
                      ? 'Opening scanner…'
                      : 'Place signature in view — captures automatically',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign on plain white paper for the cleanest result',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const Spacer(flex: 3),
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: _GalleryButton(
                          onPressed: _busy
                              ? null
                              : () => _captureAndCrop(
                                    source: ImageSource.gallery,
                                  ),
                        ),
                      ),
                    ),
                    _CaptureButton(
                      busy: _busy,
                      onPressed: _busy ? null : _startLiveScan,
                    ),
                    // Keeps the capture button centred.
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The soft focus plane and the corner brackets, sized and centred as one
/// unit so they always land on the exact same box.
class _ScanFrameArea extends StatelessWidget {
  const _ScanFrameArea({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          CustomPaint(
            painter: _CornerBracketPainter(
              color: AppColors.accentBlue,
              strokeWidth: 3.2,
              cornerLength: 28,
              radius: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top + radius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + radius,
          rect.top,
        )
        ..lineTo(rect.left + cornerLength, rect.top),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..quadraticBezierTo(
          rect.right,
          rect.top,
          rect.right,
          rect.top + radius,
        )
        ..lineTo(rect.right, rect.top + cornerLength),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.bottom - cornerLength)
        ..lineTo(rect.right, rect.bottom - radius)
        ..quadraticBezierTo(
          rect.right,
          rect.bottom,
          rect.right - radius,
          rect.bottom,
        )
        ..lineTo(rect.right - cornerLength, rect.bottom),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(rect.left + cornerLength, rect.bottom)
        ..lineTo(rect.left + radius, rect.bottom)
        ..quadraticBezierTo(
          rect.left,
          rect.bottom,
          rect.left,
          rect.bottom - radius,
        )
        ..lineTo(rect.left, rect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.radius != radius;
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: PressableScale(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gallery',
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.onPressed,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.accentBlue,
            width: 5,
          ),
          boxShadow: AppShadows.elevated,
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.accentPurple,
                ),
              )
            : const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.accentPurple,
                size: 30,
              ),
      ),
    );
  }
}
