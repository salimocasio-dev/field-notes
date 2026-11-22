// Los estantes' set: its four baked states (the sheet's setKey.baked: anillos 0 or 1, mesa 0 or 1) built by
// EstantesSet.buildSet (the port of estantes-set.html) against the pictures the page made in headless Chrome
// (coqui/ref/pp/estantes/, made by coqui/tool/ref/pp/make.js), as the page's own frame: the bake, then the frame (no wind:
// the set has no tufts, leaves or water). The owner's rule is pixel for pixel; page 11's 0.5% is the outer limit.
//
// On the vm each buffer (pix, zb, kinds) is compared element by element with the reference file. In a browser the hashes
// of the three buffers are compared with the hashes of the reference files (test/support/fixtures/estantes_set_refs.dart).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/estantes/estantes_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/estantes_set_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

int _differ(List<num> a, List<num> b) {
  var n = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) n++;
  }
  return n;
}

void main() {
  final refs = (jsonDecode(estantesSetRefs) as List)
      .cast<Map<String, dynamic>>();
  final e = estantesEngine(), b = PpBuild(e), set = EstantesSet(e, b);
  final rows = <String>[];

  test('there are 4 (the sheet\'s setKey.baked)', () {
    expect(refs, hasLength(4));
  });

  for (final r in refs) {
    test('${r['id']}: built by buildSet, every pixel the reference\'s', () {
      final state = EstantesState.fromQuery(r['query'] as String);
      expect(EstantesState.fromKey(state.key).query, '?${r['query']}');
      final sw = Stopwatch()..start();
      set.buildSet(state);
      final ms = sw.elapsedMicroseconds / 1000;
      set.frame();
      final hashes = {
        'pix': hashOf(e.pix),
        'zb': hashOf(e.zb),
        'kinds': hashOf(e.kinds),
      };
      final pix = refFile('pp/estantes/${r['id']}/pix.bin');
      String line;
      if (pix != null) {
        final zb = refFile('pp/estantes/${r['id']}/zb.bin')!;
        final kinds = refFile('pp/estantes/${r['id']}/kinds.bin')!;
        for (final (k, f) in [('pix', pix), ('zb', zb), ('kinds', kinds)]) {
          expect(
            hashBytes(f),
            r[k],
            reason:
                'the fixture holds the hash of $k.bin: run tool/make_set_fixture.dart',
          );
        }
        final n = e.W * e.H;
        final dp = _differ(
          e.pix,
          Uint32List.view(Uint8List.fromList(pix).buffer),
        );
        final dz = _differ(
          e.zb,
          Float32List.view(Uint8List.fromList(zb).buffer),
        );
        final dk = _differ(e.kinds, kinds);
        line =
            '${r['id']}: pix $dp, zb $dz, kinds $dk of $n differ; bake ${ms.toStringAsFixed(1)} ms';
        expect([dp, dz, dk], [0, 0, 0], reason: line);
      } else {
        final same = [
          for (final k in const ['pix', 'zb', 'kinds'])
            '$k ${hashes[k] == r[k] ? 'equal (0 differ)' : 'NOT equal'}',
        ];
        line =
            '${r['id']}: ${same.join(', ')}; bake ${ms.toStringAsFixed(1)} ms';
        for (final k in const ['pix', 'zb', 'kinds']) {
          expect(hashes[k], r[k], reason: line);
        }
      }
      rows.add(line);
    });
  }
  tearDownAll(() => report('estantes-set', rows));
}
