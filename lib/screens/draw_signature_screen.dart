import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:signature/signature.dart';

import '../services/ads_service.dart';
import '../services/signature_image_store.dart';
import '../theme/theme.dart';
import '../widgets/help_screen.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';

enum _PenType { pen, pencil, brush, marker, eraser }

extension on _PenType {
  String get label => switch (this) {
        _PenType.pen => 'Pen',
        _PenType.pencil => 'Pencil',
        _PenType.brush => 'Brush',
        _PenType.marker => 'Marker',
        _PenType.eraser => 'Eraser',
      };

  IconData get icon => switch (this) {
        _PenType.pen => Icons.edit_outlined,
        _PenType.pencil => Icons.draw_outlined,
        _PenType.brush => Icons.brush_outlined,
        _PenType.marker => Icons.format_color_fill_outlined,
        _PenType.eraser => Icons.auto_fix_off_outlined,
      };

  bool get isEraser => this == _PenType.eraser;

  double get opacity => switch (this) {
        _PenType.pen => 1.0,
        _PenType.pencil => 0.75,
        _PenType.brush => 1.0,
        _PenType.marker => 0.6,
        _PenType.eraser => 1.0,
      };

  double get widthMultiplier => switch (this) {
        _PenType.pen => 1.0,
        _PenType.pencil => 0.85,
        _PenType.brush => 1.75,
        _PenType.marker => 2.0,
        // Wider than the thickest ink setting so erase covers strokes cleanly.
        _PenType.eraser => 1.5,
      };

  StrokeCap get strokeCap => switch (this) {
        _PenType.brush || _PenType.marker || _PenType.eraser => StrokeCap.round,
        _ => StrokeCap.butt,
      };
}

class DrawSignatureScreen extends StatefulWidget {
  const DrawSignatureScreen({super.key});

  @override
  State<DrawSignatureScreen> createState() => _DrawSignatureScreenState();
}

class _DrawSignatureScreenState extends State<DrawSignatureScreen> {
  static const _canvasColor = Color(0xFFF8F7FC);
  static const _clearRed = Color(0xFFE53935);
  static const _undoSkyBlue = Color(0xFF0EA5E9);

  static BoxDecoration _solidButton(Color color) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static const _penColors = <Color>[
    Color(0xFF111111),
    Color(0xFF241B3A),
    AppColors.accentPurple,
    AppColors.accentBlue,
    Color(0xFF0EA5A5),
    Color(0xFF17C964),
    Color(0xFF84A342),
    Color(0xFFF5A524),
    Color(0xFFF97316),
    Color(0xFFE53935),
    Color(0xFFEC4899),
    Color(0xFF6B4226),
  ];

  static const _strokeWidths = <double>[2, 4, 6];
  static const _penTypes = _PenType.values;
  static const _exportMargin = 20;

  late SignatureController _controller;
  int _selectedColor = 0;
  int _selectedStroke = 1; // Medium
  _PenType _penType = _PenType.pen;
  bool _saving = false;

  bool get _isEraser => _penType.isEraser;

  Color get _effectivePenColor {
    if (_isEraser) return _canvasColor;
    return _penColors[_selectedColor].withValues(alpha: _penType.opacity);
  }

  double get _effectiveStrokeWidth {
    if (_isEraser) {
      // 1.5x the thick (index 2) setting, independent of the thickness row.
      return _strokeWidths.last * _penType.widthMultiplier;
    }
    return _strokeWidths[_selectedStroke] * _penType.widthMultiplier;
  }

  void _syncPenStyleToController() {
    _controller.penColor = _effectivePenColor;
    _controller.penStrokeWidth = _effectiveStrokeWidth;
    _controller.strokeCap = _penType.strokeCap;
  }

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: _effectiveStrokeWidth,
      penColor: _effectivePenColor,
      strokeCap: _penType.strokeCap,
      // Transparent export — canvas color is display-only; eraser pixels
      // are punched to alpha 0 in post-processing before save.
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectColor(int index) {
    if (_isEraser) return;
    if (index == _selectedColor) return;
    setState(() {
      _selectedColor = index;
      _syncPenStyleToController();
    });
  }

  void _selectStroke(int index) {
    if (index == _selectedStroke) return;
    setState(() {
      _selectedStroke = index;
      _syncPenStyleToController();
    });
  }

  void _selectPenType(_PenType type) {
    if (type == _penType) return;
    setState(() {
      _penType = type;
      _syncPenStyleToController();
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {});
  }

  void _undo() {
    _controller.undo();
    setState(() {});
  }

  img.ColorRgba8 get _canvasRgb => img.ColorRgba8(
        (_canvasColor.r * 255.0).round().clamp(0, 255),
        (_canvasColor.g * 255.0).round().clamp(0, 255),
        (_canvasColor.b * 255.0).round().clamp(0, 255),
        255,
      );

  bool _nearCanvasColor(img.Pixel pixel, {int tol = 10}) {
    final bg = _canvasRgb;
    return (pixel.r - bg.r).abs() <= tol &&
        (pixel.g - bg.g).abs() <= tol &&
        (pixel.b - bg.b).abs() <= tol;
  }

  /// Turns canvas-colored pixels (display bg / eraser strokes) fully transparent.
  img.Image _makeCanvasColorTransparent(img.Image src, {int tol = 10}) {
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        if (pixel.a > 0 && _nearCanvasColor(pixel, tol: tol)) {
          src.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
    return src;
  }

  /// Crops [src] to non-transparent content bounds, plus [margin] on each side.
  img.Image _cropToContent(img.Image src, {int margin = _exportMargin}) {
    var minX = src.width;
    var minY = src.height;
    var maxX = 0;
    var maxY = 0;
    var found = false;

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final pixel = src.getPixel(x, y);
        if (pixel.a < 8) continue;
        found = true;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (!found) return src;

    minX = math.max(0, minX - margin);
    minY = math.max(0, minY - margin);
    maxX = math.min(src.width - 1, maxX + margin);
    maxY = math.min(src.height - 1, maxY + margin);

    final width = math.max(1, maxX - minX + 1);
    final height = math.max(1, maxY - minY + 1);
    return img.copyCrop(src, x: minX, y: minY, width: width, height: height);
  }

  /// Builds a PNG cropped to ink bounds with a fully transparent background.
  Future<Uint8List?> _exportCroppedPng() async {
    final points = _controller.points;
    if (points.isEmpty) {
      debugPrint('[DrawSignature] export aborted: no points');
      return null;
    }

    // Bounding box from all points (includes eraser strokes).
    var minX = points.first.offset.dx;
    var maxX = minX;
    var minY = points.first.offset.dy;
    var maxY = minY;
    var maxStroke = _controller.penStrokeWidth;
    for (final p in points) {
      minX = math.min(minX, p.offset.dx);
      maxX = math.max(maxX, p.offset.dx);
      minY = math.min(minY, p.offset.dy);
      maxY = math.max(maxY, p.offset.dy);
      final w = p.strokeWidth ?? _controller.penStrokeWidth;
      maxStroke = math.max(maxStroke, w);
    }

    final pad = _exportMargin + (maxStroke / 2);
    final exportW = math.max(1, (maxX - minX + pad * 2).ceil());
    final exportH = math.max(1, (maxY - minY + pad * 2).ceil());
    debugPrint(
      '[DrawSignature] export bbox=${exportW}x$exportH points=${points.length}',
    );

    final rawBytes = await _controller.toPngBytes(
      width: exportW,
      height: exportH,
    );
    if (rawBytes == null || rawBytes.isEmpty) {
      debugPrint('[DrawSignature] toPngBytes returned empty');
      return null;
    }
    debugPrint('[DrawSignature] raw PNG bytes=${rawBytes.length}');

    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      debugPrint('[DrawSignature] decodeImage failed');
      return null;
    }

    // Eraser strokes are painted as canvas color — punch them (and any
    // leftover bg) to full transparency before cropping.
    _makeCanvasColorTransparent(decoded, tol: 10);
    debugPrint('[DrawSignature] canvas-color → transparent done');
    final cropped = _cropToContent(decoded, margin: _exportMargin);
    debugPrint(
      '[DrawSignature] cropped PNG ${cropped.width}x${cropped.height}',
    );
    return Uint8List.fromList(img.encodePng(cropped));
  }

  void _showError(String message) {
    if (!mounted) return;
    debugPrint('[DrawSignature] ERROR: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save({Uint8List? preExported}) async {
    if (_saving) return;
    if (!_controller.isNotEmpty) {
      _showError('Please draw your signature first');
      return;
    }

    setState(() => _saving = true);
    debugPrint('[DrawSignature] save started');
    try {
      final bytes = preExported ?? await _exportCroppedPng();
      if (bytes == null || bytes.isEmpty) {
        _showError('Could not export signature image — try drawing again');
        return;
      }

      final id = 'sig_${DateTime.now().millisecondsSinceEpoch}';
      final imageRef = await SignatureImageStore.save(id, bytes);
      debugPrint('[DrawSignature] image stored (${bytes.length} bytes)');

      if (!mounted) return;
      debugPrint('[DrawSignature] navigating to /save-signature');
      await context.push(
        '/save-signature',
        extra: <String, String>{
          'name': '',
          'style': 'Drawn',
          'source': 'draw',
          'imagePath': imageRef,
          'id': id,
        },
      );
      debugPrint('[DrawSignature] returned from save-signature');
    } catch (e, st) {
      debugPrint('[DrawSignature] save failed: $e\n$st');
      _showError('Could not save signature: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPreview() async {
    if (_saving) return;
    if (!_controller.isNotEmpty) {
      _showError('Please draw your signature first');
      return;
    }
    final bytes = await _exportCroppedPng();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      _showError('Could not build preview — try drawing again');
      return;
    }
    final shouldSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SignaturePreviewPage(pngBytes: bytes),
      ),
    );
    if (shouldSave == true && mounted) {
      await _save(preExported: bytes);
    }
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavyAppHeader(
                title: 'Draw Signature',
                onBack: () => AdsService.instance.showInterstitial(
                  onComplete: () {
                    if (context.mounted) context.pop();
                  },
                ),
                trailing: HelpButton(
                  onTap: () => HelpScreen.show(context, const HelpScreen(
                    title: 'Draw Signature',
                    intro: 'Sign with your finger or a stylus, just like on '
                        'paper — the background is removed automatically.',
                    steps: [
                      HelpStep(
                        icon: Icons.draw_rounded,
                        title: 'Draw on the canvas',
                        body: 'Sign in one smooth motion for the most '
                            'natural-looking result.',
                      ),
                      HelpStep(
                        icon: Icons.palette_outlined,
                        title: 'Pick a pen, colour and thickness',
                        body: 'Switch pen type, ink colour or stroke '
                            'thickness any time — your existing strokes '
                            'stay as they were drawn.',
                      ),
                      HelpStep(
                        icon: Icons.undo_rounded,
                        title: 'Undo or Clear',
                        body: 'Undo removes your last stroke; Clear starts '
                            'the canvas over.',
                      ),
                      HelpStep(
                        icon: Icons.fullscreen_rounded,
                        title: 'Preview',
                        body: 'Tap "Preview" above the canvas to see the '
                            'final, cropped signature full-screen before '
                            'saving.',
                      ),
                      HelpStep(
                        icon: Icons.save_outlined,
                        title: 'Save',
                        body: 'Tap "Save Signature" to name it and add it '
                            'to My Signatures.',
                      ),
                    ],
                    tips: [
                      'A slightly wider pen usually looks more like a real '
                          'signature.',
                      'You can always come back and draw another version — '
                          'saved signatures don’t get overwritten.',
                    ],
                  )),
                ),
                fontSize: 15,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: AppDecorations.card(
                    color: _canvasColor,
                    radius: AppRadii.sm,
                    prominent: true,
                    sheen: true,
                    borderColor: AppColors.borderSubtle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Signature(
                          controller: _controller,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: 28,
                        child: IgnorePointer(
                          child: Container(
                            height: 1,
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.sm,
                        top: AppSpacing.xs,
                        child: PressableScale(
                          onTap: _openPreview,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.navy.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fullscreen_rounded,
                                  size: 14,
                                  color: AppColors.navy.withValues(alpha: 0.75),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Preview',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontSize: 11,
                                    color:
                                        AppColors.navy.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _sectionLabel('Pen type'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (var i = 0; i < _penTypes.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _PenTypeTile(
                        type: _penTypes[i],
                        selected: _penType == _penTypes[i],
                        onTap: () => _selectPenType(_penTypes[i]),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _sectionLabel('Color'),
              const SizedBox(height: AppSpacing.sm),
              Opacity(
                opacity: _isEraser ? 0.38 : 1,
                child: IgnorePointer(
                  ignoring: _isEraser,
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      itemCount: _penColors.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final color = _penColors[index];
                        final selected = index == _selectedColor;
                        return PressableScale(
                          onTap: () => _selectColor(index),
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: selected ? 36 : 28,
                            height: selected ? 36 : 28,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppColors.navy
                                    : AppColors.borderSoft,
                                width: selected ? 2.4 : 1.2,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _sectionLabel('Thickness'),
              const SizedBox(height: AppSpacing.sm),
              Opacity(
                opacity: _isEraser ? 0.38 : 1,
                child: IgnorePointer(
                  ignoring: _isEraser,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_strokeWidths.length, (index) {
                      final selected = index == _selectedStroke;
                      final dotSize = 6.0 + (index * 4);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: PressableScale(
                          onTap: () => _selectStroke(index),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: selected ? 40 : 36,
                            height: selected ? 40 : 36,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.navy.withValues(alpha: 0.08)
                                  : AppColors.primaryBackground,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              border: Border.all(
                                color: selected
                                    ? AppColors.navy
                                    : AppColors.borderSoft,
                                width: selected ? 2 : 1.2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.navy
                                      : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: _clear,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: DecoratedBox(
                          decoration: _solidButton(_clearRed),
                          child: Center(
                            child: Text(
                              'Clear',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: _undo,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: DecoratedBox(
                          decoration: _solidButton(_undoSkyBlue),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.undo_rounded,
                                  size: 18,
                                  color: AppColors.textOnAccent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Undo',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textOnAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: _saving ? null : _save,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: DecoratedBox(
                          decoration: AppDecorations.purpleButton(
                            radius: AppRadii.sm,
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.textOnAccent,
                                    ),
                                  )
                                : Text(
                                    'Save Signature',
                                    style: AppTextStyles.onAccentLabel.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PenTypeTile extends StatelessWidget {
  const _PenTypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final _PenType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navy.withValues(alpha: 0.08)
              : AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.borderSoft,
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 16,
              color: selected ? AppColors.navy : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.navy : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen preview of the exported (cropped, transparent) signature.
/// Pops `true` when the user taps Save, `false` on back.
class _SignaturePreviewPage extends StatelessWidget {
  const _SignaturePreviewPage({required this.pngBytes});

  final Uint8List pngBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavyAppHeader(
                title: 'Preview',
                onBack: () => Navigator.of(context).pop(false),
                fontSize: 15,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Container(
                  decoration: AppDecorations.card(
                    color: Colors.white,
                    radius: AppRadii.sm,
                    prominent: true,
                    borderColor: AppColors.borderSubtle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Image.memory(pngBytes, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: DecoratedBox(
                          decoration: AppDecorations.card(
                            radius: AppRadii.sm,
                            elevated: false,
                            sheen: false,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 18,
                                  color: AppColors.navy,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Back',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: DecoratedBox(
                          decoration: AppDecorations.purpleButton(
                            radius: AppRadii.sm,
                          ),
                          child: Center(
                            child: Text(
                              'Save Signature',
                              style: AppTextStyles.onAccentLabel.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
