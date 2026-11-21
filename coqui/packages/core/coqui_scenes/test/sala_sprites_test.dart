// The sprites sala.js makes for itself (coqui/ref/sprites/escenas/sala/), each made again by replaying the call that made
// it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser against their
// hash (test/support/fixtures/sala_sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the old background bg()
// (sala.js:107, and the pot it draws at :32), the lamp (:109), the sofa and the armchair (:110) and the low table (:114).
// The scratch canvas `bor` (sala.js:120, W.borroso) holds the last blurred frame of a run: not a fixed sprite (index.json
// says so). `vis` (sala.js:137) is the camera's little window, smoothed down from a person's sprite: made again here as
// the hud makes it, with smoothing on (the sheet's smoothing.places[2]).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/sala/sala.dart' show mkTrozo;
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/sala_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

final _person = RegExp(
  r'^p(abuelo|hermana|hermano|mama|papa)(idle|wave[01]|foto|taza|tu|yo|ojos)([01])([01])(arriba|1)?(z)?$',
);

/// sala.js:137, what the hud makes for the camera's window when it is out of focus: the 5 x 5 canvas filled pale blue,
/// the person's sprite (22 x 23 of it) drawn down onto it with smoothing on.
Sprite visOf(String quien) {
  final t = Sprite(5, 5, Uint32List(25)), x = Ctx(t.px, 5, 5);
  x.fillStyle = hexColour('#BFE0F0');
  x.fillRect(0, 0, 5, 5);
  x.smoothing = true;
  x.drawImageRect(
    mkPersona(FAM[quien]!, 'idle', false, false),
    PX - 11,
    0,
    22,
    23,
    0,
    0,
    5,
    5,
  );
  return t;
}

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line or a
/// scratch canvas.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws them; :120 is the scratch canvas of the blur
  if (const {32, 107, 109, 110, 114, 120}.contains(line)) return null;
  if (line == 88) {
    // spr("ab"+pose+habla, ()=>mkAbuela(pose, habla))
    final pose = key.substring(2, key.length - 1), habla = key[key.length - 1];
    return () => mkAbuela(pose, habla == '1');
  }
  if (line == 87) {
    // spr("bb"+e+(a%2), ()=>KIT.mkBebe(e, a%2))
    final e = key.substring(2, key.length - 1), f = key[key.length - 1];
    return () => mkBebe(e, f == '1');
  }
  if (line == 90) {
    // spr("p"+id+pose+habla+(p.sent?1:0)+(p.gafas||"")+(p.dormido?"z":""), ()=>KIT.mkPersona(w, pose, habla, p.sent))
    final m = _person.firstMatch(key)!;
    final id = m[1]!, gafas = m[5], z = m[6] != null;
    final w = gafas != null || z
        ? FAM[id]!.copyWith(
            gafas: gafas == null ? null : (gafas == '1' ? 1 : gafas),
            dormido: z,
          )
        : FAM[id]!;
    return () => mkPersona(w, m[2]!, m[3] == '1', m[4] == '1');
  }
  if (line == 57 || line == 135) {
    // spr("pf"+id, ()=>KIT.mkPersona(FAM[id], "idle", 0, 0))
    final id = key.substring(2);
    return () => mkPersona(FAM[id]!, 'idle', false, false);
  }
  if (line == 102) {
    // rana: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    return () => mkCoqui(num.parse(m[1]!), int.parse(m[2]!), m[3] == '1');
  }
  if (key == 'cq.5_f') return () => mkCoqui(.5, 0, false); // marco
  if (key == 'cq.7_0') return () => mkCoqui(.7, 0, false); // hud
  if (line == 65) {
    // trozo: spr("trozo"+(mord?1:0), ()=>mkTrozo(mord))
    return () => mkTrozo(key == 'trozo1');
  }
  if (key == 'vis') {
    // the hud's camera window: the last person it showed out of focus in the run that made it (la-foto right: the boy)
    return () => visOf('hermano');
  }
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(salaSpriteRefs) as List)
      .cast<Map<String, dynamic>>();
  final rows = <String>[];
  for (final r in refs) {
    final key = r['key'] as String, make = replay(key, r['caller'] as String);
    final file = (r['file'] as String?) ?? '$key.rgba';
    if (make == null) {
      rows.add(
        '$key: not the port\'s (${r['caller']}: dropped, or a scratch canvas)',
      );
      continue;
    }
    test('$key (${r['caller']}): every pixel as the old page made it', () {
      final s = make();
      expect([s.w, s.h], [r['w'], r['h']]);
      final bytes = refFile('sprites/escenas/sala/$file');
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
  tearDownAll(() => report('sala-sprites', rows));
}
