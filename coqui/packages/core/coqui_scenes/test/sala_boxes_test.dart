// La sala's touch boxes. (1) Every thing of the set lies inside its touch box: in each of the 5 states, each pixel the
// set's part for that thing drew (set-kit.js `part`) is inside its box (the sheet's things.<id>.box, as its code for
// sala.js lines 82 and 83 gives it). (2) The cake lies inside its box at points.bizcocho, covered and with every number of
// slices; each person lies inside caja(id) (relative to where they stand: the sheet keeps it) at their places, standing
// and sitting. (3) hit, in the kit's order, returns each thing's key at the middle of its box wherever it shows (the 5
// states, the review pictures, the kept moments of the recorded runs), but where the old order gives the point to a
// thing tested before it; those are listed in [shadowedBy] (the numbers go to the report).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/sala/sala.dart';
import 'package:coqui_scenes/src/sala/sala_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/sala_preview_fixture.dart';
import 'support/fixtures/sala_set_refs.dart';
import 'support/report.dart';
import 'support/sala_preview_remap.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (sala-set.html: `part(name, ...)`). The floor (`sala`) is the
/// ground, no part: its box is the old floor's (the sheet's things.sala.what).
const Map<String, List<String>> partsOf = {
  'mesita': ['mesita'],
  'sofa': ['sofa'],
  'butaca': ['butaca'],
  'fotos': ['fotos'],
  'lampara': ['lampara'],
  'puerta': ['puerta'],
  'ventana': ['ventana'],
};

/// The things whose drawn pixels go outside their box, and why.
const Map<String, String> outside = {
  'sofa': 'in every state 27 of its 3667 pixels, the column x 67, 1 px left of the sheet\'s box [68, 81, 92, 51] (the old one\'s x and width): the turned box of its arms reaches it; its touch slack is 0 (sala.js COSAS m 0): reported, not changed',
  'butaca': 'in every state 28 of its 1552 pixels, the column x 202, 1 px right of the sheet\'s box [160, 88, 42, 39]: its right arm reaches it; slack 0: reported, not changed',
  'puerta': 'in every state 59 of its 1220 pixels, the column x 33, 1 px left of the sheet\'s box [34, 50, 36, 93]: the door\'s casing reaches it; slack 0: reported, not changed',
};

/// What lies partly outside the box sala.js gives it relative to itself (the sheet keeps those boxes: code lines 79 and
/// 82), as in the old game: the cake's box is [x - 1, y, 30, 16] at its point, which never held the dish's ends, the
/// candles' tops or the cover with its steam; a grown-up's caja is 22 wide, the hands and abuela's skirt reach past it.
const Set<String> outsideOld = {
  'the cake tapado',
  'the cake 1',
  'the cake 2',
  'the cake 3',
  'the cake 4',
  'the cake 5',
  'the cake 6',
  'the cake 7',
  'mama at [97, 127] standing',
  'mama at [97, 127] sitting',
  'papa at [131, 127] standing',
  'papa at [131, 127] sitting',
  'abuelo at [181, 127] standing',
  'abuelo at [181, 127] sitting',
  'abuela at [42, 168] standing',
};

/// Whether thing [k] shows in [W] (and so can be touched).
bool shows(Sala scene, String k, Map<String, dynamic> W) {
  switch (k) {
    case 'pajaro':
      return W['ave'] != null && (W['ave'] as Map)['mode'] != 'none';
    case 'coqui':
      return jsTruthy((W['cq'] as Map)['vis']);
  }
  final t = scene.cosa(k)!;
  return (t.si == null || t.si!(W)) && scene.box(k, W) != null;
}

/// The middles hit gives to another thing, because the kit tests that thing first (the old order is kept: the frog
/// first, then the list's order: the seven people, the cake, the low table, the sofa, the armchair, the frames, the lamp,
/// the door, the window, the floor).
const Map<String, String> shadowedBy = {
  'butaca -> abuelo': 'abuelo in his armchair: the people come before the furniture in the list',
  'butaca -> abuela': 'abuela standing at his armchair (pair abuelo.no)',
  'hermana -> hermano': 'the two children side by side, overlapping: the boy is first in the list',
  'mama -> bebe': 'the baby on mamá\'s lap: the baby is before her in the list',
  'mesita -> bizcocho': 'the cake on the low table comes before the table',
  'papa -> hermana':
      'a child standing before papá: the children are first in the list',
  'papa -> hermano': 'the same, the boy',
  'sofa -> bebe':
      'someone on or before the sofa: the people come before the furniture',
  'sofa -> hermana': 'the same',
  'sofa -> hermano': 'the same',
  'sofa -> mama': 'the same',
  'sofa -> papa': 'the same',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Sala scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('sala');
    scene = frame.scene as Sala;
  });
  final refs = (jsonDecode(salaSetRefs) as List).cast<Map<String, dynamic>>();
  final rows = <String>[];

  test('every thing of the set lies inside its touch box, in every state', () {
    final e = salaEngine(), b = PpBuild(e);
    final over = <String>{};
    for (final r in refs) {
      final st = SalaState.fromQuery(r['query'] as String);
      final s = SalaSet(e, b, st);
      s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      s.buildSet();
      final tags = s.k.PART_TAGS!;
      for (final t in partsOf.entries) {
        final box = scene.box(t.key, const {})!;
        var drawn = 0, out = 0, far = 0;
        var bx0 = 1 << 30, by0 = 1 << 30, bx1 = -1, by1 = -1;
        for (var i = 0; i < tags.length; i++) {
          if (!t.value.contains(tags[i])) continue;
          drawn++;
          final x = i % e.W, y = i ~/ e.W;
          if (x < bx0) bx0 = x;
          if (y < by0) by0 = y;
          if (x > bx1) bx1 = x;
          if (y > by1) by1 = y;
          if (x < box[0] ||
              x >= box[0] + box[2] ||
              y < box[1] ||
              y >= box[1] + box[3]) {
            out++;
            final d = [
              box[0] - x,
              x - (box[0] + box[2] - 1),
              box[1] - y,
              y - (box[1] + box[3] - 1),
            ].reduce((a, b) => a > b ? a : b);
            if (d > far) far = d.toInt();
          }
        }
        rows.add(
          '${r['id']} ${t.key} (parts ${t.value.join(', ')}): $out of $drawn drawn pixels outside $box'
          '${out > 0 ? ', at most $far px out' : ''}; drawn over [$bx0, $by0, ${bx1 - bx0 + 1}, ${by1 - by0 + 1}]',
        );
        expect(drawn, greaterThan(0), reason: '${t.key} in ${r['id']}');
        if (out > 0) over.add(t.key);
      }
    }
    expect(over, outside.keys.toSet(), reason: 'outside its box: $over');
  });

  test('the cake and every person lie inside their box', () {
    final out = <String>[];
    var checked = 0;
    void check(String what, List<num> box, void Function(Ctx c) draw) {
      final pix = Uint32List(240 * 216), c = Ctx(pix, 240, 216);
      draw(c);
      var n = 0, o = 0;
      for (var i = 0; i < pix.length; i++) {
        if (pix[i] >> 24 == 0) continue;
        n++;
        final x = i % 240, y = i ~/ 240;
        if (x < box[0] ||
            x >= box[0] + box[2] ||
            y < box[1] ||
            y >= box[1] + box[3]) {
          o++;
        }
      }
      checked++;
      rows.add('$what: $o of $n pixels outside $box');
      expect(n, greaterThan(0), reason: what);
      if (o > 0) out.add(what);
    }

    frame.host.fresh();
    frame.host.W = {...frame.host.W, ...scene.fresh(const {})};
    final pt = scene.sheet.screenPoint('bizcocho').xy;
    for (final n in <Object>['tapado', 1, 2, 3, 4, 5, 6, 7]) {
      check(
        'the cake $n',
        scene.box('bizcocho', {'pastel': 7})!,
        (c) => scene.bizcocho(c, pt[0], pt[1], n),
      );
    }
    final W = frame.host.W;
    for (final id in const [
      'mama',
      'papa',
      'abuelo',
      'bebe',
      'abuela',
      'hermano',
      'hermana',
    ]) {
      final p =
          (W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
      p['vis'] = 1;
      for (final sent in id == 'bebe' || id == 'abuela' ? [0] : [0, 1]) {
        p['sent'] = sent;
        check(
          '$id at ${scene.SITIO[id]!.take(2).toList()}${sent == 1 ? ' sitting' : ' standing'}',
          scene.caja(id)!,
          (c) => scene.gente(c, id, 0),
        );
      }
    }
    rows.add(
      'the cake and the people: $checked checked, outside their box: $out',
    );
    expect(out.toSet(), outsideOld, reason: rows.last);
  });

  // hit at the middle of each box, in the 5 states, the review pictures and the moments of the stories
  test('hit gives each thing its key at the middle of its box, wherever it shows', () {
    final worlds = <(String, Map<String, dynamic>, int)>[];
    for (final r in refs) {
      final st = SalaState.fromQuery(r['query'] as String);
      final W = <String, dynamic>{
        'fx': <Map<String, dynamic>>[],
        'heart': 0,
        'lost': 0,
        'resp': null,
        ...scene.fresh(const {}),
      };
      W['fotos'] = [
        for (var i = 0; i < 3; i++)
          st.fotos[i] == '1'
              ? <String, dynamic>{
                  'q': ['mama'],
                  'ok': 0,
                  'pata': 1,
                }
              : null,
      ];
      expect(scene.setKey(W), st.key);
      worlds.add(('state ${r['id']}', W, 8));
    }
    for (final c in (jsonDecode(
      salaPreviewCases,
    ) as List).cast<Map<String, dynamic>>()) {
      if (c['kind'] == 'pair') {
        worlds.add((
          c['id'] as String,
          ScenePictures.pictureW(
            scene,
            (c['set'] as Map<String, dynamic>?) ?? const {},
          ),
          pictureF,
        ));
      } else {
        worlds.add((
          c['id'] as String,
          salaPreviewRemapW(
            salaPreviewBaseW(
              scene.fresh(const {}),
              c['W'] as Map<String, dynamic>,
            ),
            scene.sheet,
            acts: (c['acts'] as List?)?.cast<String>(),
          ),
          c['F'] as int,
        ));
      }
    }
    final misses = <String>{};
    var checked = 0;
    for (final (name, W, F) in worlds) {
      frame.host
        ..W = W
        ..F = F
        ..cam = scene.CAM['wide']!;
      final keys = [for (final t in scene.cosas) t.id, 'pajaro', 'coqui'];
      for (final k in keys) {
        if (!shows(scene, k, W)) continue;
        List<num> mid;
        if (k == 'coqui') {
          final b = frogBox(W['cq'] as Map<String, dynamic>);
          mid = [b.x + b.w / 2, b.y + b.h / 2];
        } else if (k == 'pajaro') {
          final p = scene.avePos(W['ave'] as Map<String, dynamic>);
          mid = [p[0], p[1] - 10];
        } else {
          final b = scene.box(k, W)!;
          mid = [b[0] + b[2] / 2, b[1] + b[3] / 2];
        }
        final got = scene.hit(mid[0], mid[1], W);
        checked++;
        if (got != k) {
          misses.add('$k -> $got');
          rows.add(
            'hit $name: the middle of $k (${mid[0]}, ${mid[1]}) gives $got',
          );
        }
      }
    }
    rows.add(
      'hit: $checked middles checked in ${worlds.length} worlds; misses by kind: ${misses.toList()..sort()}',
    );
    expect(misses, shadowedBy.keys.toSet(), reason: rows.last);
  });

  tearDownAll(() => report('sala-boxes', rows));
}
