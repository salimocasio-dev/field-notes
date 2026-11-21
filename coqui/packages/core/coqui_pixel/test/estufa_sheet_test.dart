// The sheet reader against La estufa's real sheet (docs/proyecto/pixel/estufa-sheet.json, order 38a): what it writes
// that the earlier sheets do not (a set parameter given as its rule in words; `smoothing` as a sentence; points that are
// a list or words, and world boxes with no screen place; a remap of kind `rect`; a clip the sheet no longer makes; the
// window's front part drawn after the window's people at a world y; `code` entries that give their numbers by kind;
// `talk` with each one's height and abuela's head; hops with no distance; `helps` with nothing in it; `faults`) parses,
// and the places it names are where its rule says. On the vm the file itself is read, in a browser the fixture made
// from it (tool/make_sheet_fixture.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

int _round(num v) => (v + .5).floor();

void main() {
  final sheet = Sheet.parse(estufaSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
    shadowX: .9,
    shadowY: -.1,
  );

  test('La estufa: S 26, origin (-102, -40), a 240 x 216 picture', () {
    expect(sheet.scene, 'estufa');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [-102, -40]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(17));
    expect(sheet.spots, hasLength(52));
    expect(sheet.lugar.keys, ['inicio', 'centro']);
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(24));
    expect(sheet.level, hasLength(17));
    expect(sheet.clips, isEmpty);
    expect(sheet.raw['clips'], contains('ventana'));
    expect(sheet.frames, isEmpty);
    expect(sheet.points.keys, isEmpty);
    expect(sheet.screenPoints.keys, ['corazon']);
    expect(sheet.otherPoints.keys, [
      'run',
      'burners',
      'burnersWhat',
      'banco',
      'ventana',
      'estante',
      'campana',
      'salpicadero',
    ]);
    expect(sheet.remapTable, hasLength(35));
    expect(sheet.moves, hasLength(38));
    expect(sheet.code, hasLength(227));
    expect(sheet.unknown.keys, ['layout', 'hopsWhat', 'checks']);
  });

  test('setKey: banco, its rule in words; two baked states', () {
    expect(sheet.setKey.params.keys, ['banco']);
    expect(sheet.setKey.params['banco']!.values, isEmpty);
    expect(sheet.setKey.params['banco']!.fromW, startsWith('W.banco ? 1 : 0'));
    expect(
      [for (final b in sheet.setKey.baked) b.query],
      ['?banco=1', '?banco=0'],
    );
  });

  test('smoothing: a sentence, no place', () {
    expect(sheet.smoothing, isEmpty);
    expect(sheet.smoothingWhat, contains('never on'));
  });

  test('points: the burners as a list, the run, the stool and the window as world points and boxes (as written)', () {
    final burners = sheet.otherPoints['burners'] as List;
    expect(burners, hasLength(2));
    expect((burners[0] as Map)['pot'], [107, 97]);
    expect((burners[1] as Map)['pot'], [145, 116]);
    expect((sheet.otherPoints['run'] as Map)['world'], [
      0,
      0,
      0,
      12.4,
      1.4,
      1.3,
    ]);
    expect((sheet.otherPoints['ventana'] as Map)['hole'], hasLength(4));
    expect(sheet.screenPoint('corazon').xy, [124, 24]);
    // the stool: its top's middle under the frog's feet (the old BANCO)
    final w = [
      for (final v in (sheet.otherPoints['banco'] as Map)['world'] as List)
        v as num,
    ];
    final p = e.project(w[0], w[1], w[2]);
    expect([_round(p.sx), _round(p.sy)], [126, 184]);
    expect((sheet.otherPoints['banco'] as Map)['top'], [126, 184]);
  });

  test('the floor rule: a person\'s or a thing\'s spot is under (x, y - 1); the frog\'s, under (q.x + 16, q.y + 25)', () {
    // (the sheet's rules.floor says q.y + 26 for the frog, where estufa-preview.html looks for his surface and his
    // shadow; its frog spots' world points are one row higher, at q.y + 25: the preview's rule is what the port uses)
    for (final s in sheet.spots.values) {
      final now = s.now!, w = s.world, p = e.project(w[0], w[1], w[2]);
      final frog = s.name.startsWith('frog.');
      final at = frog ? [now[0] + 16, now[1] + 25] : [now[0], now[1] - 1];
      expect((p.sx - at[0]).abs(), lessThan(.01), reason: s.name);
      expect((p.sy - at[1]).abs(), lessThan(.01), reason: s.name);
    }
    expect(
      [for (final l in sheet.lugar.values) l.frog],
      [
        [110, 157],
        [110, 157],
      ],
    );
  });

  test(
    'remap: a rect (the smell\'s curve), moved points, the review crops',
    () {
      final r = sheet.remapTable.firstWhere((r) => r.kind == 'rect');
      expect(r.old, [106, 104, 90, 117]);
      expect(r.now, [106, 79, 90, 117]);
      expect(r.moved, isTrue);
      final s = sheet.remapTable.firstWhere(
        (r) => r.kind == 'point' && r.old[0] == 126 && r.old[1] == 127,
      );
      expect(
        [s.now, s.moved],
        [
          [126, 107],
          true,
        ],
      );
      final cam = sheet.remapTable.firstWhere(
        (r) =>
            r.kind == 'cam' && r.uses.contains('cual-estufa.json hace.si.cam'),
      );
      final c = cam.crops!['hace.si']!;
      expect(
        [c.crop, c.zoom],
        [
          [44, 79, 196, 104],
          1,
        ],
      );
    },
  );

  test('front: the stool after everyone; the window\'s parts after its people, at world y -.57', () {
    expect(sheet.front, ['banco', 'ventana']);
    final banco = sheet.frontParts['banco']!,
        win = sheet.frontParts['ventana']!;
    expect([banco.sortY, banco.line], [9999, null]);
    expect(banco.raw['parts'], ['banco', 'banco.patas']);
    expect([win.sortY, win.line], [null, null]);
    expect(win.raw['y'], -.57);
    expect(win.raw['parts'], hasLength(16));
    expect(sheet.frontTags, hasLength(2));
  });

  test(
    'code: 227 entries, their numbers by kind; no line is left without one',
    () {
      expect(sheet.code.every((c) => c.old.isEmpty), isTrue);
      final c19 = sheet.code.firstWhere((c) => c.line == 19);
      expect((c19.raw['numbers'] as Map)['place'], hasLength(12));
      expect(sheet.code.where((c) => c.line is String), hasLength(2));
    },
  );

  test('talk: places, each one\'s height, abuela\'s head, the rounds card as a rectangle', () {
    final t = sheet.talk!;
    expect(t.places, hasLength(17));
    expect(t.places.first, (side: 0, dy: 0));
    expect(t.heads, isEmpty);
    expect(t.heights, {
      'luis': 44,
      'carmen': 44,
      'abuelo': 56,
      'mama': 56,
      'papa': 56,
    });
    expect(t.abuelaHead, 0);
    expect(t.boardRect, [2, 2, 68, 26]);
    expect(sheet.bubbleRects['hola'], [-16, -46, 34, 44]);
  });

  test(
    'hops: 28 pairs; one count changed (saco to servir), with no distance',
    () {
      expect(sheet.hopsAll, hasLength(28));
      expect(sheet.hops, hasLength(1));
      final h = sheet.hops.single;
      expect([h.a, h.b, h.old, h.now], ['saco', 'servir', 3, 2]);
      expect(h.dOld.isNaN && h.dNow.isNaN, isTrue);
    },
  );

  test('helps: none; behind: none; faults: line 122 with 125', () {
    expect(sheet.helps, isNull);
    expect(sheet.behind!.items, isEmpty);
    expect(sheet.faults, hasLength(1));
    expect([sheet.faults.single.line, sheet.faults.single.and], [122, 125]);
    expect(sheet.faults.single.what, contains('baby'));
  });

  test('dropped: the background and the stool; moves: 38, the answer cards in the sky', () {
    expect([for (final d in sheet.droppedCode) d.line], [133, 154]);
    final m = sheet.moves.firstWhere((m) => m.line == 331);
    expect(m.to, 'fresh:()=>({respEn:[146,20],');
    expect(sheet.moves.firstWhere((m) => m.line == 134).places, hasLength(3));
  });
}
