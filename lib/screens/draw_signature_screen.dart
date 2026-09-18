import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';

enum _PenType { pen, pencil, brush, marker }

extension on _PenType {
  String get label => switch (this) {
        _PenType.pen => 'Pen',
        _PenType.pencil => 'Pencil',
        _PenType.brush => 'Brush',
        _PenType.marker => 'Marker',
      };

  IconData get icon => switch (this) {
        _PenType.pen => Icons.edit_outlined,
        _PenType.pencil => Icons.draw_outlined,
        _PenType.brush => Icons.brush_outlined,
        _PenType.marker => Icons.format_color_fill_outlined,
      };

  double get opacity => switch (this) {
        _PenType.pen => 1.0,
        _PenType.pencil => 0.75,
        _PenType.brush => 1.0,
        _PenType.marker => 0.6,
      };

  double get widthMultiplier => switch (this) {
        _PenType.pen => 1.0,
        _PenType.pencil => 0.85,
        _PenType.brush => 1.75,
        _PenType.marker => 2.0,
      };

  StrokeCap get strokeCap => switch (this) {
        _PenType.brush || _PenType.marker => StrokeCap.round,
        _ => StrokeCap.butt,
      };
}

class DrawSignatureScreen extends StatefulWidget {
  const DrawSignatureScreen({super.key});

  @override
  State<DrawSignatureScreen> createState() => _DrawSignatureScreenState();
}

class _DrawSignatureScreenState extends State<DrawSignatureScreen> {
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

  late SignatureController _controller;
  int _selectedColor = 0;
  int _selectedStroke = 1; // Medium
  _PenType _penType = _PenType.pen;
  bool _saving = false;

  Color get _effectivePenColor =>
      _penColors[_selectedColor].withValues(alpha: _penType.opacity);

  double get _effectiveStrokeWidth =>
      _strokeWidths[_selectedStroke] * _penType.widthMultiplier;

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
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectColor(int index) {
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
      final bytes = await _controller.toPngBytes();
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
                    color: const Color(0xFFF8F7FC),
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
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
              const SizedBox(height: AppSpacing.md),
              _sectionLabel('Thickness'),
              const SizedBox(height: AppSpacing.sm),
              Row(
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
              size: 18,
              color: selected ? AppColors.navy : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 10,
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
