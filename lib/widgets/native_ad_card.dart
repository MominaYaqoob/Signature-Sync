import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../theme/theme.dart';

/// A native ad rendered with Google's built-in "medium" template, styled to
/// match the app's navy/purple palette. Collapses to nothing if the ad
/// fails to load (or on web, which google_mobile_ads doesn't support) —
/// never leaves an empty placeholder box in the feed.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _load();
  }

  void _load() {
    NativeAd(
      adUnitId: TestAdUnitIds.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _ad = ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _failed = true);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: AppRadii.md,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textOnAccent,
          backgroundColor: AppColors.accentPurple,
          style: NativeTemplateFontStyle.bold,
          size: 13,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textPrimary,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          size: 11,
        ),
      ),
    ).load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || _failed) return const SizedBox.shrink();

    return Container(
      // Different creatives (1-line vs 2-line body, with/without an image)
      // need different heights, and the platform view doesn't report its
      // own content height back to Flutter — it just fills whatever box
      // it's given. A tall minHeight avoids clipping a long creative, but
      // leaves blank space under a short one; a white background (matching
      // the template's own `mainBackgroundColor`) makes that leftover
      // space read as ordinary card padding instead of a stray gap.
      constraints: const BoxConstraints(minHeight: 380, maxHeight: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md - 1),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
