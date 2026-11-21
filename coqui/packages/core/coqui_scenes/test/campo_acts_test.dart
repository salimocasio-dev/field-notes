// El campo's acts and what is new in its sheet. Every act the five stories name runs, in each story's order and with the
// story's own arguments, on a host whose waits return at once (each one tick), and its world draws after it; the places
// the sheet moves (`moves`) are where the port puts the children, Canelo, the balls and the frog, and where the answer
// cards stand; the hops between the frog's places are the kit's count from today's places (the sheet's `hops`: 6 pairs
// one fewer, none walked in a recorded run; the acts' own hopTo counts are the old); a ripple ring is drawn just before
// whatever floats or wades (`helps.ring`); the reeds are drawn again over whoever is behind them (`front`); the hint
// frames and twinkles of the tree and the reeds are drawn round their hint boxes (`hintBox`); a bubble goes where the
// sheet's `talk` says; the shadows the sheet names; the darkness of the frog's shut eyes; the water's glints come and go
// with the frame's time; remap gives the sheet's places, and a pair picture's own W is placed through it.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/campo/campo.dart';
import 'package:coqui_scenes/src/campo/campo_places.dart';
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

const stories = [
  'la-bola',
  'arriba-abajo',
  'otra-vez',
  'd-bola-canelo',
  'h-campo',
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
  late Campo scene;
  late TickingHost host;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('campo');
    scene = frame.scene as Campo;
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
    scene.host = frame.host;
    frame.draw(
      W,
      F: F ?? host.F,
      cam: scene.CAM['wide']!,
      allSigns: allSigns,
      tick: tick,
    );
    scene.host = host;
  }

  Map<String, dynamic> person(String id) =>
      (host.W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
  Map<String, dynamic> ball(String n) =>
      (host.W['bolas'] as Map<String, dynamic>)[n] as Map<String, dynamic>;
  List<num> at(Map<String, dynamic> p) => [p['x'], p['y']];

  test('the frog starts at LUGAR.inicio; one baked state; one view; the heart in the sky', () {
    final W = fresh();
    final q = W['cq'] as Map<String, dynamic>;
    expect([q['x'], q['y']], scene.sheet.spots['frog.inicio']!.now);
    expect(scene.setKey(W), 'campo');
    W['mojado'] = 3;
    W['oscuro'] = .5;
    W['cesta'] = [88, 208];
    expect(scene.setKey(W), 'campo');
    expect(scene.CAM, {
      'wide': [22, 0, 196, 216],
    });
    expect(scene.heartAt, [110, 30]);
    expect(scene.LUGAR.keys, ['centro', 'inicio']);
  });

  // a story's variables, as a run fills them
  Object? sub(String act, String k, Object? v) {
    if (v is! String || !v.startsWith(r'$')) return v;
    if (act == 'bienA' || act == 'malA') return 'tira';
    if (act == 'esconden' || act == 'ensena') return 'luis';
    if (act == 'quien15' || act == 'duda') return 'carmen';
    if (act == 'tiro') return 'arriba';
    if (k == 'en') return 'abajo';
    if (act == 'perrocoge') return 'cq';
    if (act == 'hazB') return 'tira';
    return 'bola_cq';
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

  test('the places the sheet moves: the answer cards in the sky, the ball hidden in the reeds, the balls afloat, the shore\'s places on the lawn or in the water', () async {
    for (final a in const ['inicio15', 'inicio16', 'inicio17']) {
      final W = fresh();
      await scene.acts[a]!({});
      expect(W['respEn'], [132, 32], reason: a);
    }
    expect(scene.JUNCO, [185, 205]);
    // the frog at the reeds (acts.busca, abajo): on the lawn above them
    var W = fresh();
    await scene.acts['inicio16']!({});
    host.hops.clear();
    await scene.acts['busca']!({'en': 'abajo'});
    expect(at(W['cq'] as Map<String, dynamic>), [147, 153]);
    expect(host.hops, [3]);
    // the four places a ball floats on the lake (acts.alagua)
    W = fresh();
    await scene.acts['inicio16']!({});
    final afloat = <List<num>>[];
    for (var k = 0; k < 4; k++) {
      (W['bolas'] as Map<String, dynamic>)['juego'] = <String, dynamic>{
        'k': 'q',
        'x': 120,
        'y': 190,
        'z': 0,
      };
      await scene.acts['alagua']!({});
      afloat.add(at(ball('flota$k')));
      expect(ball('flota$k')['flota'], 1);
    }
    expect(afloat, [
      [203, 206],
      [202, 191],
      [201, 207],
      [170, 207],
    ]);
    // Canelo by the water in story 17, and the ball he leaves at the shore (malA17)
    W = fresh();
    await scene.acts['inicio17']!({});
    await scene.acts['sube17']!({});
    expect(at(W['perro'] as Map<String, dynamic>), [155, 178]);
    await scene.acts['alafila']!({'b': 'luis'});
    expect(at(W['perro'] as Map<String, dynamic>), [157, 177]);
    await scene.acts['jadea']!({});
    expect(at(W['perro'] as Map<String, dynamic>), [146, 188]);
    await scene.acts['empuja']!({});
    expect(at(W['perro'] as Map<String, dynamic>), [153, 183]);
    await scene.acts['malA17']!({'b': 'bola_cq'});
    expect(at(ball('cq')), [166, 207]);
    // the children by the water when none is right (acts.final16)
    W = fresh();
    await scene.acts['inicio16']!({});
    W['marcas'] = <dynamic>['x', 'x', 'x'];
    await scene.acts['final16']!({});
    expect(at(person('luis')), [147, 191]);
    expect(at(person('carmen')), [127, 201]);
    // Luis at the reeds (acts.luisbusca, abajo), and under the tree as before
    W = fresh();
    await scene.acts['inicio16']!({});
    await scene.acts['luisbusca']!({'en': 'abajo'});
    expect(at(person('luis')), [158, 186]);
    W = fresh();
    await scene.acts['inicio16']!({});
    await scene.acts['luisbusca']!({'en': 'arriba'});
    expect(at(person('luis')), [82, 166]);
  });

  test('a ball a child holds up sits in the raised hand (moves line 59): 8 px to the side the child faces, h - 3 over the feet', () async {
    fresh();
    await scene.acts['inicio15']!({});
    final lu = person('luis');
    lu['pose'] = 'arriba';
    expect(scene.manos('luis'), [
      (lu['x'] as num) + 8,
      (lu['y'] as num) + 1,
      44 - 3,
    ]);
    lu['dir'] = -1;
    expect(scene.manos('luis')[0], (lu['x'] as num) - 8);
    lu['pose'] = 'offer';
    expect(scene.manos('luis'), [
      (lu['x'] as num) - 11,
      (lu['y'] as num) + 1,
      44 - 27,
    ]);
  });

  test('a place an act reads from the story file goes through the sheet\'s remap (d-bola-canelo beats.27 and .37: Canelo by the water)', () async {
    final W = fresh();
    await scene.acts['inicio15']!({});
    await scene.acts['perro']!({'x': 168, 'y': 192, 'modo': 'walk'});
    expect(at(W['perro'] as Map<String, dynamic>), [157, 179]);
    await scene.acts['perro']!({'x': 176, 'y': 176});
    expect(at(W['perro'] as Map<String, dynamic>), [172, 172]);
    expect(
      () => scene.acts['perro']!({'x': 1, 'y': 2}),
      throwsA(isA<SheetError>()),
    );
  });

  test('the hops: the kit\'s count from today\'s places; the 6 pairs of the sheet\'s hops one fewer, the others the old', () async {
    num count(List<num> a, List<num> b) {
      final dx = a[0] - b[0], dy = a[1] - b[1];
      final d = math.sqrt(dx * dx + dy * dy);
      // campo-sheet-make.js hop: kit.js acts.ir hops none under 3 px (it only sets the scale)
      return d < 3 ? 0 : math.max(1, math.min(4, ((d / 30) + .5).floor()));
    }

    List<num> now(String n) => scene.sheet.spots['frog.$n']!.now!;
    List<num> old(String n) => scene.sheet.spots['frog.$n']!.old;
    expect(scene.sheet.hopsAll, hasLength(91));
    final changed = <String>[];
    for (final h in scene.sheet.hopsAll) {
      expect(count(now(h.a), now(h.b)), h.now, reason: '${h.a}-${h.b} today');
      expect(count(old(h.a), old(h.b)), h.old, reason: '${h.a}-${h.b} old');
      if (h.now != h.old) changed.add('${h.a}-${h.b}');
    }
    expect(changed, [for (final h in scene.sheet.hops) '${h.a}-${h.b}']);
    expect(scene.sheet.hops, hasLength(6));
    for (final h in scene.sheet.hops) {
      expect(h.now, h.old - 1, reason: '${h.a}-${h.b}');
    }
    // the kit's ir between LUGAR's places (centro, inicio: the same place)
    final W = fresh(), q = W['cq'] as Map<String, dynamic>;
    q['x'] = 60;
    q['y'] = 150;
    host.hops.clear();
    await scene.acts['ir']!({'a': 'centro'});
    expect(host.hops, [
      count([60, 150], scene.LUGAR['centro']!),
    ]);
  });

  // the pixels of [W]'s frame that are [col]
  int colourCount(Map<String, dynamic> W, int col) {
    draw(W);
    var n = 0;
    for (final p in frame.picture) {
      if (p == col) n++;
    }
    return n;
  }

  test('helps.ring: a ripple ring before a ball afloat or on the water, and under Canelo wading; none on the lawn', () async {
    final ring = scene.sheet.helps!.ring.colour;
    final W = fresh();
    expect(colourCount(W, ring), 0);
    W['bolas'] = <String, dynamic>{
      'flota0': <String, dynamic>{
        'k': 'q',
        'x': 203,
        'y': 206,
        'z': 0,
        'flota': 1,
      },
    };
    expect(colourCount(W, ring), greaterThan(10));
    W['bolas'] = <String, dynamic>{
      'a': <String, dynamic>{'k': 'L', 'x': 183, 'y': 202, 'z': 0},
    };
    expect(
      colourCount(W, ring),
      greaterThan(10),
      reason: 'a ball lying on the water (pair arriba.no)',
    );
    W['bolas'] = <String, dynamic>{
      'a': <String, dynamic>{'k': 'L', 'x': 120, 'y': 180, 'z': 0},
    };
    expect(colourCount(W, ring), 0, reason: 'a ball on the lawn');
    W['bolas'] = <String, dynamic>{};
    W['perro'] = <String, dynamic>{'x': 183, 'y': 201, 'pose': 'run', 'dir': 1};
    expect(
      colourCount(W, ring),
      greaterThan(20),
      reason: 'Canelo wading (tira17)',
    );
    (W['perro'] as Map<String, dynamic>)['dy'] = 8;
    expect(colourCount(W, ring), 0, reason: 'Canelo in the air');
    W['perro'] = <String, dynamic>{
      'x': 157,
      'y': 177,
      'pose': 'sit',
      'dir': -1,
    };
    expect(colourCount(W, ring), 0, reason: 'Canelo on the lawn');
  });

  // the pixels of a ball's own drawing that the frame does not change from the frame without it: the set drawn again over
  // it (the sheet's front)
  int coveredBall(Map<String, dynamic> W, String n) {
    draw(W);
    final withB = Uint32List.fromList(frame.picture);
    final bs = Map<String, dynamic>.from(W['bolas'] as Map);
    final o = bs.remove(n) as Map<String, dynamic>;
    draw({...W, 'bolas': bs});
    final without = Uint32List.fromList(frame.picture);
    final mine = Uint32List(240 * 216), c = Ctx(mine, 240, 216);
    scene.host = frame.host;
    frame.host.W = {...W};
    final im = mkBola(o['k'] as String), p = scene.bolaXY(o);
    c.drawImage(im, p[0] - (im.w >> 1), p[1] - p[2] - im.h + 1);
    scene.host = host;
    var k = 0;
    for (var i = 0; i < mine.length; i++) {
      if (mine[i] >> 24 != 0 && withB[i] == without[i]) k++;
    }
    return k;
  }

  test('front: the reeds are drawn again over a ball among their stalks; none over a ball at JUNCO, in front of them, or on the lawn', () async {
    final W = fresh();
    W['bolas'] = <String, dynamic>{
      'juego': <String, dynamic>{
        'k': 'q',
        'x': scene.JUNCO[0],
        'y': scene.JUNCO[1],
        'z': 0,
      },
    };
    // a ball among the reeds' stalks, over the water behind the front ones: partly hidden
    W['bolas'] = <String, dynamic>{
      'juego': <String, dynamic>{'k': 'q', 'x': 184, 'y': 188, 'z': 0},
    };
    expect(coveredBall(W, 'juego'), greaterThan(20));
    // at JUNCO (moves line 50: 185, 205) the ball lies in the water in front of the bed: no reed is nearer (as the
    // preview draws it; the sheet's front.why says the reeds stand in front of it there: reported)
    W['bolas'] = <String, dynamic>{
      'juego': <String, dynamic>{
        'k': 'q',
        'x': scene.JUNCO[0],
        'y': scene.JUNCO[1],
        'z': 0,
      },
    };
    expect(coveredBall(W, 'juego'), 0);
    W['bolas'] = <String, dynamic>{
      'juego': <String, dynamic>{'k': 'q', 'x': 120, 'y': 190, 'z': 0},
    };
    expect(coveredBall(W, 'juego'), 0);
  });

  test('the hint frames and twinkles of the tree and the reeds are drawn round their hint boxes; another thing\'s round its box', () {
    for (final k in const ['arbol', 'juncos', 'perro']) {
      for (final sign in const ['spot', 'twinkle']) {
        final W = fresh();
        if (k == 'perro') {
          W['perro'] = <String, dynamic>{
            'x': 120,
            'y': 170,
            'pose': 'sit',
            'dir': 1,
          };
        }
        W[sign] = k;
        draw(W, allSigns: true);
        final got = Uint32List.fromList(frame.picture);
        W[sign] = null;
        draw(W, allSigns: true);
        final c = Ctx(frame.picture, 240, 216);
        final b = scene.cosa(k)!.hintBox ?? scene.box(k, W)!;
        frame.host.F = host.F;
        if (sign == 'spot') {
          spot(c, b, host.F >> 1, scene.SW, scene.SH);
        } else {
          frame.host.signs.twinkle(c, b);
        }
        expect(got, frame.picture, reason: '$sign at $k round $b');
      }
    }
    // a touch still answers in the box: a point of the reeds' box outside their hint box is the reeds'
    final W = fresh();
    expect(scene.hit(230, 150, W), 'juncos');
  });

  test('shadows: the frog, the children, Canelo, the basket, a ball on the lawn or in the air; none in the tree, carried, afloat or on the water', () async {
    final W = fresh();
    await scene.acts['inicio15']!({});
    List<num> radii(Map<String, dynamic> W) =>
        [for (final s in scene.shadows(W)) s.r]..sort();
    // the frog .45, two children (5 each) .3, Canelo .32, the basket .36, the frog's ball at his feet .19; the children's
    // balls are in their hands
    expect(radii(W), [.19, ...List.filled(10, .3), .32, .36, .45]..sort());
    final cq = ball('cq');
    cq['z'] = 30;
    final s = scene.shadows(W).firstWhere((s) => s.r == .19);
    expect(
      s.z,
      .19,
      reason:
          'from the ball\'s middle as it lies there, on the ground under it',
    );
    cq['con'] = 'cq';
    expect(scene.shadows(W).where((s) => s.r == .19), isEmpty);
    cq
      ..['con'] = null
      ..['x'] = 64
      ..['y'] = 152
      ..['z'] = 33;
    expect(
      scene.shadows(W).where((s) => s.r == .19),
      isEmpty,
      reason: 'in the tree',
    );
    cq
      ..['x'] = 183
      ..['y'] = 202
      ..['z'] = 0;
    expect(
      scene.shadows(W).where((s) => s.r == .19),
      isEmpty,
      reason: 'on the water',
    );
    cq
      ..['x'] = 120
      ..['y'] = 190
      ..['flota'] = 1;
    expect(
      scene.shadows(W).where((s) => s.r == .19),
      isEmpty,
      reason: 'afloat',
    );
    person('luis')['al'] = .5;
    expect(scene.shadows(W).where((s) => s.r == .3), hasLength(5));
    (W['perro'] as Map<String, dynamic>)['dy'] = 10;
    expect(
      scene.shadows(W).where((s) => s.r == .32),
      hasLength(1),
      reason: 'Canelo in the air: on the ground under him',
    );
    W['cesta'] = null;
    expect(scene.shadows(W).where((s) => s.r == .36), isEmpty);
  });

  test(
    'talk: a child\'s bubble clear of the rounds card and of the faces',
    () async {
      final W = fresh();
      await scene.acts['inicio15']!({});
      W['tarjeta'] = 1;
      person('luis')['bub'] = 'hola';
      final top = [88, 178 - 44 - 1];
      final t = scene.talkPlace(top, 6, 'hola', W);
      final r = scene.sheet.bubbleRects['hola']!, x0 = scene.CAM['wide']![0];
      final rect = [t[0] + r[0], t[1] + r[1], r[2], r[3]];
      final card = [2 + x0, 2, 68, 26];
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

  test('his eyes shut (acts.esconde16): the picture goes dark, the frog drawn again over it', () async {
    final W = fresh();
    await scene.acts['inicio16']!({});
    draw(W);
    final light = Uint32List.fromList(frame.picture);
    W['oscuro'] = .95;
    draw(W);
    final dark = Uint32List.fromList(frame.picture);
    var darker = 0;
    for (var i = 0; i < light.length; i++) {
      if ((dark[i] & 0xFF) < (light[i] & 0xFF)) darker++;
    }
    expect(darker, greaterThan(light.length * .8));
    // the frog is drawn again over the darkness: his box keeps pixels of the light frame
    final b = frogBox(W['cq'] as Map<String, dynamic>);
    var same = 0;
    for (var y = b.y.toInt(); y < b.y + b.h; y++) {
      for (var x = b.x.toInt(); x < b.x + b.w; x++) {
        if (dark[y * 240 + x] == light[y * 240 + x]) same++;
      }
    }
    expect(same, greaterThan(50));
    await scene.acts['esconde16']!({'en': 'abajo'});
    expect(W['oscuro'], 0);
    expect(at(ball('juego')), scene.JUNCO);
  });

  test('the water\'s glints come and go with the frame\'s time: two frames differ only on the water, at its glints', () {
    final W = fresh();
    (W['cq'] as Map<String, dynamic>)['vis'] = 0;
    final glints = <int>{
      for (final g in frame.engine.glints) ...[g.i - 1, g.i, g.i + 1],
    };
    expect(frame.engine.glints, isNotEmpty);
    // wind time 0 and 1.5 s (F 30 of 50 ms)
    draw(W, F: 0, tick: 50);
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

  test('remap: a ground point keeps its place, the stories\' and the pairs\' the sheet moved; where the cards stand; a flight\'s direction as it is; pair rectangles their pictures\' crop', () {
    for (final r in scene.sheet.remapTable) {
      if (r.kind == 'point' && !r.moved && r.now != null) {
        expect(scene.remap(r.old), r.now, reason: '${r.old}');
        expect(scene.remap(r.old), r.old, reason: 'the floor rule');
      }
    }
    expect(scene.remap([168, 192]), [157, 179]);
    expect(scene.remap([110, 182]), [118, 144]);
    expect(scene.remap([112, 40]), [132, 32]);
    expect(scene.remap([1, 0]), [1, 0]);
    expect(scene.remap([14, 78, 150, 79.6]), [0, 66, 196, 104]);
    // pictures that share an old rectangle but not a crop are asked for by name
    expect(() => scene.remap([74, 126, 113, 60]), throwsA(isA<SheetError>()));
    expect(() => scene.remap([1, 2]), throwsA(isA<SheetError>()));
  });

  test('a pair picture\'s own W: its children, balls and flower through the remap (mi.si: Luis and the ball up the lawn)', () {
    final w = ScenePictures.pictureW(scene, const {
      'gente': {
        'luis': {'x': 110, 'y': 182, 'pose': 'yo', 'dir': 1},
      },
      'bolas': {
        'a': {'k': 'L', 'con': 'luis'},
        'b': {'k': 'q', 'x': 152, 'y': 184},
      },
      'flor': [137, 178],
      'cq': {
        'x': 144,
        'y': 153,
        's': 1,
        'dy': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
      },
    });
    expect(at((w['gente'] as Map)['luis'] as Map<String, dynamic>), [118, 144]);
    expect(at((w['bolas'] as Map)['b'] as Map<String, dynamic>), [160, 146]);
    expect((w['bolas'] as Map)['a'], {'k': 'L', 'con': 'luis'});
    expect(w['flor'], [137, 142]);
    expect(at(w['cq'] as Map<String, dynamic>), [152, 115]);
  });

  test('the sheet names every place of campo.js but those its rules.floor keeps (lines 233 and 286), and floorRule serves those lines only', () {
    expect(CampoPlaces.floorRuleOnly, {233, 286});
    expect(
      () => CampoPlaces(scene.sheet, scene.projection).floorRule(232, 1, 2),
      throwsA(isA<SheetError>()),
    );
    expect(
      () => CampoPlaces(scene.sheet, scene.projection).floor(240, 1, 2),
      throwsA(isA<SheetError>()),
    );
  });
}
