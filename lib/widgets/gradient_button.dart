import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum GradientButtonVariant { purple, green }

/// Primary CTA with purple or green gradient fill.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = GradientButtonVariant.purple,
    this.expanded = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GradientButtonVariant variant;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final decoration = variant == GradientButtonVariant.purple
        ? AppDecorations.purpleButton()
        : AppDecorations.greenButton();

    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: decoration,
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.textOnAccent, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label, style: AppTextStyles.labelLarge),
        ],
      ),
    );

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: expanded ? child : IntrinsicWidth(child: child),
        ),
      ),
    );
  }
}
