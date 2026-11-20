// The sheet reader against El balcón's real sheet (docs/proyecto/pixel/balcon-sheet.json, order 30a): what it writes that
// El frente's does not (no frames; `front` as parts at old lines; the lugar's `q`; abuela's spots with `ab`; the remap's
// pictures, crops and level entries; the baked states with no reference folder; `MESA_Y` and `behind`) parses, and what
// the engine gives is the numbers the sheet records. On the vm the file itself is read, in a browser the fixture made
// from it (tool/make_sheet_fixture.dart).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

const hundredth = .0051;

Matcher near(num v) => closeTo(v, hundredth);

void main() {
  final sheet = Sheet.parse(balconSheetText());
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );
  final raw = sheet.raw;

  test('El balcón: S 26, origin (38, 20), a 240 x 216 picture', () {
    expect(sheet.scene, 'balcon');
    expect(sheet.S, 26);
    expect([sheet.originX, sheet.originY], [38, 20]);
    expect([sheet.pictureW, sheet.pictureH], [240, 216]);
  });

  test('every part is there, in the numbers the sheet has', () {
    expect(sheet.things, hasLength(13));
    expect(sheet.spots, hasLength(13));
    expect(sheet.lugar, hasLength(11));
    expect(sheet.views.keys, ['wide', 'mesa', 'porche']);
    expect(sheet.pictures, hasLength(20));
    expect(sheet.clips.keys, ['puerta.hueco']);
    expect(sheet.frames, isEmpty, reason: 'the sheet has no frames');
    expect(sheet.unknown.keys, containsAll(['roof', 'hops', 'checks']));
  });

  test('front: three parts of the set drawn again at their old lines', () {
    expect(sheet.front, ['silla_grande', 'silla_pequena', 'mesa']);
    expect({for (final p in sheet.frontParts.values) p.name: p.line}, {
      'silla_grande': 127,
      'silla_pequena': 135,
      'mesa': 136,
    });
    expect(sheet.frontParts['mesa']!.replaces, contains('mkMesa'));
    expect(sheet.frontPlane, contains('tan(30 deg)'));
    expect(sheet.frontHow, contains('bakedZ[i] >'));
  });

  test('MESA_Y and behind: the old number and the new one', () {
    expect(sheet.numbers.keys, containsAll(['MESA_Y', 'behind']));
    expect(sheet.numbers['MESA_Y']!.old, 128);
    expect(sheet.numberOf('MESA_Y'), raw['MESA_Y']['new']);
    expect(sheet.numbers['behind']!.old, 144);
    expect(sheet.numberOf('behind'), raw['behind']['new']);
    expect(sheet.unknown.containsKey('MESA_Y'), isFalse);
    expect(() => sheet.numberOf('nada'), throwsA(isA<SheetError>()));
  });

  test('the baked states: four queries, no reference folder named', () {
    expect([for (final b in sheet.setKey.baked) b.query], [
      '?door=shut&win=shut',
      '?door=open&win=shut',
      '?door=shut&win=open',
      '?door=open&win=open',
    ]);
    expect(sheet.setKey.baked.every((b) => b.ref == null), isTrue);
    expect(sheet.setKey.baked.first.reached, contains('que-calor'));
    expect(sheet.setKey.params.keys, ['door', 'win']);
  });

  test('the spots: the engine puts each where the sheet records it', () {
    for (final s in sheet.spots.values) {
      final p = sheet.screenOf(s.name, e);
      expect([p.x, p.y], [near(s.screen[0]), near(s.screen[1])], reason: s.name);
      if (s.scale != null) {
        final f = sheet.frogAt(s.name, e);
        expect([f.x, f.y], s.frog, reason: s.name);
      } else {
        // abuela's: ab = round(sx), round(sy) + 1; her sprite at ab - (30, 50)
        expect(s.ab, [(p.x + .5).floor(), (p.y + .5).floor() + 1]);
        final a = sheet.abuelaAt(s.name, e);
        expect([a.x, a.y], [s.ab![0] - 30, s.ab![1] - 50], reason: s.name);
      }
    }
  });

  test('lugar: the frog box the sheet writes as q, and the old entry', () {
    for (final l in sheet.lugar.values) {
      expect(sheet.lugarOf(l.name, e), [l.frog[0], l.frog[1], l.scale]);
      expect(l.old, hasLength(3));
    }
    expect(sheet.lugar['junto']!.spot, 'mesa');
  });

  test('the things of the set: each box is the engine\'s box of its world box', () {
    for (final t in sheet.things.values) {
      if (t.world == null) continue;
      expect(sheet.boxOf(t.id, e), t.box, reason: t.id);
      expect(sheet.hitBoxOf(t.id, e), t.hit!.box, reason: t.id);
    }
    expect(sheet.things['abuela']!.places!['silla']!.box, hasLength(4));
  });

  test('views and pictures: the engine gives the windows the sheet records', () {
    for (final v in sheet.views.values) {
      expect(sheet.viewOf(v.name, e), v.cam, reason: v.name);
    }
    for (final p in sheet.pictures.values) {
      expect(sheet.pictureRegion(p.name, e), p.crop, reason: p.name);
    }
  });

  test('remap: a pair rectangle names its pictures and their crops; an abuela point her ab; a level x nothing', () {
    final cam = sheet.remapCam([86, 98, 68, 36.1]);
    expect(cam.to.pictures, contains('vaso.si'));
    expect(cam.crops!['vaso.si']!.crop, sheet.pictures['vaso.si']!.crop);
    expect(cam.crops!['vaso.si']!.zoom, 2);
    final ab = sheet.remapPoint(94, 147);
    expect(ab.to.spot, 'abuela.lado');
    expect(ab.ab, sheet.spots['abuela.lado']!.ab);
    final perch = sheet.remapPoint(120, 86);
    expect(perch.to.point, 'PERCH');
    expect(perch.screen, hasLength(2));
    expect(sheet.remap('x', [80]).to.level, isTrue);
    expect(sheet.remapX(120), sheet.remap('x', [120]).x);
    expect(sheet.remapPoint(84, 129).frog, sheet.spots['abuela']!.frog);
  });
}
