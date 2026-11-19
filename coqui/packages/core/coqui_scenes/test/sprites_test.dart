// The sprites frente.js makes for itself (coqui/ref/sprites/escenas/frente/), each made again by replaying the call
// that made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser
// against their hash (test/support/fixtures/sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the old background bg()
// (frente.js:140, and the palm, the bush and the pot it draws at :42) and the small palm and the birdhouse
// (frente.js:97, :100). The frogs juego.js draws are juego.js's (index.json `notDumped`).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart' hide mkAve;
import 'package:coqui_scenes/src/frente/frente.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  if (const {42, 97, 100, 140}.contains(line))
    return null; // dropped: the set draws them
  if (line == 139) {
    // AB(pose, op): spr("ab"+pose+op, ()=>mkAbuela(pose, op))
    final pose = key.substring(2, key.length - 1), op = key[key.length - 1];
    return () => mkAbuela(pose, op == '1');
  }
  if (line == 82) {
    // drawAve: spr("ave"+st+fl, ()=>mkAve(st==="round"?"round":st, fl))
    final st = key.substring(3, key.length - 1),
        fl = int.parse(key[key.length - 1]);
    return () => mkAve(st == 'round' ? 'round' : st, fl);
  }
  if (key == 'cloud') return mkCloud; // ambient: spr("cloud", mkCloud)
  if (key == 'nube') return mkNube; // draw: spr("nube", mkNube)
  if (key.startsWith('cq.42_')) {
    final bl = int.parse(
      key.substring(6),
    ); // spr("cq.42_"+bl, ()=>mkCoqui(.42, bl, 0))
    return () => mkCoqui(.42, bl, false);
  }
  if (key == 'cq.6_0') return () => mkCoqui(.6, 0, false);
  if (key == 'cq.7_0') return () => mkCoqui(.7, 0, false); // plato
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(spriteRefs) as List).cast<Map<String, dynamic>>();
  final rows = <String>[];
  for (final r in refs) {
    final key = r['key'] as String, make = replay(key, r['caller'] as String);
    if (make == null) {
      rows.add('$key: dropped (the set draws it: ${r['caller']})');
      continue;
    }
    test('$key (${r['caller']}): every pixel as the old page made it', () {
      final s = make();
      expect([s.w, s.h], [r['w'], r['h']]);
      final bytes = refFile('sprites/escenas/frente/$key.rgba');
      if (bytes != null) {
        expect(
          hashBytes(bytes),
          r['hash'],
          reason: 'run tool/make_sprite_fixture.dart',
        );
        final want = Uint32List.view(Uint8List.fromList(bytes).buffer);
        var n = 0;
        for (var i = 0; i < want.length; i++) {
          if (want[i] != s.px[i]) n++;
        }
        rows.add('$key: $n of ${want.length} pixels differ');
        expect(n, 0);
      } else {
        final same = hashOf(s.px) == r['hash'];
        rows.add('$key: ${same ? 'hash equal (0 differ)' : 'hash NOT equal'}');
        expect(same, isTrue);
      }
    });
  }
  tearDownAll(() => report('sprites', rows));
}
