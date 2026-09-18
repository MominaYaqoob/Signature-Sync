import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../theme/theme.dart';
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
    if (points.isEmpty) return null;

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

    final rawBytes = await _controller.toPngBytes(
      width: exportW,
      height: exportH,
    );
    if (rawBytes == null || rawBytes.isEmpty) return null;

    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return null;

    // Eraser strokes are painted as canvas color — punch them (and any
    // leftover bg) to full transparency before cropping.
    _makeCanvasColorTransparent(decoded, tol: 10);
    final cropped = _cropToContent(decoded, margin: _exportMargin);
    return Uint8List.fromList(img.encodePng(cropped));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_controller.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature first')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final bytes = await _exportCroppedPng();
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please draw your signature first')),
        );
        return;
      }

      final docs = await getApplicationDocumentsDirectory();
      final signaturesDir = Directory('${docs.path}/signatures');
      if (!await signaturesDir.exists()) {
        await signaturesDir.create(recursive: true);
      }

      final id = 'sig_${DateTime.now().millisecondsSinceEpoch}';
      final file = File('${signaturesDir.path}/$id.png');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      await context.push(
        '/save-signature',
        extra: <String, String>{
          'name': '',
          'style': 'Drawn',
          'source': 'draw',
          'imagePath': file.path,
          'id': id,
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
                onBack: () => context.pop(),
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
                        right: AppSpacing.md,
                        top: AppSpacing.sm,
                        child: IgnorePointer(
                          child: Text(
                            'Preview',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontSize: 11,
                              color: AppColors.navy.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
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
                          decoration: AppDecorations.card(
                            radius: AppRadii.sm,
                            elevated: false,
                            sheen: false,
                          ),
                          child: Center(
                            child: Text(
                              'Clear',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
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
                          decoration: AppDecorations.card(
                            radius: AppRadii.sm,
                            elevated: false,
                            sheen: false,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.undo_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Undo',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
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
