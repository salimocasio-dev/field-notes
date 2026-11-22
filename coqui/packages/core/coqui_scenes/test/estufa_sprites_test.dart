// The sprites estufa.js makes for itself (coqui/ref/sprites/escenas/estufa/), each made again by replaying the call that
// made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against
// their hash (test/support/fixtures/estufa_sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the background fondo()
// (estufa.js:133) and the old stool (estufa.js:154, `cosa("banco")`). The flames, the steam and smoke, the smell's curve,
// the thought clouds and the rounds card are drawn on the canvas, not made as sprites: the scene's acts test draws them.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/estufa/estufa.dart' show Estufa;
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/estufa_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

// estufa.js COSA's kinds, longest first (a sprite's key is "es" + kind + variant)
const _kinds = [
  'espumadera',
  'vasochoco',
  'molinillo',
  'monticulo',
  'mantelito',
  'vasoagua',
  'espatula',
  'cucharon',
  'cucharac',
  'fritura',
  'quemada',
  'platito',
  'fuentec',
  'bandeja',
  'medida',
  'basura',
  'monton',
  'espuma',
  'pinzas',
  'salero',
  'frasco',
  'granon',
  'cuenco',
  'platoc',
  'platof',
  'sarten',
  'fuente',
  'frito',
  'muslo',
  'huevo',
  'grano',
  'tazon',
  'jarra',
  'plato',
  'banco',
  'olla',
  'saco',
  'taza',
  'masa',
  'cubo',
];

final _person = RegExp(
  r'^pm(luis|carmen|abuelo|mama|papa)([a-z]+[01]?)([01])0(c?)$',
);

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws them (the background, estufa.js:133; the old stool, estufa.js:154)
  if (line == 133 || key == 'esbanco') return null;
  final pm = _person.firstMatch(key);
  if (pm != null) {
    // spr("pm"+id+pose+habla+"0"+(p.cierra?"c":""), ()=>KIT.mkPersona(w2, pose, habla, 0))
    final w = Estufa.QUIEN[pm[1]!]!;
    return () => mkPersona(
      pm[4] == 'c' ? w.copyWith(dormido: true) : w,
      pm[2]!,
      pm[3] == '1',
      false,
    );
  }
  final ab = RegExp(r'^ab([a-z]+[01]?)([01])$').firstMatch(key);
  if (ab != null) return () => mkAbuela(ab[1]!, ab[2] == '1');
  final bb = RegExp(r'^bb([a-z]+)([01])$').firstMatch(key);
  if (bb != null) return () => mkBebe(bb[1]!, bb[2] == '1');
  final cq = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key);
  if (cq != null) {
    return () => mkCoqui(num.parse(cq[1]!), int.parse(cq[2]!), cq[3] == '1');
  }
  if (key.startsWith('es')) {
    final rest = key.substring(2);
    for (final k in _kinds) {
      if (rest.startsWith(k)) {
        final v = rest.substring(k.length);
        return () => Estufa.cosaMake(k, v.isEmpty ? null : v);
      }
    }
  }
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(estufaSpriteRefs) as List)
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
      final bytes = refFile('sprites/escenas/estufa/$file');
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
  test('the sprites of the dropped lines are the background and the old stool only', () {
    expect(
      [
        for (final r in refs)
          if (replay(r['key'] as String, r['caller'] as String) == null)
            r['key'],
      ],
      ['esbanco', 'estufa'],
    );
  });
  tearDownAll(() => report('estufa-sprites', rows));
}
