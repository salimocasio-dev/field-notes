// The sprites lago.js makes for itself (coqui/ref/sprites/escenas/lago/), each made again by replaying the call that
// made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against
// their hash (test/support/fixtures/lago_sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the background fondo()
// (lago.js:112) and the old reeds mkJunco (lago.js:116). The flower, the sack, the splashes, the water lines, the brush,
// the ripple rings and the fish's patch are drawn on the canvas, not made as sprites: the scene's acts test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/lago/lago.dart'
    show Lago, mkBolsa, mkBote, mkPajaro, mkPan, mkPato, mkPez, mkPote;
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/lago_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

final _person = RegExp(r'^pc(luis|carmen)([a-z]+[01]?)([01])([01])$');

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws them (the background, lago.js:112; the old reeds, lago.js:116)
  if (line == 112 || line == 116) return null;
  if (line == 90) {
    // spr("pc"+id+pose+habla+(p.sent?1:0), ()=>KIT.mkPersona(QUIEN[id], pose, habla, p.sent))
    final m = _person.firstMatch(key)!;
    return () => mkPersona(Lago.QUIEN[m[1]!]!, m[2]!, m[3] == '1', m[4] == '1');
  }
  if (line == 107) {
    // rana: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    return () => mkCoqui(num.parse(m[1]!), int.parse(m[2]!), m[3] == '1');
  }
  if (key == 'pan') return mkPan;
  if (key == 'bolsa') return mkBolsa;
  final pt = RegExp(r'^pt(blanco|negro|amarillo)(nada|vuela|anda)([01])$')
      .firstMatch(key);
  if (pt != null) return () => mkPato(pt[1]!, pt[2]!, int.parse(pt[3]!));
  final pz = RegExp(r'^pz([a-z]+)$').firstMatch(key);
  if (pz != null) return () => mkPez(pz[1]!);
  final pj = RegExp(r'^pj([a-z]+)([01])([01])$').firstMatch(key);
  if (pj != null) {
    return () => mkPajaro(pj[1]!, int.parse(pj[2]!), int.parse(pj[3]!));
  }
  final bt = RegExp(r'^bt([a-z]+)$').firstMatch(key);
  if (bt != null) return () => mkBote(bt[1]!);
  final po = RegExp(r'^po([a-z]+)$').firstMatch(key);
  if (po != null) return () => mkPote(po[1]!);
  final pe = RegExp(r'^pe([a-z]+)([01])$').firstMatch(key);
  if (pe != null) return () => mkPerro(pe[1]!, pe[2] == '1');
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(lagoSpriteRefs) as List)
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
      final bytes = refFile('sprites/escenas/lago/$file');
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
  test('the sprites of the dropped lines are the background and the old reeds only', () {
    expect(
      [
        for (final r in refs)
          if (replay(r['key'] as String, r['caller'] as String) == null)
            r['key'],
      ],
      ['jn0', 'jn1', 'jn2', 'jn3', 'jn4', 'lago'],
    );
  });
  tearDownAll(() => report('lago-sprites', rows));
}
