// La nevera's set: its ten reached baked states (the sheet's setKey.baked: the fridge shut, open or half open, the drawer
// shut or pulled out, the sink empty, with dishwater or juice, the stool there or not) built by buildSet (the port of
// nevera-set.html on the kitchen's kit) against the picture the page made in headless Chrome (coqui/ref/pp/nevera/,
// made by coqui/tool/ref/pp/make.js), as the page's own frame (the baked set: no wind, no water, no shadow cast). Page
// 11-pixel-engine, decision 2: up to 0.5% of the pixels may differ (El frente's limit).
//
// On the vm each buffer (pix, zb, kinds) is compared element by element with the reference file. In a browser there
// are no files: the hashes of the three buffers are compared with the hashes of the reference files
// (test/support/fixtures/nevera_set_refs.dart); equal hashes, 0 elements differ. The vm checks the fixture is the files'.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/nevera/nevera_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/nevera_set_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';
import 'support/fixtures/sheets.dart';

int _differ(List<num> a, List<num> b) {
  var n = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) n++;
  }
  return n;
}

// the folder of a state in coqui/ref/pp/nevera/ (coqui/tool/ref/pp/states.json): nev-<nev>-cajon-<cajon>-pila-<pila>-banco-<b>
String _folder(String key) {
  final p = key.split('.');
  return 'nev-${p[0]}-cajon-${p[1]}-pila-${p[2]}-banco-${p[3]}';
}

void main() {
  final refs = (jsonDecode(neveraSetRefs) as List).cast<Map<String, dynamic>>();
  final sheet = Sheet.parse(sheetTexts['nevera']!);
  final e = neveraEngine(), b = PpBuild(e);
  final rows = <String>[];

  test('there are 10, the baked states of the sheet', () {
    final baked = [for (final s in sheet.setKey!.baked) _folder(s.key!)];
    expect(baked, hasLength(10));
    expect(refs.map((r) => r['id']).toSet(), baked.toSet());
  });

  test('the engine is the sheet\'s', () {
    expect([e.W, e.H, e.S], [sheet.pictureW, sheet.pictureH, sheet.S]);
    expect([e.OX, e.OY], [e.W / 2 + sheet.originX, e.H / 2 + sheet.originY]);
  });

  for (final r in refs) {
    test('${r['id']}: built by buildSet, within 0.5% of the reference', () {
      final state = NeveraState.fromQuery(r['query'] as String);
      expect(_folder(state.key), r['id']);
      expect(NeveraState.fromKey(state.key).key, state.key);
      final sw = Stopwatch()..start();
      NeveraSet(e, b, state).buildSet();
      final ms = sw.elapsedMicroseconds / 1000;
      final hashes = {
        'pix': hashOf(e.pix),
        'zb': hashOf(e.zb),
        'kinds': hashOf(e.kinds),
      };
      final pix = refFile('pp/nevera/${r['id']}/pix.bin');
      String line;
      if (pix != null) {
        // the vm: the files themselves, and the fixture is theirs
        final zb = refFile('pp/nevera/${r['id']}/zb.bin')!;
        final kinds = refFile('pp/nevera/${r['id']}/kinds.bin')!;
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
        expect(dp, lessThanOrEqualTo(n * .005), reason: line);
        expect(dz, lessThanOrEqualTo(n * .005), reason: line);
        expect(dk, lessThanOrEqualTo(n * .005), reason: line);
      } else {
        // a browser: the hashes
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
  tearDownAll(() => report('nevera-set', rows));
}
