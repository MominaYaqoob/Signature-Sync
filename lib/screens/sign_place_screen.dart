import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../models/signature_model.dart';
import '../services/ads_service.dart';
import '../services/document_signer.dart';
import '../services/storage_service.dart';
import '../theme/theme.dart';
import '../widgets/date_stamp_style_picker.dart';
import '../widgets/help_screen.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/signature_visual.dart';

/// SCREEN C — Place Signature. Renders the actual uploaded page (PDF page
/// rendered to an image, or the photo/image itself) and lets the user drag,
/// resize and rotate a real saved signature on top of it.
class SignPlaceScreen extends StatefulWidget {
  const SignPlaceScreen({super.key});

  @override
  State<SignPlaceScreen> createState() => _SignPlaceScreenState();
}

class _SignPlaceScreenState extends State<SignPlaceScreen> {
  static const _minSize = Size(80, 36);
  static const _maxSize = Size(320, 140);

  String _filePath = '';
  String _fileType = 'pdf';
  int _pageCount = 1;
  int _pageIndex = 0;
  bool _ready = false;

  Uint8List? _pageBytes;
  double _pageAspect = 0.72;
  bool _loadingPage = true;
  String? _pageError;

  late List<SignatureModel> _signatures;
  int _selectedSig = 0;

  Offset? _position;
  Size _stampSize = const Size(160, 64);
  double _rotation = 0;
  Size? _docSize;

  bool _addDate = false;
  DateStampStyle _dateStyle = DateStampStyle.plain;
  Offset? _datePosition;
  final Size _dateSize = const Size(168, 28);
  late final String _dateText = formatDateStampText(DateTime.now());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;

    final extra = GoRouterState.of(context).extra;
    final data = extra is Map
        ? extra.map((k, v) => MapEntry('$k', '${v ?? ''}'))
        : <String, String>{};

    _filePath = data['filePath'] ?? '';
    _fileType = (data['fileType'] ?? 'pdf').toLowerCase();
    _pageCount = int.tryParse(data['pageCount'] ?? '') ?? 1;

    _signatures = StorageService.getAllSignatures();
    final defaultIndex = _signatures.indexWhere((s) => s.isDefault);
    _selectedSig = defaultIndex >= 0 ? defaultIndex : 0;

    _loadPage(0);
  }

  Future<void> _loadPage(int index) async {
    setState(() {
      _loadingPage = true;
      _pageError = null;
    });

    if (_filePath.isEmpty || !File(_filePath).existsSync()) {
      if (!mounted) return;
      setState(() {
        _loadingPage = false;
        _pageError = 'Document file not found';
      });
      return;
    }

    try {
      Uint8List bytes;
      if (_fileType == 'pdf') {
        final doc = await PdfDocument.openFile(_filePath);
        try {
          final page = await doc.getPage(index + 1);
          try {
            // Render at ~2x the page's native size for a crisp on-screen
            // preview, capped so huge pages don't blow up memory.
            final targetWidth = (page.width * 2).clamp(300, 1600).toDouble();
            final targetHeight = targetWidth * (page.height / page.width);
            final rendered = await page.render(
              width: targetWidth,
              height: targetHeight,
              format: PdfPageImageFormat.png,
            );
            if (rendered == null) throw Exception('Could not render page');
            bytes = rendered.bytes;
          } finally {
            await page.close();
          }
        } finally {
          await doc.close();
        }
      } else {
        bytes = await File(_filePath).readAsBytes();
      }

      final aspect = await _imageAspectRatio(bytes);
      if (!mounted) return;
      setState(() {
        _pageBytes = bytes;
        _pageAspect = aspect;
        _pageIndex = index;
        _loadingPage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPage = false;
        _pageError = 'Could not open this page: $e';
      });
    }
  }

  Future<double> _imageAspectRatio(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final aspect = frame.image.width / frame.image.height;
    frame.image.dispose();
    codec.dispose();
    return aspect <= 0 ? 0.72 : aspect;
  }

  bool get _canApply =>
      !_loadingPage &&
      _pageError == null &&
      _pageBytes != null &&
      _signatures.isNotEmpty;

  Future<void> _pickSignature() async {
    if (_signatures.isEmpty) return;
    final index = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose signature',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_signatures.length, (i) {
                  final sig = _signatures[i];
                  final selected = i == _selectedSig;
                  return ListTile(
                    onTap: () => Navigator.pop(context, i),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: selected
                        ? AppColors.accentPurple.withValues(alpha: 0.14)
                        : null,
                    leading: SizedBox(
                      width: 64,
                      height: 40,
                      child: SignatureVisual.fromModel(
                        sig,
                        color: selected
                            ? AppColors.accentPurple
                            : AppColors.accentBlue,
                        fontSize: 26,
                      ),
                    ),
                    title: Text(
                      sig.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium,
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.accentPurple,
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (index != null) setState(() => _selectedSig = index);
  }

  void _nudgeResize({required bool enlarge}) {
    setState(() {
      final factor = enlarge ? 1.12 : 0.9;
      final ratio = _stampSize.height / _stampSize.width;
      final width =
          (_stampSize.width * factor).clamp(_minSize.width, _maxSize.width);
      _stampSize = Size(width, (width * ratio).clamp(_minSize.height, _maxSize.height));
    });
  }

  void _rotate() {
    setState(() => _rotation += math.pi / 12);
  }

  void _apply() {
    if (!_canApply) return;
    final signature = _signatures[_selectedSig];
    final docSize = _docSize;
    final position = _position;

    final extra = <String, Object?>{
      'filePath': _filePath,
      'fileType': _fileType,
      'pageIndex': _pageIndex,
      'pageCount': _pageCount,
      'signatureId': signature.id,
      // Placement as fractions of the page, so a later merge step can map
      // it onto the document at full resolution regardless of screen size.
      if (docSize != null && position != null)
        'stamp': <String, double>{
          'xFrac': (position.dx / docSize.width).clamp(0, 1),
          'yFrac': (position.dy / docSize.height).clamp(0, 1),
          'widthFrac': (_stampSize.width / docSize.width).clamp(0, 1),
          'heightFrac': (_stampSize.height / docSize.height).clamp(0, 1),
          'rotationRadians': _rotation,
        },
      if (_addDate && docSize != null && _datePosition != null)
        'dateStamp': <String, Object?>{
          'xFrac': (_datePosition!.dx / docSize.width).clamp(0, 1),
          'yFrac': (_datePosition!.dy / docSize.height).clamp(0, 1),
          'widthFrac': (_dateSize.width / docSize.width).clamp(0, 1),
          'heightFrac': (_dateSize.height / docSize.height).clamp(0, 1),
          'style': _dateStyle.name,
          'text': _dateText,
        },
    };

    // End of the sign-document flow — one of the app's ad plan placements.
    AdsService.instance.showInterstitial(
      onComplete: () {
        if (context.mounted) {
          context.push('/sign-document/success', extra: extra);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: NavyAppHeader(
                title: 'Place Signature',
                onBack: () => context.pop(),
                fontSize: 15,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HelpButton(
                      onTap: () => HelpScreen.show(context, const HelpScreen(
                        title: 'Place Signature',
                        intro: 'Position your signature on the document '
                            'exactly where it should appear on the final '
                            'signed file.',
                        steps: [
                          HelpStep(
                            icon: Icons.gesture_rounded,
                            title: 'Choose a signature',
                            body: 'Tap "Signature" at the bottom to switch '
                                'which saved signature to place.',
                          ),
                          HelpStep(
                            icon: Icons.open_with_rounded,
                            title: 'Drag to position',
                            body: 'Touch and drag the signature anywhere '
                                'on the page.',
                          ),
                          HelpStep(
                            icon: Icons.photo_size_select_large_rounded,
                            title: 'Resize or rotate',
                            body: 'Drag a corner handle to resize, or use '
                                'the "Rotate" button.',
                          ),
                          HelpStep(
                            icon: Icons.filter_none_rounded,
                            title: 'Switch pages',
                            body: 'On a multi-page PDF, use the arrows '
                                'above the page to sign a different page.',
                          ),
                          HelpStep(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Apply',
                            body: 'Tap "Apply" once it looks right — this '
                                'creates the final signed file.',
                          ),
                        ],
                        tips: [
                          'The position you see here is exactly how it '
                              'will look on the signed file.',
                          'You can’t undo Apply, but the original '
                              'document is never changed — a new signed '
                              'copy is created.',
                        ],
                      )),
                    ),
                    Opacity(
                      opacity: _canApply ? 1 : 0.4,
                      child: Material(
                        color: AppColors.accentBlue,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _canApply ? _apply : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text(
                              'Apply',
                              style: AppTextStyles.onAccentLabel.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_pageCount > 1) _buildPageStrip(),
            if (_signatures.isNotEmpty) _buildDateControls(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Center(child: _buildDocument()),
              ),
            ),
            if (_signatures.isEmpty)
              _buildEmptySignaturesBar()
            else
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ToolButton(
                        icon: Icons.gesture_rounded,
                        label: 'Signature',
                        onTap: _pickSignature,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToolButton(
                        icon: Icons.photo_size_select_large_rounded,
                        label: 'Resize',
                        onTap: () => _nudgeResize(enlarge: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToolButton(
                        icon: Icons.rotate_right_rounded,
                        label: 'Rotate',
                        onTap: _rotate,
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

  Widget _buildDateControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FilterChip(
                selected: _addDate,
                label: const Text('Add date'),
                onSelected: (v) {
                  setState(() {
                    _addDate = v;
                    if (v && _datePosition == null && _docSize != null) {
                      final sig = _position ??
                          Offset(_docSize!.width * 0.1, _docSize!.height * 0.62);
                      _datePosition = Offset(
                        sig.dx,
                        (sig.dy + _stampSize.height + 8)
                            .clamp(0, _docSize!.height - _dateSize.height),
                      );
                    }
                  });
                },
                selectedColor: AppColors.accentPurple.withValues(alpha: 0.18),
                checkmarkColor: AppColors.accentPurpleDark,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: _addDate
                      ? AppColors.accentPurpleDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              if (_addDate)
                Expanded(
                  child: Text(
                    _dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
            ],
          ),
          if (_addDate) ...[
            const SizedBox(height: 8),
            DateStampStylePicker(
              selected: _dateStyle,
              onSelect: (s) => setState(() => _dateStyle = s),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: (_loadingPage || _pageIndex == 0)
                ? null
                : () => _loadPage(_pageIndex - 1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textSecondary,
          ),
          Text(
            'Page ${_pageIndex + 1} of $_pageCount',
            style: AppTextStyles.labelMedium,
          ),
          IconButton(
            onPressed: (_loadingPage || _pageIndex >= _pageCount - 1)
                ? null
                : () => _loadPage(_pageIndex + 1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySignaturesBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(radius: 14),
      child: Row(
        children: [
          const Icon(Icons.gesture_rounded, color: AppColors.accentPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Create a signature first to place it here.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () => context.push('/draw-signature'),
            child: Text(
              'Create',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocument() {
    if (_loadingPage) {
      return const CircularProgressIndicator(color: AppColors.accentPurple);
    }
    if (_pageError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _pageError!,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      );
    }
    final bytes = _pageBytes;
    if (bytes == null) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: _pageAspect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _docSize = size;
          _position ??= Offset(size.width * 0.1, size.height * 0.62);

          final maxLeft = math.max(0.0, size.width - _stampSize.width);
          final maxTop = math.max(0.0, size.height - _stampSize.height);
          final position = Offset(
            _position!.dx.clamp(0, maxLeft),
            _position!.dy.clamp(0, maxTop),
          );

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(bytes, fit: BoxFit.fill),
                ),
                if (_signatures.isNotEmpty)
                  Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() => _position = position + details.delta);
                      },
                      child: Transform.rotate(
                        angle: _rotation,
                        child: SizedBox(
                          width: _stampSize.width,
                          height: _stampSize.height,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: _stampSize.width,
                                height: _stampSize.height,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.accentPurple
                                        .withValues(alpha: 0.55),
                                    width: 1.2,
                                  ),
                                ),
                                child: SignatureVisual.fromModel(
                                  _signatures[_selectedSig],
                                  color: AppColors.accentPurpleDark,
                                  fontSize: _stampSize.height * 0.55,
                                ),
                              ),
                              ..._buildHandles(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_addDate && _signatures.isNotEmpty) _buildDateStamp(size),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateStamp(Size docSize) {
    _datePosition ??= Offset(
      (_position?.dx ?? docSize.width * 0.1),
      ((_position?.dy ?? docSize.height * 0.62) + _stampSize.height + 8)
          .clamp(0, docSize.height - _dateSize.height),
    );
    final maxLeft = math.max(0.0, docSize.width - _dateSize.width);
    final maxTop = math.max(0.0, docSize.height - _dateSize.height);
    final datePos = Offset(
      _datePosition!.dx.clamp(0, maxLeft),
      _datePosition!.dy.clamp(0, maxTop),
    );
    final label = _dateStyle == DateStampStyle.signedOn
        ? 'Signed on: $_dateText'
        : _dateText;

    return Positioned(
      left: datePos.dx,
      top: datePos.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _datePosition = datePos + details.delta);
        },
        child: Container(
          width: _dateSize.width,
          height: _dateSize.height,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _dateStyle == DateStampStyle.boxed
                  ? AppColors.accentBlue
                  : AppColors.accentBlue.withValues(alpha: 0.45),
              width: _dateStyle == DateStampStyle.boxed ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: _dateSize.height * 0.42,
              fontStyle: _dateStyle == DateStampStyle.cursive
                  ? FontStyle.italic
                  : FontStyle.normal,
              fontWeight: _dateStyle == DateStampStyle.plain
                  ? FontWeight.w500
                  : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHandles() {
    const handleSize = 12.0;
    final positions = <Alignment>[
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ];

    return positions.map((alignment) {
      return Align(
        alignment: alignment,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              final growX = details.delta.dx * (alignment.x > 0 ? 1 : -1);
              final growY = details.delta.dy * (alignment.y > 0 ? 1 : -1);
              _stampSize = Size(
                (_stampSize.width + growX).clamp(_minSize.width, _maxSize.width),
                (_stampSize.height + growY)
                    .clamp(_minSize.height, _maxSize.height),
              );
              if (alignment.x < 0) {
                _position =
                    Offset(_position!.dx + details.delta.dx, _position!.dy);
              }
              if (alignment.y < 0) {
                _position =
                    Offset(_position!.dx, _position!.dy + details.delta.dy);
              }
            });
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(
              color: AppColors.accentBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accentPurple, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
