// El campo's touch boxes. (1) Every thing of the set lies inside its touch box: in its one state, each pixel the set's
// part for that thing drew (set-kit.js `part`) is inside its box (the sheet's things.<id>.box, as its code for campo.js
// lines 66 to 68 gives it): the tree, the reeds (still: no leaf or reed moves at any wind step), the field (its lawn and
// the lake: painted on the ground). The hint boxes of the tree and the reeds (the part of each box the hint frame shows)
// lie inside their boxes. (2) What the sprite layer draws for a thing lies inside its box: each child standing at a place
// of the stories (caja(id), relative to where they stand: the sheet keeps it), Canelo in each pose, each ball, the
// basket. (3) hit, in the kit's order, returns each thing's key at the middle of its box wherever it shows (the state, the
// review pictures, the kept moments of the recorded runs), but where the old order gives the point to a thing tested
// before it; those are listed in [shadowedBy] (the numbers go to the report).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/campo/campo.dart';
import 'package:coqui_scenes/src/campo/campo_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/campo_preview_remap.dart';
import 'support/fixtures/campo_preview_fixture.dart';
import 'support/fixtures/campo_set_refs.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (campo-set.html: `part(name, ...)`); the field is the ground's (the lawn,
/// the bank and the lake: no part).
const Map<String, List<String>> partsOf = {
  'arbol': ['arbol'],
  'juncos': ['juncos'],
  'campo': ['campo'],
};

/// The things whose drawn pixels go outside their box, and why (none: the sheet maker checks it, campo-sheet-make.js
/// checks.boxes).
const Map<String, String> outside = {};

/// What lies partly outside the box campo.js gives it relative to itself (the sheet keeps those boxes: code lines 52, 61
/// and 64), as in the old game: a child's caja is 22 wide and the arms of offer, arriba and tu reach past it; Canelo's box
/// is [x - 14, y - 20, 28, 22] and his ears and tail reach past its top and sides (his touch slack is 2: COSAS m 2); the
/// basket's [x - 11, y - 16, 22, 18] and the balls heaped in it reach over its top. Reported, not changed.
const Set<String> outsideOld = {
  'luis offer',
  'luis arriba',
  'luis tu',
  'carmen offer',
  'carmen arriba',
  'carmen tu',
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
  'cesta',
};

/// Whether thing [k] shows in [W] (and so can be touched).
bool shows(Campo scene, String k, Map<String, dynamic> W) {
  if (k == 'coqui') return jsTruthy((W['cq'] as Map)['vis']);
  final t = scene.cosa(k)!;
  return (t.si == null || t.si!(W)) && scene.box(k, W) != null;
}

/// The middles hit gives to another thing, because the kit tests that thing first (the old order is kept: the balls
/// first (z), then the frog, then the list's order: the two children, Canelo, the basket, the tree, the reeds, the
/// field), each with why.
const Map<String, String> shadowedBy = {
  'arbol -> coqui': 'the frog up in the crown (pair abajo.no: in the tree): the kit tests the frog before the tree',
  'campo -> carmen': 'Carmen in the middle of the field (pair coge, arriba-abajo): the children come before the field',
  'campo -> coqui': 'the frog in the middle of the field (LUGAR.centro, the stories\' start): the kit tests the frog first',
  'campo -> luis': 'Luis in the middle of the field (pair tira, level mi): the children come before the field',
  'carmen -> bola_carmen': 'the ball in Carmen\'s hands, in front of her body: the balls are tested first (z)',
  'carmen -> bola_cq': 'the frog\'s ball in Carmen\'s hands (otra-vez, d-bola-canelo): the balls first',
  'carmen -> bola_luis': 'Luis\'s big ball beside Carmen (la-bola): the balls first',
  'coqui -> bola_cq': 'the frog\'s ball in his hands, in front of him: the balls first',
  'coqui -> bola_luis': 'Luis\'s big ball flying past the frog (la-bola, h-campo): the balls first',
  'luis -> bola_luis': 'the ball in Luis\'s hands, in front of his body: the balls first',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Campo scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('campo');
    scene = frame.scene as Campo;
  });
  final refs = (jsonDecode(campoSetRefs) as List).cast<Map<String, dynamic>>();
  final rows = <String>[];

  test('every thing of the set lies inside its touch box, in its state', () {
    final e = campoEngine(), b = PpBuild(e);
    final over = <String>{};
    final s = CampoSet(e, b);
    s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    final tags = s.k.PART_TAGS!;
    final drawnBy = <String, Set<int>>{};
    for (var i = 0; i < tags.length; i++) {
      if (tags[i] != null) (drawnBy[tags[i]!] ??= {}).add(i);
    }
    // no leaf sways: the set's parts are still at every wind step
    expect(e.leaves, isEmpty);
    // the field's lawn, its bank and its lake (painted on the ground: no part)
    for (var i = 0; i < e.W * e.H; i++) {
      if (e.ground[i] != 0) (drawnBy['campo'] ??= {}).add(i);
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
        'campo ${t.key} (${t.value.join(', ')}): $out of $drawn pixels outside $box'
        '${out > 0 ? ', at most $far px out' : ''}',
      );
      expect(drawn, greaterThan(0), reason: t.key);
      if (out > 0) over.add(t.key);
    }
    expect(over, outside.keys.toSet(), reason: 'outside its box: $over');
  });

  test('the hint boxes of the tree and the reeds lie inside their touch boxes, their hands inside them', () {
    expect(
      [
        for (final t in scene.cosas)
          if (t.hintBox != null) t.id,
      ],
      ['arbol', 'juncos'],
    );
    for (final (k, wantBox, wantHint, wantHand) in const [
      ('arbol', [34, 71, 55, 84], [36, 71, 53, 84], [60, 100]),
      ('juncos', [177, 140, 62, 51], [177, 164, 27, 27], [188, 190]),
    ]) {
      final box = scene.box(k, const {})!, hint = scene.cosa(k)!.hintBox!;
      expect(box, wantBox);
      expect(hint, wantHint);
      expect(hint[0] >= box[0] && hint[0] + hint[2] <= box[0] + box[2], isTrue);
      expect(hint[1] >= box[1] && hint[1] + hint[3] <= box[1] + box[3], isTrue);
      final h = scene.handAt(k)!;
      expect(h, wantHand);
      expect(h[0] >= hint[0] && h[0] < hint[0] + hint[2], isTrue, reason: k);
      expect(h[1] >= hint[1] && h[1] < hint[1] + hint[3], isTrue, reason: k);
    }
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
    // the children at a place of the stories (la-bola: their places, CASA)
    W['gente'] = <String, dynamic>{
      for (final (id, x, y) in const [('luis', 88, 178), ('carmen', 186, 154)])
        id: <String, dynamic>{'x': x, 'y': y, 'pose': 'idle', 'vis': 1},
    };
    for (final id in const ['luis', 'carmen']) {
      for (final pose in const ['idle', 'offer', 'arriba', 'tu', 'yo']) {
        ((W['gente'] as Map)[id] as Map)['pose'] = pose;
        check('$id $pose', scene.caja(id)!, (c) => scene.gente(c, id, 0));
      }
      ((W['gente'] as Map)[id] as Map)['pose'] = 'idle';
    }
    // Canelo on the lawn, in every pose he takes
    for (final pose in const [
      'sit',
      'walk',
      'run',
      'bark',
      'eat',
      'husmea',
      'lie',
    ]) {
      for (final a in const [0, 2]) {
        W['perro'] = <String, dynamic>{
          'x': 120,
          'y': 160,
          'pose': pose,
          'dir': 1,
        };
        check(
          'perro $pose ${a == 0 ? 'still' : 'step'}',
          scene.box('perro', W)!,
          (c) => scene.perro(c, a),
        );
      }
    }
    W['perro'] = null;
    // each ball on the lawn, and in the air
    for (final (k, n) in const [('L', 'luis'), ('C', 'carmen'), ('q', 'cq')]) {
      for (final z in const [0, 30]) {
        W['bolas'] = <String, dynamic>{
          n: <String, dynamic>{'k': k, 'x': 120, 'y': 180, 'z': z},
        };
        check(
          'bola_$n ${z == 0 ? 'on the lawn' : 'in the air'}',
          scene.box('bola_$n', W)!,
          (c) =>
              scene.unaBola(c, (W['bolas'] as Map)[n] as Map<String, dynamic>),
        );
      }
    }
    W['bolas'] = <String, dynamic>{};
    // the basket at its place, full (campo.js:103)
    W['cesta'] = [104, 208];
    check('cesta', scene.box('cesta', W)!, (c) {
      final im = mkBola('q');
      for (var i = 0; i < 4; i++) {
        c.drawImage(im, 104 - 10 + i * 5, 208 - 16 - (i % 2) * 2);
      }
      c.drawImage(mkCesta(), 104 - 10, 208 - 11);
    });
    W['cesta'] = null;
    rows.add(
      'the sprite layer\'s things: $checked checked, outside their box: $out',
    );
    expect(out.toSet(), outsideOld, reason: rows.last);
  });

  // hit at the middle of each box, in the state, the review pictures and the moments of the stories
  test('hit gives each thing its key at the middle of its box, wherever it shows', () {
    final worlds = <(String, Map<String, dynamic>, int)>[];
    worlds.add((
      'state campo',
      <String, dynamic>{
        'fx': <Map<String, dynamic>>[],
        'heart': 0,
        'lost': 0,
        'resp': null,
        ...scene.fresh(const {}),
      },
      8,
    ));
    for (final c in (jsonDecode(
      campoPreviewCases,
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
          campoPreviewRemapW(
            campoPreviewBaseW(
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

  tearDownAll(() => report('campo-boxes', rows));
}
