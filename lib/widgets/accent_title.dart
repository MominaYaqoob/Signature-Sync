import 'package:flutter/material.dart';

import '../theme/theme.dart';

Color _softFillFor(Color accent) {
  if (accent == AppColors.accentBlue) return AppColors.softBlue;
  if (accent == AppColors.accentMintGreen) return AppColors.softGreen;
  if (accent == AppColors.accentOrange) return AppColors.softOrange;
  if (accent == AppColors.accentPurple) return AppColors.softPurple;
  return AppColors.softPink;
}

/// Screen title inside a soft colored container + accent bar.
class AccentTitle extends StatelessWidget {
  const AccentTitle({
    super.key,
    required this.title,
    this.style,
    this.accent = AppColors.accentPink,
    this.barWidth = 44,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final TextStyle? style;
  final Color accent;
  final double barWidth;
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 1.2,
              ),
              boxShadow: AppShadows.card,
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
                const SizedBox(height: 10),
                Container(
                  width: barWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        accent.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
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
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent.withValues(alpha: 0.26),
                  width: 1.1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: 30,
                    height: 3.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          accent.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (actionLabel != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!, style: AppTextStyles.link),
            ),
          ),
      ],
    );
  }
}
