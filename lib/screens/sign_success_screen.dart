import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';

/// SCREEN D — Success / Export
class SignSuccessScreen extends StatelessWidget {
  const SignSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accentMintGreen.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentMintGreen.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.accentMintGreen,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Document signed successfully!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Your file is ready to share or save locally.',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary.copyWith(fontSize: 13),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.accentPink.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share coming soon')),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Text(
                          'Share',
                          style: AppTextStyles.onAccentLabel.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved to device (placeholder)'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Text(
                        'Save to device',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Done',
                  style: AppTextStyles.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
