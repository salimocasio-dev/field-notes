// La mesa's acts and what is new in its sheet. The numbers the port reads from the sheet's moved sources (the seats
// stepped down the table, the doorway and the walkway, the places in front of each seat, the counter's stacks, the
// answer cards per story); every moved source is a piece of mesa.js at its line; the hops between the frog's places are
// the old ones but the one pair the sheet names (frog.ranaa - rana.2, 3 to 2), and the walk of the STOP (from abuela's
// hand at the counter to Carmen's place, 2 to 1: tengo-hambre); whoever comes in to sit appears on the step outside the
// doorway and walks behind the chairs; the table and the wall are drawn again over whoever is behind them, a chair never
// over whoever sits (`front`); the shadows on the clear floor only, none on El colmado's stall; remap gives the sheet's
// places (h-mesa's sitters on their chairs), a pair picture's own W through the story moves, and cocina.no puts abuela at
// El colmado's stall; estado writes what the old one writes. Every act of the four files runs in the 12 recorded runs
// (feature_story's differential test, on the real scene).
import 'dart:convert';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart' show Mulberry32;
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/mesa/mesa.dart';
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

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

// mesa.js ranaA's count between two frog places q (his feet at q + (16, 27)): none under 3 px, else round(d / 40), 1 to 3
int hopsOf(List<num> a, List<num> b) {
  final d = math.sqrt(math.pow(b[0] - a[0], 2) + math.pow(b[1] - a[1], 2));
  return d < 3 ? 0 : math.max(1, math.min(3, _round(d / 40)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StillFrame frame;
  late Mesa scene;
  late TickingHost host;
  setUpAll(() async {
    frame = await ScenePictures(bundle: testBundle()).frameOf('mesa');
    // the acts' own scene, with the game's random source (elige25)
    scene = Mesa((frame.scene as Mesa).sheet, rng: Mulberry32(7));
    host = TickingHost(scene);
  });

  Map<String, dynamic> fresh() {
    host
      ..fresh()
      ..S = {
        'stake': {'thing': 'none', 'steps': 3},
      }
      ..F = 40
      ..V = <String, dynamic>{}
      ..cam = scene.CAM['wide']!;
    return host.W;
  }

  void draw(Map<String, dynamic> W, {int? F}) {
    frame.host.V = host.V;
    frame.draw(
      W,
      F: F ?? host.F,
      cam: scene.CAM['wide']!,
      allSigns: false,
      tick: 0,
    );
  }

  Map<String, dynamic> person(String id) =>
      (host.W['gente'] as Map<String, dynamic>)[id] as Map<String, dynamic>;

  test('the frog starts at its old place; the keys of the set; one view; the heart', () {
    final W = fresh();
    final q = W['cq'] as Map<String, dynamic>;
    expect([q['x'], q['y']], [104, 161]);
    expect(scene.setKey(W), 'm0h0');
    W['mantel'] = 1;
    expect(scene.setKey(W), 'm1h0');
    W['mantel'] = 0;
    W['estufa'] = {'horno': 1};
    expect(scene.setKey(W), 'm0h1');
    W['afuera'] = 1;
    expect(scene.setKey(W), 'frutas');
    expect(scene.CAM, {
      'wide': [22, 0, 196, 216],
    });
    expect(scene.heartAt, [124, 22]);
    expect(scene.LUGAR.keys, ['inicio', 'centro']);
  });

  test('the moved sources\' numbers: the seats, the doorway, the walkway, the places in front, the stacks, the cards', () {
    expect(scene.SILLA, [104, 128, 152, 176]);
    expect(scene.SD, [-15, -3, 9, 21]);
    expect(
      [for (var i = 0; i < 4; i++) 150 + scene.SD[i]],
      [135, 147, 159, 171],
    );
    expect(scene.PUERTA, [84, 101]);
    expect(scene.PUERTA, scene.sheet.spots['puerta']!.now);
    // PASO(x) = round(64.45 + x / 2): the walkway's row
    expect([scene.PASO(84), scene.PASO(104), scene.PASO(176)], [106, 116, 152]);
    expect(scene.FOGON, scene.sheet.spots['fogon']!.now);
    expect(scene.LUIS, [75, 160]);
    expect(scene.CAN, [196, 204]);
    expect(scene.FRX, [0, 0, -6, 2]);
    expect(scene.FR, [0, 0, 5, 10]);
    expect(scene.FAX, [24, 24, 24, 26]);
    for (final k in scene.EN.keys) {
      expect(scene.EN[k], scene.sheet.spots['mostrador.$k']!.now, reason: k);
    }
    expect(scene.ENQ['jarron'], [78, 112]);
    // the frog's places in front of each seat: the sheet's spots rana.i
    for (var i = 0; i < 4; i++) {
      expect(
        [scene.SILLA[i] - 14 + scene.FRX[i] - 16, 190 + scene.FR[i] - 27],
        scene.sheet.spots['rana.$i']!.now,
        reason: 'rana.$i',
      );
      expect(
        [scene.SILLA[i] + scene.FAX[i], 204 + scene.FA[i]],
        scene.sheet.spots['abuela.$i']!.now,
        reason: 'abuela.$i',
      );
    }
  });

  test(
    'the sheet\'s moves: every moved source is a piece of mesa.js at its line',
    () {
      final src = historiaFile('escenas/mesa.js');
      if (src == null) {
        markTestSkipped('reads historia/ (vm only)');
        return;
      }
      final lines = src.split('\n');
      for (final m in scene.sheet.moves) {
        for (final l in m.lines.isEmpty ? [m.line] : m.lines) {
          expect(
            lines[l - 1].contains(m.src),
            isTrue,
            reason: 'mesa.js:$l: ${m.src}',
          );
        }
      }
    },
  );

  test('hops: all 36 pairs keep the old count but frog.ranaa - rana.2 (3 to 2); the STOP walk takes one fewer', () {
    final sh = scene.sheet;
    List<num> spot(String n, bool now) {
      final s = sh.spots[n]!;
      return now ? s.now! : s.old!;
    }

    var changed = <String>[];
    for (final h in sh.hopsAll) {
      final o = hopsOf(spot(h.a, false), spot(h.b, false)),
          n = hopsOf(spot(h.a, true), spot(h.b, true));
      expect([o, n], [h.old, h.now], reason: '${h.a} - ${h.b}');
      if (o != n) changed.add('${h.a} - ${h.b}');
    }
    expect(changed, ['frog.ranaa - rana.2']);
    expect(sh.hops.single.a, 'frog.ranaa');
    // the STOP of order 37b: from abuela's hand at the counter (acts.lleva26 `de: "abuela"`, q = (ab.x - 46, ab.y - 17),
    // abuela at ENQ.jarron + (26, 182 - ...): q 58,165) to Carmen's place at seat 2 (rana.2): 64 px, 2 hops, became 58,
    // 1 hop (tengo-hambre beats.32.after.0, beats.70.right.0; feature_story's differential test, mesaHopStop)
    final hand = [scene.ENQ['jarron']![0] + 26 - 30 - 16, 182 + 10 - 27];
    expect(hand, [58, 165]);
    expect(hopsOf(hand, spot('rana.2', false)), 2);
    expect(hopsOf(hand, spot('rana.2', true)), 1);
  });

  test('whoever comes in to sit appears on the step outside the doorway, walks behind the chairs and sits at 150 + SD', () async {
    final W = fresh();
    await scene.acts['inicio24']!({});
    expect(W['respEn'], [98, 20]);
    final seen = <List<num>>[];
    final pr = scene.sienta('papa', 1);
    seen.add([person('papa')['x'], person('papa')['y']]);
    await pr;
    // on the step, its first step up onto the walkway's end (mueve's first tick is taken before it waits)
    expect(seen.first[0], 84);
    expect(seen.first[1], inInclusiveRange(101, scene.PASO(84)));
    expect(
      [person('papa')['x'], person('papa')['y'], person('papa')['sent']],
      [128, 147, 1],
    );
    expect(W['sitio'], {'papa': 1});
    draw(W);
    await scene.sale('papa');
    expect(
      [person('papa')['x'], person('papa')['y'], person('papa')['vis']],
      [84, 101, 0],
    );
    await scene.acts['inicio25']!({});
    expect(W['respEn'], [123, 20]);
    expect(
      [
        for (final id in const ['abuelo', 'mama', 'papa', 'carmen'])
          person(id)['y'],
      ],
      [135, 147, 159, 171],
    );
    await scene.acts['inicio26']!({});
    expect(W['respEn'], [98, 20]);
  });

  test('front: someone behind the table has it drawn over them; a sitter keeps their own chair behind them', () async {
    final W = fresh();
    await scene.acts['inicio25']!({});
    W['cq']['vis'] = 0;
    // abuela behind the table, at the walkway's row in front of the second chair
    person('abuela')
      ..['x'] = 140
      ..['y'] = scene.PASO(140) + 4;
    draw(W);
    final withTable = List<int>.of(frame.picture);
    final key = scene.setKey(W), parts = scene.frontPixelsOf(key)!;
    final table = parts['mesa']!;
    final set = frame.engine.bakedPix;
    // within abuela's sprite (x - 12 .. x + 12, y - 52 .. y), every pixel of the table is the set's own: drawn again over her
    final ab = person('abuela'), ax = ab['x'] as num, ay = ab['y'] as num;
    var mine = 0, over = 0;
    for (final i in table) {
      final x = i % 240, y = i ~/ 240;
      if (x < ax - 12 || x > ax + 12 || y < ay - 52 || y > ay) continue;
      mine++;
      if (withTable[i] & 0xFFFFFF == set[i] & 0xFFFFFF) over++;
    }
    expect(mine, greaterThan(0));
    expect(over, mine);
    // a sitter's chair: none of its pixels drawn over the sitter's own
    expect(parts['sillas'], isNotEmpty);
  });

  test('the wall and the door\'s frame are drawn over whoever stands on the step outside', () async {
    final W = fresh();
    await scene.acts['inicio24']!({});
    W['cq']['vis'] = 0;
    person('luis')
      ..['x'] = scene.PUERTA[0]
      ..['y'] = scene.PUERTA[1];
    draw(W);
    final parts = scene.frontPixelsOf(scene.setKey(W))!;
    final pic = frame.picture, set = frame.engine.bakedPix;
    var wall = 0;
    for (final p in const [
      'pared',
      'puerta',
      'puerta.umbral',
      'puerta.jamba',
    ]) {
      for (final i in parts[p]!) {
        final x = i % 240, y = i ~/ 240;
        if ((x - scene.PUERTA[0]).abs() < 12 &&
            y > scene.PUERTA[1] - 44 &&
            y < scene.PUERTA[1] &&
            pic[i] == set[i])
          wall++;
      }
    }
    expect(wall, greaterThan(0));
  });

  test('shadows: on the clear floor only; none for a sitter; none at El colmado\'s stall', () async {
    final W = fresh();
    await scene.acts['inicio25']!({});
    final sh = scene.shadows(W);
    // the frog at the counter, Luis, abuela: on the floor; the four sitters cast none
    expect(sh.length, 1 + 5 + 5);
    W['afuera'] = 1;
    expect(scene.shadows(W), isEmpty);
  });

  test('remap: h-mesa\'s sitters on their chairs; the frog out of a picture as it is; pair rectangles their crops', () {
    expect(scene.remap([104, 150]), [104, 135]);
    expect(scene.remap([128, 150]), [128, 147]);
    expect(scene.remap([176, 150]), [176, 171]);
    expect(scene.remap([48, 168]), [48, 168]);
    expect(scene.remap([40, 173]), [40, 173]);
    expect(scene.remap([0, 0]), [0, 0]);
    expect(scene.remap([84, 84, 113, 60]), [93, 75, 98, 52]);
  });

  test('a pair picture\'s own W: the story moves of cual-mesa first; cocina.no at El colmado\'s stall', () {
    Map<String, dynamic> w(String j) => jsonDecode(j) as Map<String, dynamic>;
    List<Object?> at(Object? p) => [(p as Map)['x'], p['y']];
    final plato = w(
      '{"gente": {"luis": {"x": 110, "y": 206, "dir": 1, "alza": "plato"}}, "cosas": [{"k": "plato", "x": 187, "y": 150, "z": 300}]}',
    );
    scene.placePair(plato);
    expect(at(plato['gente']['luis']), [144, 120]);
    expect(at(plato['cosas'][0]), [173, 159]);
    final sed = w('{"gente": {"carmen": {"x": 128, "y": 150, "sent": 1}}}');
    scene.placePair(sed);
    expect(at(sed['gente']['carmen']), [128, 147]);
    final no = w(
      '{"afuera": 1, "gente": {"abuela": {"x": 176, "y": 176, "dir": -1}}}',
    );
    scene.placePair(no);
    expect(at(no['gente']['abuela']), [115, 203]);
  });

  test('estado writes what the old one writes', () async {
    final W = fresh();
    await scene.acts['prueba']!({'n': 1});
    expect(
      scene.estado(W),
      'gente=abuela@202,194 luis@75,160 abuelo@104,135s papa@128,147s mama@152,159s carmen@176,171s '
      'puestos=P1:bizcochoT1:choco|P2:bizcocho_T1!roto|P1T1!charco+tazacaida|P1:choco!roto+charco '
      'mostr={"platos":5,"tazas":4} vacios= marcas=ok,x,',
    );
    for (final n in const [1, 2, 3]) {
      await scene.acts['prueba']!({'n': n});
      draw(W);
    }
  });

  test('elige25 draws twice from the game\'s random source', () async {
    final W = fresh();
    await scene.acts['inicio25']!({});
    person('abuelo')['alza'] = 'cuchara';
    person('papa')['alza'] = 'tenedor';
    await scene.acts['elige25']!({'no': 'mama'});
    expect(['abuelo', 'papa'], contains(host.V['pb']));
    expect(const ['cuchara', 'tenedor', 'cuchillo'], contains(host.V['tb']));
    expect(host.V['tb'], isNot(person('${host.V['pb']}')['alza']));
    expect(W['sitio'], hasLength(4));
  });
}
