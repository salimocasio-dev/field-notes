// El cielo's set: all 10 states of the sheet's setKey.baked (`azul`, `nublado`, `gris`, `rosa`, `noche` ×
// `arriba`, `abajo`) built by CieloSet.buildSet (the port of cielo-set.html, on La playa's kit) against the pictures
// the page made in headless Chrome (coqui/ref/pp/cielo/). Every pixel, depth and kind must match 0 of 51,840.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/cielo/cielo_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/cielo_set_refs.dart';
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
  final refs = (jsonDecode(cieloSetRefs) as List).cast<Map<String, dynamic>>();
  final e = cieloEngine(), b = PpBuild(e), set = CieloSet(e, b);
  final rows = <String>[];

  test('there are 10: every state of the sheet\'s setKey.baked', () {
    expect(
      {for (final r in refs) r['id']},
      const {
        'azul-arriba',
        'azul-abajo',
        'nublado-arriba',
        'nublado-abajo',
        'gris-arriba',
        'gris-abajo',
        'rosa-arriba',
        'rosa-abajo',
        'noche-arriba',
        'noche-abajo',
      },
    );
  });

  for (final r in refs) {
    test('${r['id']}: built by buildSet, every pixel the reference\'s', () {
      final state = CieloState.fromQuery(r['query'] as String);
      expect(CieloState.fromKey(state.key).query, '?${r['query']}');
      expect(state.key, r['id']);
      final sw = Stopwatch()..start();
      set.buildSet(state);
      final ms = sw.elapsedMicroseconds / 1000;
      set.frame(0);
      final hashes = {
        'pix': hashOf(e.pix),
        'zb': hashOf(e.zb),
        'kinds': hashOf(e.kinds),
      };
      final pix = refFile('pp/cielo/${r['id']}/pix.bin');
      String line;
      if (pix != null) {
        final zb = refFile('pp/cielo/${r['id']}/zb.bin')!;
        final kinds = refFile('pp/cielo/${r['id']}/kinds.bin')!;
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

  tearDownAll(() => report('cielo_set', rows));
}
