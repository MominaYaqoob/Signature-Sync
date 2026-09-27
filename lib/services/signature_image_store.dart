import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Stores signature PNGs where the platform allows it.
///
/// Mobile/desktop: a file under `<app documents>/signatures/` and the returned
/// reference is its path. Web has no file system (path_provider throws
/// MissingPluginException), so the PNG is kept inline as a `data:` URI that
/// Hive persists alongside the signature record.
///
/// Always persists **PNG** (never JPEG) so alpha from background removal
/// survives — JPEG has no alpha channel and would flatten transparency.
class SignatureImageStore {
  SignatureImageStore._();

  static const _dataUriPrefix = 'data:image/png;base64,';

  static bool _isDataUri(String ref) => ref.startsWith('data:');

  static bool _looksLikePng(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;

  /// Ensures [bytes] are a PNG with an alpha channel. If the payload is
  /// already PNG, it is returned as-is; otherwise it is re-encoded as PNG.
  static Uint8List ensurePng(Uint8List bytes) {
    if (_looksLikePng(bytes)) return bytes;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode signature image bytes');
    }
    return Uint8List.fromList(
      img.encodePng(decoded.convert(numChannels: 4)),
    );
  }

  /// Saves [bytes] as a PNG and returns the reference to store in `imagePath`.
  static Future<String> save(String id, Uint8List bytes) async {
    final pngBytes = ensurePng(bytes);
    if (kIsWeb) return '$_dataUriPrefix${base64Encode(pngBytes)}';

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/signatures');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/$id.png');
    await file.writeAsBytes(pngBytes, flush: true);
    return file.path;
  }

  static bool exists(String? ref) {
    if (ref == null || ref.isEmpty) return false;
    if (_isDataUri(ref)) return true;
    if (kIsWeb) return false;
    return File(ref).existsSync();
  }

  static Future<void> delete(String? ref) async {
    if (ref == null || ref.isEmpty || _isDataUri(ref) || kIsWeb) return;
    try {
      final file = File(ref);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort — a leftover file is harmless.
    }
  }

  /// Reads the raw PNG bytes for a saved reference (file path or data URI).
  static Future<Uint8List> readBytes(String ref) async {
    if (_isDataUri(ref)) {
      return base64Decode(ref.substring(ref.indexOf(',') + 1));
    }
    return File(ref).readAsBytes();
  }

  static Widget image(
    String ref, {
    BoxFit fit = BoxFit.contain,
    ImageErrorWidgetBuilder? errorBuilder,
  }) {
    if (_isDataUri(ref)) {
      return Image.memory(
        base64Decode(ref.substring(ref.indexOf(',') + 1)),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        errorBuilder: errorBuilder,
      );
    }
    return Image.file(
      File(ref),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
      errorBuilder: errorBuilder,
    );
  }
}
