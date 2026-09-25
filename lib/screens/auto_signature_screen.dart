import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/ads_service.dart';
import '../theme/signature_fonts.dart';
import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/signature_inputs.dart';

/// Type a name, pick one of the bundled signature fonts and an ink colour.
class AutoSignatureScreen extends StatefulWidget {
  const AutoSignatureScreen({super.key});

  @override
  State<AutoSignatureScreen> createState() => _AutoSignatureScreenState();
}

class _AutoSignatureScreenState extends State<AutoSignatureScreen> {
  final _nameController = TextEditingController();
  SignatureFont _font = kSignatureFonts.first;
  SignatureFontCategory? _category; // null = All
  int _inkIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _typedName => _nameController.text.trim();

  String get _displayName => _typedName.isEmpty ? 'Your Name' : _typedName;

  Color get _ink => kInkColors[_inkIndex].color;

  List<SignatureFont> get _visibleFonts => _category == null
      ? kSignatureFonts
      : kSignatureFonts.where((f) => f.category == _category).toList();

  void _useSignature() {
    if (_typedName.isEmpty) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type your name first')),
      );
      return;
    }
    context.push(
      '/save-signature',
      extra: <String, String>{
        'name': _typedName,
        'style': _font.family,
        'source': 'auto',
        'imagePath': '',
        'ink': '${_ink.toARGB32()}',
        'id': 'sig_${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fonts = _visibleFonts;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: NavyAppHeader(
                title: 'Auto Signature',
                onBack: () => AdsService.instance.showInterstitial(
                  onComplete: () {
                    if (context.mounted) context.pop();
                  },
                ),
                fontSize: 15,
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      0,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _PreviewPaper(
                          text: _displayName,
                          isPlaceholder: _typedName.isEmpty,
                          font: _font,
                          ink: _ink,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SignatureNameField(controller: _nameController),
                        const SizedBox(height: AppSpacing.md),
                        InkPicker(
                          selected: _inkIndex,
                          onSelect: (i) => setState(() => _inkIndex = i),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Text(
                              'CHOOSE A STYLE',
                              style: AppTextStyles.eyebrow.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${fonts.length} styles',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoryChips(
                      selected: _category,
                      onSelect: (c) => setState(() => _category = c),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    sliver: SliverGrid.builder(
                      itemCount: fonts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.45,
                      ),
                      itemBuilder: (context, index) {
                        final font = fonts[index];
                        return _StyleTile(
                          text: _displayName,
                          font: font,
                          ink: _ink,
                          selected: font == _font,
                          onTap: () => setState(() => _font = font),
                        );
                      },
                    ),
                  ),
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
              child: SizedBox(
                height: 52,
                child: PressableScale(
                  onTap: _useSignature,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Opacity(
                    opacity: _typedName.isEmpty ? 0.55 : 1,
                    child: DecoratedBox(
                      decoration: AppDecorations.purpleButton(
                        radius: AppRadii.sm,
                      ),
                      child: Center(
                        child: Text(
                          'Use this signature',
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

/// Large live preview drawn on "paper" with a signing line.
class _PreviewPaper extends StatelessWidget {
  const _PreviewPaper({
    required this.text,
    required this.isPlaceholder,
    required this.font,
    required this.ink,
  });

  final String text;
  final bool isPlaceholder;
  final SignatureFont font;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: AppDecorations.card(
        radius: AppRadii.md,
        prominent: true,
        color: Colors.white,
        borderColor: AppColors.divider,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                font.family,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 10,
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Signing line with an "x" mark, like on a paper form.
          Positioned(
            left: 18,
            right: 18,
            bottom: 30,
            child: Row(
              children: [
                Text(
                  '×',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(height: 1, color: AppColors.borderSoft),
                ),
              ],
            ),
          ),
          Positioned.fill(
            left: 28,
            right: 28,
            top: 22,
            bottom: 28,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: FittedBox(
                  key: ValueKey('${font.family}|$text|${ink.toARGB32()}'),
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: font.style(
                      fontSize: 48,
                      color: isPlaceholder ? ink.withValues(alpha: 0.3) : ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelect});

  final SignatureFontCategory? selected;
  final ValueChanged<SignatureFontCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <SignatureFontCategory?>[
      null,
      ...SignatureFontCategory.values,
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          return PressableScale(
            onTap: () => onSelect(option),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navy : AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.navy : AppColors.borderSoft,
                ),
              ),
              child: Text(
                option?.label ?? 'All',
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.textOnAccent
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.text,
    required this.font,
    required this.ink,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final SignatureFont font;
  final Color ink;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPurple.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: selected ? AppColors.accentPurple : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppShadows.elevated : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          text,
                          maxLines: 1,
                          style: font.style(fontSize: 30, color: ink),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    font.family,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 10,
                      color: selected
                          ? AppColors.accentPurpleDark
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.accentPurple,
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
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
