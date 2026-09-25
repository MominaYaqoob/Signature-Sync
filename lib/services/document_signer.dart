import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf_fmt;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;

import '../models/signature_model.dart';
import 'signature_rasterizer.dart';

/// Where a signature was dropped on the page, as fractions of that page's
/// size (0..1) — resolution-independent, set by the Place screen.
class StampPlacement {
  const StampPlacement({
    required this.pageIndex,
    required this.xFrac,
    required this.yFrac,
    required this.widthFrac,
    required this.heightFrac,
    required this.rotationRadians,
  });

  /// 0-based page the signature was placed on.
  final int pageIndex;
  final double xFrac;
  final double yFrac;
  final double widthFrac;
  final double heightFrac;
  final double rotationRadians;

  factory StampPlacement.fromMap(Map<Object?, Object?> map, int pageIndex) {
    double frac(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return StampPlacement(
      pageIndex: pageIndex,
      xFrac: frac('xFrac'),
      yFrac: frac('yFrac'),
      widthFrac: frac('widthFrac'),
      heightFrac: frac('heightFrac'),
      rotationRadians: frac('rotationRadians'),
    );
  }
}

/// Result of [buildSignedDocument]: where the file was written, plus a PNG
/// of the signed page so the caller can show it immediately without
/// re-opening/re-rendering the (possibly large) output file.
class SignedDocumentResult {
  const SignedDocumentResult({required this.filePath, required this.previewPng});

  final String filePath;
  final Uint8List previewPng;
}

/// Builds the final signed file by compositing [signature] onto
/// [placement.pageIndex] of the source document, and writes it under the
/// app's documents/signed/ folder.
///
/// PDFs are rebuilt page-by-page as full-bleed images (each page rendered,
/// signed page gets the stamp, then reassembled into a new PDF) — this is
/// done with fully offline, free packages, at the cost of the output PDF's
/// text no longer being selectable/searchable.
Future<SignedDocumentResult> buildSignedDocument({
  required String sourcePath,
  required String fileType,
  required int pageCount,
  required StampPlacement placement,
  required SignatureModel signature,
}) async {
  final stampBytes = await resolveSignatureStampPng(signature);

  final docs = await getApplicationDocumentsDirectory();
  final outDir = Directory('${docs.path}/signed');
  if (!await outDir.exists()) await outDir.create(recursive: true);
  final id = 'signed_${DateTime.now().millisecondsSinceEpoch}';

  if (fileType == 'pdf') {
    final outPath = '${outDir.path}/$id.pdf';
    final preview = await _buildSignedPdf(
      sourcePath: sourcePath,
      pageCount: pageCount,
      placement: placement,
      stampBytes: stampBytes,
      outPath: outPath,
    );
    return SignedDocumentResult(filePath: outPath, previewPng: preview);
  }

  final outPath = '${outDir.path}/$id.png';
  final baseBytes = await File(sourcePath).readAsBytes();
  final composited = compositeStampOnImage(
    baseBytes: baseBytes,
    stampBytes: stampBytes,
    placement: placement,
  );
  await File(outPath).writeAsBytes(composited, flush: true);
  return SignedDocumentResult(filePath: outPath, previewPng: composited);
}

/// Rebuilds the PDF page-by-page as images; returns the *signed* page's PNG
/// for use as an on-screen preview.
Future<Uint8List> _buildSignedPdf({
  required String sourcePath,
  required int pageCount,
  required StampPlacement placement,
  required Uint8List stampBytes,
  required String outPath,
}) async {
  final source = await pdfx.PdfDocument.openFile(sourcePath);
  final pdfDoc = pw.Document();
  Uint8List? signedPagePreview;
  try {
    for (var i = 0; i < pageCount; i++) {
      final page = await source.getPage(i + 1);
      Uint8List pageBytes;
      try {
        // Render at 3x for print-quality output; capped so large pages
        // don't blow up memory/output size.
        final targetWidth = (page.width * 3).clamp(300, 2400).toDouble();
        final targetHeight = targetWidth * (page.height / page.width);
        final rendered = await page.render(
          width: targetWidth,
          height: targetHeight,
          format: pdfx.PdfPageImageFormat.png,
        );
        if (rendered == null) {
          throw Exception('Could not render page ${i + 1}');
        }
        pageBytes = rendered.bytes;
      } finally {
        await page.close();
      }

      final isSignedPage = i == placement.pageIndex;
      final finalBytes = isSignedPage
          ? compositeStampOnImage(
              baseBytes: pageBytes,
              stampBytes: stampBytes,
              placement: placement,
            )
          : pageBytes;
      if (isSignedPage) signedPagePreview = finalBytes;

      pdfDoc.addPage(
        pw.Page(
          pageFormat: pdf_fmt.PdfPageFormat(
            page.width,
            page.height,
            marginAll: 0,
          ),
          build: (context) => pw.Image(
            pw.MemoryImage(finalBytes),
            fit: pw.BoxFit.fill,
          ),
        ),
      );
    }
  } finally {
    await source.close();
  }

  final bytes = await pdfDoc.save();
  await File(outPath).writeAsBytes(bytes, flush: true);
  return signedPagePreview!;
}

/// Composites [stampBytes] (a transparent signature PNG) onto [baseBytes]
/// at [placement]'s fractional geometry, resized and rotated to match.
/// Public so it can also be used for the on-screen "review before saving"
/// preview.
Uint8List compositeStampOnImage({
  required Uint8List baseBytes,
  required Uint8List stampBytes,
  required StampPlacement placement,
}) {
  final base = img.decodeImage(baseBytes)!.convert(numChannels: 4);
  var stamp = img.decodeImage(stampBytes)!.convert(numChannels: 4);

  final stampW = (placement.widthFrac * base.width).round().clamp(1, base.width);
  final stampH =
      (placement.heightFrac * base.height).round().clamp(1, base.height);
  stamp = img.copyResize(
    stamp,
    width: stampW,
    height: stampH,
    interpolation: img.Interpolation.cubic,
  );

  if (placement.rotationRadians != 0) {
    final degrees = placement.rotationRadians * 180 / math.pi;
    stamp = img.copyRotate(
      stamp,
      angle: degrees,
      interpolation: img.Interpolation.cubic,
    );
  }

  // Rotating grows the canvas to fit the rotated content, so re-centre on
  // where the (unrotated) box was — matching the Place screen's
  // Transform.rotate, which pivots around the box centre.
  final centerX = placement.xFrac * base.width + stampW / 2;
  final centerY = placement.yFrac * base.height + stampH / 2;
  final dstX = (centerX - stamp.width / 2).round();
  final dstY = (centerY - stamp.height / 2).round();

  img.compositeImage(base, stamp, dstX: dstX, dstY: dstY);
  return Uint8List.fromList(img.encodePng(base));
}
