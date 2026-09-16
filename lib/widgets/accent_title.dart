import 'package:flutter/material.dart';

import '../theme/theme.dart';

Color _softFillFor(Color accent) {
  if (accent == AppColors.accentBlue) return AppColors.softBlue;
  if (accent == AppColors.accentMintGreen) return AppColors.softGreen;
  if (accent == AppColors.accentOrange) return AppColors.softOrange;
  if (accent == AppColors.accentPurple) return AppColors.softPurple;
  return AppColors.softPink;
}

/// Screen title inside a soft colored container.
class AccentTitle extends StatelessWidget {
  const AccentTitle({
    super.key,
    required this.title,
    this.style,
    this.accent = AppColors.accentPink,
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
    final fill = _softFillFor(accent);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: AppDecorations.card(
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
                    style: AppTextStyles.eyebrow.copyWith(color: accent),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: style ??
                      AppTextStyles.titleLarge.copyWith(
                        fontSize: 24,
                        height: 1.2,
                      ),
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
    this.accent = AppColors.accentPurple,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
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
            decoration: AppDecorations.card(
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
                color: accent,
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
              // Muted gray — chips carry section color; links stay calm/consistent
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
