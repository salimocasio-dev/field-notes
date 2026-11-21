// The sheet reader against La sala's real sheet (docs/proyecto/pixel/sala-sheet.json, order 31a): what it writes that El
// frente's and El balcón's do not (spots and views with no screen but a `new` place; points on the screen only, a photo's
// frame with its turn and nail; the remap's floor points; a shadow radius by kind; `front` with its sort row; `moves`,
// `smoothing`, `bubbles` and `talk`; a set parameter whose values are words) parses, and what the engine gives is the
// numbers the sheet records. On the vm the file itself is read, in a browser the fixture made from it
// (tool/make_sheet_fixture.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

const hundredth = .0051;

Matcher near(num v) => closeTo(v, hundredth);

int _round(num v) => (v + .5).floor();

void main() {
  final sheet = Sheet.parse(salaSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  test('La sala: S 26, origin (20, -33), a 240 x 216 picture', () {
    expect(sheet.scene, 'sala');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [20, -33]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(16));
    expect(sheet.spots, hasLength(25));
    expect(sheet.lugar, hasLength(9));
    expect(sheet.views.keys, ['wide', 'sofa']);
    expect(sheet.pictures, hasLength(22));
    expect(sheet.level, hasLength(28));
    expect(sheet.clips, hasLength(6));
    expect(sheet.frames, isEmpty);
    expect(sheet.points, isEmpty, reason: 'every point is on the screen only');
    expect(sheet.screenPoints, hasLength(13));
    expect(sheet.unknown.keys, ['room', 'top', 'checks']);
    expect(sheet.hops, hasLength(36));
  });

  test('setKey: luz by its values, fotos in words; five baked states', () {
    expect(sheet.setKey.params['luz']!.values, ['1', '0']);
    expect(sheet.setKey.params['fotos']!.values, isEmpty);
    expect(sheet.setKey.params['fotos']!.valuesWhat, contains('0 or 1'));
    expect(
      [for (final b in sheet.setKey.baked) b.query],
      [
        '?luz=1&fotos=000',
        '?luz=1&fotos=100',
        '?luz=1&fotos=110',
        '?luz=1&fotos=111',
        '?luz=1&fotos=010',
      ],
    );
  });

  test(
    'the spots: their world point is under the place the sheet gives as new',
    () {
      for (final s in sheet.spots.values) {
        final p = sheet.screenOf(s.name, e), now = s.now!;
        expect([p.x, p.y], [near(s.screen[0]), near(s.screen[1])]);
        if (s.scale != null) {
          // the frog: the floor point under (q.x + 16, q.y + 25)
          final f = sheet.frogAt(s.name, e);
          expect([f.x, f.y], now, reason: s.name);
        } else if (!s.name.startsWith('puerta.')) {
          // a person: the floor point under (x, y - 1)
          expect([_round(p.x), _round(p.y) + 1], now, reason: s.name);
        }
      }
      expect(sheet.spots['juntos.0']!.now, [80, 196]);
      expect(sheet.spots['juntos.0']!.old, [96, 196]);
    },
  );

  test('lugar: the frog box the sheet writes as q', () {
    for (final l in sheet.lugar.values) {
      expect(sheet.lugarOf(l.name, e), [l.frog[0], l.frog[1], l.scale]);
    }
  });

  test('the things of the set: their box is the sheet\'s, the box of their world box to 2 px (a square world box round the thing)', () {
    for (final t in sheet.things.values) {
      if (t.world == null) continue;
      final b = sheet.boxOf(t.id, e);
      for (var i = 0; i < 4; i++) {
        expect(b[i], closeTo(t.box![i], 2), reason: '${t.id} $b ${t.box}');
      }
    }
    expect(sheet.things['bizcocho']!.box, [107, 142, 30, 16]);
  });

  test('views: one window, x0 22, from their world centre', () {
    for (final v in sheet.views.values) {
      expect(sheet.viewOf(v.name, e), [22, 0, 196, 216], reason: v.name);
      expect(v.cam, [22, 0, 196, 216]);
    }
  });

  test('clips: a frame\'s opening is its screen quad (the photo is clipped to it); its world points are on the left wall', () {
    for (final c in sheet.clips.values) {
      expect(c.thing, 'fotos');
      expect(c.screen, hasLength(4));
      expect(
        Sheet.boxOfPoints([for (final p in c.screen) (sx: p[0], sy: p[1])]),
        c.box,
        reason: c.name,
      );
      for (final w in c.world) {
        expect(w[0], .05, reason: c.name);
      }
    }
  });

  test('screen points: a point, a rectangle, a list; the photos\' frames with turn and nail', () {
    expect(sheet.screenPoint('bizcocho').xy, [108, 142]);
    expect(sheet.screenPoint('retrato').rect, [22, 88, 198, 124]);
    expect(sheet.screenPoint('destapa.estrellas').points, hasLength(3));
    expect(sheet.screenPoint('foto.1').angle, 0);
    expect(sheet.screenPoint('foto.1.torcida').angle, -.24);
    expect(sheet.screenPoint('foto.2').nail, [127, 27]);
    expect(() => sheet.screenPoint('nada'), throwsA(isA<SheetError>()));
    expect(() => sheet.screenPoint('retrato').xy, throwsA(isA<SheetError>()));
  });

  test('remap: a floor point keeps its place (new); pair rectangles name their crops', () {
    final r = sheet.remapPoint(120, 146);
    expect(r.to.floor, hasLength(3));
    expect(r.now, [120, 146]);
    final cam = sheet.remapCam([41, 70, 113, 60]);
    expect(cam.crops!['mama.si']!.zoom, 2);
    expect(sheet.remap('x', [70]).to.level, isTrue);
  });

  test('shadows: the frog\'s radius, the people\'s by kind', () {
    expect(sheet.shadows['coqui']!.radius, .45);
    expect(sheet.shadows['people']!.radii, {
      'grown': .35,
      'nino': .3,
      'bebe': .25,
    });
    expect(() => sheet.shadows['people']!.radius, throwsA(isA<SheetError>()));
  });

  test('front: the low table, drawn again at its row of the sorted list', () {
    expect(sheet.front, ['mesita']);
    final p = sheet.frontParts['mesita']!;
    expect(p.line, 114);
    expect(p.sortY, 165);
    expect(p.boxes, contains('x - 24'));
  });

  test('moves: eight pieces of the old source and their replacements', () {
    expect(sheet.moves, hasLength(8));
    expect(
      [for (final m in sheet.moves) m.line],
      [198, 214, 228, 236, 247, 247, 224, 77],
    );
    final c = sheet.moves.first;
    expect(c.act, 'corren');
    expect(c.places.first.who, 'hermano');
    expect(c.places.first.old, [94, 198]);
    expect(c.places.first.now, [80, 200]);
  });

  test('smoothing: three places, each kept as the sheet says', () {
    expect(
      [for (final p in sheet.smoothing) p.at],
      ['sala.js:120', 'sala.js:121', 'sala.js:137'],
    );
    expect(sheet.notSmoothing, contains('sala.js:190'));
  });

  test(
    'bubbles and talk: the rectangles, the places, the heads, the corner cards',
    () {
      expect(sheet.bubbleRects['amor'], [-14, -38, 30, 36]);
      final t = sheet.talk!;
      expect(t.places, hasLength(17));
      expect(t.places.first, (side: 0, dy: 0));
      expect(t.heads['mama.sent'], (top: -47, head: 0));
      num none(String f) => 0;
      expect(t.board('plato', none), [2, 2, 80, 31]);
      expect(t.board('cafe', (f) => f == 'aciertos' ? 2 : 0), [2, 2, 72, 38]);
      expect(t.board('visor', none), [2, 2, 52, 52]);
      expect(t.board('retrato', none), [29, 5, 138, 90]);
      expect(t.board('nada', none), isNull);
    },
  );
}
