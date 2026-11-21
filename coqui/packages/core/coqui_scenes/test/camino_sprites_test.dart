// The sprites camino.js makes for itself (coqui/ref/sprites/escenas/camino/), each made again by replaying the call that
// made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against
// their hash (test/support/fixtures/camino_sprite_refs.dart).
//
// The sprites of the line the set now draws are not the port's (the sheet's `dropped`): the background fondo()
// (camino.js:95). The biscuit, the guineo, the leash, the lit rings and the shaking leaves are drawn on the canvas, not
// made as sprites: the scene's acts test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/camino/camino.dart'
    show Camino, mkArbusto, mkCaracol, mkGato, mkPajarito;
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/camino_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

final _person = RegExp(r'^pc(luis|carmen)(idle|wave[01]|offer)([01])([01])$');

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws it
  if (line == 95) return null;
  if (line == 76) {
    // spr("ab"+ps+habla, ()=>mkAbuela(ps, habla))
    final pose = key.substring(2, key.length - 1), habla = key[key.length - 1];
    return () => mkAbuela(pose, habla == '1');
  }
  if (line == 77) {
    // spr("pc"+id+pose+habla+(p.sent?1:0), ()=>KIT.mkPersona(QUIEN[id], pose, habla, p.sent))
    final m = _person.firstMatch(key)!;
    return () =>
        mkPersona(Camino.QUIEN[m[1]!]!, m[2]!, m[3] == '1', m[4] == '1');
  }
  if (line == 88) {
    // rana: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    return () => mkCoqui(num.parse(m[1]!), int.parse(m[2]!), m[3] == '1');
  }
  if (key == 'cq.6_0') return () => mkCoqui(.6, 0, false); // respIcon
  if (key == 'cesta') return mkCesta;
  if (key == 'arbusto') return mkArbusto;
  if (key == 'car0' || key == 'car1') return () => mkCaracol(key == 'car1');
  if (key == 'pj0' || key == 'pj1') return () => mkPajarito(key == 'pj1');
  final pe = RegExp(r'^pe([a-z]+)([01])$').firstMatch(key);
  if (pe != null) return () => mkPerro(pe[1]!, pe[2] == '1');
  final gt = RegExp(r'^gt([a-z]+)([01])$').firstMatch(key);
  if (gt != null) return () => mkGato(gt[1]!, gt[2] == '1');
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(caminoSpriteRefs) as List)
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
      final bytes = refFile('sprites/escenas/camino/$file');
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
  test('the sprites of the dropped line are the background only', () {
    expect(
      [
        for (final r in refs)
          if (replay(r['key'] as String, r['caller'] as String) == null)
            r['key'],
      ],
      ['camino0', 'camino1'],
    );
  });
  tearDownAll(() => report('camino-sprites', rows));
}
