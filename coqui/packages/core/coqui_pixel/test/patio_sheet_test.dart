// The sheet reader against El patio's real sheet (docs/proyecto/pixel/patio-sheet.json, order 32a): what it writes that
// the earlier sheets do not (`behind`; `flowerLeaves`; `hops` and `hopsAll`; a point given by its x and its heights, the
// sun; `moves` with values of W, no places, a sort row and where the answer cards stand; a thing's hand point; remap
// entries that moved, that stay screen points, or that name another scene's picture; corner cards of two parts) parses,
// and what the engine gives is the numbers the sheet records. On the vm the file itself is read, in a browser the
// fixture made from it (tool/make_sheet_fixture.dart).
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

const hundredth = .0051;

Matcher near(num v) => closeTo(v, hundredth);

int _round(num v) => (v + .5).floor();

void main() {
  final sheet = Sheet.parse(patioSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  test('El patio: S 26, origin (0, 4), a 240 x 216 picture', () {
    expect(sheet.scene, 'patio');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [0, 4]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(21));
    expect(sheet.spots, hasLength(23));
    expect(sheet.lugar, hasLength(14));
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(25));
    expect(sheet.level, hasLength(27));
    expect(sheet.clips, isEmpty);
    expect(sheet.frames, isEmpty);
    expect(sheet.points.keys, ['nido']);
    expect(sheet.screenPoints, hasLength(8));
    expect(sheet.remapTable, hasLength(73));
    expect(sheet.code, hasLength(97));
    expect(sheet.unknown.keys, ['layout', 'hopsWhat', 'clipsWhat', 'checks']);
  });

  test('setKey: hora, door, gate by their values; 15 baked states', () {
    expect(sheet.setKey.params.keys, ['hora', 'door', 'gate']);
    expect(sheet.setKey.params['hora']!.values, [
      'dia',
      'tarde',
      'tarde2',
      'ocaso',
      'crepusculo',
      'noche',
    ]);
    expect(sheet.setKey.baked, hasLength(15));
    expect(sheet.setKey.baked.first.query, '?hora=dia&door=shut&gate=shut');
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
          // a person: the ground point under (x, y - 1)
          expect([_round(p.x), _round(p.y) + 1], now, reason: s.name);
        }
      }
      expect(sheet.spots['frog.porton']!.now, [126, 86]);
      expect(sheet.spots['frog.porton']!.old, [128, 104]);
      expect(sheet.spots['asoma']!.now, [52, 108]);
    },
  );

  test('lugar: the frog box the sheet writes as q', () {
    for (final l in sheet.lugar.values) {
      expect(sheet.lugarOf(l.name, e), [l.frog[0], l.frog[1], l.scale]);
    }
    expect(sheet.lugarOf('sale', e), [130, 68, .5]);
  });

  test('hops: every pair\'s count is kit.js acts.ir\'s from today\'s places; 8 differ from the old', () {
    expect(sheet.hopsAll, hasLength(91));
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
      final dx = a[0] - b[0], dy = a[1] - b[1];
      expect(math.sqrt(dx * dx + dy * dy), near(h.dNow), reason: h.a);
    }
    expect(sheet.hops, hasLength(8));
    expect(
      [for (final h in sheet.hops) '${h.a}-${h.b} ${h.old}>${h.now}'],
      [
        'centro-sale 3>4',
        'caja-sale 2>3',
        'camaL-porton 2>3',
        'camaR-porton 2>3',
        'luis-porton 1>2',
        'carmen-porton 2>3',
        'carmenA-sale 1>2',
        'luisC-sale 2>3',
      ],
    );
    for (final h in sheet.hops) {
      expect(h.a == 'porton' || h.b == 'porton' || h.b == 'sale', isTrue);
    }
    expect(
      [
        for (final h in sheet.hopsAll)
          if (h.old != h.now) '${h.a}-${h.b}',
      ],
      [for (final h in sheet.hops) '${h.a}-${h.b}'],
    );
  });

  test('the things of the set: their box is the box of their world box to 2 px; the gate\'s hand point', () {
    for (final t in sheet.things.values) {
      if (t.world == null) continue;
      final b = sheet.boxOf(t.id, e);
      for (var i = 0; i < 4; i++) {
        expect(b[i], closeTo(t.box![i], 2), reason: '${t.id} $b ${t.box}');
      }
    }
    expect(sheet.things['porton']!.hand, [133, 46]);
    expect(sheet.things['nido']!.hand, isNull);
    expect(sheet.things['caja']!.box, [104, 112, 32, 24]);
    expect(sheet.things['caja']!.sprite, isTrue);
  });

  test('views: one window, x0 22, from its world centre', () {
    expect(sheet.viewOf('wide', e), [22, 0, 196, 216]);
  });

  test('screen points: the sun by its x and its heights; the stars; the nest a world point', () {
    final sol = sheet.screenPoint('sol');
    expect(sol.x, 100);
    expect(sol.heights, [26, 40, 56, 73]);
    expect(() => sol.xy, throwsA(isA<SheetError>()));
    expect(sheet.screenPoint('luna').xy, [150, 26]);
    expect(sheet.screenPoint('estrellas').points![5], [100, 44]);
    expect(sheet.screenPoint('hoyos.R').points!.first, [192, 186]);
    expect(sheet.screenPoint('cerca.ave').xy, [178, 83]);
    // the bird's feet on its nest (the sheet's screen), the nest's middle 2 rows lower (its world point)
    expect(sheet.anchor('nido').screen, [181, 66]);
    final n = sheet.screenOf('nido', e);
    expect([n.x, n.y], [near(181), closeTo(68, .01)]);
    expect(() => sheet.screenPoint('luna').x, throwsA(isA<SheetError>()));
  });

  test('behind: the sky objects, drawn first, the set again over them', () {
    final b = sheet.behind!;
    expect(b.what, contains('-1e8'));
    expect([for (final i in b.items) i.at], ['patio.js:131', 'patio.js:132']);
    expect(b.items.first.boxes, contains('star'));
  });

  test('flowerLeaves: two stages, the palette, the lines that get them', () {
    final f = sheet.flowerLeaves!;
    expect(f.palette, {'d': 0xFF2D5314, 'l': 0xFF366C1C, 't': 0xFF489A2E});
    final open = f.stage('open'), bud = f.stage('bud');
    expect(
      [open.x0, open.y0, open.rows.length, open.rows.first.length],
      [-5, -22, 22, 11],
    );
    expect(
      [bud.x0, bud.y0, bud.rows.length, bud.rows.first.length],
      [-4, -13, 13, 9],
    );
    expect(open.head, [-4, -18, 9, 9]);
    expect([for (final g in f.gets) g.line], [135]);
    expect([for (final g in f.not) g.line], [60, 69, 144, 'juego.js']);
    expect(() => f.stage('seed'), throwsA(isA<SheetError>()));
  });

  test(
    'moves: thirteen pieces of the old source, their values, places and cards',
    () {
      expect(sheet.moves, hasLength(13));
      expect(
        [for (final m in sheet.moves) m.line],
        [16, 58, 208, 240, 295, 308, 135, 86, 86, 195, 248, 290, 291],
      );
      final sol = sheet.moves.first;
      expect(sol.places, isEmpty);
      expect(sol.values.single, (key: 'W.soly', old: 24, now: 26));
      final fam = sheet.moves[11];
      final bebe = fam.places.firstWhere((p) => p.who == 'bebe');
      expect(bebe.z, 137);
      expect(bebe.now, [103, 109]);
      expect(sheet.moves[12].respEn, [164, 4]);
      expect(sheet.moves[7].places.single.who, 'cq');
    },
  );

  test('remap: the same screen place, the two that moved, screen points, none, another scene\'s picture', () {
    final r = sheet.remapPoint(30, 104);
    expect(r.to.floor, hasLength(3));
    expect(r.now, [30, 104]);
    expect(r.moved, isFalse);
    final m = sheet.remapPoint(150, 150);
    expect(
      [m.moved, m.now],
      [
        true,
        [180, 150],
      ],
    );
    expect(sheet.remapPoint(124, 124).to.screen, [124, 124]);
    expect(sheet.remapPoint(1, -1).to.none, contains('direction'));
    final p = sheet.remapCam([22, 84, 196, 104]);
    expect(p.cropsElsewhere, {'parque.si': 'camino'});
    expect(p.crops, isEmpty);
    expect(sheet.remapCam([22, 30, 196, 104]).crops!['parque.no']!.crop, [
      22,
      30,
      196,
      104,
    ]);
  });

  test('shadows: the ball\'s, the frog\'s, the people\'s by kind', () {
    expect(sheet.shadows['bola']!.radius, .28);
    expect(sheet.shadows['coqui']!.radius, .45);
    expect(sheet.shadows['people']!.radii, {
      'grown': .35,
      'nino': .3,
      'bebe': .25,
    });
  });

  test('front: nothing of the set covers a character', () {
    expect(sheet.front, isEmpty);
    expect(sheet.frontParts, isEmpty);
    expect(sheet.frontHow, contains('nothing of the set covers a character'));
  });

  test('bubbles and talk: the rectangles, the places, the heads, the corner cards of one part and of two', () {
    expect(sheet.bubbleRects['q'], [-12, -40, 26, 38]);
    final t = sheet.talk!;
    expect(t.places, hasLength(17));
    expect(t.heads['carmen.sent'], (top: -38, head: 0));
    num none(String f) => 0;
    expect(t.boardsOf('tarjeta sol', none), [
      [2, 2, 36, 54],
    ]);
    expect(t.boardsOf('tarjeta luces', none), [
      [2, 2, 86, 32],
    ]);
    expect(t.boardsOf('tanteo', none), [
      [2, 2, 71, 28],
      [119, 2, 75, 28],
    ]);
    expect(t.boardsOf('tanteo', (f) => f == 'canasta.length' ? 5 : 0), [
      [2, 2, 101, 28],
      [119, 2, 75, 28],
    ]);
    expect(t.boardsOf('nada', none), isEmpty);
  });
}
