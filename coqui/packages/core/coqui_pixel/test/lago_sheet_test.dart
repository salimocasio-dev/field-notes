// The sheet reader against El lago's real sheet (docs/proyecto/pixel/lago-sheet.json, order 35a): what it writes that
// the earlier sheets do not (the water as a thing whose world is null; the dock as a box of six numbers and the mooring
// posts as a list of points; the ripple rings by kind, a duck's, a boat's, the bread's, and the fish's pale patch; a move
// that takes another thing with it, `shift`; the shadows' rule in words; three parts in front; 23 moves; no hop changed)
// parses, and what the engine gives is the numbers the sheet records. On the vm the file itself is read, in a browser the
// fixture made from it (tool/make_sheet_fixture.dart).
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

int _round(num v) => (v + .5).floor();

void main() {
  final sheet = Sheet.parse(lagoSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  test('El lago: S 26, origin (0, 4), a 240 x 216 picture', () {
    expect(sheet.scene, 'lago');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [0, 4]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(19));
    expect(sheet.spots, hasLength(35));
    expect(sheet.lugar.keys, ['inicio', 'muelle']);
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(22));
    expect(sheet.level, hasLength(16));
    expect(sheet.clips, isEmpty);
    expect(sheet.frames, isEmpty);
    expect(sheet.points.keys, ['poste']);
    expect(sheet.screenPoints.keys, [
      'shore',
      'dock',
      'postes',
      'corazon',
      'sol',
      'nubes',
    ]);
    expect(sheet.remapTable, hasLength(48));
    expect(sheet.moves, hasLength(23));
    expect(sheet.unknown.keys, ['layout', 'hopsWhat', 'clipsWhat', 'checks']);
  });

  test('setKey: no parameter; one baked state', () {
    expect(sheet.setKey.params, isEmpty);
    expect([for (final b in sheet.setKey.baked) b.query], ['?']);
  });

  test('the spots: the frog\'s are at the place the sheet gives as new', () {
    for (final s in sheet.spots.values) {
      if (s.scale == null) continue;
      final f = sheet.frogAt(s.name, e), now = s.now!;
      expect([f.x, f.y], [now[0], now[1]], reason: s.name);
    }
    expect(sheet.spots['carmen.inicio19']!.now, [206, 110]);
    expect(sheet.spots['carmen.inicio19']!.old, [196, 117]);
  });

  test('hops: every pair\'s count is kit.js acts.ir\'s from the frog\'s places, none changed', () {
    expect(sheet.hopsAll, hasLength(21));
    expect(sheet.hops, isEmpty);
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
      expect(h.now, h.old, reason: '${h.a} - ${h.b}');
    }
  });

  test('the things of the set: the water has no world; the boxes, hint boxes and hands', () {
    expect(sheet.things['agua']!.world, isNull);
    expect(sheet.things['agua']!.raw['ground'], isTrue);
    final j = sheet.things['juncos']!,
        p = sheet.things['poste']!,
        m = sheet.things['muelle']!;
    expect(
      [j.box, j.hintBox, j.hand],
      [
        [193, 140, 29, 33],
        [193, 140, 11, 33],
        [199, 157],
      ],
    );
    expect(
      [p.box, p.hintBox, p.hand],
      [
        [162, 129, 8, 37],
        null,
        [166, 152],
      ],
    );
    expect(
      [m.box, m.hintBox, m.hand],
      [
        [16, 120, 139, 73],
        [36, 120, 119, 73],
        [96, 160],
      ],
    );
  });

  test('views: one window, x0 22', () {
    expect(sheet.viewOf('wide', e), [22, 0, 196, 216]);
  });

  test('points: the shore as a line, the dock as a box, the mooring posts, the post, the sun, the clouds', () {
    final shore = sheet.screenPoint('shore');
    expect(shore.line, .272);
    expect(shore.points, [
      [125, 115],
      [15, 170],
    ]);
    final dock = sheet.screenPoint('dock');
    expect(dock.line, isNull);
    expect(dock.points, hasLength(4));
    expect(dock.raw['world'], hasLength(6));
    expect(sheet.screenPoint('postes').points, [
      [40, 141],
      [133, 141],
    ]);
    expect(sheet.anchor('poste').screen, [166, 132]);
    expect(sheet.anchor('poste').raw['foot'], [166, 164]);
    expect(sheet.screenPoint('sol').radius, 8);
    expect(sheet.screenPoint('nubes').points, hasLength(3));
  });

  test(
    'dropped: two pieces of the old source, the background and the old reeds',
    () {
      expect([for (final d in sheet.droppedCode) d.line], [112, 116]);
      expect(sheet.droppedCode.every((d) => d.to.isEmpty), isTrue);
      expect(sheet.dropped.first, startsWith('112: the background'));
    },
  );

  test('moves: 23 pieces of the old source, the post that takes the paddling duck with it, the answer cards', () {
    expect([for (final m in sheet.moves) m.respEn].whereType<List<int>>(), [
      [121, 75],
      [127, 31],
      [132, 32],
    ]);
    final post = sheet.moves.firstWhere((m) => m.src == 'POSTE=[152,146]');
    expect(post.to, 'POSTE=[166,156]');
    expect(
      [post.shift!.who, post.shift!.when, post.shift!.by],
      [
        'pato',
        'rema',
        [14, 10],
      ],
    );
    expect(
      [
        for (final m in sheet.moves)
          if (m.shift != null) m.line,
      ],
      [17],
    );
    final p7 = sheet.moves.firstWhere((m) => m.line == 63);
    expect(p7.places, hasLength(21));
    expect(p7.places.first.now, [142, 177]);
  });

  test('helps: the ring\'s colour, a duck\'s, a boat\'s and the bread\'s rings, the fish\'s patch, the four lines it adds', () {
    final h = sheet.helps!;
    expect([h.margin, h.edge], [8, 6]);
    expect(h.ring.inner, .45);
    expect(h.ring.colour, 0xFFF6ECD4);
    expect(h.ring.kinds.keys, ['pato', 'bote', 'pan']);
    expect(h.ring.kind('pato'), (rx: 13, ry: 3, dy: 0));
    expect(h.ring.kind('bote'), (rx: 11, ry: 3, dy: 0));
    expect(h.ring.kind('pan'), (rx: 7, ry: 2.5, dy: 0));
    expect(() => h.ring.ball, throwsA(isA<SheetError>()));
    final pez = h.ring.patch('pez');
    expect(
      [pez.centre, pez.rx, pez.ry, pez.soft],
      [
        [0, -.5],
        13,
        8.5,
        3,
      ],
    );
    expect(pez.patch, 0xFFE0D2A6);
    expect(pez.dash, 0xFFD3C495);
    expect(h.lines, hasLength(4));
    expect(h.lines[2].to, contains('PREVIEW.patch(c,o);'));
  });

  test('shadows: by kind, none of the old code\'s own', () {
    expect(sheet.shadows.keys, [
      'coqui',
      'people',
      'perro',
      'pato',
      'ave',
      'bote',
      'pan',
      'bolsa',
      'saco',
    ]);
    expect(sheet.shadows['people']!.radii, {'nino': .3});
    expect(sheet.shadows['pato']!.radius, .26);
    expect(sheet.shadowsNote, contains('lago.js draws no shadow'));
  });

  test('front: the reeds, the post and the mooring posts after everyone, the sorted list\'s tags', () {
    expect(sheet.front, ['juncos', 'poste', 'muelle.postes']);
    for (final p in sheet.frontParts.values) {
      expect([p.sortY, p.line], [9999, null]);
    }
    expect(sheet.frontWaterDepth, isNull);
    expect(sheet.frontTags, hasLength(7));
  });

  test('bubbles and talk: the places, the heads standing and sitting, the rounds card as a rectangle', () {
    final t = sheet.talk!;
    expect(t.places, hasLength(17));
    expect(t.heads['luis.s'], (top: -38, head: 0));
    expect(t.boardRect, [2, 2, 68, 26]);
  });

  test('remap: the same screen place, the ones that moved, the frog out of a picture', () {
    expect(sheet.remapPoint(96, 118).now, [86, 113]);
    expect(sheet.remapPoint(96, 118).moved, isTrue);
    expect(sheet.remapPoint(0, 0).to.none, isNotNull);
    expect(sheet.remapPoint(150, 190).now, [150, 190]);
    expect(sheet.remapCam([84, 84, 113, 60]).crops!['pajaro.si']!.crop, [
      142,
      76,
      98,
      52,
    ]);
  });
}
