// The sprites comer.js makes for itself (coqui/ref/sprites/escenas/comer/), each made again by replaying the call that
// made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against
// their hash (test/support/fixtures/comer_sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the background fondo()
// (comer.js:549) and the old table (comer.js:552, `spr("mesa", mkMesa)`). The steam, the streams, the long spoons, the
// arms and hands, the thought clouds and the rounds card are drawn on the canvas, not made as sprites: the scene's acts
// test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/comer/comer_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/comer_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

// comer.js COSA's kinds, longest first (a sprite's key is "cm" + kind + variant)
final _kinds = [...COSA.keys]..sort((a, b) => b.length.compareTo(a.length));

final _person = RegExp(
  r'^pmN(luis|carmen|abuelo|mama|papa)([01])([01])([012])(c?)(feliz|asco)?(-?\d+)?$',
);

// the kind a key names after its prefix, and the rest (the variant)
(String, String)? _kind(String rest) {
  for (final k in _kinds) {
    if (rest.startsWith(k)) return (k, rest.substring(k.length));
  }
  return null;
}

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws them (the background, comer.js:549; the old table, comer.js:552)
  if (line == 549 || line == 552) return null;
  final pm = _person.firstMatch(key);
  if (pm != null) {
    // spr("pmN"+id+op+(p.sent?1:0)+pie+(p.cierra?"c":"")+(cf?p.cara:"")+(gi||""), ()=>mkPersonaN(w2, op, p.sent, pie))
    final w = QUIEN[pm[1]!]!;
    return () => mkPersonaN(
      w,
      pm[2] == '1',
      pm[3] == '1',
      int.parse(pm[4]!),
      dormido: pm[5] == 'c',
      cara: pm[6],
      giro: pm[7] == null ? 0 : int.parse(pm[7]!),
    );
  }
  final ab = RegExp(r'^abN([01])([012])$').firstMatch(key);
  if (ab != null) {
    return () =>
        recolor(mkAbuelaN(ab[1] == '1', int.parse(ab[2]!)), APRON);
  }
  final abs = RegExp(r'^abSN([01])$').firstMatch(key);
  if (abs != null) return () => recolor(mkAbuelaSN(abs[1] == '1'), APRON);
  final cq = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key);
  if (cq != null) {
    return () => mkCoqui(num.parse(cq[1]!), int.parse(cq[2]!), cq[3] == '1');
  }
  final cai = RegExp(r'^cqcai(\d)$').firstMatch(key);
  if (cai != null) {
    return () => giro(mkCoqui(1, 0, false), int.parse(cai[1]!) * .75);
  }
  final esp = RegExp(r'^cqesp([01])$').firstMatch(key);
  if (esp != null) return () => mkRanaEsp(esp[1] == '1');
  final pe = RegExp(r'^pe([a-z]+)([01])$').firstMatch(key);
  if (pe != null) return () => mkPerro(pe[1]!, pe[2] == '1');
  // spr("cmg"+it.k+(it.v==null?"":it.v)+it.ang, ()=>giro(cosa(it.k,it.v),it.ang)); "cmgrano" is "cm" + "grano"
  final g = RegExp(r'^cmg(.*?)(-?0\.\d+)$').firstMatch(key);
  final gk = g == null ? null : _kind(g[1]!);
  if (g != null && gk != null) {
    return () => giro(
      cosaIm(gk.$1, gk.$2.isEmpty ? null : gk.$2),
      double.parse(g[2]!),
    );
  }
  if (key.startsWith('cm')) {
    final rest = key.substring(2);
    final tilt = rest.startsWith('tilt');
    final kv = _kind(tilt ? rest.substring(4) : rest);
    if (kv != null) {
      return () => cosaIm(
        tilt ? 'tilt${kv.$1}' : kv.$1,
        kv.$2.isEmpty ? null : kv.$2,
      );
    }
  }
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(comerSpriteRefs) as List)
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
      final bytes = refFile('sprites/escenas/comer/$file');
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
      ['comer', 'mesa'],
    );
  });
  tearDownAll(() => report('comer-sprites', rows));
}
