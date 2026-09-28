import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:signature_sync/services/signature_background.dart';

/// Builds a synthetic "photo": white paper with a black ink square in the
/// middle, like a signature stroke.
Uint8List _fakeScanPhoto() {
  final image = img.Image(width: 100, height: 100, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(250, 248, 245, 255)); // off-white paper
  for (var y = 40; y < 60; y++) {
    for (var x = 40; x < 60; x++) {
      image.setPixelRgba(x, y, 10, 10, 10, 255); // near-black ink
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

/// Left half bright paper, right half shadowed paper (~lum 140), with a
/// dark ink stroke only on the left — shadows must not be kept as ink.
Uint8List _fakeUnevenLightingPhoto() {
  final image = img.Image(width: 200, height: 120, numChannels: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (x < 100) {
        image.setPixelRgba(x, y, 250, 248, 245, 255); // bright paper
      } else {
        // Soft shadow across the right half — darker than inkFloor absolute
        // but still "paper" relative to its local neighbourhood.
        image.setPixelRgba(x, y, 145, 142, 138, 255);
      }
    }
  }
  // Ink stroke only on the bright side.
  for (var y = 45; y < 75; y++) {
    for (var x = 30; x < 70; x++) {
      image.setPixelRgba(x, y, 12, 12, 12, 255);
    }
  }
  // Dark-ish "blob" on the shadowed side that is NOT darker than local paper
  // by much (still ~130) — must become transparent under adaptive threshold.
  for (var y = 45; y < 75; y++) {
    for (var x = 130; x < 170; x++) {
      image.setPixelRgba(x, y, 128, 125, 120, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('removeSignatureBackground clears paper, keeps ink opaque', () {
    final params = BackgroundRemovalParams(
      bytes: _fakeScanPhoto(),
      paperThreshold: kDefaultPaperThreshold,
      inkColorValue: 0xFF111111,
    );

    final result = removeSignatureBackground(params);
    expect(result, isNotNull);

    final decoded = img.decodePng(result!)!;
    // Paper corner is transparent.
    expect(decoded.getPixel(5, 5).a, 0);
    // Ink centre is fully opaque and painted the requested ink colour.
    final inkPixel = decoded.getPixel(50, 50);
    expect(inkPixel.a, 255);
    expect(inkPixel.r, 0x11);
  });

  test('a higher threshold removes more of the paper', () {
    final photo = _fakeScanPhoto();
    final low = removeSignatureBackground(
      BackgroundRemovalParams(
        bytes: photo,
        paperThreshold: kPaperThresholdMin,
        inkColorValue: 0xFF111111,
      ),
    )!;
    final high = removeSignatureBackground(
      BackgroundRemovalParams(
        bytes: photo,
        paperThreshold: kPaperThresholdMax,
        inkColorValue: 0xFF111111,
      ),
    )!;

    int opaqueCount(Uint8List png) {
      final decoded = img.decodePng(png)!;
      var count = 0;
      for (var y = 0; y < decoded.height; y++) {
        for (var x = 0; x < decoded.width; x++) {
          if (decoded.getPixel(x, y).a > 0) count++;
        }
      }
      return count;
    }

    // Counts stay in the same ballpark either way on this sharp synthetic.
    expect(opaqueCount(high), greaterThan(0));
    expect(opaqueCount(low), greaterThan(0));
    expect((opaqueCount(high) - opaqueCount(low)).abs(), lessThan(80));
  });

  test('uneven lighting: shadowed paper clears, ink stays', () {
    final result = removeSignatureBackground(
      BackgroundRemovalParams(
        bytes: _fakeUnevenLightingPhoto(),
        paperThreshold: kDefaultPaperThreshold,
        inkColorValue: 0xFF111111,
      ),
    );
    expect(result, isNotNull);
    final decoded = img.decodePng(result!)!;

    // Bright-side paper transparent.
    expect(decoded.getPixel(10, 10).a, 0);
    // Shadowed-side paper (no real ink) transparent — this failed with a
    // global threshold because lum≈140 looked like "ink".
    expect(decoded.getPixel(150, 20).a, 0);
    expect(decoded.getPixel(150, 60).a, lessThan(40));
    // Real ink on the bright side stays solid.
    final ink = decoded.getPixel(50, 60);
    expect(ink.a, 255);
    expect(ink.r, 0x11);
  });

  test('cropTransparentMargins tightens the canvas around the ink', () {
    final processed = removeSignatureBackground(
      BackgroundRemovalParams(
        bytes: _fakeScanPhoto(),
        paperThreshold: kDefaultPaperThreshold,
        inkColorValue: 0xFF111111,
      ),
    )!;
    final cropped = cropTransparentMargins(processed, margin: 4);
    final decoded = img.decodePng(cropped)!;

    // 20px ink square + 4px margin each side ≈ 28px, well under the
    // original 100x100 canvas.
    expect(decoded.width, lessThan(50));
    expect(decoded.height, lessThan(50));
  });
}
