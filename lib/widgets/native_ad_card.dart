import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../theme/theme.dart';

/// Compact native ad for the home feed. Uses the small template so the
/// card only takes the height the creative needs — no tall empty slab
/// under the ad. Collapses to nothing if load fails (or on web).
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
        // Small template ≈ one compact card row — fits the home feed
        // without reserving medium-template empty space below the creative.
        templateType: TemplateType.small,
        mainBackgroundColor: AppColors.cardBackground,
        cornerRadius: AppRadii.md,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textOnAccent,
          backgroundColor: AppColors.accentPurple,
          style: NativeTemplateFontStyle.bold,
          size: 12,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textPrimary,
          style: NativeTemplateFontStyle.bold,
          size: 13,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          size: 11,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.textSecondary,
          size: 10,
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

    // Height matches the small native template (~90–120); no minHeight
    // padding that left blank space under the ad.
    return Container(
      height: 112,
      decoration: AppDecorations.card(
        radius: AppRadii.md,
        color: AppColors.cardBackground,
        borderColor: AppColors.accentPurple.withValues(alpha: 0.16),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: ad),
    );
  }
}
