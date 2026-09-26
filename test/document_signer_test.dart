import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:signature_sync/models/signature_model.dart';
import 'package:signature_sync/services/document_signer.dart';

img.Image _solidImage(int w, int h, img.ColorRgba8 color) {
  final image = img.Image(width: w, height: h, numChannels: 4);
  img.fill(image, color: color);
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('compositeStampOnImage', () {
    test('places an opaque stamp at the requested fractional position',
        () async {
      final base = _solidImage(200, 200, img.ColorRgba8(255, 255, 255, 255));
      final stamp = _solidImage(20, 20, img.ColorRgba8(255, 0, 0, 255));

      final result = await compositeStampOnImage(
        baseBytes: Uint8List.fromList(img.encodePng(base)),
        stampBytes: Uint8List.fromList(img.encodePng(stamp)),
        placement: const StampPlacement(
          pageIndex: 0,
          xFrac: 0.5, // stamp's left edge at x=100
          yFrac: 0.5, // top edge at y=100
          widthFrac: 0.1, // 20px wide on a 200px canvas
          heightFrac: 0.1,
          rotationRadians: 0,
        ),
      );

      final decoded = img.decodePng(result)!;
      // Centre of the stamp (110, 110) should be red.
      final centre = decoded.getPixel(110, 110);
      expect(centre.r, 255);
      expect(centre.g, 0);
      expect(centre.a, 255);
      // Far corner, untouched by the stamp, stays white.
      final corner = decoded.getPixel(5, 5);
      expect(corner.r, 255);
      expect(corner.g, 255);
      expect(corner.b, 255);
    });

    test('a transparent stamp does not paint over the page', () async {
      final base = _solidImage(100, 100, img.ColorRgba8(255, 255, 255, 255));
      final stamp = _solidImage(20, 20, img.ColorRgba8(0, 0, 0, 0));

      final result = await compositeStampOnImage(
        baseBytes: Uint8List.fromList(img.encodePng(base)),
        stampBytes: Uint8List.fromList(img.encodePng(stamp)),
        placement: const StampPlacement(
          pageIndex: 0,
          xFrac: 0.4,
          yFrac: 0.4,
          widthFrac: 0.2,
          heightFrac: 0.2,
          rotationRadians: 0,
        ),
      );

      final decoded = img.decodePng(result)!;
      final centre = decoded.getPixel(50, 50);
      expect(centre.r, 255);
      expect(centre.g, 255);
      expect(centre.b, 255);
    });
  });

  testWidgets(
    'buildSignedDocument stamps a typed signature onto an image document',
    (tester) async {
      await tester.runAsync(() async {
        final tempDir = await Directory.systemTemp.createTemp('doc_signer');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );

        try {
          final source = _solidImage(300, 300, img.ColorRgba8(255, 255, 255, 255));
          final sourcePath = '${tempDir.path}/source.png';
          await File(sourcePath).writeAsBytes(
            Uint8List.fromList(img.encodePng(source)),
          );

          final signature = SignatureModel(
            id: 'sig_1',
            name: 'My signature',
            style: SignatureStyle.typed,
            createdAt: DateTime(2026, 1, 1),
            signatureText: 'Momina Yaqoob',
            inkColor: 0xFF111111,
          );

          final result = await buildSignedDocument(
            sourcePath: sourcePath,
            fileType: 'image',
            pageCount: 1,
            placement: const StampPlacement(
              pageIndex: 0,
              xFrac: 0.1,
              yFrac: 0.6,
              widthFrac: 0.4,
              heightFrac: 0.2,
              rotationRadians: 0,
            ),
            signature: signature,
          );

          expect(File(result.filePath).existsSync(), isTrue);
          final decodedOut = img.decodePng(
            await File(result.filePath).readAsBytes(),
          )!;
          // The output is the same page size and has some non-white pixels
          // where the signature ink was stamped.
          expect(decodedOut.width, 300);
          expect(decodedOut.height, 300);

          var foundInk = false;
          for (var y = 180; y < 240 && !foundInk; y++) {
            for (var x = 30; x < 150; x++) {
              final p = decodedOut.getPixel(x, y);
              if (p.a > 0 && (p.r < 250 || p.g < 250 || p.b < 250)) {
                foundInk = true;
                break;
              }
            }
          }
          expect(foundInk, isTrue, reason: 'expected signature ink on the page');
        } finally {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
          if (tempDir.existsSync()) {
            try {
              await tempDir.delete(recursive: true);
            } catch (_) {}
          }
        }
      });
    },
  );
}
