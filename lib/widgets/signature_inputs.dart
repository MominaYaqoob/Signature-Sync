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

/// Ink colour swatches in a single horizontal row (label under the row).
class InkPicker extends StatelessWidget {
  const InkPicker({super.key, required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final name = kInkColors[selected.clamp(0, kInkColors.length - 1)].label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ink',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < kInkColors.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                PressableScale(
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(999),
                  child: Tooltip(
                    message: kInkColors[i].label,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: kInkColors[i].color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == selected
                              ? AppColors.accentPurple
                              : Colors.white,
                          width: i == selected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kInkColors[i]
                                .color
                                .withValues(alpha: 0.28),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: i == selected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

