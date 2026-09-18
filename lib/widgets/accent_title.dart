import 'package:flutter/material.dart';

import '../theme/theme.dart';

Color _softFillFor(Color accent) {
  if (accent == AppColors.accentBlue) return AppColors.softBlue;
  if (accent == AppColors.accentMintGreen) return AppColors.softGreen;
  if (accent == AppColors.accentOrange) return AppColors.softOrange;
  if (accent == AppColors.accentPurple) return AppColors.softPurple;
  if (accent == AppColors.navy) return AppColors.softNavy;
  return AppColors.softPink;
}

bool _isBrandBar(Color accent) =>
    accent == AppColors.navy || accent == AppColors.accentBlue;

List<Color> _barColors(Color accent) {
  if (accent == AppColors.accentBlue) {
    return const [Color(0xFF4CA1FF), AppColors.accentBlue];
  }
  return const [Color(0xFF243556), AppColors.navy];
}

/// Screen title — navy/blue solid bars match Home; other accents keep soft chips.
class AccentTitle extends StatelessWidget {
  const AccentTitle({
    super.key,
    required this.title,
    this.style,
    this.accent = AppColors.navy,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final TextStyle? style;
  final Color accent;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final brandBar = _isBrandBar(accent);
    final fill = _softFillFor(accent);
    final titleColor = brandBar ? AppColors.textOnAccent : AppColors.textPrimary;
    final subtitleColor =
        brandBar ? AppColors.navyMuted : accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: brandBar
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _barColors(accent),
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: (accent == AppColors.accentBlue
                                ? AppColors.accentBlue
                                : AppColors.navy)
                            .withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  )
                : AppDecorations.card(
                    color: fill,
                    radius: AppRadii.md,
                    elevated: true,
                    sheen: true,
                    borderColor: accent.withValues(alpha: 0.22),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: AppTextStyles.eyebrow.copyWith(color: subtitleColor),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: (style ??
                          AppTextStyles.titleLarge.copyWith(
                            fontSize: 24,
                            height: 1.2,
                          ))
                      .copyWith(color: titleColor),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// Section title chip + optional action.
class AccentSectionHeader extends StatelessWidget {
  const AccentSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.accent = AppColors.navy,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final brandBar = _isBrandBar(accent);
    final fill = _softFillFor(accent);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: brandBar
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: _barColors(accent),
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  )
                : AppDecorations.card(
                    color: fill,
                    radius: AppRadii.sm,
                    elevated: false,
                    sheen: false,
                    borderColor: accent.withValues(alpha: 0.22),
                  ),
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: brandBar ? AppColors.textOnAccent : accent,
              ),
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
