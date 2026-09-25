import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's published Android TEST ad unit ids — always resolve, never fill
/// with real (paid) creatives. Swap these for real AdMob unit ids before
/// release. Android-only: this app doesn't target iOS.
/// https://developers.google.com/admob/android/test-ads
class TestAdUnitIds {
  TestAdUnitIds._();

  static const appOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const native = 'ca-app-pub-3940256099942544/2247696110';
}

/// Owns the app's App Open and Interstitial ads: preloading them, showing
/// them at the call sites screens ask for, and always reloading the next
/// one so there's rarely a wait. Native ads are loaded per-widget instead
/// (see NativeAdCard) since each placement needs its own instance.
class AdsService with WidgetsBindingObserver {
  AdsService._();

  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool _showingAd = false;

  AppOpenAd? _appOpenAd;
  bool _loadingAppOpenAd = false;
  DateTime? _appOpenAdLoadedAt;
  DateTime? _appOpenAdShownAt;
  DateTime? _pausedAt;

  /// Showing the ad itself backgrounds the app (it's a separate Activity),
  /// so dismissing it fires another `resumed` event — without a cooldown
  /// that reopens the very same ad in a loop. Also filters out transient
  /// blips (screenshot UI, a share sheet, a permission dialog) that pause
  /// and resume the app without the user actually having left it.
  static const _minGapBetweenShows = Duration(minutes: 2);
  static const _minBackgroundedTime = Duration(seconds: 15);

  InterstitialAd? _interstitialAd;
  bool _loadingInterstitialAd = false;

  /// Initializes the SDK and starts preloading the App Open + Interstitial
  /// ads so they're likely ready the first time a screen wants one. Call
  /// once, early in `main()`.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    _loadAppOpenAd();
    _loadInterstitialAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume (not the cold start, which the Splash screen triggers itself)
    // is the one lifecycle event this service reacts to on its own.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      // Skip resumes that don't reflect the user actually leaving and
      // coming back: e.g. the ad we just showed is its own Activity, so
      // dismissing it resumes us too — without this check, a fast-loading
      // (esp. test) ad would immediately reopen itself in a loop. Same
      // guard filters out a screenshot, a share sheet, a permission
      // dialog, etc. briefly stealing focus.
      if (pausedAt != null &&
          DateTime.now().difference(pausedAt) < _minBackgroundedTime) {
        return;
      }
      showAppOpenAdIfAvailable();
    }
  }

  // ── App Open ─────────────────────────────────────────────────────────

  void _loadAppOpenAd() {
    if (_loadingAppOpenAd || _appOpenAd != null) return;
    _loadingAppOpenAd = true;
    AppOpenAd.load(
      adUnitId: TestAdUnitIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingAppOpenAd = false;
          _appOpenAd = ad;
          _appOpenAdLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _loadingAppOpenAd = false;
          debugPrint('[AdsService] App Open ad failed to load: $error');
        },
      ),
    );
  }

  /// Shows the App Open ad if one is loaded and fresh, and if another
  /// full-screen ad isn't already on screen. Safe to call speculatively
  /// (e.g. on every resume) — it's a no-op otherwise.
  void showAppOpenAdIfAvailable() {
    final ad = _appOpenAd;
    if (_showingAd || ad == null) return;

    final shownAt = _appOpenAdShownAt;
    if (shownAt != null &&
        DateTime.now().difference(shownAt) < _minGapBetweenShows) {
      return;
    }

    // AdMob considers App Open inventory stale after ~4 hours.
    final loadedAt = _appOpenAdLoadedAt;
    if (loadedAt != null &&
        DateTime.now().difference(loadedAt) > const Duration(hours: 4)) {
      ad.dispose();
      _appOpenAd = null;
      _loadAppOpenAd();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _showingAd = true;
        _appOpenAdShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _showingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _showingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
    );
    ad.show();
  }

  // ── Interstitial ─────────────────────────────────────────────────────

  void _loadInterstitialAd() {
    if (_loadingInterstitialAd || _interstitialAd != null) return;
    _loadingInterstitialAd = true;
    InterstitialAd.load(
      adUnitId: TestAdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitialAd = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitialAd = false;
          debugPrint('[AdsService] Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  /// Shows the interstitial if one is ready, then calls [onComplete] —
  /// whether the ad played, failed, or there simply wasn't one loaded yet,
  /// so callers can always chain their navigation off this.
  void showInterstitial({required VoidCallback onComplete}) {
    final ad = _interstitialAd;
    if (_showingAd || ad == null) {
      onComplete();
      return;
    }

    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _showingAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _showingAd = false;
        ad.dispose();
        _loadInterstitialAd();
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _showingAd = false;
        ad.dispose();
        _loadInterstitialAd();
        onComplete();
      },
    );
    ad.show();
  }
}
