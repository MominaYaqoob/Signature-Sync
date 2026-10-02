import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import '../theme/theme.dart';

/// Home native ad — Arrow Drift–style small card (no media, CTA full-width
/// at bottom). Uses Android factory `nativeAdSmall` + [native_ad_small.xml].
/// Collapses to nothing until loaded / on failure.
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  static const double _slotHeight = 168;
  static const double _radius = 14;

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
      factoryId: 'nativeAdSmall',
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
      width: double.infinity,
      height: _slotHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: AppColors.borderSoft.withValues(alpha: 0.95),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: ad),
    );
  }
}
