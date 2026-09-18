import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Shared navy header bar (back + title) — matches Home / tab headings.
class NavyAppHeader extends StatelessWidget {
  const NavyAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.fontSize = 16,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF243556),
            AppColors.navy,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textOnAccent,
              ),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge.copyWith(
                fontSize: fontSize,
                color: AppColors.textOnAccent,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
