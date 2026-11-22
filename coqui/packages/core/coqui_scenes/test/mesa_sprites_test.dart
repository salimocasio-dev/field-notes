// The sprites mesa.js makes for itself (coqui/ref/sprites/escenas/mesa/), each made again by replaying the call that
// made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against
// their hash (test/support/fixtures/mesa_sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the background fondo()
// (mesa.js:156) and the old table mkMesa() (mesa.js:171). The bubbles, the thoughts, the steam and the pulled cloth are
// drawn on the canvas, not made as sprites: the scene's acts test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/mesa/mesa.dart' show Mesa;
import 'package:coqui_scenes/src/mesa/mesa_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/mesa_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

final _person = RegExp(
  r'^pm(luis|carmen|abuelo|mama|papa)([a-z]+[01]?)([01])([01])$',
);

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws them (the background, mesa.js:156; the old table, mesa.js:171)
  if (line == 156 || line == 171) return null;
  if (line == 141) {
    // spr("pm"+id+pose+habla+(p.sent?1:0), ()=>KIT.mkPersona(w, pose, habla, p.sent))
    final m = _person.firstMatch(key)!;
    return () => mkPersona(Mesa.QUIEN[m[1]!]!, m[2]!, m[3] == '1', m[4] == '1');
  }
  if (line == 137) {
    // spr("ab"+ps+habla, ()=>mkAbuela(ps, habla))
    final m = RegExp(r'^ab([a-z]+[01]?)([01])$').firstMatch(key)!;
    return () => mkAbuela(m[1]!, m[2] == '1');
  }
  if (line == 143) {
    // spr("bb"+e+(a%2), ()=>KIT.mkBebe(e, a%2))
    final m = RegExp(r'^bb([a-z]+)([01])$').firstMatch(key)!;
    return () => mkBebe(m[1]!, m[2] == '1');
  }
  if (line == 152) {
    // rana: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    final s = m[1]!.startsWith('.') ? '0${m[1]}' : m[1]!;
    return () => mkCoqui(num.parse(s), int.parse(m[2]!), m[3] == '1');
  }
  if (line == 101) {
    // cosa: spr("ms"+k+(c==null?"":c), ()=>(COSA[k]||COSA.plato)(c))
    final rest = key.substring(2);
    if (rest.startsWith('tabla')) {
      return () => COSA['tabla']!(int.parse(rest.substring(5)));
    }
    if (rest.startsWith('mancha')) {
      return () => COSA['mancha']!(rest.substring(6));
    }
    return () => (COSA[rest] ?? COSA['plato']!)(null);
  }
  if (line == 175) {
    // perro: spr("pe"+o.pose+f, ()=>mkPerro(o.pose, f))
    final m = RegExp(r'^pe([a-z]+)([01])$').firstMatch(key)!;
    return () => mkPerro(m[1]!, m[2] == '1');
  }
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(mesaSpriteRefs) as List)
      .cast<Map<String, dynamic>>();
  final rows = <String>[];
  test('there are 79, the old page\'s', () {
    expect(refs, hasLength(79));
  });
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
      final bytes = refFile('sprites/escenas/mesa/$file');
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
  test('the sprites of the dropped lines are the background and the old table only', () {
    expect(
      [
        for (final r in refs)
          if (replay(r['key'] as String, r['caller'] as String) == null)
            r['key'],
      ],
      ['cocina', 'mesa0', 'mesa1'],
    );
  });
  tearDownAll(() => report('mesa-sprites', rows));
}
