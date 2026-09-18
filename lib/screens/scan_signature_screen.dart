import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';

/// Paper pixels brighter than this (0–255 luminance) become transparent.
const _paperBrightnessThreshold = 180;

/// Pixels darker than this are treated as solid ink (fully opaque).
const _inkBrightnessFloor = 110;

/// Normalized ink color written onto kept strokes (dark navy).
const _inkColor = AppColors.navy;

class ScanSignatureScreen extends StatefulWidget {
  const ScanSignatureScreen({super.key});

  @override
  State<ScanSignatureScreen> createState() => _ScanSignatureScreenState();
}

class _ScanSignatureScreenState extends State<ScanSignatureScreen> {
  static const _previewBg = Color(0xFF17181C);

  bool _busy = false;

  /// Removes light paper background; keeps dark ink with soft edge alpha.
  Uint8List? _removePaperBackground(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final src = decoded.convert(numChannels: 4);
    final inkR = (_inkColor.r * 255.0).round().clamp(0, 255);
    final inkG = (_inkColor.g * 255.0).round().clamp(0, 255);
    final inkB = (_inkColor.b * 255.0).round().clamp(0, 255);

    final softRange =
        (_paperBrightnessThreshold - _inkBrightnessFloor).clamp(1, 255);

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        // Rec. 601 luminance
        final luminance =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();

        if (luminance > _paperBrightnessThreshold) {
          src.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }

        final int alpha;
        if (luminance <= _inkBrightnessFloor) {
          alpha = 255;
        } else {
          // Soft falloff between ink floor and paper threshold.
          final t = (luminance - _inkBrightnessFloor) / softRange;
          alpha = ((1.0 - t) * 255.0).round().clamp(0, 255);
        }

        src.setPixelRgba(x, y, inkR, inkG, inkB, alpha);
      }
    }

    return Uint8List.fromList(img.encodePng(src));
  }

  Future<void> _captureAndCrop() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (photo == null) return;
      if (!mounted) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: photo.path,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop signature',
            toolbarColor: AppColors.navy,
            toolbarWidgetColor: Colors.white,
            statusBarColor: AppColors.navy,
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
      if (cropped == null) return;
      if (!mounted) return;

      final croppedBytes = await File(cropped.path).readAsBytes();
      final processed = _removePaperBackground(croppedBytes);
      if (processed == null || processed.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process scanned signature')),
        );
        return;
      }

      final id = 'sig_${DateTime.now().millisecondsSinceEpoch}';
      final docs = await getApplicationDocumentsDirectory();
      final signaturesDir = Directory('${docs.path}/signatures');
      if (!await signaturesDir.exists()) {
        await signaturesDir.create(recursive: true);
      }
      final dest = File('${signaturesDir.path}/$id.png');
      await dest.writeAsBytes(processed, flush: true);

      if (!mounted) return;
      await context.push(
        '/save-signature',
        extra: <String, String>{
          'name': '',
          'style': 'Scanned',
          'source': 'scan',
          'imagePath': dest.path,
          'id': id,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture signature: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _previewBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Placeholder "camera" feed — subtle vignette / grain feel.
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
          // Soft faux focus plane
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
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
                    onBack: () => context.pop(),
                    fontSize: 15,
                  ),
                ),
                const Spacer(flex: 2),
                const _ScanFrame(
                  width: 280,
                  height: 168,
                ),
                const SizedBox(height: 18),
                Text(
                  'Align signature within frame',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(flex: 3),
                _CaptureButton(
                  busy: _busy,
                  onPressed: _busy ? null : _captureAndCrop,
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

class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CornerBracketPainter(
          color: AppColors.accentBlue,
          strokeWidth: 3.2,
          cornerLength: 28,
          radius: 16,
        ),
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

    // Top-left
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

    // Top-right
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

    // Bottom-right
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

    // Bottom-left
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
                Icons.photo_camera_rounded,
                color: AppColors.accentPurple,
                size: 30,
              ),
      ),
    );
  }
}
