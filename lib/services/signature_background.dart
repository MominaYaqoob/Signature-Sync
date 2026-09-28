import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Inputs for [removeSignatureBackground] — a plain data class so the work
/// can run on a background isolate via `compute()` (no Flutter/UI imports).
class BackgroundRemovalParams {
  const BackgroundRemovalParams({
    required this.bytes,
    required this.paperThreshold,
    required this.inkColorValue,
  });

  /// Source photo bytes (any format `package:image` can decode).
  final Uint8List bytes;

  /// Controls how aggressively paper is removed (0–255 scale). Applied as an
  /// offset against the *local* paper brightness estimate — not a single
  /// global luminance cutoff — so uneven lighting/shadows don't get kept as
  /// ink. Higher = remove more of near-paper greys.
  final int paperThreshold;

  /// Ink colour to paint onto kept strokes, as an ARGB32 int.
  final int inkColorValue;

  /// Darkness (vs local paper) at which strokes become solid ink. Kept a
  /// fixed distance below [paperThreshold] so the slider still moves both.
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

/// Long-side size of the lighting-map downsample. Thin ink strokes vanish at
/// this scale; gradual shadows remain — that's what we want.
const _lightingMapLongSide = 48;

/// Removes the paper background from a scanned/gallery signature photo,
/// keeping ink with a soft anti-aliased edge. Uses **local/adaptive**
/// thresholding against a low-frequency lighting map so shadowed paper is
/// not mistaken for ink. Runs off the UI thread when called through
/// `compute(removeSignatureBackground, params)`.
Uint8List? removeSignatureBackground(BackgroundRemovalParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) return null;

  final src = decoded.convert(numChannels: 4);

  // Pure ARGB parse — no Flutter Color (keeps this isolate-safe).
  final argb = params.inkColorValue;
  final inkR = (argb >> 16) & 0xFF;
  final inkG = (argb >> 8) & 0xFF;
  final inkB = argb & 0xFF;

  final paperThreshold = params.paperThreshold;
  final inkFloor = params.inkFloor;

  // Map absolute slider values → darkness offsets from white, then apply
  // them relative to the local paper estimate (matches old behaviour on
  // evenly lit white paper where localBg ≈ 255).
  final softOffset = (255 - paperThreshold).clamp(1, 200);
  final solidOffset = (255 - inkFloor).clamp(softOffset + 1, 240);
  final softRange = (solidOffset - softOffset).clamp(1, 255);
  // Absolute safety net for thick dark ink that can still darken the
  // lighting map after downsample — never miss near-black strokes.
  const absoluteInkFloor = 48;

  final lighting = _buildLightingMap(src);

  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final pixel = src.getPixel(x, y);
      // Rec. 601 luminance
      final luminance =
          (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();

      final lp = lighting.getPixel(x, y);
      final localBg =
          (0.299 * lp.r + 0.587 * lp.g + 0.114 * lp.b).round().clamp(1, 255);
      final darkness = localBg - luminance;

      final int alpha;
      if (luminance <= absoluteInkFloor) {
        alpha = 255;
      } else if (darkness < softOffset) {
        // Not darker than local paper by enough — treat as paper (incl. soft
        // shadows that aren't ink-dark relative to their neighbourhood).
        src.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      } else if (darkness >= solidOffset) {
        alpha = 255;
      } else {
        final t = (darkness - softOffset) / softRange;
        alpha = (t * 255.0).round().clamp(0, 255);
      }

      src.setPixelRgba(x, y, inkR, inkG, inkB, alpha);
    }
  }

  return Uint8List.fromList(img.encodePng(src));
}

/// Low-frequency estimate of local paper brightness: downscale grayscale so
/// thin ink strokes vanish, dilate toward bright paper values (so leftover
/// ink doesn't pull the estimate down), then bilinear-upscale to full size.
img.Image _buildLightingMap(img.Image src) {
  final w = src.width;
  final h = src.height;
  final gray = img.Image(width: w, height: h, numChannels: 3);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      final lum =
          (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
      gray.setPixelRgb(x, y, lum, lum, lum);
    }
  }

  final longSide = math.max(w, h);
  final scale = _lightingMapLongSide / longSide;
  final smallW = math.max(1, (w * scale).round());
  final smallH = math.max(1, (h * scale).round());

  var small = img.copyResize(
    gray,
    width: smallW,
    height: smallH,
    interpolation: img.Interpolation.average,
  );
  // Mild dilate only — strong dilate would bleed bright paper into large
  // shadow regions and recreate the global-threshold failure mode.
  small = _dilateBright(small, radius: 1);

  return img.copyResize(
    small,
    width: w,
    height: h,
    interpolation: img.Interpolation.linear,
  );
}

/// Local-max filter so the lighting map tracks paper, not ink.
img.Image _dilateBright(img.Image src, {int radius = 1}) {
  final out = img.Image(width: src.width, height: src.height, numChannels: 3);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      var maxLum = 0;
      for (var dy = -radius; dy <= radius; dy++) {
        for (var dx = -radius; dx <= radius; dx++) {
          final xx = (x + dx).clamp(0, src.width - 1);
          final yy = (y + dy).clamp(0, src.height - 1);
          final p = src.getPixel(xx, yy);
          final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
          if (lum > maxLum) maxLum = lum;
        }
      }
      out.setPixelRgb(x, y, maxLum, maxLum, maxLum);
    }
  }
  return out;
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
