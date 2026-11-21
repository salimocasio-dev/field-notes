// The sprites patio.js makes for itself (coqui/ref/sprites/escenas/patio/), each made again by replaying the call that made
// it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against their
// hash (test/support/fixtures/patio_sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the sky cielo(n) (patio.js:129)
// and the background fondo() (patio.js:132). A flower in a bed (florEn), its leaves (the sheet's flowerLeaves), the sun,
// the moon, the stars and the fireflies are drawn on the canvas, not made as sprites: the scene's acts test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/patio/patio.dart'
    show Patio, mkCaja, mkCanasta, mkCosa, mkSaco;
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/patio_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

final _person = RegExp(
  r'^pp(luis|carmen|mama|papa|abuelo)(idle|wave[01]|offer|ojos)([01])([01])$',
);

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws them
  if (const {129, 132}.contains(line)) return null;
  if (line == 100) {
    // spr("ab"+pose+habla, ()=>mkAbuela(pose, habla))
    final pose = key.substring(2, key.length - 1), habla = key[key.length - 1];
    return () => mkAbuela(pose, habla == '1');
  }
  if (line == 99) {
    // spr("bb"+e+(a%2), ()=>KIT.mkBebe(e, a%2))
    final e = key.substring(2, key.length - 1), f = key[key.length - 1];
    return () => mkBebe(e, f == '1');
  }
  if (line == 101) {
    // spr("pp"+id+pose+habla+(p.sent?1:0), ()=>KIT.mkPersona(QUIEN[id], pose, habla, p.sent))
    final m = _person.firstMatch(key)!;
    return () =>
        mkPersona(Patio.QUIEN[m[1]!]!, m[2]!, m[3] == '1', m[4] == '1');
  }
  if (line == 109) {
    // rana: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    return () => mkCoqui(num.parse(m[1]!), int.parse(m[2]!), m[3] == '1');
  }
  if (key == 'cq.6_0') return () => mkCoqui(.6, 0, false); // respIcon
  if (key == 'cq.7_0') return () => mkCoqui(.7, 0, false); // hud
  if (key == 'kaven0') return () => mkAve('n', false); // hud
  if (key == 'caja') return mkCaja;
  if (key == 'canasta') return mkCanasta;
  if (key == 'saco0' || key == 'saco1') return () => mkSaco(key == 'saco1');
  if (line == 76) {
    // cosa: spr("cosa"+k, ()=>mkCosa(k))
    return () => mkCosa(key.substring(4));
  }
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(patioSpriteRefs) as List)
      .cast<Map<String, dynamic>>();
  final rows = <String>[];
  for (final r in refs) {
    final key = r['key'] as String, make = replay(key, r['caller'] as String);
    final file = (r['file'] as String?) ?? '$key.rgba';
    if (make == null) {
      rows.add('$key: not the port\'s (${r['caller']}: dropped)');
      continue;
    }
    test('$key (${r['caller']}): every pixel as the old page made it', () {
      final s = make();
      expect([s.w, s.h], [r['w'], r['h']]);
      final bytes = refFile('sprites/escenas/patio/$file');
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
  test(
    'the sprites of the dropped lines are the sky and the background only',
    () {
      expect(
        [
          for (final r in refs)
            if (replay(r['key'] as String, r['caller'] as String) == null)
              r['key'],
        ],
        [
          'cielo0',
          'cielo1',
          'cielo2',
          'cielo3',
          'cielo4',
          'patio00',
          'patio01',
          'patio10',
          'patio11',
        ],
      );
    },
  );
  tearDownAll(() => report('patio-sprites', rows));
}
