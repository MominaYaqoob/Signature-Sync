import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/signature_fonts.dart';

/// Which parts of the name the autograph shows.
enum AutographLayout {
  /// "Momina Yaqoob" with enlarged capitals.
  full,

  /// "M Yaqoob"
  initialAndLast,

  /// "Momina Y"
  firstAndInitial,

  /// "MY" — large monogram-style initials.
  initials,

  /// "MominaYaqoob" run together like a quick signature.
  joined,

  /// "Yaqoob" — surname only with a big capital.
  lastOnly,
}

/// Decorative pen stroke drawn with the name.
enum AutographSwash { none, underline, loopBack, doubleLine, wave, tail }

/// One randomly generated autograph design. The same spec always draws the
/// same result, so it can be previewed and then exported identically.
class AutographSpec {
  const AutographSpec({
    required this.font,
    required this.layout,
    required this.swash,
    required this.slant,
    required this.capitalScale,
    required this.letterSpacing,
  });

  final SignatureFont font;
  final AutographLayout layout;
  final AutographSwash swash;

  /// Forward lean (0 = upright).
  final double slant;

  /// How much bigger the leading capitals are than the rest.
  final double capitalScale;
  final double letterSpacing;

  /// Builds a random design. Multi-word names get every layout; a single
  /// word only makes sense as the full word.
  factory AutographSpec.random(math.Random random, {required bool multiWord}) {
    final fonts = kSignatureFonts
        .where((f) => f.category != SignatureFontCategory.bold)
        .toList();
    final layouts =
        multiWord ? AutographLayout.values : const [AutographLayout.full];
    final layout = layouts[random.nextInt(layouts.length)];

    // Initials alone look unfinished without a flourish.
    final swashes = layout == AutographLayout.initials
        ? AutographSwash.values.where((s) => s != AutographSwash.none).toList()
        : AutographSwash.values;

    return AutographSpec(
      font: fonts[random.nextInt(fonts.length)],
      layout: layout,
      swash: swashes[random.nextInt(swashes.length)],
      slant: 0.06 + random.nextDouble() * 0.26,
      capitalScale: 1.2 + random.nextDouble() * 0.55,
      letterSpacing: -random.nextDouble() * 1.8,
    );
  }

  AutographSpec copyWith({AutographSwash? swash}) => AutographSpec(
        font: font,
        layout: layout,
        swash: swash ?? this.swash,
        slant: slant,
        capitalScale: capitalScale,
        letterSpacing: letterSpacing,
      );
}

/// Human-readable labels for the swash picker.
extension AutographSwashLabel on AutographSwash {
  String get label => switch (this) {
        AutographSwash.none => 'None',
        AutographSwash.underline => 'Underline',
        AutographSwash.loopBack => 'Loop',
        AutographSwash.doubleLine => 'Double',
        AutographSwash.wave => 'Wave',
        AutographSwash.tail => 'Tail',
      };
}

/// A small preview path for [swash] at a fixed size — the same shapes
/// [AutographPainter] draws, parameterized for style-picker thumbnails.
Path swashPreviewPath(AutographSwash swash, {double width = 48, double height = 48}) {
  final w = width;
  final fs = height;
  final path = Path();
  switch (swash) {
    case AutographSwash.none:
      break;
    case AutographSwash.underline:
      path
        ..moveTo(w * 0.02, fs * 0.24)
        ..quadraticBezierTo(w * 0.55, fs * 0.44, w * 1.08, fs * 0.06);
    case AutographSwash.loopBack:
      path
        ..moveTo(w * 0.97, -fs * 0.04)
        ..cubicTo(w * 1.14, fs * 0.36, w * 0.45, fs * 0.46, -w * 0.06, fs * 0.2);
    case AutographSwash.doubleLine:
      path
        ..moveTo(w * 0.02, fs * 0.2)
        ..quadraticBezierTo(w * 0.55, fs * 0.38, w * 1.08, fs * 0.04)
        ..moveTo(w * 0.14, fs * 0.36)
        ..quadraticBezierTo(w * 0.55, fs * 0.5, w * 0.96, fs * 0.24);
    case AutographSwash.wave:
      path
        ..moveTo(-w * 0.03, fs * 0.28)
        ..cubicTo(w * 0.3, fs * 0.06, w * 0.66, fs * 0.52, w * 1.06, fs * 0.2);
    case AutographSwash.tail:
      path
        ..moveTo(w * 0.97, fs * 0.02)
        ..quadraticBezierTo(w * 1.12, fs * 0.34, w * 0.62, fs * 0.3)
        ..quadraticBezierTo(w * 0.35, fs * 0.28, w * 0.2, fs * 0.36);
  }
  return path;
}

/// Draws [name] using [spec]. Scales the whole autograph (text + swash) to
/// fit the canvas, so the same painter works for tiles and for export.
class AutographPainter extends CustomPainter {
  AutographPainter({
    required this.name,
    required this.spec,
    required this.ink,
    this.fontEpoch = 0,
  });

  final String name;
  final AutographSpec spec;
  final Color ink;

  /// Bump after fonts finish loading to force a repaint with real glyphs.
  final int fontEpoch;

  static const _baseSize = 60.0;

  List<String> get _words => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .toList();

  /// (text, size multiplier) runs for the chosen layout.
  List<(String, double)> _runs() {
    final words = _words;
    if (words.isEmpty) return const [];
    final cap = spec.capitalScale;
    final first = words.first;
    final last = words.last;

    List<(String, double)> word(String w, [double scale = 1]) => [
          (w[0], cap * scale),
          if (w.length > 1) (w.substring(1), 1.0),
        ];

    switch (words.length == 1 ? AutographLayout.full : spec.layout) {
      case AutographLayout.full:
        return [
          for (var i = 0; i < words.length; i++) ...[
            if (i > 0) (' ', 1.0),
            ...word(words[i]),
          ],
        ];
      case AutographLayout.initialAndLast:
        return [(first[0], cap), (' ', 1.0), ...word(last)];
      case AutographLayout.firstAndInitial:
        return [...word(first), (' ', 1.0), (last[0], cap)];
      case AutographLayout.initials:
        return [(first[0], cap * 1.25), (last[0], cap * 1.25)];
      case AutographLayout.joined:
        return [for (final w in words) ...word(w)];
      case AutographLayout.lastOnly:
        return word(last, 1.2);
    }
  }

  TextPainter _textPainter() {
    final runs = _runs();
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      text: TextSpan(
        children: [
          for (final (text, scale) in runs)
            TextSpan(
              text: text,
              style: spec.font
                  .style(fontSize: _baseSize * scale, color: ink)
                  .copyWith(letterSpacing: spec.letterSpacing, height: 1),
            ),
        ],
      ),
    )..layout();
    return tp;
  }

  /// Unscaled drawing bounds, relative to the baseline start of the text.
  Rect _bounds(TextPainter tp) {
    final w = tp.width;
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final descent = tp.height - ascent;
    final fs = _baseSize;
    final swashBelow = spec.swash == AutographSwash.none ? 0.0 : fs * 0.55;
    return Rect.fromLTRB(
      -w * 0.1 - spec.slant * (descent + swashBelow),
      -ascent - fs * 0.05,
      w * 1.14 + spec.slant * ascent,
      math.max(descent, swashBelow) + fs * 0.05,
    );
  }

  /// Size of the autograph at scale 1 (used for export).
  Size get naturalSize {
    final tp = _textPainter();
    final size = _bounds(tp).size;
    tp.dispose();
    return size;
  }

  Path _swashPath(double w) =>
      swashPreviewPath(spec.swash, width: w, height: _baseSize);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = _textPainter();
    if (tp.width == 0) {
      tp.dispose();
      return;
    }
    final bounds = _bounds(tp);
    final scale = math.min(
      size.width / bounds.width,
      size.height / bounds.height,
    );

    canvas.save();
    // Centre the scaled autograph in the canvas.
    canvas.translate(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );
    canvas.scale(scale);
    // Lean forward around the baseline, like handwriting.
    canvas.skew(-spec.slant, 0);

    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(canvas, Offset(0, -ascent));

    final swash = _swashPath(tp.width);
    canvas.drawPath(
      swash,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = _baseSize * 0.04
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();
    tp.dispose();
  }

  @override
  bool shouldRepaint(AutographPainter old) =>
      old.name != name ||
      old.spec != spec ||
      old.ink != ink ||
      old.fontEpoch != fontEpoch;
}

/// Renders the autograph to a tightly-sized transparent PNG.
Future<Uint8List> renderAutographPng({
  required String name,
  required AutographSpec spec,
  required Color ink,
  double pixelRatio = 3,
}) async {
  final painter = AutographPainter(name: name, spec: spec, ink: ink);
  final size = painter.naturalSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size.width * pixelRatio).ceil(),
    (size.height * pixelRatio).ceil(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}
