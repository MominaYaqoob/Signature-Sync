import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Isolate-friendly params for [processScannedSignatureBytes].
class SignatureScanProcessParams {
  const SignatureScanProcessParams({required this.bytes});

  final Uint8List bytes;
}

/// Fast paper-signature cleanup for the Scan Signature camera path.
///
/// Decode → bake EXIF → max-width 1200 → grayscale → threshold vs
/// `0.65 * average luminance` (darker = opaque black ink) → trim
/// transparent margins → PNG. Safe to run via [compute] / Isolate.run.
Uint8List? processScannedSignatureBytes(SignatureScanProcessParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) return null;

  var image = img.bakeOrientation(decoded);

  const maxW = 1200;
  if (image.width > maxW) {
    final h = (image.height * (maxW / image.width)).round().clamp(1, 100000);
    image = img.copyResize(
      image,
      width: maxW,
      height: h,
      interpolation: img.Interpolation.linear,
    );
  }

  // Average luminance (Rec. 601) over the frame.
  var sum = 0;
  final count = image.width * image.height;
  if (count == 0) return null;
  for (final p in image) {
    sum += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
  }
  final avg = sum / count;
  final cutoff = avg * 0.65;

  final out = img.Image(
    width: image.width,
    height: image.height,
    numChannels: 4,
  );
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      if (lum < cutoff) {
        out.setPixelRgba(x, y, 0, 0, 0, 255);
      } else {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  final trimmed = _trimTransparent(out);
  return Uint8List.fromList(img.encodePng(trimmed));
}

img.Image _trimTransparent(img.Image src, {int margin = 4}) {
  var minX = src.width;
  var minY = src.height;
  var maxX = 0;
  var maxY = 0;
  var found = false;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a < 8) continue;
      found = true;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  if (!found) return src;

  minX = math.max(0, minX - margin);
  minY = math.max(0, minY - margin);
  maxX = math.min(src.width - 1, maxX + margin);
  maxY = math.min(src.height - 1, maxY + margin);

  return img.copyCrop(
    src,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

/// Convenience wrapper for [compute].
Uint8List? processScannedSignatureCompute(SignatureScanProcessParams params) {
  return processScannedSignatureBytes(params);
}
