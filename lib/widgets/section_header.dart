import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'accent_title.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
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
    return AccentSectionHeader(
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      accent: accent,
    );
  }
}
