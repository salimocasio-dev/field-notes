// The sprites balcon.js makes for itself (coqui/ref/sprites/escenas/balcon/), each made again by replaying the call
// that made it in the old page, and compared exactly: every pixel. On the vm against the RGBA bytes, in a browser
// against their hash (test/support/fixtures/balcon_sprite_refs.dart).
//
// The sprites of the lines the set now draws are not the port's (the sheet's `dropped`): the old background bg()
// (balcon.js:121, and the bush it draws at :56) and the three pieces of furniture (balcon.js:127, :135, :136). The bird's
// sprites are kit.js's and the frog juego.js draws is juego.js's (index.json `notDumped`).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/balcon_sprite_refs.dart';
import 'support/hash.dart';
import 'support/ref_files.dart';
import 'support/report.dart';

/// The call that made a sprite, from its key and where the old page made it: null for a sprite of a dropped line.
Sprite Function()? replay(String key, String caller) {
  final line = int.parse(caller.split(':')[1]);
  // dropped: the set draws them
  if (const {56, 121, 127, 135, 136}.contains(line)) return null;
  if (line == 129) {
    // spr("abS"+pose+habla, ()=>KIT.mkAbuelaS(pose, habla, 0))
    final pose = key.substring(3, key.length - 1), habla = key[key.length - 1];
    return () => mkAbuelaS(pose, habla == '1', false);
  }
  if (line == 124) {
    // spr("ab"+pose+habla, ()=>mkAbuela(pose, habla))
    final pose = key.substring(2, key.length - 1), habla = key[key.length - 1];
    return () => mkAbuela(pose, habla == '1');
  }
  if (line == 119) {
    // rana: spr("cq"+q.s+"_"+bl+op, ()=>mkCoqui(q.s, bl, op))
    final m = RegExp(r'^cq([\d.]+)_([01])([01])$').firstMatch(key)!;
    return () => mkCoqui(num.parse(m[1]!), int.parse(m[2]!), m[3] == '1');
  }
  if (key == 'cq.7_0') return () => mkCoqui(.7, 0, false); // tanteo
  throw StateError('no call known for $key ($caller)');
}

void main() {
  final refs = (jsonDecode(balconSpriteRefs) as List)
      .cast<Map<String, dynamic>>();
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
      final bytes = refFile('sprites/escenas/balcon/$key.rgba');
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
  tearDownAll(() => report('balcon-sprites', rows));
}
