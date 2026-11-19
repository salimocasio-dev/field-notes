// The map's island with no places (ground, slabSides, growGrass, decorate), built with mapa.js's calls in the
// order coqui/ref/pp/island/calls.md gives, against the picture the old code made in Chrome. Page 11-pixel-engine,
// decision 2: up to 0.5% of the pixels may differ; more is a porting bug.
//
// The build runs once, when the file loads, so each test's name can carry its measured number: it shows in the
// test report on the vm and in chrome.
import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/compare.dart';
import 'support/island_build.dart';
import 'support/ref_data.dart';

void main() {
  final state =
      jsonDecode(refText('island/state.json')) as Map<String, dynamic>;
  final eng = state['engine'] as Map<String, dynamic>;
  final e = PpEngine(
    w: eng['W'] as int,
    h: eng['H'] as int,
    s: (eng['S'] as num).toDouble(),
    originX: (eng['originX'] as num).toDouble(),
    originY: (eng['originY'] as num).toDouble(),
    shadowX: (eng['SHADOW_X'] as num).toDouble(),
    shadowY: (eng['SHADOW_Y'] as num).toDouble(),
    still: eng['STILL'] as bool,
  );
  final island = IslandBuild(e, PpBuild(e));
  final calls = <DecorateCall>[];
  island.build(calls.add);

  final pix = diffExact(e.pix, readU32(refBytes('island/pix.bin')));
  final zb = diffExact(e.zb, readF32(refBytes('island/zb.bin')));
  final kinds = diffExact(e.kinds, refBytes('island/kinds.bin'));

  test('the build counts what the old one counted', () {
    final counts = state['counts'] as Map<String, dynamic>;
    expect(e.tufts, hasLength(counts['tufts'] as int));
    expect(island.waterPix.length ~/ 4, counts['waterPix'] as int);
    expect(e.leaves, hasLength(counts['leaves'] as int));
    expect(calls, hasLength(state['decorateCalls'] as int));
  });

  test('decorate makes the calls decorate-calls.json lists, in order', () {
    final want = (jsonDecode(refText('island/decorate-calls.json')) as List)
        .cast<Map<String, dynamic>>();
    expect(calls, hasLength(want.length));
    for (var n = 0; n < want.length; n++) {
      final at = 'call ${n + 1}, ${want[n]['fn']}';
      expect(calls[n].fn, want[n]['fn'], reason: at);
      final got = calls[n].args, args = want[n]['args'] as List;
      expect(got, hasLength(args.length), reason: at);
      for (var k = 0; k < args.length; k++) {
        if (args[k] is num) {
          // hash() uses Math.sin, which differs between engines in its last digits
          expect(
            got[k] as num,
            closeTo(args[k] as num, 1e-9),
            reason: '$at, argument $k',
          );
        } else {
          expect(got[k], args[k], reason: '$at, argument $k');
        }
      }
    }
  });

  // Page 11-pixel-engine, decision 2: "up to 0.5% of pixels"
  const limit = 0.5;
  test('pix: ${pix.text} differ, limit $limit%', () {
    expect(
      pix.percent,
      lessThanOrEqualTo(limit),
      reason: 'first ones:\n${pix.first.join('\n')}',
    );
  });
  test('zb: ${zb.text} differ, limit $limit%', () {
    expect(
      zb.percent,
      lessThanOrEqualTo(limit),
      reason: 'first ones:\n${zb.first.join('\n')}',
    );
  });
  test('kinds: ${kinds.text} differ, limit $limit%', () {
    expect(
      kinds.percent,
      lessThanOrEqualTo(limit),
      reason: 'first ones:\n${kinds.first.join('\n')}',
    );
  });
}
