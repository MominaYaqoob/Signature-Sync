import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Persist a camera/scanner image into app documents and soft-cap width at
/// [maxWidth]. Isolate-safe decode path via [compute].
Future<String> persistDocumentScanImage(
  String sourcePath, {
  int maxWidth = 1600,
}) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/documents');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final id = 'doc_${DateTime.now().millisecondsSinceEpoch}';
  final dest = File('${dir.path}/$id.jpg');

  final bytes = await File(sourcePath).readAsBytes();
  final result = await compute(
    _downscaleScanIsolate,
    _DownscaleParams(bytes: bytes, maxWidth: maxWidth),
  );
  await dest.writeAsBytes(result, flush: true);
  return dest.path;
}

class _DownscaleParams {
  const _DownscaleParams({required this.bytes, required this.maxWidth});

  final Uint8List bytes;
  final int maxWidth;
}

Uint8List _downscaleScanIsolate(_DownscaleParams params) {
  final decoded = img.decodeImage(params.bytes);
  if (decoded == null) {
    throw StateError('Could not decode scanned image');
  }
  var image = img.bakeOrientation(decoded);
  if (image.width > params.maxWidth) {
    final h =
        (image.height * (params.maxWidth / image.width)).round().clamp(1, 100000);
    image = img.copyResize(
      image,
      width: params.maxWidth,
      height: h,
      interpolation: img.Interpolation.linear,
    );
  }
  // Soft-cap height too so portrait shots stay reasonable.
  const maxH = 2400;
  if (image.height > maxH) {
    final w =
        (image.width * (maxH / image.height)).round().clamp(1, params.maxWidth);
    image = img.copyResize(
      image,
      width: w,
      height: maxH,
      interpolation: img.Interpolation.linear,
    );
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 88));
}
