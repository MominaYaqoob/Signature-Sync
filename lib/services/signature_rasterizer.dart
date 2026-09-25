import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/signature_model.dart';
import '../theme/theme.dart';
import '../widgets/signature_visual.dart';
import 'signature_image_store.dart';

/// Returns signature ink ready to stamp onto a document, as a transparent
/// PNG: the saved drawing/scan/generated image when there is one, or a
/// freshly-rasterized render of the typed text/font otherwise.
Future<Uint8List> resolveSignatureStampPng(
  SignatureModel signature, {
  double typedFontSize = 140,
}) async {
  final path = signature.imagePath;
  if (path != null && SignatureImageStore.exists(path)) {
    return SignatureImageStore.readBytes(path);
  }
  return rasterizeTypedSignature(signature, fontSize: typedFontSize);
}

/// Renders a typed/generated signature's text to a tightly-cropped,
/// transparent PNG at [fontSize] (document stamps need much higher
/// resolution than an on-screen preview).
Future<Uint8List> rasterizeTypedSignature(
  SignatureModel signature, {
  double fontSize = 140,
}) async {
  await GoogleFonts.pendingFonts();

  final color = signature.inkColor != null
      ? Color(signature.inkColor!)
      : AppColors.accentPurple;
  final style = signatureFontStyle(
    signature.fontLabel,
    fontSize: fontSize,
    color: color,
  );

  final painter = TextPainter(
    text: TextSpan(text: signature.displayText, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  // Padding avoids clipping cursive overshoot/descenders at the edges.
  final padding = fontSize * 0.12;
  final width = (painter.width + padding * 2).ceil().clamp(1, 4000);
  final height = (painter.height + padding * 2).ceil().clamp(1, 2000);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, Offset(padding, padding));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  painter.dispose();
  return data!.buffer.asUint8List();
}
