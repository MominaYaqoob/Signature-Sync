import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'router/app_router.dart';
import 'services/ads_service.dart';
import 'services/storage_service.dart';
import 'theme/theme.dart';

/// Bundled font families; each has a license file in assets/google_fonts/licenses.
const _bundledFontLicenses = [
  'Poppins', 'GreatVibes', 'DancingScript', 'Sacramento', 'Pacifico',
  'Allura', 'AlexBrush', 'Parisienne', 'PinyonScript', 'MrDeHaviland',
  'MonsieurLaDoulaise', 'HerrVonMuellerhoff', 'MrsSaintDelafield',
  'CedarvilleCursive', 'HomemadeApple', 'LaBelleAurore', 'Kristi', 'Satisfy',
  'Yellowtail', 'Italianno', 'Arizonia', 'RougeScript', 'Qwigley',
  'Birthstone', 'Whisper',
];

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in _bundledFontLicenses) {
      final text = await rootBundle
          .loadString('assets/google_fonts/licenses/$family.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts: $family'], text);
    }
  });
}

void main() {
  // Catch async errors that escape Futures / microtasks so a failed AdMob
  // (or any other) init can't kill the process with a silent zone error.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Framework errors (build/layout/paint) → log, don't terminate.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
      if (details.stack != null) debugPrint('${details.stack}');
    };

    _registerFontLicenses();
    await StorageService.init();

    // google_mobile_ads has no web implementation. NEVER await ads init
    // before runApp — on some OEM / Play Services builds MobileAds.initialize()
    // can hang forever (no throw), which looks like "APK installs but won't open".
    // Fire-and-forget + catch so UI always starts; zone handler catches escapes.
    if (!kIsWeb) {
      unawaited(
        AdsService.instance.initialize().catchError((Object e, StackTrace st) {
          debugPrint(
              '[AdsService] initialize failed (app continues): $e\n$st');
        }),
      );
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.navy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    runApp(
      // DevicePreview must never wrap release builds (perf + odd overlays).
      kReleaseMode
          ? const SignatureSyncApp()
          : DevicePreview(
              // Chrome / web pe mobile frames; real phone pe off.
              enabled: kIsWeb,
              builder: (context) => const SignatureSyncApp(),
            ),
    );
  }, (error, stack) {
    debugPrint('[Zone] uncaught error: $error\n$stack');
  });
}

class SignatureSyncApp extends StatefulWidget {
  const SignatureSyncApp({super.key});

  @override
  State<SignatureSyncApp> createState() => _SignatureSyncAppState();
}

class _SignatureSyncAppState extends State<SignatureSyncApp> {
  late final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Signature Maker & eSign PDF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: kReleaseMode ? null : DevicePreview.locale(context),
      builder: kReleaseMode ? null : DevicePreview.appBuilder,
      routerConfig: _router,
    );
  }
}
