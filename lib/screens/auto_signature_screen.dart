import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

typedef _FontBuilder = TextStyle Function({
  double? fontSize,
  Color? color,
  FontWeight? fontWeight,
});

class _SignatureStyle {
  const _SignatureStyle({
    required this.id,
    required this.label,
    required this.font,
  });

  final String id;
  final String label;
  final _FontBuilder font;
}

final _styles = <_SignatureStyle>[
  _SignatureStyle(
    id: 'dancing',
    label: 'Dancing Script',
    font: ({fontSize, color, fontWeight}) => GoogleFonts.dancingScript(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
  ),
  _SignatureStyle(
    id: 'great_vibes',
    label: 'Great Vibes',
    font: ({fontSize, color, fontWeight}) => GoogleFonts.greatVibes(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
  ),
  _SignatureStyle(
    id: 'sacramento',
    label: 'Sacramento',
    font: ({fontSize, color, fontWeight}) => GoogleFonts.sacramento(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
  ),
  _SignatureStyle(
    id: 'pacifico',
    label: 'Pacifico',
    font: ({fontSize, color, fontWeight}) => GoogleFonts.pacifico(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
  ),
  _SignatureStyle(
    id: 'allura',
    label: 'Allura',
    font: ({fontSize, color, fontWeight}) => GoogleFonts.allura(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
  ),
];

class AutoSignatureScreen extends StatefulWidget {
  const AutoSignatureScreen({super.key});

  @override
  State<AutoSignatureScreen> createState() => _AutoSignatureScreenState();
}

class _AutoSignatureScreenState extends State<AutoSignatureScreen> {
  late final TextEditingController _nameController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Aliza Khan');
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _displayName {
    final value = _nameController.text.trim();
    return value.isEmpty ? 'Your Name' : value;
  }

  void _useSignature() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Using “$_displayName” · ${_styles[_selectedIndex].label}',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Auto Signature',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: TextField(
                controller: _nameController,
                style: AppTextStyles.bodyLarge,
                cursorColor: AppColors.accentPurple,
                decoration: InputDecoration(
                  hintText: 'Type your name',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(
                      color: AppColors.accentPurple,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
              child: Text(
                'CHOOSE A STYLE',
                style: AppTextStyles.eyebrow.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                itemCount: _styles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final style = _styles[index];
                  final selected = index == _selectedIndex;
                  return _StylePreviewCard(
                    name: _displayName,
                    styleLabel: style.label,
                    textStyle: style.font(
                      fontSize: 34,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.accentPurple.withValues(alpha: 0.95),
                    ),
                    selected: selected,
                    onTap: () => setState(() => _selectedIndex = index),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              child: SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.accentPink.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _useSignature,
                      borderRadius: BorderRadius.circular(14),
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

class _StylePreviewCard extends StatelessWidget {
  const _StylePreviewCard({
    required this.name,
    required this.styleLabel,
    required this.textStyle,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String styleLabel;
  final TextStyle textStyle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: selected
          ? AppDecorations.card(
              radius: 14,
              color: const Color(0xFF4A3A72),
            ).copyWith(
              border: Border.all(color: AppColors.accentPurple, width: 1.6),
              boxShadow: AppShadows.tinted(color: AppColors.accentPurple),
            )
          : AppDecorations.card(radius: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        styleLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 10,
                          color: selected
                              ? AppColors.accentPurple
                              : AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.textOnAccent,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
