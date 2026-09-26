import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf_fmt;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

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

/// Visual preset for an optional date stamp drawn near the signature.
enum DateStampStyle {
  /// Small plain sans-serif date.
  plain,

  /// Italic / cursive ink look.
  cursive,

  /// Date inside a thin rounded box.
  boxed,

  /// Prefixed with "Signed on:".
  signedOn,
}

extension DateStampStyleLabel on DateStampStyle {
  String get label => switch (this) {
        DateStampStyle.plain => 'Plain',
        DateStampStyle.cursive => 'Cursive',
        DateStampStyle.boxed => 'Boxed',
        DateStampStyle.signedOn => 'Signed on',
      };

  static DateStampStyle fromName(String? name) {
    for (final s in DateStampStyle.values) {
      if (s.name == name) return s;
    }
    return DateStampStyle.plain;
  }
}

/// Optional date stamp placement (fractions of page size), independent of
/// the signature [StampPlacement].
class DateStampPlacement {
  const DateStampPlacement({
    required this.pageIndex,
    required this.xFrac,
    required this.yFrac,
    required this.widthFrac,
    required this.heightFrac,
    required this.style,
    required this.text,
  });

  final int pageIndex;
  final double xFrac;
  final double yFrac;
  final double widthFrac;
  final double heightFrac;
  final DateStampStyle style;
  final String text;

  factory DateStampPlacement.fromMap(Map<Object?, Object?> map, int pageIndex) {
    double frac(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return DateStampPlacement(
      pageIndex: pageIndex,
      xFrac: frac('xFrac'),
      yFrac: frac('yFrac'),
      widthFrac: frac('widthFrac'),
      heightFrac: frac('heightFrac'),
      style: DateStampStyleLabel.fromName(map['style'] as String?),
      text: (map['text'] as String?)?.trim().isNotEmpty == true
          ? map['text'] as String
          : formatDateStampText(DateTime.now()),
    );
  }

  Map<String, Object?> toMap() => {
        'xFrac': xFrac,
        'yFrac': yFrac,
        'widthFrac': widthFrac,
        'heightFrac': heightFrac,
        'style': style.name,
        'text': text,
      };
}

/// Human-readable date for stamps, e.g. "September 26, 2026".
String formatDateStampText(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

/// Result of [buildSignedDocument]: where the file was written, plus a PNG
/// of the signed page so the caller can show it immediately without
/// re-opening/re-rendering the (possibly large) output file.
class SignedDocumentResult {
  const SignedDocumentResult({required this.filePath, required this.previewPng});

  final String filePath;
  final Uint8List previewPng;
}

/// Strips filesystem-illegal characters and any trailing .pdf/.png so callers
/// can safely append the real extension. Empty after sanitize → caller should
/// fall back to an auto-generated name.
String sanitizeFileBaseName(String input) {
  var s = input.trim();
  s = s.replaceAll(RegExp(r'\.(pdf|png)$', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Soft cap so paths stay portable on older Android storage layouts.
  if (s.length > 80) s = s.substring(0, 80).trim();
  return s;
}

String _uniqueOutPath(Directory outDir, String base, String extension) {
  var candidate = '${outDir.path}/$base$extension';
  if (!File(candidate).existsSync()) return candidate;
  var n = 2;
  while (true) {
    candidate = '${outDir.path}/${base}_$n$extension';
    if (!File(candidate).existsSync()) return candidate;
    n++;
  }
}

/// Builds the final signed file by compositing [signature] onto
/// [placement.pageIndex] of the source document, and writes it under the
/// app's documents/signed/ folder.
///
/// [preferredBaseName] is an optional user-chosen file stem (no extension).
/// Blank / invalid values fall back to `signed_<timestamp>`.
///
/// For PDFs, tries a text-preserving Syncfusion overlay first; on any
/// failure falls back to the legacy image-flattened rebuild so signing
/// never hard-fails for the user.
Future<SignedDocumentResult> buildSignedDocument({
  required String sourcePath,
  required String fileType,
  required int pageCount,
  required StampPlacement placement,
  required SignatureModel signature,
  String? preferredBaseName,
  DateStampPlacement? datePlacement,
}) async {
  final stampBytes = await resolveSignatureStampPng(signature);

  final docs = await getApplicationDocumentsDirectory();
  final outDir = Directory('${docs.path}/signed');
  if (!await outDir.exists()) await outDir.create(recursive: true);

  final sanitized = sanitizeFileBaseName(preferredBaseName ?? '');
  final base = sanitized.isEmpty
      ? 'signed_${DateTime.now().millisecondsSinceEpoch}'
      : sanitized;

  if (fileType == 'pdf') {
    final outPath = _uniqueOutPath(outDir, base, '.pdf');
    try {
      final preview = await _buildSignedPdfPreservingText(
        sourcePath: sourcePath,
        pageCount: pageCount,
        placement: placement,
        stampBytes: stampBytes,
        outPath: outPath,
        datePlacement: datePlacement,
      );
      return SignedDocumentResult(filePath: outPath, previewPng: preview);
    } catch (e, st) {
      debugPrint(
        '[document_signer] Syncfusion PDF path failed; '
        'falling back to legacy flatten: $e\n$st',
      );
      final preview = await _buildSignedPdfLegacy(
        sourcePath: sourcePath,
        pageCount: pageCount,
        placement: placement,
        stampBytes: stampBytes,
        outPath: outPath,
        datePlacement: datePlacement,
      );
      return SignedDocumentResult(filePath: outPath, previewPng: preview);
    }
  }

  final outPath = _uniqueOutPath(outDir, base, '.png');
  final baseBytes = await File(sourcePath).readAsBytes();
  final composited = await compositeStampOnImage(
    baseBytes: baseBytes,
    stampBytes: stampBytes,
    placement: placement,
    datePlacement: datePlacement,
  );
  await File(outPath).writeAsBytes(composited, flush: true);
  return SignedDocumentResult(filePath: outPath, previewPng: composited);
}

/// Loads the original PDF with Syncfusion, draws stamp (+ optional date) on
/// the graphics layer of the target page, and saves — leaving other pages
/// and the original text layer intact. Returns a PNG preview of the signed
/// page (rendered via pdfx for the success screen only).
Future<Uint8List> _buildSignedPdfPreservingText({
  required String sourcePath,
  required int pageCount,
  required StampPlacement placement,
  required Uint8List stampBytes,
  required String outPath,
  DateStampPlacement? datePlacement,
}) async {
  final inputBytes = await File(sourcePath).readAsBytes();
  final document = sf.PdfDocument(inputBytes: inputBytes);
  try {
    if (placement.pageIndex < 0 ||
        placement.pageIndex >= document.pages.count) {
      throw StateError(
        'pageIndex ${placement.pageIndex} out of range '
        '(${document.pages.count} pages)',
      );
    }
    final page = document.pages[placement.pageIndex];
    // Syncfusion Flutter graphics use a top-left origin (same as our fractions).
    final pageSize = page.getClientSize();
    final stampW = placement.widthFrac * pageSize.width;
    final stampH = placement.heightFrac * pageSize.height;
    final stampX = placement.xFrac * pageSize.width;
    final stampY = placement.yFrac * pageSize.height;

    final stampBitmap = sf.PdfBitmap(stampBytes);
    final g = page.graphics;
    g.save();
    if (placement.rotationRadians != 0) {
      final cx = stampX + stampW / 2;
      final cy = stampY + stampH / 2;
      g.translateTransform(cx, cy);
      g.rotateTransform(placement.rotationRadians * 180 / math.pi);
      g.drawImage(
        stampBitmap,
        Rect.fromCenter(
          center: Offset.zero,
          width: stampW,
          height: stampH,
        ),
      );
    } else {
      g.drawImage(
        stampBitmap,
        Rect.fromLTWH(stampX, stampY, stampW, stampH),
      );
    }
    g.restore();

    if (datePlacement != null &&
        datePlacement.pageIndex == placement.pageIndex) {
      final dateW = datePlacement.widthFrac * pageSize.width;
      final dateH = datePlacement.heightFrac * pageSize.height;
      final datePng = await renderDateStampPng(
        text: datePlacement.text,
        style: datePlacement.style,
        width: dateW,
        height: dateH,
      );
      g.drawImage(
        sf.PdfBitmap(datePng),
        Rect.fromLTWH(
          datePlacement.xFrac * pageSize.width,
          datePlacement.yFrac * pageSize.height,
          dateW,
          dateH,
        ),
      );
    }

    final saved = await document.save();
    await File(outPath).writeAsBytes(
      saved is Uint8List ? saved : Uint8List.fromList(saved),
      flush: true,
    );
  } finally {
    document.dispose();
  }

  // Preview only: render the signed page from the saved file with pdfx.
  return _renderPdfPagePreview(outPath, placement.pageIndex);
}

Future<Uint8List> _renderPdfPagePreview(String pdfPath, int pageIndex) async {
  final source = await pdfx.PdfDocument.openFile(pdfPath);
  try {
    final page = await source.getPage(pageIndex + 1);
    try {
      final targetWidth = (page.width * 2).clamp(300, 1600).toDouble();
      final targetHeight = targetWidth * (page.height / page.width);
      final rendered = await page.render(
        width: targetWidth,
        height: targetHeight,
        format: pdfx.PdfPageImageFormat.png,
      );
      if (rendered == null) {
        throw Exception('Could not render preview page');
      }
      return rendered.bytes;
    } finally {
      await page.close();
    }
  } finally {
    await source.close();
  }
}

/// Legacy path: rebuilds the PDF page-by-page as full-bleed images.
/// Kept as a safety net when Syncfusion cannot parse a document.
Future<Uint8List> _buildSignedPdfLegacy({
  required String sourcePath,
  required int pageCount,
  required StampPlacement placement,
  required Uint8List stampBytes,
  required String outPath,
  DateStampPlacement? datePlacement,
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
          ? await compositeStampOnImage(
              baseBytes: pageBytes,
              stampBytes: stampBytes,
              placement: placement,
              datePlacement: datePlacement,
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

/// Renders [text] as a transparent PNG in [style] at roughly [width]×[height]
/// logical pixels (device pixel ratio applied for sharpness).
Future<Uint8List> renderDateStampPng({
  required String text,
  required DateStampStyle style,
  required double width,
  required double height,
  double pixelRatio = 3,
}) async {
  final display = style == DateStampStyle.signedOn ? 'Signed on: $text' : text;
  final w = math.max(8.0, width);
  final h = math.max(8.0, height);
  final ink = const Color(0xFF1A2744);
  final baseStyle = switch (style) {
    DateStampStyle.plain => TextStyle(
        color: ink,
        fontSize: h * 0.45,
        fontWeight: FontWeight.w500,
        height: 1.1,
      ),
    DateStampStyle.cursive => TextStyle(
        color: ink,
        fontSize: h * 0.5,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        height: 1.1,
      ),
    DateStampStyle.boxed || DateStampStyle.signedOn => TextStyle(
        color: ink,
        fontSize: h * 0.4,
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
  };

  final tp = TextPainter(
    text: TextSpan(text: display, style: baseStyle),
    textDirection: TextDirection.ltr,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: w - (style == DateStampStyle.boxed ? 12 : 4));

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  if (style == DateStampStyle.boxed) {
    const pad = 4.0;
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, w - 2, h - 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..color = ink.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    tp.paint(canvas, Offset(pad, math.max(pad, (h - tp.height) / 2)));
  } else {
    tp.paint(canvas, Offset(2, math.max(0, (h - tp.height) / 2)));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (w * pixelRatio).ceil().clamp(1, 4096),
    (h * pixelRatio).ceil().clamp(1, 4096),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  tp.dispose();
  return data!.buffer.asUint8List();
}

/// Composites [stampBytes] (a transparent signature PNG) onto [baseBytes]
/// at [placement]'s fractional geometry, resized and rotated to match.
/// When [datePlacement] is non-null, also draws the date stamp. Omitting
/// it leaves the output pixel-identical to signature-only compositing.
Future<Uint8List> compositeStampOnImage({
  required Uint8List baseBytes,
  required Uint8List stampBytes,
  required StampPlacement placement,
  DateStampPlacement? datePlacement,
}) async {
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

  if (datePlacement != null) {
    final dateW =
        (datePlacement.widthFrac * base.width).round().clamp(1, base.width);
    final dateH =
        (datePlacement.heightFrac * base.height).round().clamp(1, base.height);
    final datePng = await renderDateStampPng(
      text: datePlacement.text,
      style: datePlacement.style,
      width: dateW.toDouble(),
      height: dateH.toDouble(),
    );
    var dateImg = img.decodeImage(datePng)!.convert(numChannels: 4);
    dateImg = img.copyResize(
      dateImg,
      width: dateW,
      height: dateH,
      interpolation: img.Interpolation.cubic,
    );
    final dx = (datePlacement.xFrac * base.width).round();
    final dy = (datePlacement.yFrac * base.height).round();
    img.compositeImage(base, dateImg, dstX: dx, dstY: dy);
  }

  return Uint8List.fromList(img.encodePng(base));
}
