// La mesa's set: its three reached baked states (the sheet's setKey.baked: mantel, horno) built by buildSet (the port of
// mesa-set.html, on the kitchen's kit) against the pictures the page made in headless Chrome (coqui/ref/pp/mesa/, made
// by coqui/tool/ref/pp/make.js), as the page's own frame: the bake, no character. Page 11-pixel-engine, decision 2: up to
// 0.5% of the pixels may differ (El frente's limit). Also the still of El colmado's stall the scene keeps for cual-mesa's
// cocina.no (mesaFrutas) against the picture frutas-set.html?surtido=frutas made (coqui/ref/pp/mesa/frutas-surtido-frutas).
//
// The states are baked one after another on one engine, as the scene bakes them (the floor, and the patio seen through
// the doorway, are laid once per engine), and again each on an engine of its own.
//
// On the vm each buffer (pix, zb, kinds) is compared element by element with the reference file. In a browser there
// are no files: the hashes of the three buffers are compared with the hashes of the reference files
// (test/support/fixtures/mesa_set_refs.dart); equal hashes, 0 elements differ. The vm checks the fixture is the files'.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/mesa/mesa_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/mesa_set_refs.dart';
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
  final all = (jsonDecode(mesaSetRefs) as List).cast<Map<String, dynamic>>();
  final refs = [
    for (final r in all)
      if (r['id'] != 'frutas-surtido-frutas') r,
  ];
  final still = all.firstWhere((r) => r['id'] == 'frutas-surtido-frutas');
  final shared = mesaEngine(), sharedB = PpBuild(shared);
  final rows = <String>[];

  test('there are 3: the baked states the stories reach (the sheet\'s setKey.baked)', () {
    expect(refs.map((r) => r['id']), ['m0h0', 'm0h1', 'm1h0']);
  });

  for (final own in [false, true]) {
    for (final r in refs) {
      test('${r['id']}${own ? ' (an engine of its own)' : ''}: built by buildSet, within 0.5% of the reference', () {
        final e = own ? mesaEngine() : shared, b = own ? PpBuild(e) : sharedB;
        final state = MesaState.fromQuery(r['query'] as String);
        expect(state.key, r['id']);
        final sw = Stopwatch()..start();
        final set = MesaSet(e, b, state)..buildSet();
        final ms = sw.elapsedMicroseconds / 1000;
        set.frame(0);
        final hashes = {
          'pix': hashOf(e.pix),
          'zb': hashOf(e.zb),
          'kinds': hashOf(e.kinds),
        };
        final pix = refFile('pp/mesa/${r['id']}/pix.bin');
        String line;
        if (pix != null) {
          final zb = refFile('pp/mesa/${r['id']}/zb.bin')!;
          final kinds = refFile('pp/mesa/${r['id']}/kinds.bin')!;
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
              '${r['id']}${own ? ' (own engine)' : ''}: pix $dp, zb $dz, kinds $dk of $n differ; bake ${ms.toStringAsFixed(1)} ms';
          expect(dp, lessThanOrEqualTo(n * .005), reason: line);
          expect(dz, lessThanOrEqualTo(n * .005), reason: line);
          expect(dk, lessThanOrEqualTo(n * .005), reason: line);
        } else {
          final same = [
            for (final k in const ['pix', 'zb', 'kinds'])
              '$k ${hashes[k] == r[k] ? 'equal (0 differ)' : 'NOT equal'}',
          ];
          line =
              '${r['id']}${own ? ' (own engine)' : ''}: ${same.join(', ')}; bake ${ms.toStringAsFixed(1)} ms';
          for (final k in const ['pix', 'zb', 'kinds']) {
            expect(hashes[k], r[k], reason: line);
          }
        }
        rows.add(line);
      });
    }
  }

  test('the still of El colmado\'s stall (cocina.no) is the picture frutas-set.html?surtido=frutas made', () {
    final px = mesaFrutas();
    expect(px.length, 240 * 216);
    expect(hashOf(px), still['pix']);
    final f = refFile('pp/mesa/frutas-surtido-frutas/pix.bin');
    if (f != null) {
      expect(hashBytes(f), still['pix']);
      expect(_differ(px, Uint32List.view(Uint8List.fromList(f).buffer)), 0);
    }
    rows.add(
      'frutas-surtido-frutas (the still): pix ${hashOf(px) == still['pix'] ? 'equal (0 differ)' : 'NOT equal'}',
    );
  });
  tearDownAll(() => report('mesa-set', rows));
}
