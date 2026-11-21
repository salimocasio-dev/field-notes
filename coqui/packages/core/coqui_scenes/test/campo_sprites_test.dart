// The sprites campo.js makes for itself (coqui/ref/sprites/escenas/campo/), each made again by replaying the call that
// made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against
// their hash (test/support/fixtures/campo_sprite_refs.dart).
//
// The sprite of the line the set now draws is not the port's (the sheet's `dropped`): the background fondo()
// (campo.js:96). The flower, the butterfly, the splashes, the drops, the frog's puddle, the darkness of his shut eyes and
// the ripple rings are drawn on the canvas, not made as sprites: the scene's acts test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/campo/campo.dart' show Campo, mkBola;
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/campo_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

final _person = RegExp(r'^pc(luis|carmen)([a-z]+[01]?)([01])$');

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws it
  if (line == 96) return null;
  if (line == 73) {
    // spr("pc"+id+pose+habla, ()=>KIT.mkPersona(QUIEN[id], pose, habla, 0))
    final m = _person.firstMatch(key)!;
    return () => mkPersona(Campo.QUIEN[m[1]!]!, m[2]!, m[3] == '1', false);
  }
  if (line == 87) {
    // rana: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    return () => mkCoqui(num.parse(m[1]!), int.parse(m[2]!), m[3] == '1');
  }
  if (key == 'cq.6_0') return () => mkCoqui(.6, 0, false); // respIcon
  if (key == 'cesta') return mkCesta;
  final bola = RegExp(r'^bola([LCq])$').firstMatch(key);
  if (bola != null) return () => mkBola(bola[1]!);
  final pe = RegExp(r'^pe([a-z]+)([01])$').firstMatch(key);
  if (pe != null) return () => mkPerro(pe[1]!, pe[2] == '1');
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(campoSpriteRefs) as List)
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
      final bytes = refFile('sprites/escenas/campo/$file');
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
      ['campo'],
    );
  });
  tearDownAll(() => report('campo-sprites', rows));
}
