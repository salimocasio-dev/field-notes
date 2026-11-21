// El lago's acts and what is new in its sheet. Every act the five stories name runs, in each story's order and with
// values for the story's own variables, on a host whose waits return at once (each one tick), and its world draws after
// it; the places the sheet moves (`moves`) are where the port puts the post, Carmen on the right bank, the boats' rows,
// where boats stick in the reeds, the ducks' places, the fish's, the flower, and where the answer cards stand; the hops
// between the frog's places are the old ones (the sheet's `hops` is empty); a ripple ring is drawn just before whatever
// floats or swims, the fish at the surface has its pale patch (`helps`); the reeds, the post and the mooring posts are
// drawn again over whoever is behind them (`front`); no shadow falls on the water (`noShade`), on the planks and the lawn
// they do; the water's glints come and go with the frame's time; remap gives the sheet's places, and a pair picture's
// own W is placed through it; the sheet names every place of lago.js but those its rules keep (lines 263, 276, 278).
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart' show Mulberry32;
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/lago/lago.dart';
import 'package:coqui_scenes/src/lago/lago_places.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_files.dart';
import 'support/sheet_bundle.dart';

/// A still host whose every wait is one tick (the frame counter goes on), so an act that waits for frames ends; it
/// records the hops of each hopTo.
class TickingHost extends StillHost {
  TickingHost(super.scene);

  final List<int> hops = [];

  @override
  Future<void> wait(num ms) async {
    F++;
  }

  @override
  Future<void> hopTo(num x, num y, int hops, [num? s1]) {
    this.hops.add(hops);
    return super.hopTo(x, y, hops, s1);
  }
}

const stories = [
  'pan-para-el-pato',
  'los-botes',
  'cual',
  'd-pato-pequeno',
  'h-lago',
];

// every {act: ...} and {set: ...} step of a story file, in its order
List<Map<String, dynamic>> actsIn(Object? v) => [
  if (v is Map && (v['act'] is String || v['set'] is Map))
    Map<String, dynamic>.from(v),
  if (v is Map)
    for (final e in v.entries)
      if (e.key != 'set') ...actsIn(e.value),
  if (v is List)
    for (final e in v) ...actsIn(e),
];

// what the runner does with a set step's positions (feature_story steps.dart remapPositions)
Object? remapPositions(Scene scene, Object? v, [String? key]) {
  if (v is Map) {
    final out = <String, dynamic>{
      for (final e in v.entries)
        e.key as String: remapPositions(scene, e.value, e.key as String),
    };
    if (v['x'] is num && v['y'] is num) {
      final r = scene.remap([v['x'] as num, v['y'] as num]);
      out['x'] = r[0];
      out['y'] = r[1];
    }
    return out;
  }
  if (key == 'respEn' && v is List && v.length == 2) {
    return scene.remap([v[0] as num, v[1] as num]);
  }
  if (v is List) return [for (final e in v) remapPositions(scene, e)];
  return v;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Lago scene;
  late TickingHost host;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('lago');
    // the acts' own scene, with the game's random source (mueven, rina)
    scene = Lago((frame.scene as Lago).sheet, rng: Mulberry32(7));
    host = TickingHost(scene);
  });

  Map<String, dynamic> fresh({String thing = 'none'}) {
    host
      ..fresh()
      ..S = {
        'stake': {'thing': thing, 'steps': 3},
      }
      ..F = 40
      ..V = <String, dynamic>{}
      ..cam = scene.CAM['wide']!;
    return host.W;
  }

  void draw(
    Map<String, dynamic> W, {
    int? F,
    bool allSigns = false,
    int tick = 0,
  }) {
    frame.host.V = host.V;
    frame.draw(
      W,
      F: F ?? host.F,
      cam: scene.CAM['wide']!,
      allSigns: allSigns,
      tick: tick,
    );
  }

  Map<String, dynamic> person(String id) =>
      (host.W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
  Map<String, dynamic> pato(String k) =>
      (host.W['patos'] as Map<String, dynamic>)[k] as Map<String, dynamic>;
  List<num> at(Map<String, dynamic> p) => [p['x'], p['y']];

  test('the frog starts at LUGAR.inicio; one baked state; one view; the heart in the sky', () {
    final W = fresh();
    final q = W['cq'] as Map<String, dynamic>;
    expect([q['x'], q['y']], scene.sheet.spots['frog.inicio']!.now);
    expect(scene.setKey(W), 'lago');
    W['bolsa'] = [96, 153];
    W['fila'] = 6;
    W['flor'] = [204, 112];
    W['pincel'] = 'rojo';
    W['saco'] = [110, 153];
    expect(scene.setKey(W), 'lago');
    expect(scene.CAM, {
      'wide': [22, 0, 196, 216],
    });
    expect(scene.heartAt, [110, 30]);
    expect(scene.LUGAR.keys, ['inicio', 'muelle']);
  });

  // a story's variables, as a run fills them
  Object? sub(String act, String k, Object? v) {
    if (v is! String || !v.startsWith(r'$')) return v;
    switch (act) {
      case 'come':
      case 'seva':
      case 'vuelve':
      case 'rina':
        return 'pato_blanco';
      case 'empuja':
        return 'bote_rojo';
      case 'luispinta':
      case 'pezviene':
        return 'azul';
      case 'pintado':
        return 'pote_rojo';
      case 'pintamal':
        return 'pote_verde';
      case 'repone':
        return 'rav';
      case 'llegan20':
      case 'posan20':
        return 'bn';
      case 'palmas':
      case 'roba':
        return 'blanco';
    }
    return v;
  }

  for (final st in stories) {
    test(
      '$st: every act it names runs, in its order, and the world draws after each',
      () async {
        final story = jsonDecode(
          historiaFile('cuentos/$st.json')!,
        ) as Map<String, dynamic>;
        final W = fresh(
          thing: (story['stake'] as Map?)?['thing'] as String? ?? 'none',
        );
        W['marcas'] = <dynamic>[null, null, null];
        final acts = actsIn(story['beats']);
        expect(acts, isNotEmpty);
        for (final o0 in acts) {
          if (o0['set'] is Map) {
            W.addAll(remapPositions(scene, o0['set']) as Map<String, dynamic>);
            continue;
          }
          final name = o0['act'] as String;
          final o = {
            for (final e in o0.entries) e.key: sub(name, e.key, e.value),
          };
          final act = scene.acts[name];
          expect(act, isNotNull, reason: '$st: no act $name');
          await act!(o);
          draw(W);
        }
      },
      skip: historiaFile('datos/curso.json') == null
          ? 'reads historia/ (vm only)'
          : false,
    );
  }

  test('the places the sheet moves: the post, the answer cards, Carmen on the right bank, the boats, the ducks, the fish, the flower', () async {
    expect(scene.POSTE, [166, 156]);
    expect(scene.PM, [
      [40, 141],
      [133, 141],
    ]);
    expect(scene.ORILLA, [188, 109]);
    expect(scene.FX, [46, 66, 85]);
    expect(scene.FY, 165);
    expect(scene.FYB, [154, 164, 174]);
    expect(scene.PEGA, [
      [192, 160],
      [187, 156],
      [196, 165],
      [184, 162],
    ]);
    expect(scene.SLOTC, hasLength(12));
    expect(scene.slotC(0), [160, 122]);
    expect(scene.slotC(30), [196, 131]);
    expect(scene.P7(1), [156, 186]);
    expect(scene.P7(7), [183, 192]);
    expect(scene.breadAt(0), [54, 159]);
    expect(scene.breadAt(5), [114, 159]);
    // story 18: the cards over the frog, the fish on open water in front of the dock's end
    var W = fresh();
    await scene.acts['inicio18']!({});
    expect(W['respEn'], [121, 75]);
    expect(at(person('luis')), [44, 154]);
    expect(at((W['peces'] as Map)['a'] as Map<String, dynamic>), [138, 194]);
    expect(at((W['aves'] as Map)['a'] as Map<String, dynamic>), [166, 132]);
    // the duck climbs out on the far bank and back (moves lines 185, 186)
    await scene.acts['orilla']!({});
    expect(at(pato('blanco')), [102, 110]);
    await scene.acts['alagua']!({});
    expect(at(pato('blanco')), [142, 184]);
    // the duck paddles round the post (moves line 17)
    await scene.acts['rema']!({});
    expect(at(pato('blanco')), [186, 172]);
    // story 19: Carmen on the right bank; the boats' row on the planks; the boats at her feet; where a boat sticks
    W = fresh();
    await scene.acts['inicio19']!({});
    expect(W['respEn'], [127, 31]);
    expect(at(person('carmen')), [206, 110]);
    expect(
      [
        for (final c in const ['rojo', 'azul', 'verde'])
          at((W['botes'] as Map)['f_$c'] as Map<String, dynamic>),
      ],
      [
        [46, 154],
        [66, 164],
        [85, 174],
      ],
    );
    await scene.acts['empuja']!({'c': 'bote_rojo'});
    await scene.acts['sopla']!({});
    // blown: it sails to the first slot of the row at Carmen's feet (anima moves it, frame by frame)
    expect((W['botes'] as Map)['b0']['meta'], [160, 122, 1.9]);
    await scene.acts['repone']!({});
    await scene.acts['empuja']!({'c': 'bote_azul'});
    await scene.acts['deriva']!({});
    expect(at((W['botes'] as Map)['b1'] as Map<String, dynamic>), [192, 160]);
    // story 20: the cards in the sky, the flower on the right bank, the ducks' places
    W = fresh();
    await scene.acts['inicio20']!({});
    expect(W['respEn'], [132, 32]);
    expect(W['flor'], [204, 112]);
    expect(
      [for (final k in Lago.PK) at(pato(k))],
      [
        [151, 179],
        [179, 181],
        [165, 200],
      ],
    );
  });

  test(
    'the hops: all 21 counts are the old ones (the sheet\'s hops is empty)',
    () {
      num count(List<num> a, List<num> b) {
        final dx = a[0] - b[0], dy = a[1] - b[1];
        final d = math.sqrt(dx * dx + dy * dy);
        return d < 3 ? 0 : math.max(1, math.min(4, ((d / 30) + .5).floor()));
      }

      List<num> now(String n) => scene.sheet.spots['frog.$n']!.now!;
      List<num> old(String n) => scene.sheet.spots['frog.$n']!.old;
      expect(scene.sheet.hops, isEmpty);
      expect(scene.sheet.hopsAll, hasLength(21));
      for (final h in scene.sheet.hopsAll) {
        expect(count(now(h.a), now(h.b)), h.now, reason: '${h.a}-${h.b} today');
        expect(count(old(h.a), old(h.b)), h.old, reason: '${h.a}-${h.b} old');
        expect(h.now, h.old, reason: '${h.a}-${h.b}');
      }
    },
  );

  // the pixels of [W]'s frame that are [col]
  int colourCount(Map<String, dynamic> W, int col, {int F = 0}) {
    draw(W, F: F);
    var n = 0;
    for (final p in frame.picture) {
      if (p == col) n++;
    }
    return n;
  }

  test('helps.ring: a ripple ring before a duck swimming, a boat on the water and the bread on the water; none for a duck on the dock, a boat on the dock, a flying duck', () {
    final ring = scene.sheet.helps!.ring.colour;
    final W = fresh();
    (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    expect(colourCount(W, ring), 0);
    W['patos'] = <String, dynamic>{
      'blanco': <String, dynamic>{
        'k': 'blanco',
        'x': 156,
        'y': 186,
        'pose': 'nada',
        'dir': -1,
      },
    };
    final swim = colourCount(W, ring);
    expect(swim, greaterThan(10));
    pato('blanco')
      ..['pose'] = 'anda'
      ..['x'] = 104
      ..['y'] = 154;
    expect(colourCount(W, ring), 0);
    pato('blanco')
      ..['pose'] = 'vuela'
      ..['x'] = 150
      ..['y'] = 60;
    expect(colourCount(W, ring), 0);
    W['patos'] = <String, dynamic>{};
    W['botes'] = <String, dynamic>{
      'b0': <String, dynamic>{'c': 'rojo', 'x': 150, 'y': 190, 'en': 'agua'},
    };
    expect(colourCount(W, ring), greaterThan(10));
    W['botes'] = <String, dynamic>{
      'f_rojo': <String, dynamic>{
        'c': 'rojo',
        'x': 46,
        'y': 154,
        'en': 'muelle',
      },
    };
    expect(colourCount(W, ring), 0);
    W['botes'] = <String, dynamic>{};
    W['pan'] = <String, dynamic>{
      'con': null,
      'x': 143,
      'y': 184,
      'z': 0,
      'vis': 1,
    };
    expect(colourCount(W, ring), greaterThan(5));
    W['pan'] = <String, dynamic>{
      'con': null,
      'x': 96,
      'y': 160,
      'z': 0,
      'vis': 1,
    };
    expect(colourCount(W, ring), 0);
  });

  test('the fish\'s patch: paler water under the fish at the surface (its own two colours), none when it leaps', () {
    final H = scene.sheet.helps!.ring.patch('pez');
    final W = fresh();
    (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    final none = colourCount(W, H.patch);
    W['peces'] = <String, dynamic>{
      'a': <String, dynamic>{'c': 'pardo', 'x': 138, 'y': 194, 'dir': 1},
    };
    final at0 = colourCount(W, H.patch);
    expect(at0 - none, greaterThan(60));
    ((W['peces'] as Map)['a'] as Map)['dy'] = 16;
    expect(colourCount(W, H.patch), none);
    // the patch is 26 x 17 at most, dithered at its edge: never a full box
    expect(at0 - none, lessThan(26 * 17));
  });

  // how many pixels of the frame inside [box] are the set's own (drawn over the item)
  int setPixelsOver(Map<String, dynamic> W, List<num> box) {
    draw(W);
    final withIt = Uint32List.fromList(frame.picture);
    final W0 = {
      ...W,
      'patos': <String, dynamic>{},
      'botes': <String, dynamic>{},
    };
    (W0['cq'] as Map<String, dynamic>)['vis'] = 0;
    draw(W0);
    var n = 0;
    for (var y = box[1].toInt(); y < box[1] + box[3]; y++) {
      for (var x = box[0].toInt(); x < box[0] + box[2]; x++) {
        if (withIt[y * 240 + x] == frame.picture[y * 240 + x]) n++;
      }
    }
    return n;
  }

  test('front: the post is drawn again over a duck paddling behind it; the reeds over a boat stuck among them', () {
    var W = fresh();
    (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    // a duck behind the post (rema's circle, the far side)
    W['patos'] = <String, dynamic>{
      'blanco': <String, dynamic>{
        'k': 'blanco',
        'x': 166,
        'y': 165,
        'pose': 'nada',
        'dir': -1,
      },
    };
    final postBox = scene.box('poste', W)!;
    final over = setPixelsOver(W, [162, 150, 8, 15]);
    expect(over, greaterThan(0), reason: 'the post over the duck, $postBox');
    // a boat stuck in the reeds (PEGA)
    W = fresh();
    (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    W['botes'] = <String, dynamic>{
      'b0': <String, dynamic>{
        'c': 'rojo',
        'x': scene.PEGA[1][0],
        'y': scene.PEGA[1][1],
        'en': 'juncos',
      },
    };
    expect(setPixelsOver(W, [177, 137, 22, 22]), greaterThan(0));
  });

  test('shadows: on the lawn and the planks; none from a duck swimming, a boat on the water or the bread on the water', () async {
    final W = fresh();
    await scene.acts['inicio20']!({});
    final kinds = [for (final s in scene.shadows(W)) s.r];
    // the frog, Luis sitting (4), Carmen (5), Canelo, the bag; no duck (all swimming)
    final sh = scene.sheet.shadows;
    expect(kinds.where((r) => r == sh['coqui']!.radius), hasLength(1));
    expect(
      kinds.where((r) => r == sh['people']!.radii!['nino']!),
      hasLength(9),
    );
    expect(kinds.where((r) => r == sh['pato']!.radius), isEmpty);
    // a duck walking on the dock casts one
    pato('blanco')
      ..['pose'] = 'anda'
      ..['x'] = 104
      ..['y'] = 154;
    expect(
      [for (final s in scene.shadows(W)) s.r]
          .where((r) => r == sh['pato']!.radius),
      hasLength(1),
    );
    // the bread on the water: none; on the dock: one
    W['pan'] = <String, dynamic>{
      'con': null,
      'x': 143,
      'y': 184,
      'z': 0,
      'vis': 1,
    };
    expect(
      [for (final s in scene.shadows(W)) s.r]
          .where((r) => r == sh['pan']!.radius),
      isEmpty,
    );
    W['pan'] = <String, dynamic>{
      'con': null,
      'x': 96,
      'y': 160,
      'z': 0,
      'vis': 1,
    };
    expect(
      [for (final s in scene.shadows(W)) s.r]
          .where((r) => r == sh['pan']!.radius),
      hasLength(1),
    );
    // a shadow cast over the water darkens nothing there (noShade): the frame with a swimming child's shadow is the frame
    // without it on the water
    final W2 = fresh();
    (W2['cq'] as Map<String, dynamic>)['vis'] = 0;
    draw(W2);
    final before = Uint32List.fromList(frame.picture);
    final kindsNow = Uint8List.fromList(frame.engine.kinds);
    W2['patos'] = <String, dynamic>{
      'blanco': <String, dynamic>{
        'k': 'blanco',
        'x': 120,
        'y': 200,
        'pose': 'anda',
        'dir': -1,
        'vis': 0,
      },
    };
    draw(W2);
    var water = 0;
    for (var i = 0; i < before.length; i++) {
      if (kindsNow[i] == 2 && before[i] != frame.picture[i]) water++;
    }
    expect(water, 0);
  });

  test('the water\'s glints come and go with the frame\'s time: on the water two frames differ only at its glints', () {
    final W = fresh();
    (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    final glints = <int>{
      for (final g in frame.engine.glints) ...[g.i - 1, g.i, g.i + 1],
    };
    draw(W, F: 0, tick: 50);
    expect(frame.engine.glints, isNotEmpty);
    final t0 = Uint32List.fromList(frame.engine.pix);
    final kinds = Uint8List.fromList(frame.engine.kinds);
    draw(W, F: 30, tick: 50);
    final t1 = Uint32List.fromList(frame.engine.pix);
    var water = 0, atGlints = 0;
    for (var i = 0; i < t0.length; i++) {
      if (t0[i] == t1[i] || kinds[i] != 2) continue;
      water++;
      if (glints.contains(i)) atGlints++;
    }
    expect(water, greaterThan(0));
    expect(atGlints, water);
  });

  test('remap: a story position keeps its place but the ones the sheet moved; the frog out of a picture as it is; pair rectangles their pictures\' crop', () {
    for (final r in scene.sheet.remapTable) {
      if (r.kind == 'point' && !r.moved && r.now != null) {
        expect(scene.remap(r.old), r.now, reason: '${r.old}');
        expect(scene.remap(r.old), r.old, reason: 'the floor rule');
      }
    }
    expect(scene.remap([96, 118]), [86, 113]);
    expect(scene.remap([104, 172]), [120, 194]);
    expect(scene.remap([152, 122]), [166, 132]);
    expect(scene.remap([140, 119]), [208, 110]);
    expect(scene.remap([0, 0]), [0, 0]);
    expect(scene.remap([84, 84, 113, 60]), [142, 76, 98, 52]);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
  });

  test('a pair picture\'s own W: its ducks, birds, boats and fish through the remap (pájaro.si: the bird on the right bank)', () {
    final w = ScenePictures.pictureW(scene, const {
      'aves': {
        'a': {'c': 'azul', 'x': 140, 'y': 119, 'dir': -1, 'pan': 1},
      },
      'patos': {
        'a': {'k': 'blanco', 'x': 100, 'y': 154, 'pose': 'anda', 'dir': -1},
      },
      'botes': {
        'a': {'c': 'verde', 'x': 96, 'y': 153, 'en': 'muelle'},
      },
      'cq': {'x': 0, 'y': 0, 's': 1, 'dy': 0, 'al': 1, 'vis': 0, 'bub': null},
    });
    expect(at((w['aves'] as Map)['a'] as Map<String, dynamic>), [208, 110]);
    expect(at((w['patos'] as Map)['a'] as Map<String, dynamic>), [100, 154]);
    expect(at((w['botes'] as Map)['a'] as Map<String, dynamic>), [96, 153]);
  });

  test('the sheet names every place of lago.js but those its rules keep (lines 263, 276, 278), and floorRule serves those lines only', () {
    final p = LagoPlaces(scene.sheet, scene.projection);
    expect(LagoPlaces.floorRuleOnly, {263, 276, 278});
    expect(p.floorRule(263, 70), 70);
    expect(() => p.floorRule(262, 1), throwsA(isA<SheetError>()));
    expect(() => p.floor(240, 1, 2), throwsA(isA<SheetError>()));
    expect(() => p.keep(240, 1), throwsA(isA<SheetError>()));
  });
}
