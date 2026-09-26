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

  /// Circular stamp/seal around monogram initials (multi-word only).
  seal,
}

/// Decorative pen stroke drawn with the name.
enum AutographSwash { none, underline, loopBack, doubleLine, wave, tail }

/// Where the swash flourish sits relative to the name.
enum AutographSwashPosition { below, above, through, beforeAndAfter }

/// Variable stroke width along flourish / connector paths.
enum AutographStrokeTaper { none, thickToThin, thinToThick, thickMiddle }

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
    this.strokeTaper = AutographStrokeTaper.none,
    this.connectedFlow = false,
    this.accentDot = false,
    this.swashPosition = AutographSwashPosition.below,
  });

  final SignatureFont font;
  final AutographLayout layout;
  final AutographSwash swash;

  /// Forward lean (0 = upright).
  final double slant;

  /// How much bigger the leading capitals are than the rest.
  final double capitalScale;
  final double letterSpacing;

  final AutographStrokeTaper strokeTaper;
  final bool connectedFlow;
  final bool accentDot;
  final AutographSwashPosition swashPosition;

  /// Builds a random design. Multi-word names get every layout; a single
  /// word only makes sense as the full word (not seal/initials).
  ///
  /// At most one "extra" effect is enabled per design (connectedFlow,
  /// accentDot, stroke taper, or side swash) so stacked flourishes don't
  /// bury the name. ~45% of designs stay fully clean.
  factory AutographSpec.random(math.Random random, {required bool multiWord}) {
    final fonts = kSignatureFonts
        .where((f) => f.category != SignatureFontCategory.bold)
        .toList();
    final layouts =
        multiWord ? AutographLayout.values : const [AutographLayout.full];
    final layout = layouts[random.nextInt(layouts.length)];

    // Initials / seal alone look unfinished without a flourish.
    final needsFlourish = layout == AutographLayout.initials ||
        layout == AutographLayout.seal;
    final swashes = needsFlourish
        ? AutographSwash.values.where((s) => s != AutographSwash.none).toList()
        : AutographSwash.values;
    final swash = swashes[random.nextInt(swashes.length)];

    // Base position stays legible: below, or occasionally above.
    // `through` is manual-only (too easy to obscure letters).
    var swashPosition = AutographSwashPosition.below;
    if (swash != AutographSwash.none && random.nextDouble() < 0.28) {
      swashPosition = AutographSwashPosition.above;
    }

    var strokeTaper = AutographStrokeTaper.none;
    var connectedFlow = false;
    var accentDot = false;

    // Pick zero or one extra effect (weighted toward none).
    final roll = random.nextDouble();
    if (roll < 0.45) {
      // Clean — no extras.
    } else if (roll < 0.60) {
      connectedFlow = true;
    } else if (roll < 0.74) {
      accentDot = true;
    } else if (roll < 0.88) {
      const tapers = [
        AutographStrokeTaper.thickToThin,
        AutographStrokeTaper.thinToThick,
        AutographStrokeTaper.thickMiddle,
      ];
      strokeTaper = tapers[random.nextInt(tapers.length)];
    } else if (swash != AutographSwash.none) {
      // Side flourishes only when a swash exists to hang them on.
      swashPosition = AutographSwashPosition.beforeAndAfter;
    } else {
      // No swash → fall back to a light accent instead of sides/through.
      accentDot = true;
    }

    return AutographSpec(
      font: fonts[random.nextInt(fonts.length)],
      layout: layout,
      swash: swash,
      slant: 0.06 + random.nextDouble() * 0.26,
      capitalScale: 1.2 + random.nextDouble() * 0.55,
      letterSpacing: -random.nextDouble() * 1.8,
      strokeTaper: strokeTaper,
      connectedFlow: connectedFlow,
      accentDot: accentDot,
      swashPosition: swashPosition,
    );
  }

  AutographSpec copyWith({
    AutographSwash? swash,
    AutographStrokeTaper? strokeTaper,
    bool? connectedFlow,
    bool? accentDot,
    AutographSwashPosition? swashPosition,
  }) =>
      AutographSpec(
        font: font,
        layout: layout,
        swash: swash ?? this.swash,
        slant: slant,
        capitalScale: capitalScale,
        letterSpacing: letterSpacing,
        strokeTaper: strokeTaper ?? this.strokeTaper,
        connectedFlow: connectedFlow ?? this.connectedFlow,
        accentDot: accentDot ?? this.accentDot,
        swashPosition: swashPosition ?? this.swashPosition,
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

extension AutographSwashPositionLabel on AutographSwashPosition {
  String get label => switch (this) {
        AutographSwashPosition.below => 'Below',
        AutographSwashPosition.above => 'Above',
        AutographSwashPosition.through => 'Through',
        AutographSwashPosition.beforeAndAfter => 'Sides',
      };
}

extension AutographStrokeTaperLabel on AutographStrokeTaper {
  String get label => switch (this) {
        AutographStrokeTaper.none => 'Even',
        AutographStrokeTaper.thickToThin => 'Taper',
        AutographStrokeTaper.thinToThick => 'Grow',
        AutographStrokeTaper.thickMiddle => 'Press',
      };
}

/// A small preview path for [swash] at a fixed size — the same shapes
/// [AutographPainter] draws, parameterized for style-picker thumbnails.
Path swashPreviewPath(AutographSwash swash,
    {double width = 48, double height = 48}) {
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
  static const _taperSegments = 28;

  List<String> get _words => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .toList();

  bool get _isSeal {
    final words = _words;
    return words.length > 1 && spec.layout == AutographLayout.seal;
  }

  /// (text, size multiplier) runs for the chosen layout.
  List<(String, double)> _runs() {
    final words = _words;
    if (words.isEmpty) return const [];
    final cap = spec.capitalScale;
    final first = words.first;
    final last = words.last;
    // Single-word names can't use multi-word layouts / seal.
    final layout = words.length == 1
        ? (spec.layout == AutographLayout.joined ||
                spec.layout == AutographLayout.lastOnly
            ? spec.layout
            : AutographLayout.full)
        : spec.layout;

    List<(String, double)> word(String w, [double scale = 1]) => [
          (w[0], cap * scale),
          if (w.length > 1) (w.substring(1), 1.0),
        ];

    switch (layout) {
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
      case AutographLayout.seal:
        // Smaller capitals + generous circle pad so letters never kiss the ring.
        final sealCap = cap * 0.78;
        return [(first[0], sealCap * 1.05), (last[0], sealCap * 1.05)];
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

  /// End point of the last contour of [path], or null if empty.
  Offset? _pathEnd(Path path) {
    Offset? end;
    for (final metric in path.computeMetrics()) {
      if (metric.length <= 0) continue;
      final tangent = metric.getTangentForOffset(metric.length);
      if (tangent != null) end = tangent.position;
    }
    return end;
  }

  /// Accent-dot centre in baseline-relative coords (y=0 at baseline).
  Offset _accentDotCenter(TextPainter tp, double ascent, Path? swashDrawn) {
    final r = _baseSize * 0.035 * (0.85 + spec.capitalScale * 0.08);
    if (swashDrawn != null && spec.swash != AutographSwash.none) {
      final end = _pathEnd(swashDrawn);
      if (end != null) {
        return Offset(end.dx + r * 1.4, end.dy - r * 0.6);
      }
    }
    return Offset(tp.width + r * 2.2, -ascent * 0.55);
  }

  /// Seal circle geometry (baseline-relative).
  (Offset center, double radius)? _sealGeometry(TextPainter tp, double ascent) {
    if (!_isSeal) return null;
    final cx = tp.width / 2;
    final cy = -ascent / 2;
    // Inner padding so initials never touch or clip the ring stroke.
    final pad = _baseSize * 0.52;
    final radius = math.max(tp.width, tp.height) / 2 + pad;
    return (Offset(cx, cy), radius);
  }

  /// Unscaled drawing bounds, relative to the baseline start of the text.
  Rect _bounds(TextPainter tp) {
    final w = tp.width;
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final descent = tp.height - ascent;
    final fs = _baseSize;

    var left = -w * 0.1 - spec.slant * (descent + fs * 0.2);
    var top = -ascent - fs * 0.05;
    var right = w * 1.14 + spec.slant * ascent;
    var bottom = descent + fs * 0.05;

    if (spec.swash != AutographSwash.none) {
      switch (spec.swashPosition) {
        case AutographSwashPosition.below:
          bottom = math.max(bottom, fs * 0.55 + fs * 0.05);
        case AutographSwashPosition.above:
          top = math.min(top, -ascent - fs * 0.55);
        case AutographSwashPosition.through:
          // Soft band under letters (not through glyph bodies).
          bottom = math.max(bottom, fs * 0.5);
        case AutographSwashPosition.beforeAndAfter:
          left = math.min(left, -fs * 0.45);
          right = math.max(right, w + fs * 0.45);
          bottom = math.max(bottom, fs * 0.28);
          top = math.min(top, -ascent - fs * 0.08);
      }
    }

    if (spec.accentDot) {
      final swashPath = spec.swash == AutographSwash.none
          ? null
          : _positionedSwashPath(tp.width, ascent);
      final dot = _accentDotCenter(tp, ascent, swashPath);
      final r = fs * 0.035 * 1.5;
      left = math.min(left, dot.dx - r);
      top = math.min(top, dot.dy - r);
      right = math.max(right, dot.dx + r);
      bottom = math.max(bottom, dot.dy + r);
    }

    final seal = _sealGeometry(tp, ascent);
    if (seal != null) {
      final (c, radius) = seal;
      final strokePad = fs * 0.05;
      left = math.min(left, c.dx - radius - strokePad);
      top = math.min(top, c.dy - radius - strokePad);
      right = math.max(right, c.dx + radius + strokePad);
      bottom = math.max(bottom, c.dy + radius + strokePad);
    }

    if (spec.connectedFlow) {
      // Connectors arc slightly above the baseline.
      top = math.min(top, -fs * 0.12);
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Size of the autograph at scale 1 (used for export).
  Size get naturalSize {
    final tp = _textPainter();
    final size = _bounds(tp).size;
    tp.dispose();
    return size;
  }

  Path _rawSwashPath(double w) =>
      swashPreviewPath(spec.swash, width: w, height: _baseSize);

  /// Swash path transformed into baseline-relative coords for [position].
  Path _positionedSwashPath(double textWidth, double ascent) {
    final raw = _rawSwashPath(textWidth);
    switch (spec.swashPosition) {
      case AutographSwashPosition.below:
        return raw;
      case AutographSwashPosition.above:
        // Mirror vertically and lift above the ascent line.
        final matrix = Matrix4.identity()
          ..translateByDouble(0, -ascent - _baseSize * 0.08, 0, 1)
          ..scaleByDouble(1.0, -1.0, 1.0, 1.0);
        return raw.transform(matrix.storage);
      case AutographSwashPosition.through:
        // Soft under-letter band (manual picker only) — keep clear of glyph bodies.
        final matrix = Matrix4.identity()
          ..translateByDouble(0, _baseSize * 0.06, 0, 1);
        return raw.transform(matrix.storage);
      case AutographSwashPosition.beforeAndAfter:
        return _sideFlourishes(textWidth, ascent);
    }
  }

  Path _sideFlourishes(double textWidth, double ascent) {
    final fs = _baseSize;
    final path = Path();
    // Short flourish before the first character.
    path
      ..moveTo(-fs * 0.38, -ascent * 0.15)
      ..quadraticBezierTo(-fs * 0.18, fs * 0.12, -fs * 0.02, fs * 0.04);
    // Short flourish after the last character.
    path
      ..moveTo(textWidth + fs * 0.02, fs * 0.02)
      ..quadraticBezierTo(
          textWidth + fs * 0.22, fs * 0.18, textWidth + fs * 0.38, -ascent * 0.1);
    return path;
  }

  double _taperFactor(AutographStrokeTaper taper, double t) {
    switch (taper) {
      case AutographStrokeTaper.none:
        return 1;
      case AutographStrokeTaper.thickToThin:
        return 1.35 - t * 0.95;
      case AutographStrokeTaper.thinToThick:
        return 0.4 + t * 0.95;
      case AutographStrokeTaper.thickMiddle:
        final mid = 1 - (t - 0.5).abs() * 2;
        return 0.45 + mid * 0.95;
    }
  }

  Paint _strokePaint(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  /// Draws [path] with optional variable stroke width via sampled segments.
  void _drawPathStroke(
    Canvas canvas,
    Path path, {
    required Color color,
    required double baseWidth,
    AutographStrokeTaper taper = AutographStrokeTaper.none,
  }) {
    if (taper == AutographStrokeTaper.none) {
      canvas.drawPath(path, _strokePaint(color, baseWidth));
      return;
    }
    for (final metric in path.computeMetrics()) {
      if (metric.length <= 0) continue;
      final n = _taperSegments;
      for (var i = 0; i < n; i++) {
        final t0 = i / n;
        final t1 = (i + 1) / n;
        final segment =
            metric.extractPath(metric.length * t0, metric.length * t1);
        final width =
            baseWidth * _taperFactor(taper, (t0 + t1) / 2).clamp(0.25, 1.6);
        canvas.drawPath(segment, _strokePaint(color, width));
      }
    }
  }

  /// Glyph boxes for non-space runs, in baseline-relative coords.
  List<Rect> _runBoxes(TextPainter tp, double ascent) {
    final runs = _runs();
    final boxes = <Rect>[];
    var offset = 0;
    for (final (text, _) in runs) {
      final len = text.length;
      if (text.trim().isEmpty) {
        offset += len;
        continue;
      }
      final glyphBoxes = tp.getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + len),
      );
      if (glyphBoxes.isNotEmpty) {
        var left = glyphBoxes.first.left;
        var right = glyphBoxes.first.right;
        var top = glyphBoxes.first.top;
        var bottom = glyphBoxes.first.bottom;
        for (final b in glyphBoxes.skip(1)) {
          left = math.min(left, b.left);
          right = math.max(right, b.right);
          top = math.min(top, b.top);
          bottom = math.max(bottom, b.bottom);
        }
        // TextPainter paints at (0, -ascent); boxes are relative to that origin.
        boxes.add(Rect.fromLTRB(left, top - ascent, right, bottom - ascent));
      }
      offset += len;
    }
    return boxes;
  }

  void _drawConnectors(Canvas canvas, TextPainter tp, double ascent) {
    final boxes = _runBoxes(tp, ascent);
    if (boxes.length < 2) return;
    final baseWidth = _baseSize * 0.018;
    for (var i = 0; i < boxes.length - 1; i++) {
      final a = boxes[i];
      final b = boxes[i + 1];
      // Join near the baseline (y ≈ 0) with a gentle upward arc.
      final p0 = Offset(a.right - _baseSize * 0.01, 0);
      final p1 = Offset(b.left + _baseSize * 0.01, 0);
      final midX = (p0.dx + p1.dx) / 2;
      final control = Offset(midX, -_baseSize * 0.10);
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(control.dx, control.dy, p1.dx, p1.dy);
      // Always even + lower contrast so connectors never compete with glyphs.
      _drawPathStroke(
        canvas,
        path,
        color: ink.withValues(alpha: 0.55),
        baseWidth: baseWidth,
      );
    }
  }

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

    // Seal ring behind the monogram so initials sit on top.
    final seal = _sealGeometry(tp, ascent);
    if (seal != null) {
      final (center, radius) = seal;
      canvas.drawCircle(
        center,
        radius,
        _strokePaint(ink, _baseSize * 0.045),
      );
    }

    tp.paint(canvas, Offset(0, -ascent));

    if (spec.connectedFlow) {
      _drawConnectors(canvas, tp, ascent);
    }

    Path? drawnSwash;
    if (spec.swash != AutographSwash.none) {
      drawnSwash = _positionedSwashPath(tp.width, ascent);
      final through = spec.swashPosition == AutographSwashPosition.through;
      final color = through ? ink.withValues(alpha: 0.3) : ink;
      _drawPathStroke(
        canvas,
        drawnSwash,
        color: color,
        baseWidth: _baseSize * 0.04,
        taper: spec.strokeTaper,
      );
    }

    if (spec.accentDot) {
      final center = _accentDotCenter(tp, ascent, drawnSwash);
      final r = _baseSize * 0.035;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = ink
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

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
