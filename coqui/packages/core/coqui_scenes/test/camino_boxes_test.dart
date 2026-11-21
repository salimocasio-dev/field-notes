// El camino's touch boxes. (1) Every thing of the set lies inside its touch box: in both states, each pixel the set's part
// for that thing drew (set-kit.js `part`) is inside its box (the sheet's things.<id>.box, as its code for camino.js lines
// 70 to 72 gives it); the big tree's swaying leaves at every place the wind takes them (pp-engine.js drawLeaves, at every
// wind step of two minutes); the path (its trodden earth and its stones); the park's lawn. The big tree's hint box (the
// part of its box the hint frame shows) lies inside its box. (2) What the sprite layer draws for a thing lies inside its
// box: each person standing and sitting at a place of the stories (caja(id), relative to where they stand: the sheet
// keeps it), Canelo and the cat in each pose, the birds in the trees. (3) hit, in the kit's order, returns each thing's
// key at the middle of its box wherever it shows (the 2 states, the review pictures, the kept moments of the recorded
// runs), but where the old order gives the point to a thing tested before it; those are listed in [shadowedBy] (the
// numbers go to the report).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/camino/camino.dart';
import 'package:coqui_scenes/src/camino/camino_set.dart';
import 'package:coqui_scenes/src/set_kit.dart' show KIND_ROAD;
import 'package:flutter_test/flutter_test.dart';

import 'support/camino_preview_remap.dart';
import 'support/fixtures/camino_preview_fixture.dart';
import 'support/fixtures/camino_set_refs.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (camino-set.html: `part(name, ...)`); the path's stones are the
/// path's (`part('camino')`), its trodden earth is the ground's (kinds: road).
const Map<String, List<String>> partsOf = {
  'porton': ['porton'],
  'arbol0': ['arbol0'],
  'arbol1': ['arbol1'],
  'arbol2': ['arbol2'],
  'banco': ['banco'],
  'grande': ['grande'],
  'camino': ['camino', 'path'],
  'parque': ['parque'],
};

/// The things whose drawn pixels go outside their box, and why (none: the sheet maker checks it, camino-sheet-make.js
/// checks.boxes).
const Map<String, String> outside = {};

/// What lies partly outside the box camino.js gives it relative to itself (the sheet keeps those boxes: code lines 64,
/// 68 and 69), as in the old game: a grown-up's caja is 22 wide, abuela's hands and skirt reach past it; Canelo's box is
/// [x - 14, y - 20, 28, 22] and his ears and tail reach past its top and sides, the cat's [x - 12, y - 18, 24, 20] and its
/// ears and tail the same (their touch slack is 2: camino.js COSAS m 2). Reported, not changed.
const Set<String> outsideOld = {
  'abuela standing',
  'perro sit still',
  'perro sit step',
  'perro walk still',
  'perro walk step',
  'perro run still',
  'perro run step',
  'perro bark still',
  'perro bark step',
  'perro eat still',
  'perro eat step',
  'perro husmea still',
  'perro husmea step',
  'perro lie still',
  'perro lie step',
  'gato sit still',
  'gato sit step',
  'gato lava still',
  'gato lava step',
  'gato walk still',
  'gato walk step',
  'gato run still',
  'gato run step',
};

/// Whether thing [k] shows in [W] (and so can be touched).
bool shows(Camino scene, String k, Map<String, dynamic> W) {
  if (k == 'coqui') return jsTruthy((W['cq'] as Map)['vis']);
  final t = scene.cosa(k)!;
  return (t.si == null || t.si!(W)) && scene.box(k, W) != null;
}

/// The middles hit gives to another thing, because the kit tests that thing first (the old order is kept: the frog
/// first, then the list's order: the three people, the nine birds, Canelo, the cat, the three small trees, the bench, the
/// big tree, the arch, the path, the park), each with why.
const Map<String, String> shadowedBy = {
  'arbol0 -> ave02': 'a bird at the third place in the first tree (its crown\'s middle): the birds are before the trees in the list',
  'arbol1 -> ave12': 'the same, in the middle tree',
  'arbol2 -> ave22': 'the same, in the third tree',
  'banco -> perro': 'Canelo barking at the cat in the first tree, before the bench (d-corre beats.49, moved to 80, 149): he is before the bench in the list',
  'camino -> carmen': 'Carmen on the path\'s middle (pairs espera, uno-dos-tres): the people come first',
  'camino -> luis': 'Luis on the path\'s middle (pairs camina, level corre): the people come first',
  'camino -> perro': 'Canelo on the path\'s middle (stories 12 and 14, d-corre, h-camino): he is before the path in the list',
  'carmen -> coqui': 'the frog in front of Carmen on the walk back (rapido-despacio): the kit tests the frog first',
  'parque -> camino': 'the middle of the park\'s box is on the path, which is before the park in the list (the park is last)',
  'parque -> carmen':
      'Carmen in the middle of the picture: the people come first',
  'parque -> luis': 'Luis in the middle of the picture: the same',
  'parque -> perro':
      'Canelo in the middle of the picture: he is before the park in the list',
  'perro -> carmen':
      'Canelo beside Carmen at a mark (uno-dos-tres): the people come first',
  'perro -> coqui': 'the frog over Canelo (donde-esta-el-gato, acts.lame): the kit tests the frog first',
  'perro -> luis':
      'Canelo at Luis\'s feet (rapido-despacio): the people come first',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Camino scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('camino');
    scene = frame.scene as Camino;
  });
  final refs = (jsonDecode(caminoSetRefs) as List).cast<Map<String, dynamic>>();
  final rows = <String>[];

  test('every thing of the set lies inside its touch box, in both states', () {
    final e = caminoEngine(), b = PpBuild(e);
    final over = <String>{};
    for (final r in refs) {
      final st = CaminoState.fromQuery(r['query'] as String);
      final s = CaminoSet(e, b, st);
      s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      s.buildSet();
      final tags = s.k.PART_TAGS!;
      final drawnBy = <String, Set<int>>{};
      for (var i = 0; i < tags.length; i++) {
        if (tags[i] != null) (drawnBy[tags[i]!] ??= {}).add(i);
      }
      // the leaves of each part, drawn by the wind at every step of two minutes: the pixels whose depth the leaves took
      final leaves = List.of(e.leaves);
      for (var w = 0; w < 120 * e.WIND_FPS; w++) {
        for (final en in s.k.PART_LEAVES.entries) {
          e.pix.setAll(0, e.bakedPix);
          e.zb.setAll(0, e.bakedZ);
          e.leaves
            ..clear()
            ..addAll(leaves.sublist(en.value[0], en.value[1]));
          e.drawLeaves(w / e.WIND_FPS);
          for (var i = 0; i < e.zb.length; i++) {
            if (e.zb[i] != e.bakedZ[i]) (drawnBy[en.key] ??= {}).add(i);
          }
        }
      }
      e.leaves
        ..clear()
        ..addAll(leaves);
      // the path's trodden earth and the park's lawn (painted on the ground: no part)
      for (var i = 0; i < e.W * e.H; i++) {
        if (e.ground[i] == 0) continue;
        if (e.kinds[i] == KIND_ROAD) (drawnBy['path'] ??= {}).add(i);
        (drawnBy['parque'] ??= {}).add(i);
      }
      for (final t in partsOf.entries) {
        final box = scene.box(t.key, const {})!;
        var drawn = 0, out = 0, far = 0;
        for (final part in t.value) {
          for (final i in drawnBy[part] ?? const <int>{}) {
            drawn++;
            final x = i % e.W, y = i ~/ e.W;
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
        }
        rows.add(
          '${r['id']} ${t.key} (${t.value.join(', ')}): $out of $drawn pixels outside $box'
          '${out > 0 ? ', at most $far px out' : ''}',
        );
        // the big tree is not there in gran 0 (story 13)
        if (t.key == 'grande' && st.gran == '0') {
          expect(drawn, 0);
          continue;
        }
        expect(drawn, greaterThan(0), reason: '${t.key} in ${r['id']}');
        if (out > 0) over.add(t.key);
      }
    }
    expect(over, outside.keys.toSet(), reason: 'outside its box: $over');
  });

  test('the big tree\'s hint box is the part of its touch box inside the picture the sheet gives', () {
    final box = scene.box('grande', const {})!,
        hint = scene.cosa('grande')!.hintBox!;
    expect(box, [160, 0, 80, 108]);
    expect(hint, [160, 12, 46, 96]);
    expect(hint[0] >= box[0] && hint[0] + hint[2] <= box[0] + box[2], isTrue);
    expect(hint[1] >= box[1] && hint[1] + hint[3] <= box[1] + box[3], isTrue);
    // no other thing carries one
    expect(
      [
        for (final t in scene.cosas)
          if (t.hintBox != null) t.id,
      ],
      ['grande'],
    );
    // its hand inside its hint box
    final h = scene.handAt('grande')!;
    expect(h, [190, 51]);
    expect(h[0] >= hint[0] && h[0] < hint[0] + hint[2], isTrue);
    expect(h[1] >= hint[1] && h[1] < hint[1] + hint[3], isTrue);
  });

  test('what the sprite layer draws for a thing lies inside its box', () {
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
    frame.host.F = 0;
    final W = frame.host.W;
    // the people at a place of the stories (uno-dos-tres, rapido-despacio), standing and sitting
    W['gente'] = <String, dynamic>{
      for (final (id, x, y) in const [
        ('luis', 174, 138),
        ('carmen', 76, 204),
        ('abuela', 66, 182),
      ])
        id: <String, dynamic>{'x': x, 'y': y, 'pose': 'idle', 'vis': 1},
    };
    for (final id in const ['luis', 'carmen', 'abuela']) {
      final p =
          (W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
      for (final sent in id == 'abuela' ? [0] : [0, 1]) {
        p['sent'] = sent;
        check(
          '$id${sent == 1 ? ' sitting' : ' standing'}',
          scene.caja(id)!,
          (c) => scene.gente(c, id, 0),
        );
      }
    }
    // Canelo and the cat on the ground, in every pose they take
    for (final (k, poses) in const [
      ('perro', ['sit', 'walk', 'run', 'bark', 'eat', 'husmea', 'lie']),
      ('gato', ['sit', 'lava', 'walk', 'run']),
    ]) {
      for (final pose in poses) {
        for (final a in const [0, 2]) {
          W[k] = <String, dynamic>{'x': 120, 'y': 160, 'pose': pose, 'dir': 1};
          check(
            '$k $pose ${a == 0 ? 'still' : 'step'}',
            scene.box(k, W)!,
            (c) => scene.animal(c, k, a),
          );
        }
      }
    }
    W['perro'] = null;
    W['gato'] = null;
    // the birds in the trees (drawn 15 x 12 at the box)
    W['pajaros'] = [3, 3, 3];
    for (var i = 0; i < 3; i++) {
      for (var k = 0; k < 3; k++) {
        check('ave$i$k', scene.box('ave$i$k', W)!, (c) {
          final p = scene.NIDO[k];
          c.drawImage(
            mkPajarito(false),
            scene.ARBOL[i][0] + p[0] - 8,
            scene.ARBOL[i][1] + p[1] - 6,
            15,
            12,
          );
        });
      }
    }
    rows.add(
      'the sprite layer\'s things: $checked checked, outside their box: $out',
    );
    expect(out.toSet(), outsideOld, reason: rows.last);
  });

  // hit at the middle of each box, in the 2 states, the review pictures and the moments of the stories
  test('hit gives each thing its key at the middle of its box, wherever it shows', () {
    final worlds = <(String, Map<String, dynamic>, int)>[];
    for (final r in refs) {
      final st = CaminoState.fromQuery(r['query'] as String);
      final W = <String, dynamic>{
        'fx': <Map<String, dynamic>>[],
        'heart': 0,
        'lost': 0,
        'resp': null,
        ...scene.fresh(const {}),
      };
      W['sinGran'] = st.gran == '0' ? 1 : 0;
      expect(scene.setKey(W), st.key);
      worlds.add(('state ${r['id']}', W, 8));
    }
    for (final c in (jsonDecode(
      caminoPreviewCases,
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
          caminoPreviewRemapW(
            caminoPreviewBaseW(
              scene.fresh(const {}),
              c['W'] as Map<String, dynamic>,
            ),
            scene.sheet,
            story: c['story'] as String?,
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
      final keys = [for (final t in scene.cosas) t.id, 'coqui'];
      for (final k in keys) {
        if (!shows(scene, k, W)) continue;
        List<num> mid;
        if (k == 'coqui') {
          final b = frogBox(W['cq'] as Map<String, dynamic>);
          mid = [b.x + b.w / 2, b.y + b.h / 2];
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

  tearDownAll(() => report('camino-boxes', rows));
}
