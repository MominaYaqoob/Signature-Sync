import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'pressable_scale.dart';

/// Elevated card shell used across screens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.alt = false,
    this.prominent = false,
    this.radius = AppRadii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool alt;
  final bool prominent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final decoration = alt
        ? AppDecorations.altCard(radius: radius)
        : AppDecorations.card(
            radius: radius,
            prominent: prominent,
          );

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;

    return PressableScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: content,
    );
  }
}
