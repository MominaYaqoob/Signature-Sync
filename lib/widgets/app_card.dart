import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Elevated card shell used across screens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.alt = false,
    this.radius = AppRadii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool alt;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final decoration = alt
        ? AppDecorations.altCard(radius: radius)
        : AppDecorations.card(radius: radius);

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
