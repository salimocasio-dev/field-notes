// The sheet reader against El camino's real sheet (docs/proyecto/pixel/camino-sheet.json, order 33a): what it writes that
// the earlier sheets do not (a thing's hint box and its screen box as corners; a point with no old place, the arch's; the
// cat-on-the-bench's depth `v` and the sun's radius; the clouds as x, y and size; remap entries of three counts that are
// no place; front parts placed by their `insert` words, with no line; `sevan`, everyone leaving in a file; `hops` empty)
// parses, and what the engine gives is the numbers the sheet records. On the vm the file itself is read, in a browser the
// fixture made from it (tool/make_sheet_fixture.dart).
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

const hundredth = .0051;

Matcher near(num v) => closeTo(v, hundredth);

int _round(num v) => (v + .5).floor();

void main() {
  final sheet = Sheet.parse(caminoSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  test('El camino: S 26, origin (0, 4), a 240 x 216 picture', () {
    expect(sheet.scene, 'camino');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [0, 4]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(22));
    expect(sheet.spots, hasLength(47));
    expect(sheet.lugar, hasLength(7));
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(25));
    expect(sheet.level, hasLength(16));
    expect(sheet.clips, isEmpty);
    expect(sheet.frames, isEmpty);
    expect(sheet.points, hasLength(14));
    expect(sheet.screenPoints.keys, [
      'nido',
      'gato_banco',
      'ave_banco',
      'corazon',
      'sol',
      'nubes',
    ]);
    expect(sheet.remapTable, hasLength(35));
    expect(sheet.code, hasLength(78));
    expect(sheet.unknown.keys, ['layout', 'hopsWhat', 'clipsWhat', 'checks']);
  });

  test('setKey: gran by its values; 2 baked states', () {
    expect(sheet.setKey.params.keys, ['gran']);
    expect(sheet.setKey.params['gran']!.values, ['1', '0']);
    expect(
      [for (final b in sheet.setKey.baked) b.query],
      ['?gran=1', '?gran=0'],
    );
  });

  test(
    'the spots: their world point is under the place the sheet gives as new',
    () {
      for (final s in sheet.spots.values) {
        final p = sheet.screenOf(s.name, e), now = s.now!;
        if (s.scale != null) {
          // the frog: the ground point under (q.x + 16, q.y + 25)
          final f = sheet.frogAt(s.name, e);
          expect([f.x, f.y], [now[0], now[1]], reason: s.name);
        } else {
          // a person or an animal: the ground point under (x, y - 1)
          expect([_round(p.x), _round(p.y) + 1], now, reason: s.name);
        }
      }
      // Canelo's x at most 188 at marks 7 and 8 (moves line 61)
      expect(sheet.spots['perro.7']!.now, [188, 133]);
      expect(sheet.spots['perro.7']!.old, [191, 133]);
      expect(sheet.spots['frog.arbol0']!.now, [49, 121]);
    },
  );

  test('lugar: the frog box the sheet writes as q', () {
    for (final l in sheet.lugar.values) {
      expect(sheet.lugarOf(l.name, e), [l.frog[0], l.frog[1], l.scale]);
    }
    expect(sheet.lugarOf('arbol0', e), [49, 121, .8]);
  });

  test('hops: every pair\'s count is kit.js acts.ir\'s from today\'s places, all 21 the old', () {
    expect(sheet.hopsAll, hasLength(21));
    int count(List<num> a, List<num> b) {
      final dx = a[0] - b[0], dy = a[1] - b[1];
      return math.max(
        1,
        math.min(4, _round(math.sqrt(dx * dx + dy * dy) / 30)),
      );
    }

    for (final h in sheet.hopsAll) {
      final a = sheet.lugarOf(h.a, e), b = sheet.lugarOf(h.b, e);
      expect(count(a, b), h.now, reason: '${h.a} - ${h.b}');
      expect(h.now, h.old, reason: '${h.a} - ${h.b}');
      final dx = a[0] - b[0], dy = a[1] - b[1];
      expect(math.sqrt(dx * dx + dy * dy), near(h.dNow), reason: h.a);
    }
    expect(sheet.hops, isEmpty);
  });

  test('the things of the set: their box is the box of their world box to 2 px (not the ground); the big tree\'s hint box and hand', () {
    for (final t in sheet.things.values) {
      if (t.world == null) continue;
      final r = t.screenRect, bx = t.box!;
      if (r != null) {
        expect([r[0], r[1], r[2] - r[0], r[3] - r[1]], bx, reason: t.id);
      }
      // the path and the park are the ground: their box is the one round the path (or the lawn) on the picture
      if (t.raw['ground'] == true) continue;
      final b = sheet.boxOf(t.id, e);
      for (var i = 0; i < 4; i++) {
        expect(b[i], closeTo(t.box![i], 2), reason: '${t.id} $b ${t.box}');
      }
    }
    final g = sheet.things['grande']!;
    expect(g.box, [160, 0, 80, 108]);
    expect(g.hintBox, [160, 12, 46, 96]);
    expect(g.hand, [190, 51]);
    expect(sheet.things['arbol0']!.hand, [70, 108]);
    expect(sheet.things['arbol0']!.hintBox, isNull);
    expect(sheet.things['gato']!.hand, isNull); // in words: x + 12, y - 10
  });

  test('views: one window, x0 22, from its world centre', () {
    expect(sheet.viewOf('wide', e), [22, 0, 196, 216]);
  });

  test('points: the arch with no old place; the cat on the bench and its depth; the sun; the clouds', () {
    final arco = sheet.anchor('arco');
    expect(arco.old, isEmpty);
    expect(arco.screen, [37, 167.5]);
    final gb = sheet.screenPoint('gato_banco');
    expect(gb.xy, [92, 123]);
    expect(gb.v, 2.1538);
    expect(sheet.screenPoint('ave_banco').xy, [81, 112]);
    expect(sheet.screenPoint('sol').radius, 9);
    expect(sheet.screenPoint('nubes').points, [
      [128, 6, .7],
      [140, 24, .8],
      [120, 44, .8],
    ]);
    expect(sheet.screenPoint('nido').points, [
      [-9, -31],
      [8, -36],
      [0, -21],
    ]);
    expect(sheet.anchor('arbol.1').screen, [112, 116]);
  });

  test('moves: ten pieces of the old source, their places and cards', () {
    expect(
      [for (final m in sheet.moves) m.line],
      [160, 193, 229, 61, 258, 84, 112, 69, 194, 62],
    );
    expect(
      [for (final m in sheet.moves) m.respEn],
      [
        [134, 14],
        [120, 34],
        [134, 34],
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ],
    );
    expect(sheet.moves[3].places, hasLength(2));
    expect(sheet.moves[8].places.single.who, 'gato');
    expect(sheet.moves[9].places.single.now, [49, 121]);
  });

  test('sevan: the order, 3 ticks apart, and each one\'s two points', () {
    final s = sheet.sevan!;
    expect(s.delay, {
      'abuela': 0,
      'carmen': 3,
      'luis': 6,
      'perro': 9,
      'cq': 12,
    });
    expect(s.points['abuela'], [
      [45, 169],
      [35, 164],
    ]);
    expect(s.points['cq'], [
      [29, 144],
      [19, 139],
    ]);
    expect(s.a, [.3, -.22]);
    expect(s.b, -.12);
  });

  test('remap: the same screen place, the ones that moved, screen points, counts that are no place, another scene\'s picture', () {
    final r = sheet.remapPoint(113, 134);
    expect(
      [r.moved, r.now],
      [
        true,
        [92, 123],
      ],
    );
    final c = sheet.remapPoint(96, 30);
    expect(
      [c.moved, c.to.screen],
      [
        true,
        [134, 14],
      ],
    );
    final d = sheet.remapPoint(88, 134);
    expect(d.now, [80, 149]);
    final n = sheet.remap('numbers', [0, 2, 0]);
    expect(n.to.none, contains('W.pajaros'));
    final p = sheet.remapCam([22, 30, 196, 104]);
    expect(p.cropsElsewhere, {'parque.no': 'patio'});
    expect(sheet.remapCam([22, 84, 196, 104]).crops!['parque.si']!.crop, [
      22,
      84,
      196,
      104,
    ]);
  });

  test('shadows: the frog\'s, the people\'s by kind, Canelo\'s, the cat\'s, the bush\'s', () {
    expect(sheet.shadows['coqui']!.radius, .45);
    expect(sheet.shadows['people']!.radii, {'grown': .35, 'nino': .3});
    expect(sheet.shadows['perro']!.radius, .32);
    expect(sheet.shadows['gato']!.radius, .25);
    expect(sheet.shadows['arbusto']!.radius, .55);
  });

  test('front: the bench in the sorted list, the arch after everyone', () {
    expect(sheet.front, ['banco', 'porton']);
    final b = sheet.frontParts['banco']!, p = sheet.frontParts['porton']!;
    expect([b.sortY, b.line], [134.5, null]);
    expect([p.sortY, p.line], [9999, null]);
    expect(b.insert, contains('134.5'));
    expect(sheet.frontPlane, contains('tan(30 deg)'));
  });

  test(
    'bubbles and talk: the rectangles, the places, the heads, the corner cards',
    () {
      expect(sheet.bubbleRects['q'], [-12, -40, 26, 38]);
      final t = sheet.talk!;
      expect(t.places, hasLength(17));
      expect(t.heads['abuela'], (top: -50, head: 0));
      num none(String f) => 0;
      expect(t.boardsOf('tarjeta galletas', none), [
        [2, 2, 90, 32],
      ]);
      expect(t.boardsOf('tarjeta guineos', none), [
        [2, 2, 86, 32],
      ]);
    },
  );
}
