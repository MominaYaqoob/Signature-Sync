import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../theme/theme.dart';

Color statusColor(DocumentStatus status) {
  return switch (status) {
    DocumentStatus.draft => AppColors.textSecondary,
    DocumentStatus.pending => AppColors.accentPurple,
    DocumentStatus.signed => AppColors.accentMintGreen,
    DocumentStatus.expired => AppColors.danger,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.statusLabel,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}
