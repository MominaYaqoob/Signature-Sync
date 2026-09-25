import 'package:flutter_test/flutter_test.dart';
import 'package:signature_sync/services/ads_service.dart';

void main() {
  // These only exercise the paths that don't touch the Google Mobile Ads
  // platform channel (never initialized in a widget test), i.e. the
  // graceful "nothing loaded yet" fallbacks every call site relies on.

  test('showInterstitial calls onComplete when no ad is loaded', () {
    var completed = false;
    AdsService.instance.showInterstitial(onComplete: () => completed = true);
    expect(completed, isTrue);
  });

  test('showAppOpenAdIfAvailable is a safe no-op when nothing is loaded', () {
    expect(AdsService.instance.showAppOpenAdIfAvailable, returnsNormally);
  });

  test('TestAdUnitIds are Google-published Android test ids', () {
    // Guards against ever accidentally swapping in a real/paid ad unit id
    // for "test ads".
    expect(TestAdUnitIds.appOpen, contains('3940256099942544'));
    expect(TestAdUnitIds.interstitial, contains('3940256099942544'));
    expect(TestAdUnitIds.native, contains('3940256099942544'));
  });
}
