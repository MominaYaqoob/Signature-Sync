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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  await StorageService.init();
  // google_mobile_ads has no web implementation.
  if (!kIsWeb) unawaited(AdsService.instance.initialize());
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.navy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    DevicePreview(
      // Chrome / web pe mobile frames; real phone pe off.
      enabled: kIsWeb,
      builder: (context) => const SignatureSyncApp(),
    ),
  );
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
