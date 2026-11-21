// The sprites banco.js makes for itself (coqui/ref/sprites/escenas/banco/), each made again by replaying the call that
// made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against
// their hash (test/support/fixtures/banco_sprite_refs.dart).
//
// The sprite of the line the set now draws is not the port's (the sheet's `dropped`): the background fondo()
// (banco.js:192). The cart (mkCarro, banco.js:198) is the set's now (moves line 198: standing, the set's part; rolling,
// the set's own pixels): its maker is kept and tested here, but the scene draws it no more. The bubbles, the notes, the
// moods, the extras and the zzz are drawn on the canvas, not made as sprites: the scene's acts test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/banco/banco.dart' show Banco;
import 'package:coqui_scenes/src/banco/banco_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/banco_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

final _person = RegExp(
  r'^pb(luis|carmen|hombre|mujer|senora|senor|joven|piraguero)([a-z]+[01]?)([01])([01])$',
);

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws it (the background, banco.js:192)
  if (line == 192) return null;
  if (line == 158) {
    // spr("pb"+id+pose+habla+(p.sent?1:0), ()=>KIT.mkPersona(w, pose, habla, p.sent))
    final m = _person.firstMatch(key)!;
    return () =>
        mkPersona(Banco.QUIEN[m[1]!]!.who!, m[2]!, m[3] == '1', m[4] == '1');
  }
  if (line == 156) {
    // spr("abS"+ps+habla, ()=>KIT.mkAbuelaS(ps, habla, 0))
    final m = RegExp(r'^abS([a-z]+[01]?)([01])$').firstMatch(key)!;
    return () => mkAbuelaS(m[1]!, m[2] == '1', false);
  }
  if (line == 157) {
    // spr("ab"+ps+habla, ()=>mkAbuela(ps, habla))
    final m = RegExp(r'^ab([a-z]+[01]?)([01])$').firstMatch(key)!;
    return () => mkAbuela(m[1]!, m[2] == '1');
  }
  if (line == 166 || line == 215) {
    // rana, respIcon: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    final s = m[1]!.startsWith('.') ? '0${m[1]}' : m[1]!;
    return () => mkCoqui(num.parse(s), int.parse(m[2]!), m[3] == '1');
  }
  if (line == 83) {
    // cosa: spr("cs"+k, COSA[k]||COSA.bolsa)
    final k = key.substring(2);
    return COSA[k] ?? COSA['bolsa']!;
  }
  if (line == 178) {
    // perro: spr("can"+tp+o.pose+f+(o.pena?1:0), ()=>mkCan(tp, o.pose, f, o.pena))
    final m = RegExp(r'^can(canelo|viejo|joven)([a-z]+)([01])([01])$')
        .firstMatch(key)!;
    return () => mkCan(m[1]!, m[2]!, int.parse(m[3]!), m[4] == '1');
  }
  if (line == 184) {
    // coche: spr("coche"+(o.capota?1:0)+(o.bebe||"")+f, ()=>mkCoche(o.capota, o.bebe, f))
    final m = RegExp(r'^coche([01])([a-z]*)([01])$').firstMatch(key)!;
    return () =>
        mkCoche(m[1] == '1', m[2]!.isEmpty ? null : m[2], int.parse(m[3]!));
  }
  if (line == 200) {
    // the pigeons: spr("pal"+(o.pose||"")+f, ()=>mkPaloma(o.pose, f))
    final m = RegExp(r'^pal([a-z]*)([01])$').firstMatch(key)!;
    return () => mkPaloma(m[1]!.isEmpty ? null : m[1], int.parse(m[2]!));
  }
  if (line == 198) {
    // the cart: spr("carro"+(W.carro==="cerrado"?1:0), ()=>mkCarro(W.carro==="cerrado"))
    final m = RegExp(r'^carro([01])$').firstMatch(key)!;
    return () => mkCarro(m[1] == '1');
  }
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(bancoSpriteRefs) as List)
      .cast<Map<String, dynamic>>();
  final rows = <String>[];
  test('there are 120, the old page\'s', () {
    expect(refs, hasLength(120));
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
      final bytes = refFile('sprites/escenas/banco/$file');
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
  test('the sprite of the dropped line is the background only', () {
    expect(
      [
        for (final r in refs)
          if (replay(r['key'] as String, r['caller'] as String) == null)
            r['key'],
      ],
      ['banco'],
    );
  });
  tearDownAll(() => report('banco-sprites', rows));
}
