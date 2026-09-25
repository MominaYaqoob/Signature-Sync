import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:signature_sync/screens/adjust_signature_background_screen.dart';

Uint8List _fakeScanPhoto() {
  final image = img.Image(width: 60, height: 60, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(250, 248, 245, 255));
  for (var y = 20; y < 40; y++) {
    for (var x = 20; x < 40; x++) {
      image.setPixelRgba(x, y, 10, 10, 10, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

/// `compute()` spawns a real isolate, which needs real wall-clock time to
/// finish — the fake clock `pump()` advances isn't enough on its own, so we
/// let real time pass via `runAsync()` between pumps while polling.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('renders a preview and enables Use this signature', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdjustSignatureBackgroundScreen(sourceBytes: _fakeScanPhoto()),
      ),
    );

    await _waitFor(tester, find.byType(Image));

    expect(find.text('Adjust Background'), findsOneWidget);
    expect(find.text('Use this signature'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Moving the slider should not throw and should keep a preview visible.
    await tester.drag(find.byType(Slider), const Offset(40, 0));
    await _waitFor(tester, find.byType(Image));
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.text('Use this signature'));
    await tester.pump();
  });
}
