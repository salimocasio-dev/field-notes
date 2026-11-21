// The sheet reader against El banco's real sheet (docs/proyecto/pixel/banco-sheet.json, order 36a): what it writes that
// the earlier sheets do not (a set key of three parameters given in words, each baked state with its key, the states not
// reached; the code entries with their numbers by kind; the points that are parts of the set given by their numbers; the
// light of the hour, the old page's patch, the cart standing and rolling, as words; hops between screen points; talk with
// each sprite's height; helps with no ring, a pigeon's shadow in the air as a function's source; a move named on several
// lines; the remap's surfaces; checks.notFixed) parses, and what the engine gives is the numbers the sheet records. On the
// vm the file itself is read, in a browser the fixture made from it (tool/make_sheet_fixture.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

void main() {
  final sheet = Sheet.parse(bancoSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  test('El banco: S 26, origin (0, 4), a 240 x 216 picture', () {
    expect(sheet.scene, 'banco');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [0, 4]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(20));
    expect(sheet.spots, hasLength(18));
    expect(sheet.lugar.keys, ['inicio', 'centro']);
    expect(sheet.views.keys, ['wide']);
    expect(sheet.pictures, hasLength(24));
    expect(sheet.level, hasLength(16));
    expect(sheet.clips, isEmpty);
    expect(sheet.frames, isEmpty);
    expect(sheet.points, isEmpty);
    expect(sheet.screenPoints.keys, ['sol', 'luna', 'nubes', 'corazon']);
    expect(sheet.otherPoints.keys, [
      'bancos',
      'bancosWhat',
      'borde',
      'seto',
      'porton',
      'poste',
      'farol',
      'cable',
      'luz',
      'arboles',
      'arbolesWhat',
      'carro',
    ]);
    expect(sheet.remapTable, hasLength(62));
    expect(sheet.moves, hasLength(42));
    expect(sheet.code, hasLength(333));
    expect(sheet.unknown.keys, ['layout', 'clipsWhat', 'checks']);
  });

  test('setKey: luz, luna and carro in words; seven baked states with their keys, five not reached', () {
    expect(sheet.setKey.params.keys, ['luz', 'luna', 'carro']);
    expect(sheet.setKey.params['luna']!.fromW, 'W.noche && W.luna ? 1 : 0');
    expect(sheet.setKey.key, 'luz + "." + luna + "." + carro');
    expect(
      [for (final b in sheet.setKey.baked) b.key],
      [
        'dia.0.abierto',
        'dia.0.no',
        'tarde.0.abierto',
        'noche.0.abierto',
        'noche.0.cerrado',
        'noche.0.no',
        'noche.1.abierto',
      ],
    );
    expect(sheet.setKey.baked.last.query, '?luz=noche&luna=1&carro=abierto');
    expect(sheet.setKey.notReached, hasLength(5));
  });

  test('the light, the patch and the cart, in the sheet\'s words', () {
    expect(sheet.light.keys, ['tarde', 'noche', 'sprites', 'shadows']);
    expect(sheet.light['sprites'], startsWith('not darkened'));
    expect(sheet.patch.keys, ['old', 'what', 'kept']);
    expect(sheet.patch['old'], startsWith('banco.js:194'));
    final c = sheet.carro!;
    expect(c.from, 'state <luz>.<luna>.cerrado, part carro');
    expect(
      c.at,
      'dx = R(W.carroX) - CARRO[0], dy = R((CARRO[0] - W.carroX) / 2)',
    );
    expect(sheet.things['carro']!.rolling, contains('R(W.carroX)'));
  });

  test('the code: every entry gives its line\'s numbers by kind', () {
    final c19 = sheet.code.firstWhere((c) => c.line == 19);
    expect(c19.old, isEmpty);
    expect(c19.numbers['place'], hasLength(12));
    expect(c19.numbers['other'], ['132']);
    expect(sheet.code.where((c) => c.raw['numbers'] == null), hasLength(2));
  });

  test('the spots: the frog\'s at the place the sheet gives as new; the surface of each', () {
    for (final s in sheet.spots.values) {
      if (s.scale == null) continue;
      final f = sheet.frogAt(s.name, e), now = s.now!;
      expect([f.x, f.y], [now[0], now[1]], reason: s.name);
    }
    expect(sheet.spots['porton']!.now, [199, 203]);
    expect(sheet.spots['porton']!.on, 'pave');
    expect(sheet.spots['cable.0']!.on, 'wire');
  });

  test('hops: 26 walks between screen points, none changed', () {
    expect(sheet.hops, isEmpty);
    expect(sheet.hopsAll, hasLength(26));
    for (final h in sheet.hopsAll) {
      expect(h.now, h.old, reason: '${h.a} - ${h.b}');
      expect(h.aAt, hasLength(2));
      expect(h.by, isNotNull);
    }
    expect(sheet.hopsAll.first.a, '104,180');
  });

  test('the things of the set: their boxes, hint box and hands', () {
    expect(sheet.things['carro']!.box, [27, 93, 43, 91]);
    expect(sheet.things['farol']!.hand, [174, 100]);
    expect(sheet.things['parque']!.hintBox, [36, 40, 168, 162]);
    for (final k in const ['banco0', 'banco1', 'banco2']) {
      expect(sheet.things[k]!.set, isTrue, reason: k);
    }
    expect(sheet.things['luis']!.sprite, isTrue);
  });

  test('views: one window, x0 22', () {
    expect(sheet.viewOf('wide', e), [22, 0, 196, 216]);
  });

  test('points: the sun, the moon, the clouds, the heart; the set\'s parts by their numbers', () {
    expect(sheet.screenPoint('sol').xy, [34, 40]);
    expect(sheet.screenPoint('sol').radius, 4);
    expect(sheet.screenPoint('luna').radius, 4);
    expect(sheet.screenPoint('nubes').points, hasLength(3));
    expect(sheet.screenPoint('corazon').xy, [110, 30]);
    expect(sheet.otherPoints['bancos'], hasLength(3));
    expect((sheet.otherPoints['farol'] as Map)['foot'], [174, 140]);
  });

  test('dropped: four pieces of the old source, the background, the moon, the night and the evening', () {
    expect([for (final d in sheet.droppedCode) d.line], [192, 193, 194, 195]);
    expect(sheet.droppedCode.every((d) => d.to.isEmpty), isTrue);
  });

  test('moves: 42 pieces of the old source; one named on several lines', () {
    final m = sheet.moves.firstWhere((m) => m.src == '246,PORTON[1])');
    expect(m.lines, [322, 325, 332, 333, 334]);
    expect(m.to, '246,PORTON[1]+12)');
    final p = sheet.moves.firstWhere((m) => m.src == 'PORTON=[188,197];');
    expect(p.places, hasLength(4));
    expect(p.places.first.now, [199, 203]);
  });

  test(
    'helps: no ring; a pigeon\'s shadow in the air (GS), the line it adds',
    () {
      final h = sheet.helps!;
      expect(h.margin, 6);
      expect(() => h.ring, throwsA(isA<SheetError>()));
      expect(h.shadowGsSource, startsWith('(x0,y0,x1,y1,t)=>'));
      expect(h.lines, hasLength(1));
      expect(h.lines.first.to, contains('o.gs=GS(x0,y0,x,y,t)'));
    },
  );

  test('shadows: by kind, none at night', () {
    expect(sheet.shadows.keys, [
      'coqui',
      'people',
      'perros',
      'coche',
      'paloma',
      'cosas',
    ]);
    expect(sheet.shadows['people']!.radius, .32);
    expect(sheet.shadows['paloma']!.radius, .16);
  });

  test('front: eight parts after everyone, the sorted list\'s tags', () {
    expect(sheet.front, [
      'banco0',
      'banco1',
      'banco2',
      'carro',
      'farol',
      'poste',
      'porton',
      'seto',
    ]);
    for (final p in sheet.frontParts.values) {
      expect([p.sortY, p.line], [9999, null]);
    }
    expect(sheet.frontTags, hasLength(6));
  });

  test('bubbles and talk: the places, each sprite\'s height, the rounds card as a rectangle', () {
    final t = sheet.talk!;
    expect(t.places, hasLength(17));
    expect(t.heads, isEmpty);
    expect(t.heights['hombre.1'], 49);
    expect(t.boardRect, [2, 2, 68, 26]);
    expect(sheet.bubbleRects.keys, hasLength(7));
  });

  test('remap: the same screen place, the ones that moved, their surfaces, the frog out of a picture', () {
    final p = sheet.remapPoint(51, 172);
    expect(
      [p.now, p.moved, p.to.on],
      [
        [40, 172],
        true,
        'pave',
      ],
    );
    expect(sheet.remapPoint(87, 161).to.on, 'seat');
    expect(sheet.remapPoint(87, 161).now, [87, 157]);
    expect(sheet.remapPoint(0, 0).to.none, isNotNull);
    expect(sheet.remapPoint(66, 55).to.on, 'sky');
    expect(sheet.remapCam([64, 154, 113, 60]).crops!['viejo.si']!.crop, [
      49,
      164,
      98,
      52,
    ]);
  });

  test('checks: the notes, and what the maker found and did not fix', () {
    final c = sheet.checks!;
    expect(c.notes, isNotEmpty);
    expect(c.notFixed, hasLength(4));
    expect(c.notFixed.last.what, startsWith('senor-senora, every plan'));
  });
}
