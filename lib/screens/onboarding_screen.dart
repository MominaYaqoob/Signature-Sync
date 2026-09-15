import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.accent,
    required this.assetPath,
    this.isFinal = false,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final Color accent;
  final String assetPath;
  final bool isFinal;
}

const _pages = <_OnboardingPageData>[
  _OnboardingPageData(
    title: 'Draw your signature',
    description:
        'Sign naturally with your finger — smooth, personal, and ready in seconds.',
    buttonLabel: 'Next',
    accent: AppColors.accentPink,
    assetPath: 'assets/illustrations/onboarding_draw.png',
  ),
  _OnboardingPageData(
    title: 'Choose a signature style',
    description:
        'Type your name and pick from elegant script fonts that look handwritten.',
    buttonLabel: 'Next',
    accent: AppColors.accentBlue,
    assetPath: 'assets/illustrations/onboarding_auto.png',
  ),
  _OnboardingPageData(
    title: 'Scan & review documents',
    description:
        'Import a PDF or image, preview every page, then place your signature with precision.',
    buttonLabel: 'Next',
    accent: AppColors.accentPurple,
    assetPath: 'assets/illustrations/onboarding_scan.png',
  ),
  _OnboardingPageData(
    title: 'Seal the deal faster',
    description:
        'Place your signature on any contract and finish paperwork without the wait.',
    buttonLabel: 'Next',
    accent: AppColors.accentMintGreen,
    assetPath: 'assets/illustrations/onboarding_sign.png',
  ),
  _OnboardingPageData(
    title: 'Private by design',
    description:
        'No login required. Your signatures and files stay on your device.',
    buttonLabel: 'Get Started',
    accent: AppColors.accentPink,
    assetPath: 'assets/illustrations/onboarding_privacy.png',
    isFinal: true,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() => context.go('/home');

  void _onPrimary() {
    if (_index >= _pages.length - 1) {
      _goHome();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final isFinal = page.isFinal;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pastel corner blobs like HTML onboarding
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: page.accent == AppColors.accentBlue
                    ? AppColors.softBlue
                    : page.accent == AppColors.accentMintGreen
                        ? AppColors.softGreen
                        : AppColors.softPink,
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isFinal ? Colors.white : page.accent)
                    .withValues(alpha: isFinal ? 0.12 : 0.12),
              ),
            ),
          ),
          if (isFinal)
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.brandGradient),
            ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: TextButton(
                      onPressed: _goHome,
                      child: Text(
                        'Skip',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isFinal
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      return _OnboardingPageView(page: _pages[index]);
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: _PageIndicators(
                      count: _pages.length,
                      index: _index,
                      accent: page.accent,
                      onFinal: isFinal,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Material(
                      color:
                          isFinal ? AppColors.primaryBackground : page.accent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _onPrimary,
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: Text(
                            page.buttonLabel,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isFinal
                                  ? AppColors.accentPink
                                  : AppColors.textOnAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    final isFinal = page.isFinal;
    final size = MediaQuery.sizeOf(context);
    final imageWidth = (size.width * 0.58).clamp(180.0, 280.0);
    final imageHeight = imageWidth * 0.9;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxImageH = constraints.maxHeight * 0.48;
        final h = imageHeight.clamp(140.0, maxImageH);
        final w = (h / 0.9).clamp(160.0, imageWidth);

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -10,
                          top: 18,
                          child: Container(
                            width: w * 0.72,
                            height: h * 0.72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: page.accent.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                        Container(
                          width: w,
                          height: h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: page.accent,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 14),
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color: page.accent.withValues(alpha: 0.4),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.1),
                                blurRadius: 0,
                                offset: const Offset(0, -1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22.5),
                            child: ColoredBox(
                              color: isFinal
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white,
                              child: Transform.scale(
                                scale: 1.28,
                                child: Image.asset(
                                  page.assetPath,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 56, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: page.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      page.title,
                      textAlign: TextAlign.left,
                      style: isFinal
                          ? AppTextStyles.onAccentTitle
                          : AppTextStyles.headlineLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      page.description,
                      textAlign: TextAlign.left,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: isFinal
                          ? AppTextStyles.onAccentBody
                          : AppTextStyles.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.count,
    required this.index,
    required this.accent,
    required this.onFinal,
  });

  final int count;
  final int index;
  final Color accent;
  final bool onFinal;

  @override
  Widget build(BuildContext context) {
    final activeColor = onFinal ? Colors.white : accent;
    final inactiveColor =
        onFinal ? Colors.white.withValues(alpha: 0.35) : AppColors.softDot;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
