// The sheet reader against El campo's real sheet (docs/proyecto/pixel/campo-sheet.json, order 34a): what it writes that
// the earlier sheets do not (the dropped lines as pieces of source; the shore as a line, its world one number; the
// crown's radii and the fork's hollow; the ripple ring of `helps` and the two lines it adds; the balls' shadows by kind
// and where they are in the tree; the water's depth for the front test and the sorted list's tags; one corner card as a
// rectangle; the reeds' and the tree's hint boxes; 27 moves; 6 pairs of the frog's places one hop fewer) parses, and
// what the engine gives is the numbers the sheet records. On the vm the file itself is read, in a browser the fixture
// made from it (tool/make_sheet_fixture.dart).
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

const hundredth = .0051;

Matcher near(num v) => closeTo(v, hundredth);

int _round(num v) => (v + .5).floor();

void main() {
  final sheet = Sheet.parse(campoSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  test('El campo: S 26, origin (0, 4), a 240 x 216 picture', () {
    expect(sheet.scene, 'campo');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [0, 4]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(10));
    expect(sheet.spots, hasLength(34));
    expect(sheet.lugar.keys, ['centro', 'inicio']);
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(22));
    expect(sheet.level, hasLength(16));
    expect(sheet.clips, isEmpty);
    expect(sheet.frames, isEmpty);
    expect(sheet.points.keys, ['arbol']);
    expect(sheet.screenPoints.keys, [
      'copa',
      'horq',
      'sitio',
      'orilla',
      'junco',
      'corazon',
      'sol',
      'nubes',
      'orilla_linea',
    ]);
    expect(sheet.remapTable, hasLength(66));
    expect(sheet.moves, hasLength(27));
    expect(sheet.unknown.keys, ['layout', 'hopsWhat', 'clipsWhat', 'checks']);
  });

  test('setKey: no parameter; one baked state', () {
    expect(sheet.setKey.params, isEmpty);
    expect([for (final b in sheet.setKey.baked) b.query], ['?']);
  });

  test('the spots: their world point is under the place the sheet gives as new', () {
    for (final s in sheet.spots.values) {
      final p = sheet.screenOf(s.name, e), now = s.now!;
      if (s.scale != null) {
        // the frog: the ground point under (q.x + 16, q.y + 25)
        final f = sheet.frogAt(s.name, e);
        expect([f.x, f.y], [now[0], now[1]], reason: s.name);
      } else {
        // a child, Canelo, a ball, the basket: the ground point under (x, y - 1)
        expect([_round(p.x), _round(p.y) + 1], now, reason: s.name);
      }
    }
    // the frog's place in acts.busca (abajo), moved up the lawn from the reeds
    expect(sheet.spots['frog.busca_abajo']!.now, [147, 153]);
    expect(sheet.spots['frog.busca_abajo']!.old, [160, 166]);
  });

  test('hops: every pair\'s count is kit.js acts.ir\'s from the frog\'s places, 6 one fewer than the old', () {
    expect(sheet.hopsAll, hasLength(91));
    int count(List<num> a, List<num> b) {
      final dx = a[0] - b[0],
          dy = a[1] - b[1],
          d = math.sqrt(dx * dx + dy * dy);
      return d < 3 ? 0 : math.max(1, math.min(4, _round(d / 30)));
    }

    for (final h in sheet.hopsAll) {
      final a = sheet.spots['frog.${h.a}']!, b = sheet.spots['frog.${h.b}']!;
      expect(count(a.now!, b.now!), h.now, reason: '${h.a} - ${h.b}');
      expect(count(a.old, b.old), h.old, reason: '${h.a} - ${h.b}');
      final dx = a.now![0] - b.now![0], dy = a.now![1] - b.now![1];
      expect(math.sqrt(dx * dx + dy * dy), near(h.dNow), reason: h.a);
    }
    expect(
      [for (final h in sheet.hops) '${h.a}-${h.b} ${h.old}>${h.now}'],
      [
        'bajoarbol-busca_abajo 4>3',
        'tumba-busca_abajo 4>3',
        'luisbusca-busca_abajo 4>3',
        'busca_arriba-busca_abajo 4>3',
        'busca_abajo-final16_si 2>1',
        'busca_abajo-inicio17 2>1',
      ],
    );
  });

  test('the things of the set: their box is the box of their world box to 2 px (not the ground); the hint boxes and hands', () {
    for (final t in sheet.things.values) {
      if (t.world == null) continue;
      final r = t.screenRect, bx = t.box!;
      // the screen corners are the drawn pixels' (the reeds': one column in from the box's left edge)
      if (r != null) {
        final rr = [r[0], r[1], r[2] - r[0], r[3] - r[1]];
        for (var i = 0; i < 4; i++) {
          expect(rr[i], closeTo(bx[i], 1), reason: '${t.id} $rr $bx');
        }
      }
      if (t.raw['ground'] == true) continue;
      final b = sheet.boxOf(t.id, e);
      for (var i = 0; i < 4; i++) {
        expect(b[i], closeTo(t.box![i], 2), reason: '${t.id} $b ${t.box}');
      }
    }
    final a = sheet.things['arbol']!, j = sheet.things['juncos']!;
    expect(
      [a.box, a.hintBox, a.hand],
      [
        [34, 71, 55, 84],
        [36, 71, 53, 84],
        [60, 100],
      ],
    );
    expect(
      [j.box, j.hintBox, j.hand],
      [
        [177, 140, 62, 51],
        [177, 164, 27, 27],
        [188, 190],
      ],
    );
    expect(sheet.things['campo']!.hintBox, isNull);
    expect(sheet.things['perro']!.sprite, isTrue);
  });

  test('views: one window, x0 22', () {
    expect(sheet.viewOf('wide', e), [22, 0, 196, 216]);
  });

  test('points: the tree\'s foot, the crown\'s radii, the fork\'s hollow, the shore as a line, the sun, the clouds', () {
    expect(sheet.anchor('arbol').screen, [60, 152]);
    final copa = sheet.screenPoint('copa');
    expect(
      [copa.xy, copa.radii, copa.old],
      [
        [63, 99],
        [25, 25],
        [60, 100, 30, 26],
      ],
    );
    expect(sheet.screenPoint('horq').hollow, [64, 111, 10, 9]);
    final shore = sheet.screenPoint('orilla_linea');
    expect(shore.line, 5.7656);
    expect(shore.points, [
      [149, 204],
      [220, 168],
    ]);
    expect(sheet.screenPoint('sol').radius, 9);
    expect(sheet.screenPoint('nubes').points, [
      [188, 12, .7],
      [204, 34, .8],
      [108, 10, .6],
    ]);
    expect(sheet.screenPoint('junco').xy, [180, 197]);
  });

  test('dropped: four pieces of the old source, the background and three old shadows', () {
    expect([for (final d in sheet.droppedCode) d.line], [96, 85, 92, 78]);
    expect(sheet.droppedCode.first.src, 'c.drawImage(spr("campo",fondo),0,0);');
    expect(sheet.droppedCode.every((d) => d.to.isEmpty), isTrue);
    expect(sheet.dropped, hasLength(4));
    expect(sheet.dropped.first, startsWith('96: the background'));
  });

  test(
    'moves: 27 pieces of the old source, their places and the answer cards',
    () {
      expect([for (final m in sheet.moves) m.respEn].whereType<List<int>>(), [
        [132, 32],
        [132, 32],
        [132, 32],
      ]);
      final m156 = sheet.moves.firstWhere((m) => m.line == 156);
      expect(
        [for (final p in m156.places) p.now],
        [
          [203, 206],
          [202, 191],
          [201, 207],
          [170, 207],
        ],
      );
      expect(sheet.moves.firstWhere((m) => m.line == 50).places.first.now, [
        185,
        205,
      ]);
      // a move named on several lines gives its places on the first
      expect(
        [
          for (final m in sheet.moves)
            if (m.src == 'perroA(164,188,"walk"') m.places.length,
        ],
        [1, 0, 0, 0, 0, 0],
      );
      expect(sheet.moves.firstWhere((m) => m.line == 59).to, contains('?8:6'));
    },
  );

  test('helps: the ripple ring, its colour, a ball\'s and Canelo\'s, and the two lines it adds', () {
    final h = sheet.helps!;
    expect([h.margin, h.edge], [8, 6]);
    expect(h.ring.inner, .45);
    expect(h.ring.colour, 0xFFF6ECD4);
    expect([h.ring.ball.rx, h.ring.ball.ry], [4, 2.5]);
    expect([h.ring.dog.rx, h.ring.dog.ry, h.ring.dog.dy], [15, 3.5, 1]);
    expect(h.lines, hasLength(2));
    expect(h.lines[0].to, contains('PREVIEW.under(c,o,p,r,im);'));
    expect(h.lines[1].to, contains('PREVIEW.wade(c,o);'));
  });

  test('shadows: the frog\'s, the children\'s, Canelo\'s, the basket\'s, the balls\' by kind and where they are in the tree', () {
    expect(sheet.shadows['coqui']!.radius, .45);
    expect(sheet.shadows['people']!.radii, {'nino': .3});
    expect(sheet.shadows['perro']!.radius, .32);
    expect(sheet.shadows['cesta']!.radius, .36);
    expect(sheet.shadows['bola']!.radii, {'L': .27, 'C': .21, 'q': .19});
    expect(sheet.shadows['bola']!.tree, (x: 64, dx: 14, y: 152, z: 24));
    expect(sheet.shadows['coqui']!.tree, isNull);
    expect(sheet.shadowsNote, contains('campo.js:96'));
  });

  test('front: the reeds after everyone, the water\'s depth, the sorted list\'s tags', () {
    expect(sheet.front, ['juncos']);
    final j = sheet.frontParts['juncos']!;
    expect([j.sortY, j.line], [9999, null]);
    expect(j.insert, contains('9999'));
    expect(sheet.frontWaterDepth, .16);
    expect(sheet.frontTags, hasLength(6));
    expect(sheet.frontTags.first.to, 'L.push({y:p.y,id,d:()=>gente(c,id,a)})');
    expect(sheet.frontPlane, contains('tan(30 deg)'));
  });

  test('bubbles and talk: the rectangles, the places, the heads, the rounds card as a rectangle', () {
    expect(sheet.bubbleRects['hola'], [-16, -46, 34, 44]);
    final t = sheet.talk!;
    expect(t.places, hasLength(17));
    expect(t.heads['luis'], (top: -41, head: 0));
    expect(t.boardRect, [2, 2, 68, 26]);
    expect(t.boards, contains('W.tarjeta'));
  });

  test('remap: the same screen place, the ones that moved, the cards in the sky, a flight\'s direction', () {
    final r = sheet.remapPoint(168, 192);
    expect(
      [r.moved, r.now],
      [
        true,
        [157, 179],
      ],
    );
    final c = sheet.remapPoint(112, 40);
    expect(
      [c.moved, c.to.screen],
      [
        true,
        [132, 32],
      ],
    );
    expect(sheet.remapPoint(1, 0).to.none, isNotNull);
    expect(sheet.remapPoint(64, 152).now, [64, 152]);
    expect(sheet.remapCam([14, 78, 150, 79.6]).crops!['abajo.si']!.crop, [
      0,
      66,
      196,
      104,
    ]);
  });
}
