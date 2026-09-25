import 'package:flutter/material.dart';

import '../theme/signature_fonts.dart';
import '../theme/theme.dart';
import 'pressable_scale.dart';

/// Name input used by the typed/generated signature screens.
class SignatureNameField extends StatelessWidget {
  const SignatureNameField({super.key, required this.controller});

  final TextEditingController controller;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyLarge,
      cursorColor: AppColors.accentPurple,
      maxLength: 40,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Type your full name',
        counterText: '',
        filled: true,
        fillColor: AppColors.cardBackground,
        prefixIcon: const Icon(
          Icons.person_outline_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: controller.clear,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: _border(AppColors.borderSubtle),
        enabledBorder: _border(AppColors.borderSubtle),
        focusedBorder: _border(AppColors.accentPurple, 1.5),
      ),
    );
  }
}

/// Black / Blue / Navy ink selector for text-based signatures.
class InkPicker extends StatelessWidget {
  const InkPicker({super.key, required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Ink',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        for (var i = 0; i < kInkColors.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          PressableScale(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
              decoration: BoxDecoration(
                color: i == selected
                    ? kInkColors[i].color.withValues(alpha: 0.08)
                    : AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: i == selected
                      ? kInkColors[i].color
                      : AppColors.borderSoft,
                  width: i == selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: kInkColors[i].color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    kInkColors[i].label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight:
                          i == selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

