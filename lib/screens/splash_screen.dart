import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2500);

  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: _duration)
      ..forward();

    Future<void>.delayed(_duration, () {
      if (!mounted) return;
      context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft white orbs like HTML splash
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: size.width * 0.42,
                height: size.width * 0.42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -50,
              child: Container(
                width: size.width * 0.55,
                height: size.width * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: -0.1,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white.withValues(alpha: 0.22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.draw_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Signature',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 27,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: ':',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 27,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              TextSpan(
                                text: 'Sync',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontSize: 27,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'SIGN IT. SYNC IT. DONE.',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 1,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 48, 40),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 4,
                            width: 34,
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.35),
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
