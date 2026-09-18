import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'router/app_router.dart';
import 'services/storage_service.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
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
