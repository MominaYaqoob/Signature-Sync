import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ads_service.dart';
import '../services/signature_image_store.dart';
import '../theme/signature_fonts.dart';
import '../theme/theme.dart';
import '../widgets/autograph_painter.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/signature_inputs.dart';

/// Turns a typed name into several autograph-style designs; Regenerate
/// shuffles fonts, layouts, slant and flourishes for fresh ideas.
class SignatureGeneratorScreen extends StatefulWidget {
  const SignatureGeneratorScreen({super.key});

  @override
  State<SignatureGeneratorScreen> createState() =>
      _SignatureGeneratorScreenState();
}

class _SignatureGeneratorScreenState extends State<SignatureGeneratorScreen> {
  static const _designCount = 6;

  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  final _random = math.Random();
  List<AutographSpec> _designs = const [];
  int _selected = 0;
  int _inkIndex = 0;
  int _fontEpoch = 0;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _regenerate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _name => _nameController.text.trim();

  bool get _multiWord => _name.split(RegExp(r'\s+')).length > 1;

  Color get _ink => kInkColors[_inkIndex].color;

  bool _lastMultiWord = false;

  void _onNameChanged() {
    // Layouts depend on having a surname; reshuffle when that changes.
    if (_multiWord != _lastMultiWord) {
      _regenerate();
    } else {
      setState(() {});
    }
  }

  void _regenerate() {
    _lastMultiWord = _multiWord;
    setState(() {
      _designs = List.generate(
        _designCount,
        (_) => AutographSpec.random(_random, multiWord: _multiWord),
      );
      _selected = 0;
    });
    // Show the fresh designs from the top (selection resets to the first).
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    // Fonts load asynchronously; repaint once real glyphs are available.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await GoogleFonts.pendingFonts();
      if (mounted) setState(() => _fontEpoch++);
    });
  }

  void _setSwash(AutographSwash swash) {
    if (_designs.isEmpty || _designs[_selected].swash == swash) return;
    setState(() {
      _designs = [..._designs];
      _designs[_selected] = _designs[_selected].copyWith(swash: swash);
    });
  }

  Future<void> _useSignature() async {
    if (_exporting) return;
    if (_name.isEmpty) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type your name first')),
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await renderAutographPng(
        name: _name,
        spec: _designs[_selected],
        ink: _ink,
      );
      final id = 'sig_${DateTime.now().millisecondsSinceEpoch}';
      final imageRef = await SignatureImageStore.save(id, bytes);
      if (!mounted) return;
      await context.push(
        '/save-signature',
        extra: <String, String>{
          'name': _name,
          'style': 'Generated',
          'source': 'generator',
          'imagePath': imageRef,
          'id': id,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create signature: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _name.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: NavyAppHeader(
                title: 'Signature Generator',
                onBack: () => AdsService.instance.showInterstitial(
                  onComplete: () {
                    if (context.mounted) context.pop();
                  },
                ),
                fontSize: 15,
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                children: [
                  Text(
                    'Type your name and we’ll design autograph-style '
                    'signatures for you. Tap Regenerate for new ideas.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SignatureNameField(controller: _nameController),
                  const SizedBox(height: AppSpacing.md),
                  InkPicker(
                    selected: _inkIndex,
                    onSelect: (i) => setState(() => _inkIndex = i),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!hasName)
                    const _EmptyHint()
                  else ...[
                    Row(
                      children: [
                        Text(
                          'YOUR DESIGNS',
                          style: AppTextStyles.eyebrow.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const Spacer(),
                        _RegenerateChip(onTap: _regenerate),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < _designs.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _DesignCard(
                        name: _name,
                        spec: _designs[i],
                        ink: _ink,
                        fontEpoch: _fontEpoch,
                        selected: i == _selected,
                        onTap: () => setState(() => _selected = i),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'SWASH STYLE',
                      style: AppTextStyles.eyebrow.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fine-tune the flourish under the selected design.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _SwashPicker(
                      selected: _designs[_selected].swash,
                      ink: _ink,
                      onSelect: _setSwash,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                20,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 52,
                    child: PressableScale(
                      onTap: hasName ? _regenerate : null,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: DecoratedBox(
                        decoration: AppDecorations.card(
                          radius: AppRadii.sm,
                          elevated: false,
                          sheen: false,
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: hasName
                              ? AppColors.accentPurple
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: _exporting ? null : _useSignature,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: Opacity(
                          opacity: hasName ? 1 : 0.55,
                          child: DecoratedBox(
                            decoration: AppDecorations.purpleButton(
                              radius: AppRadii.sm,
                            ),
                            child: Center(
                              child: _exporting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.textOnAccent,
                                      ),
                                    )
                                  : Text(
                                      'Use this signature',
                                      style: AppTextStyles.onAccentLabel
                                          .copyWith(fontSize: 14),
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
          ],
        ),
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({
    required this.name,
    required this.spec,
    required this.ink,
    required this.fontEpoch,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final AutographSpec spec;
  final Color ink;
  final int fontEpoch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 124,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.accentPurple : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.elevated : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: CustomPaint(
                  painter: AutographPainter(
                    name: name,
                    spec: spec,
                    ink: ink,
                    fontEpoch: fontEpoch,
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.accentPurple,
                  child: Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.textOnAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwashPicker extends StatelessWidget {
  const _SwashPicker({
    required this.selected,
    required this.ink,
    required this.onSelect,
  });

  final AutographSwash selected;
  final Color ink;
  final ValueChanged<AutographSwash> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AutographSwash.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final swash = AutographSwash.values[index];
          final isSelected = swash == selected;
          return PressableScale(
            onTap: () => onSelect(swash),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentPurple.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accentPurple : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 30,
                    child: swash == AutographSwash.none
                        ? Icon(
                            Icons.not_interested_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          )
                        : CustomPaint(
                            painter: _SwashPreviewPainter(
                              swash: swash,
                              color: isSelected
                                  ? AppColors.accentPurpleDark
                                  : ink,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    swash.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.accentPurpleDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SwashPreviewPainter extends CustomPainter {
  _SwashPreviewPainter({required this.swash, required this.color});

  final AutographSwash swash;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = swashPreviewPath(
      swash,
      width: size.width * 0.9,
      height: size.height,
    );
    canvas.save();
    canvas.translate(size.width * 0.05, size.height * 0.3);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SwashPreviewPainter oldDelegate) =>
      oldDelegate.swash != swash || oldDelegate.color != color;
}

class _RegenerateChip extends StatelessWidget {
  const _RegenerateChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentPurple.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_fix_high_rounded,
              size: 14,
              color: AppColors.accentPurple,
            ),
            const SizedBox(width: 4),
            Text(
              'Regenerate',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: AppDecorations.card(
        radius: AppRadii.md,
        elevated: false,
        sheen: false,
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_fix_high_rounded,
            size: 36,
            color: AppColors.accentPurple.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your autographs will appear here',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Use your full name for the most variety',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
