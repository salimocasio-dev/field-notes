// El patio's acts and what is new in its sheet. Every act the six stories name runs, in each story's order and with the
// story's own arguments, on a host whose waits return at once (each one tick), and its world draws after it; the places
// the sheet moves (`moves`) are where the port puts people and the frog; the hops between the frog's places are the
// kit's count from today's places, as the sheet's `hops` and `hopsAll` say; the sun, the moon and the stars are behind the
// set (`behind`); a flower in a bed comes with its own leaves, drawn just before it (`flowerLeaves`); a bubble goes where
// the sheet's `talk` says; the ball casts its shadow on the lawn and not in the tree; the hour's blades come back with
// their state; the scene draws its random numbers from the game's one source; remap gives the sheet's places.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/patio/patio.dart';
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
  'las-flores',
  'que-es-esto',
  'hasta-manana',
  'd-la-bola',
  'd-buenas-noches',
  'h-patio',
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
// and a number y goes through the scene's remap
Object? remapPositions(Scene scene, Object? v) {
  if (v is Map) {
    final out = <String, dynamic>{
      for (final e in v.entries)
        e.key as String: remapPositions(scene, e.value),
    };
    if (v['x'] is num && v['y'] is num) {
      final r = scene.remap([v['x'] as num, v['y'] as num]);
      out['x'] = r[0];
      out['y'] = r[1];
    }
    return out;
  }
  if (v is List) return [for (final e in v) remapPositions(scene, e)];
  return v;
}

int _round(num v) => (v + .5).floor();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Patio scene;
  late TickingHost host;
  final rng = CountingRng(Mulberry32(1));
  setUpAll(() async {
    final sheet = (await ScenePictures(bundle: testBundle()).frameOf('patio'))
        .scene
        .sheet;
    frame = StillFrame(Patio(sheet, rng: rng));
    scene = frame.scene as Patio;
    host = TickingHost(scene);
  });

  Map<String, dynamic> fresh({String thing = 'none'}) {
    host
      ..fresh()
      ..S = {
        'stake': {'thing': thing, 'steps': 3},
      }
      ..F = 40;
    return host.W;
  }

  void draw(Map<String, dynamic> W, {int? F}) {
    frame.host.V = host.V;
    scene.host = frame.host;
    frame.draw(W, F: F ?? host.F, cam: scene.CAM['wide']!);
    scene.host = host;
  }

  Map<String, dynamic> person(String id) =>
      (host.W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
  List<num> at(String id) => [person(id)['x'], person(id)['y']];

  test('the frog starts at LUGAR.centro; the bird on its nest; the sun at its highest, 2 px lower than the old', () {
    final W = fresh();
    final q = W['cq'] as Map<String, dynamic>;
    expect([q['x'], q['y']], scene.sheet.spots['frog.centro']!.now);
    expect([(W['ave'] as Map)['x'], (W['ave'] as Map)['y']], [181, 66]);
    expect(W['soly'], 26);
    expect(scene.SOLY, [26, 40, 56, 73]);
    expect(scene.ESTRELLAS[5], [100, 44]);
    expect(scene.setKey(W), 'dia-shut-shut');
    W
      ..['sol'] = 3
      ..['osc'] = .3
      ..['pdoor'] = 1;
    expect(scene.setKey(W), 'crepusculo-open-shut');
    W['noche'] = 1;
    W['porton'] = 1;
    expect(scene.setKey(W), 'noche-open-open');
  });

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
        host.V = {'mem_flores': '11011-10111'};
        final acts = actsIn(story['beats']);
        expect(acts, isNotEmpty);
        // the story's variables, as a run fills them: a child, a bed, a thing from the sack
        Object? sub(String k, Object? v) {
          if (v is! String || !v.startsWith(r'$')) return v;
          if (k == 'cama') return 'L';
          if (k == 'que') return 'flor';
          return 'luis';
        }

        for (final o0 in acts) {
          if (o0['set'] is Map) {
            W.addAll(remapPositions(scene, o0['set']) as Map<String, dynamic>);
            continue;
          }
          final o = {for (final e in o0.entries) e.key: sub(e.key, e.value)};
          final name = o['act'] as String, act = scene.acts[name];
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

  test(
    'the places the sheet moves are where the port puts people and the frog',
    () async {
      List<num> moved(int line, String who) => scene.sheet.moves
          .firstWhere(
            (m) => m.line == line && m.places.any((p) => p.who == who),
          )
          .places
          .firstWhere((p) => p.who == who)
          .now;
      final W = fresh();
      await scene.acts['inicio9']!({});
      expect(at('carmen'), moved(195, 'carmen'));
      expect(at('luis'), [160, 128]);
      expect([(W['bola'] as Map)['x'], (W['bola'] as Map)['y']], [174, 128]);
      await scene.acts['asoma']!({});
      expect(at('abuela'), moved(208, 'abuela'));
      expect(W['pdoor'], 1);
      await scene.acts['seva']!({'quien': 'abuela'});
      expect(at('abuela'), moved(240, 'whoever'));
      expect(person('abuela')['vis'], 0);
      await scene.acts['juntos']!({'quien': 'luis'});
      expect(at('luis'), moved(295, 'whoever'));
      final q = W['cq'] as Map<String, dynamic>;
      expect([q['x'], q['y']], moved(86, 'cq'));
      expect([q['x'], q['y']], [126, 86]);
      await scene.acts['vuelveluis']!({});
      await scene.acts['luiscorre']!({});
      expect(at('luis'), moved(308, 'luis'));
      fresh();
      await scene.acts['inicio10']!({});
      expect(at('carmen'), moved(248, 'carmen'));
      expect(at('luis'), [190, 160]);
      fresh();
      await scene.acts['inicio11']!({});
      for (final who in const ['abuela', 'abuelo', 'mama', 'bebe', 'papa']) {
        expect(at(who), moved(290, who), reason: who);
      }
      expect(person('bebe')['z'], 137);
      expect(at('luis'), moved(291, 'luis'));
      expect(at('carmen'), moved(291, 'carmen'));
      expect(host.W['respEn'], [164, 4]);
      expect(
        [(host.W['ave'] as Map)['x'], (host.W['ave'] as Map)['y']],
        [178, 83],
      );
      expect(host.W['soly'], 73);
      // the frog goes out through the gate: LUGAR.sale, past the fence's line
      host.hops.clear();
      await scene.acts['sevan']!({});
      final s = scene.sheet.lugarOf('sale', scene.projection);
      expect(
        [(host.W['cq'] as Map)['x'], (host.W['cq'] as Map)['y']],
        [s[0], s[1]],
      );
      expect(host.hops, [3]);
    },
  );

  test('a place an act reads from the story file goes through the sheet\'s remap', () async {
    fresh();
    await scene.acts['inicio9']!({});
    // h-patio beats.20: carmen to (84, 150), which the sheet moves to (80, 150)
    await scene.acts['anda']!({'quien': 'carmen', 'x': '84', 'y': '150'});
    expect(at('carmen'), [80, 150]);
    await scene.acts['pon']!({'quien': 'luis', 'x': '136', 'y': '164'});
    expect(at('luis'), [136, 164]);
    expect(
      () => scene.acts['anda']!({'quien': 'carmen', 'x': '1', 'y': '2'}),
      throwsA(isA<SheetError>()),
    );
  });

  test('the hops between the frog\'s places are the kit\'s count from today\'s places, as the sheet says', () async {
    for (final h in scene.sheet.hopsAll) {
      for (final (from, to) in [(h.a, h.b), (h.b, h.a)]) {
        final W = fresh(), q = W['cq'] as Map<String, dynamic>;
        final L = scene.LUGAR[from]!;
        q['x'] = L[0];
        q['y'] = L[1];
        host.hops.clear();
        await scene.acts['ir']!({'a': to});
        expect(host.hops, [h.now], reason: '$from to $to');
      }
    }
    expect([
      for (final h in scene.sheet.hopsAll)
        if (h.old != h.now) '${h.a}-${h.b}',
    ], hasLength(8));
  });

  test('behind: the sun and the stars are drawn first, the set\'s own pixels over them wherever the set drew anything', () {
    // the sun low (73): the part of it over the hills and the far corner is the set's
    // (against the same frame with no sun: patio.js draws it while soly < 110)
    var W = fresh();
    W['soly'] = 110;
    W['sol'] = 3;
    draw(W);
    final none = Uint32List.fromList(frame.picture);
    final baked = frame.bakes.bakeKey(scene.setKey(W));
    W['soly'] = 73;
    draw(W);
    var sky = 0, set = 0;
    for (var y = 73 - 20; y <= 73 + 20; y++) {
      for (var x = 100 - 20; x <= 100 + 20; x++) {
        final i = y * 240 + x;
        if (baked.zb[i] > -1e8) {
          set++;
          expect(frame.picture[i], none[i], reason: '$x, $y');
        } else if (frame.picture[i] != none[i]) {
          sky++;
        }
      }
    }
    expect(
      set,
      greaterThan(50),
      reason: 'the hills and the lawn in front of the low sun',
    );
    expect(sky, greaterThan(200), reason: 'the sun shows in the sky');
    // at 109 the sun is wholly behind the set: the frame is the one with no sun
    W['soly'] = 109;
    draw(W);
    expect(frame.picture, none);
    // at night, the stars the house hides are not drawn over it; those in the sky are
    W = fresh();
    W['noche'] = 1;
    draw(W);
    final night = frame.bakes.bakeKey(scene.setKey(W));
    for (final s in scene.ESTRELLAS) {
      final i = s[1].toInt() * 240 + s[0].toInt();
      final hidden = night.zb[i] > -1e8;
      expect(
        frame.picture[i] == (0xFF000000 | (night.pix[i] & 0xFFFFFF)),
        hidden,
        reason: 'star at $s',
      );
    }
    final hidden = [
      for (final s in scene.ESTRELLAS)
        if (night.zb[s[1].toInt() * 240 + s[0].toInt()] > -1e8) s,
    ];
    expect(hidden, [
      [60, 18],
      [40, 46],
      [72, 64],
      [140, 60],
    ]);
  });

  test('a flower in a bed comes with its own leaves, drawn just before it, not dimmed', () {
    for (final (k, hora) in const [(1, 'dia'), (0, 'dia'), (1, 'noche')]) {
      final W = fresh();
      if (hora == 'noche') W['noche'] = 1;
      W['flores'] = <String, dynamic>{
        'L': [
          <String, dynamic>{'k': k, 'c': 1},
        ],
        'R': <dynamic>[],
      };
      draw(W);
      final st = scene.sheet.flowerLeaves!.stage(k == 1 ? 'open' : 'bud');
      final h = hoyo('L', 0);
      // the flower alone, on a clear picture: which pixels are its own
      final mine = Uint32List(240 * 216);
      scene.host = frame.host;
      scene.florEn(Ctx(mine, 240, 216), h[0], h[1], {'k': k, 'c': 1});
      scene.host = host;
      var leaves = 0, flower = 0;
      for (var j = 0; j < st.rows.length; j++) {
        for (var c = 0; c < st.rows[j].length; c++) {
          final ch = st.rows[j][c];
          if (ch == '.') continue;
          final x = h[0] + st.x0 + c, y = h[1] + st.y0 + j, i = y * 240 + x;
          if (mine[i] >> 24 != 0) {
            // the flower is drawn over its leaves
            expect(frame.picture[i], mine[i], reason: 'flower at $x, $y');
            flower++;
          } else {
            expect(
              frame.picture[i],
              scene.sheet.flowerLeaves!.palette[ch],
              reason: 'leaf at $x, $y ($hora)',
            );
            leaves++;
          }
        }
      }
      expect(leaves, greaterThan(k == 1 ? 80 : 40));
      expect(flower, greaterThan(0));
    }
  });

  test('the ball casts its shadow on the lawn, not in the tree', () {
    final W = fresh();
    W['bola'] = <String, dynamic>{'x': 174, 'y': 128};
    final on = scene.shadows(W).where((s) => s.r == .28).toList();
    expect(on, hasLength(1));
    final g = scene.projection.unproject(174, 127);
    expect([on.single.x, on.single.y, on.single.z], [g.x, g.y, .05]);
    W['bola'] = <String, dynamic>{'x': 196, 'y': 64};
    expect(scene.shadows(W).where((s) => s.r == .28), isEmpty);
  });

  test('talk: the frog\'s bubble goes beside his head when over it would leave the view or land on a face', () {
    final W = fresh();
    final q = W['cq'] as Map<String, dynamic>, L = scene.LUGAR['sale']!;
    q['x'] = L[0];
    q['y'] = L[1];
    q['s'] = L[2];
    q['bub'] = 'amor';
    host.cam = scene.CAM['wide']!;
    final b = host.frogBox(q);
    final top = [b.x + (b.w.toInt() >> 1), b.y + 2];
    final t = scene.talkPlace(top, b.w.toInt() >> 1, 'amor', W);
    final r = scene.sheet.bubbleRects['amor']!;
    expect(t[1] + r[1], greaterThanOrEqualTo(0));
    expect(scene.talkPlace(top, 6, null, W), top);
    draw(W);
  });

  test('the blades of a state come back with it: a frame of one hour after another\'s is the same', () {
    final day = fresh();
    draw(day);
    final first = Uint32List.fromList(frame.picture);
    final night = fresh()..['noche'] = 1;
    draw(night);
    final dusk = fresh()
      ..['sol'] = 3
      ..['osc'] = .3;
    draw(dusk);
    draw(fresh());
    expect(frame.picture, first);
  });

  test('lados draws one random number from the game\'s source; with none it says so', () async {
    fresh();
    await scene.acts['inicio9']!({});
    final before = rng.draws;
    await scene.acts['lados']!({});
    expect(rng.draws, before + 1);
    final xs = [person('luis')['x'], person('carmen')['x']]..sort();
    expect(xs, [scene.LADOS[0][0], scene.LADOS[1][0]]);
    final bare = Patio(scene.sheet);
    TickingHost(bare).fresh();
    await bare.acts['inicio9']!({});
    expect(() => bare.acts['lados']!({}), throwsStateError);
    scene.host = host;
  });

  test('remap: a ground point keeps its place, two of the stories\' the sheet moved; points in the air and directions as they are; pair rectangles their pictures\' crop', () {
    expect(scene.remap([30, 104]), [30, 104]);
    expect(scene.remap([84, 150]), [80, 150]);
    expect(scene.remap([150, 150]), [180, 150]);
    expect(scene.remap([124, 124]), [124, 124]);
    expect(scene.remap([1, -1]), [1, -1]);
    expect(scene.remap([-16, -27]), [-16, -27]);
    expect(scene.remap([16, 146, 113, 60]), [23, 150, 98, 52]);
    expect(scene.remap([22, 30, 196, 104]), [22, 30, 196, 104]);
    expect(() => scene.remap([22, 84, 196, 104]), throwsA(isA<SheetError>()));
    expect(() => scene.remap([2, 3]), throwsA(isA<SheetError>()));
    // the frog's places at the gate, from the sheet: the kit hops from them
    final p = scene.LUGAR['porton']!, s = scene.LUGAR['sale']!;
    expect([p[0], p[1], s[0], s[1]], [126, 86, 130, 68]);
    final d = math.sqrt(math.pow(p[0] - s[0], 2) + math.pow(p[1] - s[1], 2));
    expect(_round(d / 30), 1);
  });
}
