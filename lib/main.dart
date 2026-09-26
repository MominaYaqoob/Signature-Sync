import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debug_agent_log.dart';
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
    // #region agent log
    agentLog('C', 'main.dart:main', 'dart_main_entered');
    // #endregion
    WidgetsFlutterBinding.ensureInitialized();

    // Framework errors (build/layout/paint) → log, don't terminate.
    FlutterError.onError = (details) {
      // #region agent log
      agentLog('E', 'main.dart:FlutterError', 'flutter_framework_error', {
        'exception': details.exceptionAsString(),
      });
      // #endregion
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
      if (details.stack != null) debugPrint('${details.stack}');
    };

    _registerFontLicenses();
    // #region agent log
    agentLog('B', 'main.dart:main', 'storage_init_before');
    // #endregion
    await StorageService.init();
    // #region agent log
    agentLog('B', 'main.dart:main', 'storage_init_after');
    // #endregion

    // google_mobile_ads has no web implementation. NEVER await ads init
    // before runApp — on some OEM / Play Services builds MobileAds.initialize()
    // can hang forever (no throw), which looks like "APK installs but won't open".
    // Fire-and-forget + catch so UI always starts; zone handler catches escapes.
    if (!kIsWeb) {
      // #region agent log
      agentLog('A', 'main.dart:main', 'ads_init_scheduled_nonblocking');
      // #endregion
      unawaited(
        AdsService.instance.initialize().then((_) {
          // #region agent log
          agentLog('A', 'main.dart:main', 'ads_init_after_ok');
          // #endregion
        }).catchError((Object e, StackTrace st) {
          // #region agent log
          agentLog('A', 'main.dart:main', 'ads_init_failed', {
            'error': e.toString(),
            'stack': st.toString(),
          });
          // #endregion
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
    // #region agent log
    agentLog('E', 'main.dart:main', 'runApp_before');
    // #endregion
    runApp(
      DevicePreview(
        // Chrome / web pe mobile frames; real phone pe off.
        enabled: kIsWeb,
        builder: (context) => const SignatureSyncApp(),
      ),
    );
    // #region agent log
    agentLog('E', 'main.dart:main', 'runApp_after');
    // #endregion
  }, (error, stack) {
    // #region agent log
    agentLog('E', 'main.dart:zone', 'uncaught_zone_error', {
      'error': error.toString(),
      'stack': stack.toString(),
    });
    // #endregion
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
      title: 'Signature: Sync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      routerConfig: _router,
    );
  }
}
