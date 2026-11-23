// The sheet reader against La nevera's real sheet (docs/proyecto/pixel/nevera-sheet.json, order 39a): what it writes that
// the earlier sheets do not (review pictures given by their screen centre and crop only, with no world point; whoever
// stands outside the window as a spot and a move's place with no world point, on the screen where the sheet's rule
// puts them; an x alone on the sill as a remap of kind `x` with its new x; `talk` with neither heads nor heights, each face
// measured from its sprite; the fridge's and its inside's boxes, hands and hint boxes by state, in their things' raw
// parts; the rows of the surfaces in `layout.numbers`) parses, and the places it names are where its rule says. On the vm
// the file itself is read, in a browser the fixture made from it (tool/make_sheet_fixture.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

int _round(num v) => (v + .5).floor();

void main() {
  final sheet = Sheet.parse(neveraSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
    shadowX: .9,
    shadowY: -.1,
  );

  test('La nevera: S 26, origin (-21, -1), a 240 x 216 picture', () {
    expect(sheet.scene, 'nevera');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [-21, -1]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(26));
    expect(sheet.spots, hasLength(43));
    expect(sheet.lugar.keys, ['inicio', 'centro']);
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(24));
    expect(sheet.level, hasLength(19));
    expect(sheet.clips, isEmpty);
    expect(sheet.raw['clips'], contains('patio'));
    expect(sheet.frames, isEmpty);
    expect(sheet.remapTable, hasLength(38));
    expect(sheet.moves, hasLength(75));
    expect(sheet.code, hasLength(246));
    expect(sheet.dropped, hasLength(10));
    expect(sheet.unknown.keys, ['layout', 'checks']);
  });

  test('the view: x0 28, the old one moved 6 px right', () {
    expect(sheet.viewOf('wide', e), [28, 0, 196, 216]);
  });

  test('setKey: nev, cajon, pila, banco in words; ten baked states', () {
    expect(sheet.setKey.params.keys, ['nev', 'cajon', 'pila', 'banco']);
    expect(sheet.setKey.baked, hasLength(10));
    expect(sheet.setKey.baked.first.key, '0.0.0.1');
    expect(sheet.setKey.baked.first.query, '?nev=0&cajon=0&pila=0&banco=1');
    expect(sheet.setKey.notReached, hasLength(20));
  });

  test('review pictures: a screen centre and a crop, no world point', () {
    for (final p in sheet.pictures.values) {
      expect(p.world, isNull, reason: p.name);
      expect(p.zoom, 2, reason: p.name);
      expect([p.crop[2], p.crop[3]], [98, 52], reason: p.name);
    }
    expect(sheet.pictures['leche.si']!.crop, [101, 152, 98, 52]);
    expect(
      () => sheet.pictureRegion('leche.si', e),
      throwsA(isA<SheetError>()),
    );
    expect([for (final l in sheet.level) l.picture], contains('vacio.si'));
  });

  test('spots: on the floor under (x, y - 1), on a surface at its height; whoever is outside on the screen only', () {
    var outside = 0;
    for (final s in sheet.spots.values) {
      if (s.world.isEmpty) {
        // whoever stands outside the window: no world point, the screen place is the sheet's new one
        outside++;
        expect(s.screen, [
          for (final v in s.now!) v.toDouble(),
        ], reason: s.name);
        expect(s.raw['on'], 'outside', reason: s.name);
        continue;
      }
      final now = s.now!, w = s.world, p = e.project(w[0], w[1], w[2]);
      if (s.raw['on'] == 'floor' && !s.name.startsWith('frog.')) {
        expect(_round(p.sx), now[0], reason: s.name);
        expect(_round(p.sy), now[1] - 1, reason: s.name);
      }
    }
    expect(outside, 12);
    expect(sheet.spots['papa.158,120']!.now, [154, 115]);
    expect(
      [for (final l in sheet.lugar.values) l.frog],
      [
        [104, 165],
        [104, 165],
      ],
    );
  });

  test('remap: moved points on the counter, the sill and outside; an x alone on the sill', () {
    SheetRemap point(num x, num y) => sheet.remapPoint(x, y);
    expect(
      [point(142, 122).now, point(142, 122).moved],
      [
        [142, 108],
        true,
      ],
    );
    expect(point(184, 120).now, [184, 130]);
    expect(point(178, 98).now, [178, 114]);
    expect(point(150, 200).now, [150, 200]);
    expect(point(0, 0).to.none, isNotNull);
    final x = sheet.remap('x', [170]);
    expect(x.now, [170]);
    final cam = sheet.remapTable.firstWhere(
      (r) =>
          r.kind == 'cam' && r.uses.contains('cual-nevera.json leche.si.cam'),
    );
    expect(cam.crops!['leche.si']!.crop, [101, 152, 98, 52]);
  });

  test('moves: the rows of the surfaces, the fridge\'s places, whoever stands outside (no world point)', () {
    final rows = sheet.moves.firstWhere((m) => m.line == 15);
    expect(rows.to, contains('CT=x=>Math.round(36.5+x/2)'));
    final hueco = sheet.moves.firstWhere((m) => m.line == 16);
    expect(
      [for (final q in hueco.places) q.now],
      [
        [70, 97],
        [87, 86],
        [70, 122],
        [85, 111],
      ],
    );
    final papa = sheet.moves.firstWhere((m) => m.src.startsWith('papa:{x:158'));
    expect(papa.places.single.world, isEmpty);
    expect(papa.places.single.now, [154, 115]);
    expect((sheet.raw['layout'] as Map)['numbers'], {
      'CT': 36.5,
      'SL': 25,
      'MU': -16.5,
      'PA': 38,
      'CB': 80,
      'VT': -46,
      'VB': 16,
    });
  });

  test('things: the fridge and its inside with a box, a hand and a hint box by state; the kitchen\'s hint box', () {
    final nv = sheet.things['nevera']!, fr = sheet.things['frutas']!;
    expect(nv.box, [33, 39, 84, 145]);
    expect(nv.raw['boxes'], hasLength(3));
    expect(nv.raw['hands'], hasLength(3));
    expect(nv.raw['hintBoxes'], hasLength(3));
    expect(fr.raw['boxes'], hasLength(2));
    expect(fr.raw['hintBoxes'], hasLength(2));
    expect(sheet.things['cocina']!.hintBox, [42, 16, 168, 186]);
    expect(sheet.things['cocina']!.hand, [126, 109]);
  });

  test('talk: places and the rounds card; no heads, no heights (each face measured from its sprite)', () {
    final t = sheet.talk!;
    expect(t.places, hasLength(17));
    expect(t.heads, isEmpty);
    expect(t.heights, isEmpty);
    expect(t.boardRect, [2, 2, 68, 26]);
    expect(t.faces, contains('the bare sprite'));
  });

  test('front: the seven set parts after everyone; shadows: the frog, the people, the things on the floor', () {
    expect(sheet.front, [
      'nevera',
      'nevera.dentro',
      'nevera.puerta',
      'mostrador',
      'pila',
      'banco',
      'ventana',
    ]);
    for (final p in sheet.frontParts.values) {
      expect(p.sortY, 9999);
    }
    expect(sheet.shadows['coqui']!.radius, .45);
    expect(sheet.shadows['people']!.radius, .32);
    expect(sheet.shadows['cosas']!.radius, .18);
  });

  test('hops: none changes (10 walks, each its old count)', () {
    expect(sheet.hops, isEmpty);
    expect(sheet.hopsAll, hasLength(10));
    for (final h in sheet.hopsAll) {
      expect(h.now, h.old);
    }
  });
}
