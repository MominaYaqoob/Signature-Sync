import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../widgets/pressable_scale.dart';

class DrawSignatureScreen extends StatefulWidget {
  const DrawSignatureScreen({super.key});

  @override
  State<DrawSignatureScreen> createState() => _DrawSignatureScreenState();
}

class _DrawSignatureScreenState extends State<DrawSignatureScreen> {
  static const _penColors = <Color>[
    Color(0xFF111111),
    AppColors.accentPurple,
    Color(0xFF3B82F6),
    AppColors.accentMintGreen,
  ];

  int _selectedColor = 0;
  bool _cleared = false;

  Color get _penColor => _penColors[_selectedColor];

  void _clear() {
    setState(() => _cleared = true);
  }

  void _save() {
    context.push(
      '/save-signature',
      extra: <String, String>{
        'name': 'Aliza',
        'style': 'Drawn',
        'source': 'draw',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Draw Signature',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: AppDecorations.card(
                    color: const Color(0xFFF8F7FC),
                    radius: AppRadii.sm,
                    prominent: true,
                    sheen: true,
                    borderColor: AppColors.borderSubtle,
                  ),
                  child: Stack(
                    children: [
                      if (!_cleared)
                        Center(
                          child: Text(
                            'Aliza',
                            style: AppTextStyles.signaturePreview(
                              color: _penColor.withValues(alpha: 0.85),
                              size: 64,
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            'Draw here',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.black.withValues(alpha: 0.28),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: 28,
                        child: Container(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.md,
                        top: AppSpacing.sm,
                        child: Text(
                          'Preview',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontSize: 10,
                            color: Colors.black.withValues(alpha: 0.3),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_penColors.length, (index) {
                  final color = _penColors[index];
                  final selected = index == _selectedColor;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: PressableScale(
                      onTap: () {
                        setState(() {
                          _selectedColor = index;
                          if (_cleared) _cleared = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selected ? 34 : 28,
                        height: selected ? 34 : 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                            width: selected ? 2.5 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: _clear,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: DecoratedBox(
                          decoration: AppDecorations.card(
                            radius: AppRadii.sm,
                            elevated: false,
                            sheen: false,
                          ),
                          child: Center(
                            child: Text(
                              'Clear',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 52,
                      child: PressableScale(
                        onTap: _save,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: DecoratedBox(
                          decoration: AppDecorations.purpleButton(
                            radius: AppRadii.sm,
                          ),
                          child: Center(
                            child: Text(
                              'Save Signature',
                              style: AppTextStyles.onAccentLabel.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
