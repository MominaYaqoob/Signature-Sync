import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:image/image.dart' as img;

/// Inputs for [removeSignatureBackground] — a plain data class so the work
/// can run on a background isolate via `compute()`.
class BackgroundRemovalParams {
  const BackgroundRemovalParams({
    required this.bytes,
    required this.paperThreshold,
    required this.inkColorValue,
  });

  /// Source photo bytes (any format `package:image` can decode).
  final Uint8List bytes;

  /// Pixels brighter than this (0–255 luminance) become fully transparent —
  /// this is "how much of the paper to remove".
  final int paperThreshold;

  /// Ink colour to paint onto kept strokes, as an ARGB32 int.
  final int inkColorValue;

  /// Pixels darker than this are treated as solid ink. Kept a fixed distance
  /// below [paperThreshold] so ink stays clean while the paper cutoff moves.
  int get inkFloor => (paperThreshold - 70).clamp(20, paperThreshold - 10);

  BackgroundRemovalParams copyWith({int? paperThreshold, int? inkColorValue}) {
    return BackgroundRemovalParams(
      bytes: bytes,
      paperThreshold: paperThreshold ?? this.paperThreshold,
      inkColorValue: inkColorValue ?? this.inkColorValue,
    );
  }
}

/// Default starting point: works well for a phone photo of ink on white
/// paper in normal indoor light.
const kDefaultPaperThreshold = 180;

/// Slider range for the paper cutoff (lower = keeps more, higher = removes
/// more) exposed to the user as "Background removal".
const kPaperThresholdMin = 120;
const kPaperThresholdMax = 235;

/// Removes the paper background from a scanned/gallery signature photo,
/// keeping ink with a soft anti-aliased edge. Runs off the UI thread when
/// called through `compute(removeSignatureBackground, params)`.
Uint8List? removeSignatureBackground(BackgroundRemovalParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) return null;

  final src = decoded.convert(numChannels: 4);
  final ink = Color(params.inkColorValue);
  final inkR = (ink.r * 255.0).round().clamp(0, 255);
  final inkG = (ink.g * 255.0).round().clamp(0, 255);
  final inkB = (ink.b * 255.0).round().clamp(0, 255);

  final paperThreshold = params.paperThreshold;
  final inkFloor = params.inkFloor;
  final softRange = (paperThreshold - inkFloor).clamp(1, 255);

  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final pixel = src.getPixel(x, y);
      // Rec. 601 luminance
      final luminance =
          (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();

      if (luminance > paperThreshold) {
        src.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      final int alpha;
      if (luminance <= inkFloor) {
        alpha = 255;
      } else {
        // Soft falloff between ink floor and paper threshold.
        final t = (luminance - inkFloor) / softRange;
        alpha = ((1.0 - t) * 255.0).round().clamp(0, 255);
      }

      src.setPixelRgba(x, y, inkR, inkG, inkB, alpha);
    }
  }

  return Uint8List.fromList(img.encodePng(src));
}

/// Crops fully-transparent margins off [pngBytes], keeping [margin] px of
/// padding around the remaining content. Returns the input unchanged if
/// nothing is opaque (e.g. threshold removed everything).
Uint8List cropTransparentMargins(Uint8List pngBytes, {int margin = 16}) {
  final decoded = img.decodePng(pngBytes);
  if (decoded == null) return pngBytes;

  var minX = decoded.width;
  var minY = decoded.height;
  var maxX = 0;
  var maxY = 0;
  var found = false;

  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      if (decoded.getPixel(x, y).a < 8) continue;
      found = true;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  if (!found) return pngBytes;

  minX = (minX - margin).clamp(0, decoded.width - 1);
  minY = (minY - margin).clamp(0, decoded.height - 1);
  maxX = (maxX + margin).clamp(0, decoded.width - 1);
  maxY = (maxY + margin).clamp(0, decoded.height - 1);

  final cropped = img.copyCrop(
    decoded,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
  return Uint8List.fromList(img.encodePng(cropped));
}
