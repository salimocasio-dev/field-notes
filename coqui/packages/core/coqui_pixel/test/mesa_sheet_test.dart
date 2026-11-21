// The sheet reader against La mesa's real sheet (docs/proyecto/pixel/mesa-sheet.json, order 37a): what it writes that the
// earlier sheets do not (talk with each face measured from its sprite, in words, and the rounds card as a rectangle: no
// heads, no heights; a remap to a spot of another scene's picture, El colmado's stall under cual-mesa's cocina.no; the
// story moves, a story file's own before the general moves) parses, and what the engine gives is the numbers the sheet
// records. On the vm the file itself is read, in a browser the fixture made from it (tool/make_sheet_fixture.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

void main() {
  final sheet = Sheet.parse(mesaSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  test('La mesa: S 26, origin (4, -22), a 240 x 216 picture', () {
    expect(sheet.scene, 'mesa');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [4, -22]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(19));
    expect(sheet.lugar.keys, ['inicio', 'centro']);
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(24));
    expect(sheet.level, hasLength(16));
    expect(sheet.clips, isEmpty);
    expect(sheet.moves, hasLength(43));
    expect(sheet.code, hasLength(244));
    expect(sheet.remapTable, hasLength(29));
    expect(sheet.unknown.keys, [
      'layout',
      'hopsWhat',
      'storyPlaces',
      'clipsWhat',
      'checks',
    ]);
  });

  test(
    'setKey: mantel and horno in words; three baked states, one not reached',
    () {
      expect(sheet.setKey.params.keys, ['mantel', 'horno']);
      expect(sheet.setKey.key, '"m" + mantel + "h" + horno');
      expect(
        [for (final b in sheet.setKey.baked) b.key],
        ['m0h0', 'm1h0', 'm0h1'],
      );
      expect(sheet.setKey.notReached, ['m1h1']);
    },
  );

  test('talk: faces in words, measured from each sprite; the rounds card a rectangle', () {
    final t = sheet.talk!;
    expect(t.heads, isEmpty);
    expect(t.heights, isEmpty);
    expect(t.faces, startsWith('a face: [hx - 6, top + 6, 12, 10]'));
    expect(t.boardRect, [2, 2, 68, 26]);
    expect(t.places, hasLength(17));
    expect(t.places.first, (side: 0, dy: 0));
  });

  test('remap: abuela at El colmado\'s stall is a spot of that scene\'s picture, with its new place', () {
    final r = sheet.remapPoint(176, 176);
    expect(r.to.scene, 'frutas');
    expect(r.to.spot, 'abuela.delante');
    expect(r.now, [115, 203]);
    expect(sheet.spots.containsKey('abuela.delante'), isFalse);
    // the places of h-mesa from the reference folder: the sitters on their chairs (150 + SD)
    expect(sheet.remapPoint(104, 150).now, [104, 135]);
    expect(sheet.remapPoint(176, 150).now, [176, 171]);
    expect(sheet.remapPoint(48, 168).now, [48, 168]);
  });

  test('storyMoves: the sitters, cual-mesa\'s own, and the stall', () {
    final m = sheet.storyMoves;
    expect(m, hasLength(11));
    expect([for (final s in m.take(4)) s.who], everyElement('sitting'));
    expect([for (final s in m.take(4)) s.now[1]], [135, 147, 159, 171]);
    expect(m.take(4).every((s) => s.uses == null), isTrue);
    final cual = m.where((s) => s.uses != null && s.scene == null).toList();
    expect(cual, hasLength(6));
    expect(cual.every((s) => s.uses!.single == 'cual-mesa.json'), isTrue);
    final stall = m.singleWhere((s) => s.scene != null);
    expect(
      [stall.scene, stall.spot, stall.now],
      [
        'frutas',
        'abuela.delante',
        [115, 203],
      ],
    );
  });

  test('the spots: the frog\'s at the place the sheet gives as new', () {
    for (final s in sheet.spots.values) {
      if (s.scale == null) continue;
      final f = sheet.frogAt(s.name, e), now = s.now!;
      expect([f.x, f.y], [now[0], now[1]], reason: s.name);
    }
    expect(sheet.spots['puerta']!.now, [84, 101]);
    expect(sheet.spots['fogon']!.now, [202, 194]);
  });

  test('hops: one pair changes, 3 to 2; 36 in all', () {
    expect(sheet.hops, hasLength(1));
    final h = sheet.hops.single;
    expect([h.a, h.b, h.old, h.now], ['frog.ranaa', 'rana.2', 3, 2]);
    expect(sheet.hopsAll, hasLength(36));
  });

  test('the things of the set: their boxes, hint boxes and hands', () {
    expect(sheet.things['mesa']!.box, [64, 102, 124, 91]);
    expect(sheet.things['mesa']!.hand, [140, 159]);
    expect(sheet.things['estufa']!.hintBox, [195, 61, 9, 87]);
    expect(sheet.things['cocina']!.hintBox, [36, 14, 168, 188]);
    expect(sheet.things['olla']!.box, [194, 90, 26, 20]);
  });

  test('front: eleven parts after everyone', () {
    expect(sheet.front, [
      'mesa',
      'mesa.patas',
      'sillas',
      'sillas.patas',
      'mostrador',
      'mostrador2',
      'estufa',
      'pared',
      'puerta',
      'puerta.umbral',
      'puerta.jamba',
    ]);
    for (final p in sheet.frontParts.values) {
      expect(p.sortY, 9999);
    }
    expect(sheet.frontTags, hasLength(6));
  });

  test(
    'shadows: the frog, the people by kind, Canelo, the things on the floor',
    () {
      expect(sheet.shadows.keys, ['coqui', 'people', 'perro', 'cosas']);
      expect(sheet.shadows['people']!.radii, {'adulto': .34, 'nino': .3});
      expect(sheet.shadows['coqui']!.radius, .45);
    },
  );

  test('dropped: the background, the lit oven, the old table', () {
    expect([for (final d in sheet.droppedCode) d.line], [156, 157, 171]);
  });

  test('helps: none', () {
    expect(sheet.helps, isNull);
  });

  test('the pictures: cocina.no is El colmado\'s stall, cocina.si wide, the rest close', () {
    expect(sheet.pictures['cocina.no']!.crop, [20, 112, 196, 104]);
    expect(sheet.pictures['cocina.si']!.zoom, 1);
    expect(sheet.pictures.values.where((p) => p.zoom == 2), hasLength(22));
  });
}
