import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:signature_sync/models/signature_model.dart';
import 'package:signature_sync/screens/sign_place_screen.dart';
import 'package:signature_sync/services/storage_service.dart';

/// A 1-page "document" image the Place screen can render without pdfx
/// (avoids needing the PDF platform channel in a widget test).
Future<String> _writeFakeDocument(Directory dir) async {
  final image = img.Image(width: 400, height: 600);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  final file = File('${dir.path}/doc.png');
  await file.writeAsBytes(Uint8List.fromList(img.encodePng(image)));
  return file.path;
}

/// Minimal router so `GoRouterState.of(context)` and `context.push(...)`
/// both work like they do in the real app.
GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/blank',
    routes: [
      GoRoute(path: '/blank', builder: (_, _) => const SizedBox()),
      GoRoute(
        path: '/place',
        builder: (context, state) => const SignPlaceScreen(),
      ),
      GoRoute(
        path: '/sign-document/success',
        builder: (context, state) =>
            Scaffold(body: Text('applied:${state.extra}')),
      ),
      GoRoute(
        path: '/draw-signature',
        builder: (context, state) => const SizedBox(),
      ),
    ],
  );
}

/// Decoding the page image and every Hive/file operation resolve on real
/// engine/IO threads and need real wall-clock time to complete — `pump()`'s
/// fake clock alone never lets them finish, so all real async work in these
/// tests is funnelled through `runAsync`.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Sets up a throwaway Hive database for one test. Must run inside
  /// `tester.runAsync` — see note on `_waitFor`.
  Future<Directory> initHive() async {
    final tempDir = await Directory.systemTemp.createTemp('sign_place_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tempDir.path,
    );
    await StorageService.init();
    return tempDir;
  }

  Future<void> disposeHive(Directory tempDir) async {
    await StorageService.clearAll();
    // Windows keeps the box files locked until Hive itself closes them;
    // deleting the temp dir first would fail with "in use by another
    // process".
    await Hive.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {
        // Best-effort cleanup — a leftover temp dir doesn't affect other
        // tests, each of which gets its own directory.
      }
    }
  }

  testWidgets('renders the real document and a real saved signature', (
    tester,
  ) async {
    late Directory tempDir;
    late String docPath;
    await tester.runAsync(() async {
      tempDir = await initHive();
      await StorageService.saveSignature(
        SignatureModel(
          id: 'sig_1',
          name: 'My signature',
          style: SignatureStyle.typed,
          createdAt: DateTime(2026, 1, 1),
          isDefault: true,
          signatureText: 'Momina Yaqoob',
        ),
      );
      docPath = await _writeFakeDocument(tempDir);
    });

    final router = _testRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    router.push(
      '/place',
      extra: <String, String>{
        'filePath': docPath,
        'fileType': 'image',
        'pageCount': '1',
      },
    );
    await tester.pump();
    await _waitFor(tester, find.byType(Image));

    expect(find.text('Place Signature'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget); // the real document page
    expect(find.text('Momina Yaqoob'), findsOneWidget); // the real signature
    expect(
      find.text('Create a signature first to place it here.'),
      findsNothing,
    );

    // Dragging the signature and its resize handle should not throw.
    await tester.drag(find.text('Momina Yaqoob'), const Offset(20, 15));
    await tester.pump();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // The success route received the placement data (page, signature id,
    // normalized geometry) needed for a later merge step.
    expect(find.textContaining('signatureId: sig_1'), findsOneWidget);

    await tester.runAsync(() => disposeHive(tempDir));
  });

  testWidgets('prompts to create a signature when none are saved', (
    tester,
  ) async {
    late Directory tempDir;
    late String docPath;
    await tester.runAsync(() async {
      tempDir = await initHive();
      docPath = await _writeFakeDocument(tempDir);
    });

    final router = _testRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    router.push(
      '/place',
      extra: <String, String>{
        'filePath': docPath,
        'fileType': 'image',
        'pageCount': '1',
      },
    );
    await tester.pump();
    await _waitFor(
      tester,
      find.text('Create a signature first to place it here.'),
    );

    expect(
      find.text('Create a signature first to place it here.'),
      findsOneWidget,
    );
    // Apply is disabled with nothing to place.
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(find.textContaining('applied:'), findsNothing);

    await tester.runAsync(() => disposeHive(tempDir));
  });

  testWidgets('shows an error when the file is missing', (tester) async {
    late Directory tempDir;
    await tester.runAsync(() async {
      tempDir = await initHive();
    });

    final router = _testRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    router.push(
      '/place',
      extra: <String, String>{
        'filePath': '${tempDir.path}/does-not-exist.png',
        'fileType': 'image',
        'pageCount': '1',
      },
    );
    await tester.pump();
    await _waitFor(tester, find.text('Document file not found'));

    expect(find.text('Document file not found'), findsOneWidget);

    await tester.runAsync(() => disposeHive(tempDir));
  });
}
