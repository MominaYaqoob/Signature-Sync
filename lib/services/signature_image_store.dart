import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Stores signature PNGs where the platform allows it.
///
/// Mobile/desktop: a file under `<app documents>/signatures/` and the returned
/// reference is its path. Web has no file system (path_provider throws
/// MissingPluginException), so the PNG is kept inline as a `data:` URI that
/// Hive persists alongside the signature record.
class SignatureImageStore {
  SignatureImageStore._();

  static const _dataUriPrefix = 'data:image/png;base64,';

  static bool _isDataUri(String ref) => ref.startsWith('data:');

  /// Saves [bytes] and returns the reference to store in `imagePath`.
  static Future<String> save(String id, Uint8List bytes) async {
    if (kIsWeb) return '$_dataUriPrefix${base64Encode(bytes)}';

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/signatures');
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/$id.png');
    await file.writeAsBytes(bytes, flush: true);
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
