// The sheet reader against A comer's real sheet (docs/proyecto/pixel/comer-sheet.json, order 40a): what it writes that the
// earlier sheets do not (no `points` at all: every place is a spot, a move's or the code's; `clips` saying in words that
// there is none; `talk` with the faces in words and the rounds card's rectangle with no words of its own; faults that name
// their lines in words, with no `line`) parses, and the places it names are where its rule says: the view at x0 32, one
// baked state, the table and the chairs as front parts at their sort rows, the frog's places on the cloth, the remap of the
// pairs' moved points, the moves' named places, the hops (every pair keeps its old count), the 831 code lines. On the vm
// the file itself is read, in a browser the fixture made from it (tool/make_sheet_fixture.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

void main() {
  final sheet = Sheet.parse(comerSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
    shadowX: .9,
    shadowY: -.1,
  );

  test('A comer: S 26, origin (-10, -43), a 240 x 216 picture', () {
    expect(sheet.scene, 'comer');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [-10, -43]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has; no points; clips in words only', () {
    expect(sheet.things, hasLength(23));
    expect(sheet.spots, hasLength(49));
    expect(sheet.lugar.keys, ['inicio', 'centro']);
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(24));
    expect(sheet.level, hasLength(12));
    expect(sheet.points, isEmpty);
    expect(sheet.clips, isEmpty);
    expect(sheet.raw['clips'], {'none': 'comer.js never calls clip()'});
    expect(sheet.frames, isEmpty);
    expect(sheet.remapTable, hasLength(60));
    expect(sheet.moves, hasLength(91));
    expect(sheet.code, hasLength(831));
    expect(sheet.dropped, hasLength(2));
  });

  test('the view: x0 32, as the old', () {
    expect(sheet.viewOf('wide', e), [32, 0, 196, 216]);
  });

  test('setKey: one baked state, "comer", for every W', () {
    expect(sheet.setKey.params, isEmpty);
    expect(sheet.setKey.baked, hasLength(1));
    expect(sheet.setKey.baked.single.key, 'comer');
    expect(sheet.setKey.notReached, isEmpty);
  });

  test('the frog\'s places: LUGAR on the cloth (q 124, 141), his feet the spot frog.inicio', () {
    for (final l in sheet.lugar.values) {
      expect(l.frog, [124, 141]);
      expect(l.spot, 'frog.inicio');
    }
    expect(sheet.spots['frog.inicio']!.now, [124, 168]);
    expect(sheet.spots['frog.inicio']!.raw['on'], 'mesa');
    // the frog's spots stand on the cloth
    for (final n in const [
      'HOME33',
      'FETCH33',
      'CASA34',
      'EAT34',
      'CASA35',
      'aparte33',
    ]) {
      expect(sheet.spots[n]!.raw['on'], 'mesa', reason: n);
    }
  });

  test('remap: the pairs\' moved points; the frog out of a picture is no place; rectangles by their pictures', () {
    SheetRemap point(num x, num y) => sheet.remapPoint(x, y);
    expect(
      [point(88, 172).now, point(88, 172).moved],
      [
        [96, 154],
        true,
      ],
    );
    expect(point(128, 164).now, [128, 164]);
    expect(point(128, 164).moved, isFalse);
    expect(point(0, 0).to.none, isNotNull);
    expect(sheet.remapTable.where((r) => r.kind == 'point'), hasLength(54));
    expect(sheet.remapTable.where((r) => r.kind == 'cam'), hasLength(4));
    expect(sheet.remapTable.where((r) => r.kind == 'crop'), hasLength(2));
    final cam = sheet.remapTable.firstWhere(
      (r) => r.kind == 'cam' && r.old[0] == 26,
    );
    expect(cam.crops!['no_me_gusta.si']!.crop, [30, 146, 98, 52]);
  });

  test(
    'moves: SY round column 118 and the layout\'s numbers; story 33\'s places',
    () {
      final n = (sheet.raw['layout'] as Map)['numbers'] as Map;
      expect(n['SYC'], 118);
      expect(n['XP'], 202);
      expect(n['DOOR'], [74, 86]);
      expect(n['PB'], [76, 105]);
      final m21 = sheet.moves.firstWhere((m) => m.line == 21);
      expect(m21.to, contains('SY='));
      final m758 = sheet.moves.firstWhere((m) => m.line == 758);
      expect(m758.to, contains('HOME33=[118,165]'));
      expect(sheet.spots['HOME33']!.now, [118, 165]);
    },
  );

  test('things: the table and papá\'s chair with their boxes (by chair), the room last', () {
    expect(sheet.things['mesa']!.box, [12, 94, 188, 117]);
    expect(sheet.things['mesa']!.hintBox, [46, 94, 154, 108]);
    expect(sheet.things['silla_papa']!.raw['byChair'], hasLength(4));
    expect(sheet.things['cocina']!.box, [0, 0, 240, 216]);
    expect(sheet.things.keys.last, 'cocina');
  });

  test('talk: 17 places, the faces in words, the rounds card\'s rectangle', () {
    final t = sheet.talk!;
    expect(t.places, hasLength(17));
    expect(t.places.first, (side: 0, dy: 0));
    expect(t.heads, isEmpty);
    expect(t.heights, isEmpty);
    expect(t.faces, contains('a person\'s face'));
    expect(t.boardRect, [2, 2, 68, 26]);
  });

  test('front: the chairs (sortY 60) and the table (sortY 173) drawn again over whoever is behind them', () {
    expect(sheet.frontParts.keys, ['sillas', 'mesa']);
    expect(sheet.frontParts['sillas']!.sortY, 60);
    expect(sheet.frontParts['mesa']!.sortY, 173);
    expect(sheet.frontParts['sillas']!.raw['parts'], [
      'silla0',
      'silla1',
      'silla2',
      'silla3',
      'sillas.patas',
    ]);
    expect(sheet.frontTags, hasLength(3));
  });

  test('shadows: the people and the dog on the floor; none for the frog', () {
    expect(sheet.shadows['people']!.radii, {
      'abuela': .35,
      'nino': .3,
      'other': .35,
    });
    expect(sheet.shadows['perro']!.radius, .3);
  });

  test('faults: three, named in words with no line', () {
    expect(sheet.faults, hasLength(3));
    for (final f in sheet.faults) {
      expect(f.line, isNull);
    }
    expect(sheet.faults.first.what, contains('di_buen'));
  });

  test('hops: no walk changes; all 28 pairs of the frog\'s named places keep their old count', () {
    expect(sheet.hops, isEmpty);
    expect(sheet.hopsAll, hasLength(28));
    expect(sheet.hopsAll.where((h) => h.now != h.old), hasLength(17));
  });
}
