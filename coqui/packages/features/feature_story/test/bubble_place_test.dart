// juego.js placeBub: where a speech bubble stands over the picture. Expected values: the old function's formulas run in node
// (tool/ref/placebub.mjs, test/fixtures/placebub.json).
import 'dart:convert';
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases = (jsonDecode(File('test/fixtures/placebub.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();

  test('the 11 cases of the old function', () {
    for (var i = 0; i < cases.length; i++) {
      final c = cases[i]['in'] as Map<String, dynamic>, want = cases[i]['out'] as Map<String, dynamic>?;
      final who = c['who'] as String;
      BubblePlacement? got;
      if (who == 'mic') {
        final mr = c['mr'] as Map<String, dynamic>, sr = c['sr'] as Map<String, dynamic>;
        got = placeAboveMic(
          MicAnchor(
            cx: ((mr['left'] as num) + (mr['width'] as num) / 2 - (sr['left'] as num)).toDouble(),
            top: ((mr['top'] as num) - (sr['top'] as num)).toDouble(),
            viewLeft: -(sr['left'] as num).toDouble(),
            viewRight: ((c['innerWidth'] as num) - (sr['left'] as num)).toDouble(),
          ),
          (c['bw'] as num).toDouble(),
        );
      } else {
        final q = (c['q'] as Map).cast<String, dynamic>();
        got = placeBubble(
          who: who,
          cam: (c['cam'] as List).cast<num>(),
          cw: (c['cw'] as num).toDouble(),
          ch: (c['ch'] as num).toDouble(),
          bw: (c['bw'] as num).toDouble(),
          bh: (c['bh'] as num).toDouble(),
          frog: frogBox(q),
          frogDy: q['dy'] as num,
          at: (c['at'] as List?)?.cast<num>(),
        );
      }
      if (want == null) {
        expect(got, isNull, reason: 'case $i');
        continue;
      }
      expect(got, isNotNull, reason: 'case $i');
      expect(got!.left, want['left'], reason: 'case $i left');
      expect(got.top, want['top'], reason: 'case $i top');
      expect(got.mode.name, switch (want['mode']) { 'above' => 'above', 'right' => 'right', _ => 'left' }, reason: 'case $i mode');
      expect(got.maxWidth, want['maxWidth']?.toDouble(), reason: 'case $i maxWidth');
      expect(got.tail, want['tail']?.toDouble(), reason: 'case $i tail');
    }
  });

  test('a speaker that cannot be seen: no bubble', () {
    expect(
      placeBubble(who: 'abuela', cam: const [0, 0, 196, 216], cw: 380, ch: 419, bw: 100, bh: 40, frog: frogBox({'x': 150, 'y': 178, 's': 1}), frogDy: 0, at: null),
      isNull,
    );
    expect(placeAboveMic(null, 56), isNull);
  });
}
