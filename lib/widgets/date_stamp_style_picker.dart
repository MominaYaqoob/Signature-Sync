import 'package:flutter/material.dart';

import '../services/document_signer.dart';
import '../theme/theme.dart';
import 'pressable_scale.dart';

/// Horizontal chip picker for [DateStampStyle] — same PressableScale +
/// AnimatedContainer language as the signature-generator swash picker.
class DateStampStylePicker extends StatelessWidget {
  const DateStampStylePicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final DateStampStyle selected;
  final ValueChanged<DateStampStyle> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DateStampStyle.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final style = DateStampStyle.values[index];
          final isSelected = style == selected;
          return PressableScale(
            onTap: () => onSelect(style),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentPurple.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accentPurple : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                style.label,
                style: AppTextStyles.labelMedium.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.accentPurpleDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
