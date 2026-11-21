// El lago's touch boxes. (1) Every thing of the set lies inside its touch box: in its one state, each pixel the set's
// part for that thing drew (set-kit.js `part`) is inside its box (the sheet's things.<id>.box, as its code for lago.js
// lines 76 and 77 gives it): the reeds, the post, the dock (its deck, pilings, landing and mooring posts), the water and
// the lake (painted on the ground: the water's pixels, and everything under the horizon). The hint boxes lie inside their
// boxes, their hands inside them. (2) What the sprite layer draws for a thing lies inside its box: each child standing
// and sitting (caja(id), relative to where they stand: the sheet keeps it), each duck in each pose, each bird, each boat,
// the fish, Canelo, the flower. (3) hit, in the kit's order, returns each thing's key at the middle of its box wherever
// it shows (the state, the review pictures, the kept moments of the recorded runs), but where the old order gives the
// point to a thing tested before it; those are listed in [shadowedBy] (the numbers go to the report).
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/lago/lago.dart';
import 'package:coqui_scenes/src/lago/lago_set.dart';
import 'package:coqui_scenes/src/set_kit.dart' show KIND_WATER;
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/lago_preview_fixture.dart';
import 'support/lago_preview_remap.dart';
import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// The set's parts that draw each thing of the set (lago-set.html: `part(name, ...)`); the water and the lake are the
/// ground's (no part: the water's pixels; everything under the horizon).
const Map<String, List<String>> partsOf = {
  'juncos': ['juncos'],
  'poste': ['poste'],
  'muelle': ['muelle', 'muelle.postes'],
  'agua': ['agua'],
  'lago': ['lago'],
};

/// The things whose drawn pixels go outside their box, and why (none: the sheet maker checks it, lago-sheet-make.js
/// checks.boxes).
const Map<String, String> outside = {};

/// What lies partly outside the box lago.js gives it relative to itself (the sheet keeps those boxes: code lines 65, 68
/// to 75), as in the old game, or what the sheet's helps add round a thing on the water (the ring, the fish's patch),
/// each with why. Reported, not changed.
const Map<String, String> outsideOld = {
  'luis offer': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'luis offer sitting': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'luis arriba': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'luis arriba sitting': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'luis tu': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'luis tu sitting': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'carmen offer': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'carmen offer sitting': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'carmen arriba': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'carmen arriba sitting': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'carmen tu': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'carmen tu sitting': 'a child\'s caja is 22 wide: the arms of offer, arriba and tu reach past it',
  'pato_blanco nada still': 'its ripple ring (helps: 13 px each side, the box 12) and its wake reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_blanco nada step': 'its ripple ring (helps: 13 px each side, the box 12) and its wake reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_blanco vuela still':
      'its wings reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_blanco vuela step':
      'its wings reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_blanco anda still':
      'its beak and tail reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_blanco anda step':
      'its beak and tail reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_negro nada still': 'its ripple ring (helps: 13 px each side, the box 12) and its wake reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_negro nada step': 'its ripple ring (helps: 13 px each side, the box 12) and its wake reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_negro vuela still':
      'its wings reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_negro vuela step':
      'its wings reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_negro anda still':
      'its beak and tail reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_negro anda step':
      'its beak and tail reach past the duck\'s box [x - 12, y - 17, 24, 18]',
  'pato_amarillo nada still':
      'its ripple ring (helps) and its wake reach past the duck\'s box',
  'pato_amarillo nada step':
      'its ripple ring (helps) and its wake reach past the duck\'s box',
  'bote_rojo agua':
      'its ripple ring (helps: 11 px each side, the box 10) and its water line',
  'bote_azul agua':
      'its ripple ring (helps: 11 px each side, the box 10) and its water line',
  'bote_verde agua':
      'its ripple ring (helps: 11 px each side, the box 10) and its water line',
  'pez at the surface': 'its pale patch (helps.ring.pez: 26 x 17) is wider than the fish\'s box [x - 11, y - 10, 22, 18]',
  'perro lie still': 'Canelo\'s box is [x - 14, y - 14, 28, 16]: his ears, head and tail reach past it',
  'perro lie step': 'Canelo\'s box is [x - 14, y - 14, 28, 16]: his ears, head and tail reach past it',
  'perro bark still': 'Canelo\'s box is [x - 14, y - 14, 28, 16]: his ears, head and tail reach past it',
  'perro bark step': 'Canelo\'s box is [x - 14, y - 14, 28, 16]: his ears, head and tail reach past it',
};

/// Whether thing [k] shows in [W] (and so can be touched).
bool shows(Lago scene, String k, Map<String, dynamic> W) {
  if (k == 'coqui') return jsTruthy((W['cq'] as Map)['vis']);
  final t = scene.cosa(k)!;
  return (t.si == null || t.si!(W)) && scene.box(k, W) != null;
}

/// The middles hit gives to another thing, because the kit tests that thing first (the old order is kept: the ducks,
/// the birds, the boats, the fish and the blue bird first (z), then the frog, then the list's order: the two children,
/// Canelo, the flower, the reeds, the post, the dock, the water, the lake), each with why.
const Map<String, String> shadowedBy = {
  'agua -> muelle': 'the middle of the water\'s box (the whole picture under the horizon) is on the dock: the kit tests the dock first; the water answers everywhere off it',
  'lago -> muelle': 'the middle of the lake\'s box (the same box) is on the dock: the kit tests the dock first',
  'luis -> pez': 'the fish leaping over the dock\'s end, in front of Luis (los-botes): the fish first (z)',
  'muelle -> bote_rojo': 'the red boat of the row on the planks at the middle of the dock\'s box (los-botes): the boats first (z)',
  'muelle -> bote_verde':
      'the green boat of the row there (los-botes): the boats first (z)',
  'muelle -> pajaro':
      'the blue bird on the planks (pair vuela.no): the birds first (z)',
  'pato_amarillo -> pato_blanco': 'the three ducks bunched (cual): the white one is tested before the yellow one (the list\'s order)',
  'pato_amarillo -> pato_negro': 'the three ducks bunched (cual): the black one is tested before the yellow one',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Lago scene;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('lago');
    scene = frame.scene as Lago;
  });
  final rows = <String>[];

  test('every thing of the set lies inside its touch box, in its state', () {
    final e = lagoEngine(), b = PpBuild(e);
    final over = <String>{};
    final s = LagoSet(e, b);
    s.k.PART_TAGS = List<String?>.filled(e.W * e.H, null);
    s.buildSet();
    final tags = s.k.PART_TAGS!;
    final drawnBy = <String, Set<int>>{};
    for (var i = 0; i < tags.length; i++) {
      if (tags[i] != null) (drawnBy[tags[i]!] ??= {}).add(i);
    }
    // no leaf sways: the set's parts are still at every wind step
    expect(e.leaves, isEmpty);
    // the water (its pixels) and the lake (everything under the horizon)
    for (var i = 0; i < e.W * e.H; i++) {
      if (e.kinds[i] == KIND_WATER) (drawnBy['agua'] ??= {}).add(i);
      if (i ~/ e.W >= HZ) (drawnBy['lago'] ??= {}).add(i);
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
        'lago ${t.key} (${t.value.join(', ')}): $out of $drawn pixels outside $box'
        '${out > 0 ? ', at most $far px out' : ''}',
      );
      expect(drawn, greaterThan(0), reason: t.key);
      if (out > 0) over.add(t.key);
    }
    expect(over, outside.keys.toSet(), reason: 'outside its box: $over');
  });

  test(
    'the hint boxes lie inside their touch boxes, their hands inside them',
    () {
      expect(
        [
          for (final t in scene.cosas)
            if (t.hintBox != null) t.id,
        ],
        ['juncos', 'muelle', 'agua', 'lago'],
      );
      for (final k in const ['juncos', 'poste', 'muelle', 'agua', 'lago']) {
        final box = scene.box(k, const {})!,
            hint = scene.cosa(k)!.hintBox ?? box;
        expect(box, scene.sheet.things[k]!.box, reason: k);
        expect(
          hint[0] >= box[0] && hint[0] + hint[2] <= box[0] + box[2],
          isTrue,
          reason: k,
        );
        expect(
          hint[1] >= box[1] && hint[1] + hint[3] <= box[1] + box[3],
          isTrue,
          reason: k,
        );
        final h = scene.handAt(k)!;
        expect(h, scene.sheet.things[k]!.hand, reason: k);
        expect(h[0] >= hint[0] && h[0] < hint[0] + hint[2], isTrue, reason: k);
        expect(h[1] >= hint[1] && h[1] < hint[1] + hint[3], isTrue, reason: k);
      }
    },
  );

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
    // the children at their places of the stories (pan-para-el-pato: on the dock, Luis sitting)
    W['gente'] = <String, dynamic>{
      for (final (id, x, y) in const [('luis', 44, 154), ('carmen', 72, 154)])
        id: <String, dynamic>{'x': x, 'y': y, 'pose': 'idle', 'vis': 1},
    };
    for (final id in const ['luis', 'carmen']) {
      final p = (W['gente'] as Map)[id] as Map;
      for (final sent in const [0, 1]) {
        p['sent'] = sent;
        for (final pose in const ['idle', 'offer', 'arriba', 'tu', 'ojos']) {
          p['pose'] = pose;
          check(
            '$id $pose${sent == 1 ? ' sitting' : ''}',
            scene.caja(id)!,
            (c) => scene.gente(c, id, 0),
          );
        }
      }
      p['pose'] = 'idle';
      p['sent'] = 0;
    }
    W['gente'] = <String, dynamic>{};
    // each duck in each pose, on the water at its place in front of the dock (P7) and on the dock
    for (final k in Lago.PK) {
      for (final pose in const ['nada', 'vuela', 'anda']) {
        for (final a in const [0, 2]) {
          final o = <String, dynamic>{
            'k': k,
            'x': pose == 'anda' ? 104 : 156,
            'y': pose == 'anda' ? 154 : 186,
            'pose': pose,
            'dir': -1,
          };
          W['patos'] = <String, dynamic>{k: o};
          check(
            'pato_$k $pose ${a == 0 ? 'still' : 'step'}',
            scene.box('pato_$k', W)!,
            (c) => scene.pato(c, o, a),
          );
        }
      }
    }
    W['patos'] = <String, dynamic>{};
    // each bird, perched and flying
    for (final k in const ['blanco', 'negro']) {
      for (final v in const [0, 1]) {
        final o = <String, dynamic>{
          'c': k,
          'x': 133,
          'y': 140,
          'dir': -1,
          'vuela': v,
        };
        W['aves'] = <String, dynamic>{k: o};
        check(
          'ave_$k ${v == 1 ? 'flying' : 'perched'}',
          scene.box('ave_$k', W)!,
          (c) => scene.ave(c, o, 0),
        );
      }
    }
    // the blue bird on the post
    {
      final o = <String, dynamic>{'c': 'azul', 'x': 166, 'y': 132, 'dir': -1};
      W['aves'] = <String, dynamic>{'a': o};
      check('pajaro', scene.box('pajaro', W)!, (c) => scene.ave(c, o, 0));
    }
    W['aves'] = <String, dynamic>{};
    // each boat of the row on the dock, and on the water
    for (final k in const ['rojo', 'azul', 'verde']) {
      for (final en in const ['muelle', 'agua']) {
        final o = <String, dynamic>{
          'c': k,
          'x': en == 'muelle' ? 66 : 150,
          'y': en == 'muelle' ? 164 : 172,
          'en': en,
        };
        W['botes'] = <String, dynamic>{'f_$k': o};
        check('bote_$k $en', scene.box('bote_$k', W)!, (c) => scene.bote(c, o));
      }
    }
    W['botes'] = <String, dynamic>{};
    // the fish at the surface and leaping
    for (final dy in const [0, 16]) {
      final o = <String, dynamic>{
        'c': 'pardo',
        'x': 138,
        'y': 194,
        'dir': 1,
        'dy': dy,
      };
      W['peces'] = <String, dynamic>{'a': o};
      check(
        'pez ${dy == 0 ? 'at the surface' : 'leaping'}',
        scene.box('pez', W)!,
        (c) => scene.pez(c, o),
      );
    }
    W['peces'] = <String, dynamic>{};
    // Canelo, lying and barking, on the lawn (inicio20)
    for (final pose in const ['lie', 'bark']) {
      for (final a in const [0, 2]) {
        W['perro'] = <String, dynamic>{
          'x': 46,
          'y': 119,
          'pose': pose,
          'dir': 1,
        };
        check(
          'perro $pose ${a == 0 ? 'still' : 'step'}',
          scene.box('perro', W)!,
          (c) {
            final f = pose == 'bark' ? (a >> 1) % 2 : 0,
                im = mkPerro(pose, f != 0);
            c.save();
            c.translate(46, (119 - im.h + 2).toDouble());
            c.drawImage(im, -13, 0);
            c.restore();
          },
        );
      }
    }
    W['perro'] = null;
    // the flower on the right bank (inicio20)
    W['flor'] = [204, 112];
    check('flor', scene.box('flor', W)!, (c) {
      final w = <String, dynamic>{
        ...W,
        'gente': <String, dynamic>{},
        'cq': <String, dynamic>{...(W['cq'] as Map<String, dynamic>), 'vis': 0},
      };
      frame.host.W = w;
      scene.draw(c, w, 0);
      frame.host.W = W;
    });
    W['flor'] = null;
    rows.add(
      'the sprite layer\'s things: $checked checked, outside their box: $out',
    );
    expect(out.toSet(), outsideOld.keys.toSet(), reason: rows.last);
  });

  // hit at the middle of each box, in the state, the review pictures and the moments of the stories
  test('hit gives each thing its key at the middle of its box, wherever it shows', () {
    final worlds = <(String, Map<String, dynamic>, int)>[];
    worlds.add((
      'state lago',
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
      lagoPreviewCases,
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
          lagoPreviewRemapW(
            lagoPreviewBaseW(
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

  tearDownAll(() => report('lago-boxes', rows));
}
