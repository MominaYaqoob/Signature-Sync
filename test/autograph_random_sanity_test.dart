import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:signature_sync/widgets/autograph_painter.dart';

void main() {
  test('random designs: at most one extra effect; through never auto-picked',
      () {
    final random = math.Random(42);
    var clean = 0;
    for (var i = 0; i < 10; i++) {
      final s = AutographSpec.random(random, multiWord: true);
      final extras = <String>[];
      if (s.connectedFlow) extras.add('flow');
      if (s.accentDot) extras.add('dot');
      if (s.strokeTaper != AutographStrokeTaper.none) extras.add('taper');
      if (s.swashPosition == AutographSwashPosition.beforeAndAfter) {
        extras.add('sides');
      }
      expect(s.swashPosition, isNot(AutographSwashPosition.through));
      expect(extras.length, lessThanOrEqualTo(1),
          reason: 'design $i stacked ${extras.join("+")}');
      if (extras.isEmpty) clean++;
      // ignore: avoid_print
      print(
        '${i + 1}. ${s.font.family} | ${s.layout.name} | '
        'swash=${s.swash.name} pos=${s.swashPosition.name} | '
        'extras=${extras.isEmpty ? "none" : extras.join("+")}',
      );
    }
    expect(clean, greaterThanOrEqualTo(3),
        reason: 'expected several clean designs in a sample of 10');
  });

  test('batch de-dup: 6 designs have unique font+layout when possible', () {
    final random = math.Random(7);
    final used = <String>{};
    final designs = <AutographSpec>[];
    var attempts = 0;
    while (designs.length < 6 && attempts < 144) {
      attempts++;
      final s = AutographSpec.random(random, multiWord: true);
      final key = '${s.font.family}|${s.layout.name}';
      if (used.contains(key)) continue;
      used.add(key);
      designs.add(s);
    }
    expect(designs.length, 6);
    expect(used.length, 6);
  });
}
