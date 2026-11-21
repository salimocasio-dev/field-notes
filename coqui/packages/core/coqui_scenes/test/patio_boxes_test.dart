// El patio's touch boxes. (1) Every thing of the set lies inside its touch box: in each of the 15 states, each pixel the
// set's part for that thing drew (set-kit.js `part`) is inside its box (the sheet's things.<id>.box, as its code for
// patio.js lines 93 to 95 gives it); the tree's swaying leaves at every place the wind takes them (pp-engine.js drawLeaves,
// at every wind step of two minutes); each bed's turned earth; the yard's lawn. (2) What the sprite layer draws for a thing lies inside its box: the crate at
// points.caja, the sack shut and open, each person standing and sitting at a place of the stories
// (caja(id), relative to where they stand: the sheet keeps it), the sun at each height. (3) hit, in the kit's order,
// returns each thing's key at the middle of its box wherever it shows (the 15 states, the review pictures, the kept
// moments of the recorded runs), but where the old order gives the point to a thing tested before it; those are listed in
// [shadowedBy] (the numbers go to the report).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/patio/patio.dart';
import 'package:coqui_scenes/src/patio/patio_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/patio_preview_fixture.dart';
import 'support/fixtures/patio_set_refs.dart';
import 'support/patio_preview_remap.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (patio-set.html: `part(name, ...)`); the stone step is the house's
/// (the door's box is its frame and opening).
const Map<String, List<String>> partsOf = {
  'porton': ['porton'],
  'nido': ['nido'],
  'arbol': ['arbol'],
  'puerta': ['puerta'],
  'casa': ['casa', 'escalon'],
  'cerca': ['cerca'],
};

/// The things whose drawn pixels go outside their box, and why.
const Map<String, String> outside = {
  'arbol': 'in every state 13 of the 4552 pixels the crown and the trunk take, 1 px left of the sheet\'s box [166, 3, 74, 127], at some wind steps: the crown is cut at x 166 when it is baked (patio-set.html tree), the wind takes a leaf a pixel further; its touch slack is 0 (patio.js COSAS m 0): reported, not changed',
  'nido': 'in every state 26 of its 220 pixels, up to 6 px right of the sheet\'s box [170, 60, 22, 16] (the old one): the branch from the trunk to the nest is drawn by the same part (patio-set.html part("nido")); the nest itself is inside: reported, not changed',
  'camaL': 'in every state 2 of its 884 pixels of turned earth, 1 px past the sheet\'s box [40, 159, 57, 39]: the bed\'s ragged edge (inBed); its touch slack is 2 (patio.js COSAS m 2): reported, not changed',
  'camaR': 'in every state 5 of its 883 pixels, up to 2 px past the box [144, 159, 56, 39]: the same; slack 2: reported, not changed',
};

/// What lies partly outside the box patio.js gives it relative to itself (the sheet keeps those boxes: code lines 89, 93
/// and 94), as in the old game: a grown-up's caja is 22 wide, the hands and abuela's skirt reach past it; the sun's box
/// is 28 x 28 round its middle, its rays reach 19 px out; the ball's box is 14 x 14 over its foot, its outline a row
/// lower.
const Set<String> outsideOld = {
  'abuelo standing',
  'abuelo sitting',
  'abuela standing',
  'mama standing',
  'mama sitting',
  'papa standing',
  'papa sitting',
  'the sun at 26',
  'the sun at 40',
  'the sun at 56',
  'the sun at 73',
};

/// Whether thing [k] shows in [W] (and so can be touched).
bool shows(Patio scene, String k, Map<String, dynamic> W) {
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
/// first, then the list's order: the seven people, the ball, the sack, the crate, the beds, the sun, the gate, the nest,
/// the tree, the bird, the door, the house, the fence, the lawn), each with why.
const Map<String, String> shadowedBy = {
  'arbol -> bola': 'the ball up in the tree (d-la-bola, acts.bolaarbol): the ball is before the tree in the list',
  'bola -> luis': 'the ball at Luis\'s feet: the people come first in the list',
  'bola -> pajaro': 'the bird on the ball in the tree (acts.avepica2): the kit tests the bird before the list\'s things',
  'camaL -> coqui':
      'the frog before bed L (pairs ven, mira): the kit tests the frog first',
  'camaR -> luis': 'Luis before bed R (pair mira.no): the people come first',
  'casa -> abuela':
      'abuela in the back door (acts.asoma): the people come first',
  'casa -> puerta': 'the middle of the house\'s box is on the door, which is before the house in the list',
  'cerca -> arbol': 'the middle of the fence\'s box is in the tree\'s, which is before the fence in the list',
  'cerca -> carmen':
      'Carmen before the fence (pair vamos): the people come first',
  'cerca -> luis': 'Luis before the fence, by the gate (hasta-manana): the people come first',
  'mama -> bebe': 'the baby in mamá\'s arms (hasta-manana): the baby is before her in the list',
  'nido -> pajaro':
      'the bird on its nest: the kit tests the bird before the list\'s things',
  'papa -> bebe': 'the baby in mamá\'s arms beside papá (hasta-manana): the baby is before him in the list',
  'patio -> carmen':
      'someone in the middle of the lawn: the people come first in the list',
  'patio -> cerca': 'the middle of the lawn\'s box is in the fence\'s, which is before the lawn in the list (the lawn is last)',
  'patio -> coqui': 'the frog in the middle of the lawn: he is tested first',
  'patio -> luis': 'the same, Luis',
  'puerta -> abuela': 'abuela in the door: the people come first',
  'puerta -> abuelo': 'abuelo before the door (hasta-manana, pair hasta mañana): the people come first',
  'sol -> papa': 'the sun at its lowest beside papá\'s head (pair hasta mañana.si): the people come first',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Patio scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('patio');
    scene = frame.scene as Patio;
  });
  final refs = (jsonDecode(patioSetRefs) as List).cast<Map<String, dynamic>>();
  final rows = <String>[];

  test('every thing of the set lies inside its touch box, in every state', () {
    final e = patioEngine(), b = PpBuild(e);
    final over = <String>{};
    for (final r in refs) {
      final st = PatioState.fromQuery(r['query'] as String);
      final s = PatioSet(e, b, st);
      s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
      s.buildSet();
      final tags = s.k.PART_TAGS!;
      // the pixels each part drew, and the tree's leaves wherever the wind takes them
      final drawnBy = <String, Set<int>>{};
      for (var i = 0; i < tags.length; i++) {
        if (tags[i] != null) (drawnBy[tags[i]!] ??= {}).add(i);
      }
      // the leaves of each part, drawn by the wind at every step of two minutes (pp-engine.js drawLeaves): the pixels whose
      // depth the leaves took, where they are drawn (behind nothing nearer)
      final leafOwner = <int, String>{};
      for (final en in s.k.PART_LEAVES.entries) {
        for (var j = en.value[0]; j < en.value[1]; j++) {
          leafOwner[j] = en.key;
        }
      }
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
      // the beds' earth (painted on the ground: no part) and the lawn of the yard
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final i = iy * e.W + ix;
          if (e.ground[i] == 0) continue;
          for (final k in const ['L', 'R']) {
            if (s.inBed(ix, iy, k) <= 1) (drawnBy['cama$k'] ??= {}).add(i);
          }
          final g = e.unproject(ix + .5, iy + .5);
          if (g.x > CX && g.y > CY) (drawnBy['patio'] ??= {}).add(i);
        }
      }
      final things = {
        ...partsOf,
        'camaL': ['camaL'],
        'camaR': ['camaR'],
        'patio': ['patio'],
      };
      for (final t in things.entries) {
        final box = scene.box(t.key, const {})!;
        var drawn = 0, out = 0, far = 0;
        var ox0 = 1 << 30, oy0 = 1 << 30, ox1 = -1, oy1 = -1;
        for (final part in t.value) {
          for (final i in drawnBy[part] ?? const <int>{}) {
            drawn++;
            final x = i % e.W, y = i ~/ e.W;
            if (x < box[0] ||
                x >= box[0] + box[2] ||
                y < box[1] ||
                y >= box[1] + box[3]) {
              out++;
              if (x < ox0) ox0 = x;
              if (y < oy0) oy0 = y;
              if (x > ox1) ox1 = x;
              if (y > oy1) oy1 = y;
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
          '${out > 0 ? ', at most $far px out, over [$ox0, $oy0, ${ox1 - ox0 + 1}, ${oy1 - oy0 + 1}]' : ''}',
        );
        expect(drawn, greaterThan(0), reason: '${t.key} in ${r['id']}');
        if (out > 0) over.add(t.key);
      }
    }
    expect(over, outside.keys.toSet(), reason: 'outside its box: $over');
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
    final W = frame.host.W;
    final caja = scene.sheet.screenPoint('caja').xy;
    check(
      'the crate',
      scene.box('caja', {'caja': 1})!,
      (c) => c.drawImage(mkCaja(), caja[0], caja[1]),
    );
    for (final ab in const [0, 1]) {
      final saco = {'x': 164, 'y': 165, 'ab': ab};
      check(
        'the sack ${ab == 1 ? 'open' : 'shut'}',
        scene.box('saco', {'saco': saco})!,
        (c) => c.drawImage(mkSaco(ab == 1), 164 - 13, 165 - 23),
      );
    }
    for (final y in scene.SOLY) {
      W['soly'] = y;
      check(
        'the sun at ${y.toInt()}',
        scene.box('sol', W)!,
        (c) => scene.sol(c, scene.SOLX, y, 0, false),
      );
    }
    // the people at a place of the stories (las-flores, hasta-manana), standing and sitting
    W['gente'] = <String, dynamic>{
      for (final (id, x, y) in const [
        ('luis', 160, 128),
        ('carmen', 94, 137),
        ('abuela', 52, 108),
        ('abuelo', 70, 129),
        ('mama', 92, 136),
        ('papa', 114, 136),
        ('bebe', 103, 160),
      ])
        id: <String, dynamic>{'x': x, 'y': y, 'pose': 'idle', 'vis': 1},
    };
    for (final id in const [
      'luis',
      'carmen',
      'bebe',
      'abuela',
      'abuelo',
      'mama',
      'papa',
    ]) {
      final p =
          (W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
      for (final sent in id == 'bebe' || id == 'abuela' ? [0] : [0, 1]) {
        p['sent'] = sent;
        check(
          '$id${sent == 1 ? ' sitting' : ' standing'}',
          scene.caja(id)!,
          (c) => scene.gente(c, id, 0),
        );
      }
    }
    rows.add(
      'the sprite layer\'s things: $checked checked, outside their box: $out',
    );
    expect(out.toSet(), outsideOld, reason: rows.last);
  });

  // hit at the middle of each box, in the 15 states, the review pictures and the moments of the stories
  test('hit gives each thing its key at the middle of its box, wherever it shows', () {
    final worlds = <(String, Map<String, dynamic>, int)>[];
    for (final r in refs) {
      final st = PatioState.fromQuery(r['query'] as String);
      final W = <String, dynamic>{
        'fx': <Map<String, dynamic>>[],
        'heart': 0,
        'lost': 0,
        'resp': null,
        ...scene.fresh(const {}),
      };
      switch (st.hora) {
        case 'tarde':
          W['sol'] = 1;
        case 'tarde2':
          W['sol'] = 2;
        case 'ocaso':
          W['sol'] = 3;
        case 'crepusculo':
          W['sol'] = 3;
          W['osc'] = .3;
        case 'noche':
          W['noche'] = 1;
      }
      W['pdoor'] = st.door == 'open' ? 1 : 0;
      W['porton'] = st.gate == 'open' ? 1 : 0;
      W['caja'] = 1;
      expect(scene.setKey(W), st.key);
      worlds.add(('state ${r['id']}', W, 8));
    }
    for (final c in (jsonDecode(
      patioPreviewCases,
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
          patioPreviewRemapW(
            patioPreviewBaseW(
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

  test('the beds\' holes are the sheet\'s points, and the gate\'s hand point is inside its box', () {
    for (final k in const ['L', 'R']) {
      expect([
        for (var i = 0; i < 5; i++) [for (final v in hoyo(k, i)) v.toDouble()],
      ], scene.sheet.screenPoint('hoyos.$k').points);
    }
    final h = scene.handAt('porton')!, b = scene.box('porton', const {})!;
    expect(h, [133, 46]);
    expect(h[0] >= b[0] && h[0] < b[0] + b[2], isTrue);
    expect(h[1] >= b[1] && h[1] < b[1] + b[3], isTrue);
  });

  tearDownAll(() => report('patio-boxes', rows));
}
