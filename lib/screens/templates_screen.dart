import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';
import '../widgets/navy_app_header.dart';
import '../widgets/pressable_scale.dart';

typedef _FontBuilder = TextStyle Function({
  double? fontSize,
  Color? color,
});

class _TemplateStyle {
  const _TemplateStyle({
    required this.id,
    required this.label,
    required this.font,
    required this.accent,
    required this.fill,
  });

  final String id;
  final String label;
  final _FontBuilder font;
  final Color accent;
  final Color fill;
}

final _templates = <_TemplateStyle>[
  _TemplateStyle(
    id: 'great_vibes',
    label: 'Great Vibes',
    font: ({fontSize, color}) => GoogleFonts.greatVibes(
          fontSize: fontSize,
          color: color,
        ),
    accent: AppColors.accentPurple,
    fill: AppColors.softPurple,
  ),
  _TemplateStyle(
    id: 'dancing',
    label: 'Dancing Script',
    font: ({fontSize, color}) => GoogleFonts.dancingScript(
          fontSize: fontSize,
          color: color,
        ),
    accent: AppColors.accentPurple,
    fill: AppColors.softPurple,
  ),
  _TemplateStyle(
    id: 'sacramento',
    label: 'Sacramento',
    font: ({fontSize, color}) => GoogleFonts.sacramento(
          fontSize: fontSize,
          color: color,
        ),
    accent: AppColors.accentBlue,
    fill: AppColors.softBlue,
  ),
  _TemplateStyle(
    id: 'allura',
    label: 'Allura',
    font: ({fontSize, color}) => GoogleFonts.allura(
          fontSize: fontSize,
          color: color,
        ),
    accent: AppColors.accentBlue,
    fill: AppColors.softBlue,
  ),
  _TemplateStyle(
    id: 'pacifico',
    label: 'Pacifico',
    font: ({fontSize, color}) => GoogleFonts.pacifico(
          fontSize: fontSize,
          color: color,
        ),
    accent: AppColors.accentBlue,
    fill: AppColors.softBlue,
  ),
  _TemplateStyle(
    id: 'great_vibes_alt',
    label: 'Elegant Script',
    font: ({fontSize, color}) => GoogleFonts.greatVibes(
          fontSize: fontSize,
          color: color,
        ),
    accent: AppColors.accentPurple,
    fill: AppColors.altCardBackground,
  ),
];

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  static const _previewName = 'Momina Yaqoob';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: NavyAppHeader(
                title: 'Templates',
                onBack: () => context.pop(),
                fontSize: 22,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                'Pick a style, then save it as your signature.',
                style: AppTextStyles.secondary,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  24,
                ),
                itemCount: _templates.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  return _TemplateCard(
                    label: template.label,
                    accent: template.accent,
                    fill: template.fill,
                    preview: Text(
                      _previewName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: template.font(
                        fontSize: 28,
                        color: template.accent,
                      ),
                    ),
                    onTap: () {
                      context.push(
                        '/save-signature',
                        extra: <String, String>{
                          'name': _previewName,
                          'style': template.label,
                          'source': 'template',
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.label,
    required this.accent,
    required this.fill,
    required this.preview,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final Color fill;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: AppDecorations.card(
          color: fill,
          radius: AppRadii.md,
          prominent: true,
          borderColor: accent.withValues(alpha: 0.22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Center(child: preview),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Use style',
              textAlign: TextAlign.center,
              style: AppTextStyles.tileLabel.copyWith(
                color: accent,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
