// El camino's acts and what is new in its sheet. Every act the five stories name runs, in each story's order and with the
// story's own arguments, on a host whose waits return at once (each one tick), and its world draws after it; the places
// the sheet moves (`moves`) are where the port puts people, Canelo, the cat and the frog, and where the answer cards
// stand; the hops between the frog's places are the kit's count from today's places, all 21 the old ones (the sheet's
// `hops` is empty); everyone leaves through the arch in a file (`sevan`); the bench and the arch are drawn again over
// whoever is behind them (`front`); the big tree's hint frame and twinkle are drawn round its hint box (`hintBox`); a
// bubble goes where the sheet's `talk` says; the shadows the sheet names; the scene draws its random numbers from the
// game's one source; remap gives the sheet's places.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/camino/camino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/content_files.dart';
import 'support/sheet_bundle.dart';

/// A still host whose every wait is one tick (the frame counter goes on), so an act that waits for frames ends; it
/// records the hops of each hopTo, and the ms of every wait.
class TickingHost extends StillHost {
  TickingHost(super.scene);

  final List<int> hops = [];
  final List<num> waits = [];

  @override
  Future<void> wait(num ms) async {
    waits.add(ms);
    F++;
  }

  @override
  Future<void> hopTo(num x, num y, int hops, [num? s1]) {
    this.hops.add(hops);
    return super.hopTo(x, y, hops, s1);
  }
}

/// The game's one random source, counting its draws.
class CountingRng implements Rng {
  CountingRng(this.inner);

  final Rng inner;
  int draws = 0;

  @override
  double next() {
    draws++;
    return inner.next();
  }
}

const stories = [
  'uno-dos-tres',
  'donde-esta-el-gato',
  'rapido-despacio',
  'd-corre',
  'h-camino',
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

// what the runner does with a set step's positions (feature_story steps.dart remapPositions): each map with a number x
// and a number y goes through the scene's remap, and so does where the answer cards stand (respEn)
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
  late Camino scene;
  late TickingHost host;
  final rng = CountingRng(Mulberry32(1));
  setUpAll(() async {
    final sheet = (await ScenePictures(bundle: testBundle()).frameOf('camino'))
        .scene
        .sheet;
    frame = StillFrame(Camino(sheet, rng: rng));
    scene = frame.scene as Camino;
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

  void draw(Map<String, dynamic> W, {int? F, bool allSigns = false}) {
    frame.host.V = host.V;
    scene.host = frame.host;
    frame.draw(W, F: F ?? host.F, cam: scene.CAM['wide']!, allSigns: allSigns);
    scene.host = host;
  }

  Map<String, dynamic> person(String id) =>
      (host.W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
  List<num> at(Map<String, dynamic> p) => [p['x'], p['y']];

  test('the frog starts at LUGAR.inicio; one set parameter, the big tree', () {
    final W = fresh();
    final q = W['cq'] as Map<String, dynamic>;
    expect([q['x'], q['y']], scene.sheet.spots['frog.inicio']!.now);
    expect(scene.setKey(W), '1');
    W['sinGran'] = 1;
    expect(scene.setKey(W), '0');
    expect(scene.CAM, {
      'wide': [22, 0, 196, 216],
    });
    expect(scene.heartAt, [110, 30]);
  });

  // a story's variables, as a run fills them
  Object? sub(String act, String k, Object? v) {
    if (v is! String || !v.startsWith(r'$')) return v;
    if (act == 'posan') return '231';
    if (act == 'gatoarbol' || k == 'en') return '1';
    if (act == 'desigual' || act == 'paseo') return 'despacio';
    return 'corre';
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

  test('the places the sheet moves: the answer cards in the sky, Canelo at marks 7 and 8, the cat on the bench, the frog at the first tree', () async {
    var W = fresh();
    await scene.acts['inicio12']!({});
    expect(W['respEn'], [134, 14]);
    expect(at(person('luis')), [174, 138]);
    expect(at(person('carmen')), scene.sheet.spots['nina.0']!.now);
    final pe = W['perro'] as Map<String, dynamic>;
    expect(at(pe), scene.sheet.spots['perro.0']!.now);
    expect(scene.perroEn(7), [188, 133]);
    expect(scene.perroEn(8), [188, 130]);
    for (var i = 0; i < 7; i++) {
      expect(scene.perroEn(i), scene.sheet.spots['perro.$i']!.old);
    }
    expect(scene.LUGAR['arbol0'], [49, 121, .8]);
    W = fresh();
    await scene.acts['inicio13']!({});
    expect(W['respEn'], [120, 34]);
    expect(W['sinGran'], 1);
    expect(at(W['gato'] as Map<String, dynamic>), [92, 123]);
    // the cat's hint hand at its back (moves line 69)
    expect(scene.handAt('gato'), [104, 113]);
    W = fresh();
    await scene.acts['inicio14']!({});
    expect(W['respEn'], [134, 34]);
    expect(at(person('abuela')), [66, 182]);
    expect(W['arbusto'], [104, 188]);
  });

  test('a place an act reads from the story file goes through the sheet\'s remap (d-corre beats.49: Canelo at the first tree)', () async {
    final W = fresh();
    await scene.acts['inicio12']!({});
    await scene.acts['perroa']!({'x': 88, 'y': 134});
    expect(at(W['perro'] as Map<String, dynamic>), [80, 149]);
    expect(
      () => scene.acts['perroa']!({'x': '1', 'y': '2'}),
      throwsA(isA<SheetError>()),
    );
  });

  test('the hops between the frog\'s places are the kit\'s count from today\'s places, all 21 the old', () async {
    expect(scene.sheet.hops, isEmpty);
    expect(scene.sheet.hopsAll, hasLength(21));
    for (final h in scene.sheet.hopsAll) {
      expect(h.now, h.old, reason: '${h.a}-${h.b}');
      for (final (from, to) in [(h.a, h.b), (h.b, h.a)]) {
        final W = fresh(), q = W['cq'] as Map<String, dynamic>;
        final L = scene.LUGAR[from]!;
        q['x'] = L[0];
        q['y'] = L[1];
        host.hops.clear();
        await scene.acts['ir']!({'a': to});
        expect(host.hops, [h.old], reason: '$from to $to');
      }
    }
  });

  test('sevan: everyone leaves through the arch in a file, 3 ticks apart, fading past its line; Canelo fades too; the frog hops twice', () async {
    final W = fresh(), sv = scene.sheet.sevan!;
    await scene.acts['inicio14']!({});
    host.waits.clear();
    host.hops.clear();
    // drawn at each tick: each one's place and how faded, every frame
    final seen = <String, List<(num, num, num)>>{};
    final pe = W['perro'] as Map<String, dynamic>,
        q = W['cq'] as Map<String, dynamic>;
    final who = {
      'abuela': person('abuela'),
      'carmen': person('carmen'),
      'luis': person('luis'),
      'perro': pe,
      'cq': q,
    };
    final run = scene.acts['sevan']!({});
    await run;
    for (final e in who.entries) {
      final p = e.value, last = sv.points[e.key]![1];
      expect([p['x'], p['y']], last, reason: e.key);
      expect(p['al'], 1 - 7 / 8, reason: e.key);
      expect(p['vis'], 0, reason: e.key);
      seen[e.key] = [];
    }
    // the waits: 5 each one's delay (0, 3, 6, 9, 12 ticks), 8 ticks each, then 500 ms; no hopTo (the frog's hops are the
    // act's own, two hop sounds)
    expect(host.hops, isEmpty);
    expect(host.waits.where((w) => w == host.TICK).length, 5 * 8);
    expect(host.waits.last, 500);
    expect(
      [
        for (final w in host.waits)
          if (w != host.TICK && w != 500) w,
      ]..sort(),
      [0, 3 * host.TICK, 6 * host.TICK, 9 * host.TICK, 12 * host.TICK],
    );
    expect(W['correa'], 0);
    expect(q['dy'], 0);
  });

  test('Canelo is drawn with his al (moves line 84): faded, his pixels are fainter', () {
    final W = fresh();
    W['perro'] = <String, dynamic>{'x': 120, 'y': 170, 'pose': 'sit', 'dir': 1};
    draw(W);
    final full = Uint32List.fromList(frame.picture);
    (W['perro'] as Map<String, dynamic>)['al'] = .25;
    draw(W);
    final faded = Uint32List.fromList(frame.picture);
    W['perro'] = null;
    draw(W);
    final none = Uint32List.fromList(frame.picture);
    var dog = 0, fainter = 0;
    for (var i = 0; i < full.length; i++) {
      if (full[i] == none[i]) continue;
      dog++;
      if (faded[i] != full[i]) fainter++;
    }
    expect(dog, greaterThan(100));
    expect(fainter, greaterThan(dog * .9));
  });

  // the pixels of [W]'s frame where [id]'s own drawing would show but the frame is the frame without them: the set drawn
  // again over them (the sheet's front)
  int coveredBack(Map<String, dynamic> W, String id) {
    draw(W);
    final withP = Uint32List.fromList(frame.picture);
    final g = Map<String, dynamic>.from(W['gente'] as Map);
    final p = g.remove(id) as Map<String, dynamic>;
    final w2 = {...W, 'gente': g};
    draw(w2);
    final without = Uint32List.fromList(frame.picture);
    final mine = Uint32List(240 * 216), c = Ctx(mine, 240, 216);
    scene.host = frame.host;
    frame.host.W = {...W};
    scene.gente(c, id, 0);
    scene.host = host;
    var n = 0;
    for (var i = 0; i < mine.length; i++) {
      if (mine[i] >> 24 != 0 && withP[i] == without[i]) n++;
    }
    expect(p, isNotNull);
    return n;
  }

  test('front: the bench is drawn again over Carmen behind it, at a small tree; nothing of it over Carmen in front', () async {
    final W = fresh();
    await scene.acts['inicio13']!({});
    final c = person('carmen');
    final behind = scene.sheet.spots['carmenva.0']!.now!;
    c['x'] = behind[0];
    c['y'] = behind[1];
    c.remove('lleva');
    final n = coveredBack(W, 'carmen');
    expect(n, greaterThan(20), reason: 'the bench over Carmen at carmenva.0');
    // in front of the bench, on the path's near side: nothing of the set over her
    c['x'] = 200;
    c['y'] = 205;
    expect(coveredBack(W, 'carmen'), 0);
  });

  test('front: the arch is drawn again over whoever is under it (sevan\'s point inside the opening)', () async {
    final W = fresh();
    await scene.acts['inicio14']!({});
    final p = person('abuela'), pt = scene.sheet.sevan!.points['abuela']!;
    p['x'] = pt[0][0];
    p['y'] = pt[0][1];
    expect(coveredBack(W, 'abuela'), greaterThan(0));
  });

  test('the big tree\'s hint frame and twinkle are drawn round its hint box; another thing\'s round its box', () {
    final hint = scene.cosa('grande')!.hintBox!;
    for (final k in const ['grande', 'arbol0', 'porton']) {
      for (final sign in const ['spot', 'twinkle']) {
        final W = fresh();
        W[sign] = k;
        draw(W, allSigns: true);
        final got = Uint32List.fromList(frame.picture);
        // the same frame with the sign drawn by hand round the box it should be round
        W[sign] = null;
        draw(W, allSigns: true);
        final c = Ctx(frame.picture, 240, 216);
        final b = k == 'grande' ? hint : scene.box(k, W)!;
        frame.host.F = host.F;
        if (sign == 'spot') {
          spot(c, b, host.F >> 1, scene.SW, scene.SH);
        } else {
          frame.host.signs.twinkle(c, b);
        }
        expect(got, frame.picture, reason: '$sign at $k round $b');
      }
    }
    // a touch still answers in the box: a point in the box but outside the hint box is the big tree's
    final W = fresh();
    expect(scene.hit(230, 5, W), 'grande');
  });

  test('shadows: the frog, the people, Canelo, the cat on the ground but not on the bench, the bush; none .5 or less faded', () async {
    final W = fresh();
    await scene.acts['inicio13']!({});
    List<num> radii(Map<String, dynamic> W) =>
        [for (final s in scene.shadows(W)) s.r]..sort();
    // the frog, two children standing (5 each), Canelo; the cat on the bench casts none
    expect(
      radii(W),
      [
        .25 + 0.07, // Canelo .32
        ...List.filled(10, .3),
        .45,
      ]..sort(),
    );
    (W['gato'] as Map<String, dynamic>)
      ..['x'] = 120
      ..['y'] = 170;
    expect(scene.shadows(W).where((s) => s.r == .25), hasLength(1));
    W['arbusto'] = [90, 193];
    expect(scene.shadows(W).where((s) => s.r == .55), hasLength(1));
    (W['perro'] as Map<String, dynamic>)['al'] = .5;
    expect(scene.shadows(W).where((s) => s.r == .32), isEmpty);
    person('luis')['sent'] = 1;
    expect(scene.shadows(W).where((s) => s.r == .3 && s.z == .3), hasLength(2));
  });

  test(
    'talk: a bubble clear of the corner card goes beside the head',
    () async {
      final W = fresh();
      await scene.acts['inicio14']!({});
      W['tarjeta'] = 'guineos';
      final top = [60, 20];
      final t = scene.talkPlace(top, 6, 'amor', W);
      final r = scene.sheet.bubbleRects['amor']!, x0 = scene.CAM['wide']![0];
      final rect = [t[0] + r[0], t[1] + r[1], r[2], r[3]];
      final card = [2 + x0, 2, 86, 32];
      final meets =
          rect[0] < card[0] + card[2] &&
          card[0] < rect[0] + rect[2] &&
          rect[1] < card[1] + card[3] &&
          card[1] < rect[1] + rect[3];
      expect(t == top || !meets, isTrue);
      expect(scene.talkPlace(top, 6, null, W), top);
      draw(W);
    },
  );

  test('gatoarbol draws two random numbers from the game\'s source; with none it says so', () async {
    fresh();
    await scene.acts['inicio13']!({});
    await scene.acts['posan']!({'p': '231'});
    final before = rng.draws;
    await scene.acts['gatoarbol']!({'en': '1', 'que': 'cola'});
    expect(rng.draws, before + 2);
    expect(host.V['n'], '3');
    expect({host.V['oa'], host.V['ob']}, {'2', '1'});
    final bare = Camino(scene.sheet);
    TickingHost(bare).fresh();
    await bare.acts['inicio13']!({});
    expect(() => bare.acts['gatoarbol']!({'en': '0'}), throwsStateError);
    scene.host = host;
  });

  test('remap: a ground point keeps its place, the stories\' the sheet moved; where the cards stand; counts as they are; pair rectangles their pictures\' crop', () {
    for (final r in scene.sheet.remapTable) {
      if (r.kind == 'point' && !r.moved && r.now != null) {
        expect(scene.remap(r.old), r.now, reason: '${r.old}');
        expect(scene.remap(r.old), r.old, reason: 'the floor rule');
      }
    }
    expect(scene.remap([113, 134]), [92, 123]);
    expect(scene.remap([88, 134]), [80, 149]);
    expect(scene.remap([96, 30]), [134, 14]);
    expect(scene.remap([0, 2, 0]), [0, 2, 0]);
    expect(scene.remap([22, 84, 196, 104]), [22, 84, 196, 104]);
    expect(scene.remap([40, 120, 150, 79.6]), [17, 108, 196, 104]);
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
  });
}
