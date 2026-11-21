// El banco's set: its seven reached baked states (the sheet's setKey.baked: luz, luna, carro) built by buildSet (the port
// of banco-set.html) against the pictures the page made in headless Chrome (coqui/ref/pp/banco/, made by
// coqui/tool/ref/pp/make.js), as the page's own frame: the bake, then drawLeaves(0) and drawTufts(0). Page
// 11-pixel-engine, decision 2: up to 0.5% of the pixels may differ (El frente's limit).
//
// On the vm each buffer (pix, zb, kinds) is compared element by element with the reference file. In a browser there
// are no files: the hashes of the three buffers are compared with the hashes of the reference files
// (test/support/fixtures/banco_set_refs.dart); equal hashes, 0 elements differ. The vm checks the fixture is the files'.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/banco/banco_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/banco_set_refs.dart';
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
  final refs = (jsonDecode(bancoSetRefs) as List).cast<Map<String, dynamic>>();
  final e = bancoEngine(), b = PpBuild(e);
  final rows = <String>[];

  test('there are 7: the baked states the stories reach (the sheet\'s setKey.baked)', () {
    expect(refs.map((r) => r['id']), [
      'luz-dia-luna-0-carro-abierto',
      'luz-dia-luna-0-carro-no',
      'luz-noche-luna-0-carro-abierto',
      'luz-noche-luna-0-carro-cerrado',
      'luz-noche-luna-0-carro-no',
      'luz-noche-luna-1-carro-abierto',
      'luz-tarde-luna-0-carro-abierto',
    ]);
  });

  for (final r in refs) {
    test('${r['id']}: built by buildSet, within 0.5% of the reference', () {
      final state = BancoState.fromQuery(r['query'] as String);
      final sw = Stopwatch()..start();
      final set = BancoSet(e, b, state)..buildSet();
      final ms = sw.elapsedMicroseconds / 1000;
      // the page's frame at its wind time
      set.frame(bancoTimeOf(r['query'] as String));
      final hashes = {
        'pix': hashOf(e.pix),
        'zb': hashOf(e.zb),
        'kinds': hashOf(e.kinds),
      };
      final pix = refFile('pp/banco/${r['id']}/pix.bin');
      String line;
      if (pix != null) {
        // the vm: the files themselves, and the fixture is theirs
        final zb = refFile('pp/banco/${r['id']}/zb.bin')!;
        final kinds = refFile('pp/banco/${r['id']}/kinds.bin')!;
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
  tearDownAll(() => report('banco-set', rows));
}
