// The sheet reader against El frente's real sheet (docs/proyecto/pixel/frente-sheet.json, order 07). On the vm the file
// itself is read, in a browser the fixture made from it (tool/make_sheet_fixture.dart). Every part parses; what the
// engine gives (a box, a screen position, a view, a crop) is compared with the numbers the sheet records.
//
// The sheet's own numbers are rounded: its boxes are exact integers (the world boxes it stores are rounded to four
// decimals and its boxes were made from the unrounded ones; every one of them came out the same), its screen positions
// are rounded to hundredths. So a screen position is compared within [hundredth] = .0051: half a hundredth and the
// little the four-decimal world adds (the worst of 49 was .0049). Everything else is exact.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/sheet_text.dart';

const hundredth = .0051;

Matcher near(num v) => closeTo(v, hundredth);

void main() {
  final text = frenteSheetText();
  final sheet = Sheet.parse(text);
  final e = PpEngine(
    w: sheet.pictureW,
    h: sheet.pictureH,
    s: sheet.S,
    originX: sheet.originX,
    originY: sheet.originY,
  );

  group('what the sheet says of itself', () {
    test('El frente: S 26, origin (-2, 12), a 240 x 216 picture', () {
      expect(sheet.scene, 'frente');
      expect(sheet.S, 26);
      expect([sheet.originX, sheet.originY], [-2, 12]);
      expect([sheet.pictureW, sheet.pictureH], [240, 216]);
      expect([sheet.viewW, sheet.viewH], [196, 216]);
      expect([sheet.pairW, sheet.pairH], [196, 104]);
      expect(
        sheet.rules.keys,
        containsAll([
          'project',
          'frog',
          'abuela',
          'bird',
          'frame',
          'sky',
          'view',
          'viewChange',
          'pair',
        ]),
      );
      expect(sheet.rules['viewChange'], contains('cuts'));
    });

    test('every part is there, in the numbers the sheet has', () {
      expect(sheet.things, hasLength(14));
      expect(sheet.spots, hasLength(15));
      expect(sheet.lugar, hasLength(7));
      expect(sheet.frames, hasLength(9));
      expect(sheet.points, hasLength(35));
      expect(sheet.views, hasLength(6));
      expect(sheet.remapTable, hasLength(18));
      expect(sheet.pictures, hasLength(24));
      expect(sheet.level, hasLength(9));
      expect(sheet.clips, hasLength(2));
      expect(sheet.code, hasLength(186));
      expect(sheet.dropped, hasLength(6));
      expect(sheet.setKey.params, hasLength(7));
      expect(sheet.setKey.baked, hasLength(25));
      expect(sheet.shadows.keys, ['coqui', 'abuela']);
      expect(sheet.front, isEmpty);
      expect(sheet.unknown, isEmpty);
    });
  });

  group('things', () {
    test('the 14 touch keys', () {
      expect(sheet.things.keys.toSet(), {
        'abuela',
        'palma_pequena',
        'casa_pequena',
        'palma_grande',
        'casa_grande',
        'pajaro',
        'bizcocho',
        'coqui',
        'nube',
        'puerta',
        'ventana',
        'casa',
        'sol',
        'palma',
      });
      final sets = [
        for (final t in sheet.things.values)
          if (t.set) t.id,
      ];
      expect(sets, [
        'palma_pequena',
        'casa_pequena',
        'palma_grande',
        'casa_grande',
        'puerta',
        'ventana',
        'casa',
        'sol',
        'palma',
      ]);
      final sprites = [
        for (final t in sheet.things.values)
          if (t.sprite) t.id,
      ];
      expect(sprites, ['abuela', 'pajaro', 'coqui', 'nube']);
      expect(sheet.things['bizcocho']!.hud, isTrue);
      expect(sheet.things['nube']!.sky, isTrue);
      expect(sheet.things['sol']!.sky, isTrue);
      expect(sheet.things['sol']!.screen!.circle, [215, 17, 12]);
      for (final t in sheet.things.values) {
        expect(t.set || t.sprite || t.hud, isTrue, reason: t.id);
        // a thing in the set has a world box, or (the sun) a shape in the sky
        if (t.set) {
          expect(t.world != null || t.screen != null, isTrue, reason: t.id);
        }
        if (t.world != null) {
          expect(t.world, hasLength(6));
          expect(t.hit!.world, hasLength(6));
        }
      }
    });

    test('abuela has a box at each of her places', () {
      final a = sheet.things['abuela']!;
      expect(a.box, isNull);
      expect(a.places!.keys, ['puerta', 'paso', 'ventana']);
      expect(a.places!['puerta']!.frame, 'abuela.puerta');
      expect(a.places!['puerta']!.old, [151, 56, 29, 49]);
      expect(a.places!['puerta']!.box, [129, 83, 29, 49]);
      expect(a.places!['ventana']!.clip, 'ventana.hueco');
      expect(a.places!['ventana']!.box, isNull);
    });

    for (final t in sheet.things.values.where((t) => t.world != null)) {
      test(
        '${t.id}: the box and the hit box are the screen box of the 8 corners, as the sheet records them',
        () {
          expect(sheet.boxOf(t.id, e), t.box, reason: 'box');
          expect(sheet.hitBoxOf(t.id, e), t.hit!.box, reason: 'hit');
          expect(sheet.worldOf(t.id), t.world);
        },
      );
    }

    test(
      'the sun\'s box is the sky\'s; a sprite and the hud have none in the set',
      () {
        expect(sheet.boxOf('sol', e), [203, 5, 25, 25]);
        for (final k in ['abuela', 'pajaro', 'coqui', 'nube', 'bizcocho']) {
          expect(
            () => sheet.boxOf(k, e),
            throwsA(isA<SheetError>()),
            reason: k,
          );
        }
        expect(() => sheet.boxOf('nada', e), throwsA(isA<SheetError>()));
      },
    );

    test('boxOfWorld is the sheet\'s rule: floor of the least, ceil of the greatest', () {
      expect(Sheet.boxOfWorld(e, [0, 0, 0, 1, 1, 1]), isNot(isEmpty));
      final b = Sheet.boxOfWorld(e, [0, 0, 0, 1, 1, 1]);
      final xs = <double>[], ys = <double>[];
      for (final x in [0, 1]) {
        for (final y in [0, 1]) {
          for (final z in [0, 1]) {
            final p = e.project(x, y, z);
            xs.add(p.sx);
            ys.add(p.sy);
          }
        }
      }
      xs.sort();
      ys.sort();
      expect(b, [
        xs.first.floor(),
        ys.first.floor(),
        xs.last.ceil() - xs.first.floor(),
        ys.last.ceil() - ys.first.floor(),
      ]);
    });
  });

  group('spots, lugar, frames and points', () {
    test('a spot is a world point; the frog\'s has a scale and a box place, abuela\'s a sprite place', () {
      final frog = sheet.spots.values.where((s) => s.scale != null);
      final abuela = sheet.spots.values.where((s) => s.abuela != null);
      expect(frog, hasLength(13));
      expect(abuela.map((s) => s.name), ['abuela.puerta', 'abuela.paso']);
      for (final s in sheet.spots.values) {
        expect(s.world, hasLength(3));
        expect((s.scale != null) != (s.abuela != null), isTrue, reason: s.name);
      }
      expect(sheet.spots['patio']!.scale, .86);
      expect(sheet.spots['patio']!.frog, [103, 145]);
      expect(sheet.spots['patio']!.old, [123, 150]);
    });

    test('every spot and point: the engine\'s projection of its world point is the sheet\'s screen position (to the hundredth)', () {
      for (final a in [...sheet.spots.values, ...sheet.points.values]) {
        if (a.name == 'cq.asoma') continue;
        final p = sheet.screenOf(a.name, e);
        expect(p.x, near(a.screen[0]), reason: '${a.name} x');
        expect(p.y, near(a.screen[1]), reason: '${a.name} y');
      }
    });

    test('cq.asoma is the one point whose screen is a sprite\'s top left, 10 and 15 pixels from its world point', () {
      final a = sheet.points['cq.asoma']!, p = sheet.screenOf('cq.asoma', e);
      expect(p.x - a.screen[0], closeTo(10, .01));
      expect(p.y - a.screen[1], closeTo(15, .01));
    });

    test(
      'the frog\'s box and abuela\'s sprite stand where the sheet puts them',
      () {
        for (final s in sheet.spots.values) {
          if (s.scale != null) {
            final f = sheet.frogAt(s.name, e);
            expect([f.x, f.y], s.frog, reason: s.name);
            expect(f.scale, s.scale);
          } else {
            final a = sheet.abuelaAt(s.name, e);
            expect([a.x, a.y], s.abuela, reason: s.name);
          }
        }
        expect(
          () => sheet.frogAt('abuela.puerta', e),
          throwsA(isA<SheetError>()),
        );
        expect(() => sheet.abuelaAt('patio', e), throwsA(isA<SheetError>()));
        expect(() => sheet.frogAt('nada', e), throwsA(isA<SheetError>()));
      },
    );

    test('lugar: [x, y, scale] for the frog\'s box, the old LUGAR names', () {
      expect(sheet.lugar.keys, [
        'puerta',
        'ventana',
        'patio',
        'casa_grande',
        'palma_grande',
        'palma_pequena',
        'casa_pequena',
      ]);
      for (final l in sheet.lugar.values) {
        expect(sheet.lugarOf(l.name, e), [
          l.frog[0],
          l.frog[1],
          l.scale,
        ], reason: l.name);
        expect(sheet.spots.containsKey(l.spot), isTrue);
      }
      expect(sheet.lugar['casa_grande']!.spot, 'puerta');
    });

    test('frames: the offset is the whole pixels from the old point to the new one, and every point made through one agrees', () {
      for (final f in sheet.frames.values) {
        final p = sheet.frameScreen(f.name, e);
        expect(p.x, near(f.screen[0]), reason: '${f.name} x');
        expect(p.y, near(f.screen[1]), reason: '${f.name} y');
        expect(f.offset, [
          (f.screen[0] - f.old[0]).round() + (f.nudge?[0] ?? 0),
          (f.screen[1] - f.old[1]).round() + (f.nudge?[1] ?? 0),
        ], reason: f.name);
        expect((f.world == null) != (f.spot == null), isTrue, reason: f.name);
      }
      for (final a in sheet.points.values.where((p) => p.frame != null)) {
        final f = sheet.frames[a.frame]!;
        final n = a.nudge ?? const [0, 0];
        expect(a.screen[0], a.old[0] + f.offset[0] + n[0], reason: a.name);
        expect(a.screen[1], a.old[1] + f.offset[1] + n[1], reason: a.name);
      }
    });

    test('the points: 19 placed in the world, 16 through a frame', () {
      expect(sheet.points.values.where((p) => p.frame == null), hasLength(19));
      expect(sheet.points.values.where((p) => p.frame != null), hasLength(16));
      expect(() => sheet.screenOf('nada', e), throwsA(isA<SheetError>()));
    });
  });

  group('views and pictures', () {
    test('each view: viewAt of the projection of its centre is the sheet\'s x0 or region', () {
      for (final v in sheet.views.values) {
        expect(sheet.viewOf(v.name, e), v.cam, reason: v.name);
        // and from the sheet's own rounded centre
        expect(
          viewAt(v.screen[0], v.screen[1], v.zoom),
          v.cam,
          reason: '${v.name} from its recorded centre',
        );
        expect(zoomOf(v.cam), v.zoom);
      }
      expect(sheet.views['wide']!.cam, [29, 0, 196, 216]);
      expect(sheet.views['puerta']!.cam, [91, 40, 98, 108]);
      expect(sheet.views['puerta']!.zoom, 2);
      expect(sheet.views['wide@donde-esta-el-pajaro']!.cam, [8, 0, 196, 216]);
    });

    test('each picture: the crop is reviewRegion at its centre and zoom; 24 of them', () {
      for (final p in sheet.pictures.values) {
        expect(sheet.pictureRegion(p.name, e), p.crop, reason: p.name);
        expect(p.crop[2], 196 ~/ p.zoom);
        expect(p.crop[3], 104 ~/ p.zoom);
      }
      expect(sheet.pictures['casa.no']!.crop, [70, 163, 98, 52]);
    });

    test('each level picture is a picture of the pairs, with the same crop and zoom; 9 of them', () {
      for (final l in sheet.level) {
        final p = sheet.pictures[l.picture]!;
        expect(l.crop, p.crop, reason: '${l.word}[${l.index}]');
        expect(l.zoom, p.zoom);
        expect(sheet.pictureRegion(l.picture, e), l.crop);
      }
      expect(sheet.level.first.word, 'abuela');
    });

    test('pictureCrop cuts the picture: 196 x 104, a 1 x 1 or 2 x 2 copy of the region', () {
      final pic = Uint32List.fromList([
        for (var i = 0; i < 240 * 216; i++) i + 1,
      ]);
      for (final name in ['casa.si', 'casa.no']) {
        final s = sheet.pictureCrop(name, e, pic),
            r = sheet.pictures[name]!.crop;
        final z = sheet.pictures[name]!.zoom;
        expect([s.w, s.h], [196, 104]);
        for (final j in [0, 51, 103]) {
          for (final i in [0, 1, 97, 195]) {
            expect(
              s.px[j * 196 + i],
              pic[(r[1] + j ~/ z) * 240 + r[0] + i ~/ z],
              reason: '$name $i,$j',
            );
          }
        }
      }
    });
  });

  group('clips', () {
    test('two world polygons of four points: the window\'s opening and the door\'s gap', () {
      expect(sheet.clips.keys, ['ventana.hueco', 'puerta.hueco']);
      final c = sheet.clips['ventana.hueco']!;
      expect([c.thing, c.face], ['ventana', 'opening']);
      expect(c.world, hasLength(4));
      expect(c.world.first, [-1.71, 0, 1.15]);
      expect(sheet.clips['puerta.hueco']!.face, 'gap');
    });

    test('each polygon is the projection of its world points; its box is the sheet\'s', () {
      for (final c in sheet.clips.values) {
        final p = sheet.clipPolygon(c.name, e);
        for (var i = 0; i < 4; i++) {
          expect(p[i].sx, near(c.screen[i][0]), reason: '${c.name} $i x');
          expect(p[i].sy, near(c.screen[i][1]), reason: '${c.name} $i y');
        }
        expect(Sheet.boxOfPoints(p), c.box, reason: c.name);
      }
    });

    for (final c in [for (final c in sheet.clips.values) c]) {
      test(
        '${c.name}: clipToWorld shows what is drawn inside the polygon and nothing outside',
        () {
          final px = Uint32List(240 * 216);
          final g = Ctx(px, 240, 216);
          g.save();
          clipToWorld(g, e, c.world);
          g.fillStyle = 0xFFFFFFFF;
          g.fillRect(0, 0, 240, 216);
          g.restore();
          final poly = sheet.clipPolygon(c.name, e);
          var area = 0.0;
          for (var i = 0; i < poly.length; i++) {
            final a = poly[i], b = poly[(i + 1) % poly.length];
            area += a.sx * b.sy - b.sx * a.sy;
          }
          area = area.abs() / 2;
          // the edge pixels are partly covered: the alphas add up to the polygon's area
          final painted = px.fold<int>(0, (a, v) => a + (v >>> 24)) / 255;
          expect(painted, closeTo(area, area * .03));
          // the middle is in, a corner of the picture is out, and all of it is inside the box
          final cx = poly.map((p) => p.sx).reduce((a, b) => a + b) / 4;
          final cy = poly.map((p) => p.sy).reduce((a, b) => a + b) / 4;
          expect(px[cy.floor() * 240 + cx.floor()], 0xFFFFFFFF);
          expect(px[0], 0);
          for (var i = 0; i < px.length; i++) {
            if (px[i] == 0) continue;
            final x = i % 240, y = i ~/ 240;
            expect(x, inInclusiveRange(c.box[0], c.box[0] + c.box[2]));
            expect(y, inInclusiveRange(c.box[1], c.box[1] + c.box[3]));
          }
        },
      );
    }

    test('clipTo for a face is clipToWorld of the face\'s four points', () {
      final t = Thing(id: 'ventana', world: [-2.26, 0, .7, .54, .32, 2.52]);
      for (final face in ['x', 'y']) {
        final a = Uint32List(240 * 216), b = Uint32List(240 * 216);
        for (final (px, draw) in [
          (a, (Ctx g) => clipTo(g, e, t, face)),
          (b, (Ctx g) => clipToWorld(g, e, facePoints(t.world!, face))),
        ]) {
          final g = Ctx(px, 240, 216);
          draw(g);
          g.fillStyle = 0xFFFFFFFF;
          g.fillRect(0, 0, 240, 216);
        }
        expect(a, b, reason: face);
        expect(a.where((v) => v != 0), isNotEmpty);
      }
    });
  });

  group('remap', () {
    test('18 positions: 9 view rectangles, 3 level crops, 3 points, 3 x', () {
      final kinds = <String, int>{};
      for (final r in sheet.remapTable) {
        kinds[r.kind] = (kinds[r.kind] ?? 0) + 1;
      }
      expect(kinds, {'cam': 9, 'crop': 3, 'x': 3, 'point': 3});
    });

    test('every entry of the table is found by its kind and old numbers, and says where', () {
      for (final r in sheet.remapTable) {
        expect(
          identical(sheet.remap(r.kind, r.old), r),
          isTrue,
          reason: '${r.kind} ${r.old}',
        );
        expect(r.uses, isNotEmpty);
        final t = r.to;
        expect(
          [t.point, t.view, t.spot, t.none].where((v) => v != null),
          hasLength(1),
          reason: '${r.old}',
        );
        switch (r.kind) {
          case 'point':
            expect(identical(sheet.remapPoint(r.old[0], r.old[1]), r), isTrue);
            if (t.spot != null) {
              final s = sheet.spots[t.spot]!;
              expect(r.screen, s.screen);
              expect(r.frog, s.frog);
              expect(r.scale, s.scale);
            }
          case 'cam':
            expect(identical(sheet.remapCam(r.old), r), isTrue);
          case 'crop':
            expect(identical(sheet.remapCrop(r.old), r), isTrue);
            expect(r.crop, isNotNull);
          case 'x':
            expect(sheet.remapX(r.old[0]), r.x);
        }
        if (t.view != null) expect(r.x0, sheet.views[t.view]!.x0);
      }
    });

    test('a position that is a point of the old scene is a crop at zoom 1 or an x, from its world point', () {
      for (final r in sheet.remapTable) {
        final w = r.to.world;
        if (w == null) continue;
        final p = e.project(w[0], w[1], w[2]);
        expect(p.sx, near(r.screen![0]), reason: '${r.old}');
        expect(p.sy, near(r.screen![1]), reason: '${r.old}');
        if (r.kind == 'cam' || r.kind == 'crop') {
          final c = reviewRegion(p.sx, p.sy, 1);
          expect([c.x, c.y, c.w, c.h], r.crop, reason: '${r.kind} ${r.old}');
        } else if (r.kind == 'x') {
          expect((p.sx + 0.5).floor(), r.x, reason: '${r.old}');
        }
      }
    });

    test('the places the stories write', () {
      final hola = sheet.remapPoint(146, 86);
      expect(hola.to.spot, 'hola');
      expect(hola.frog, [108, 109]);
      expect(hola.scale, .62);
      expect(sheet.remapPoint(176, 116).to.spot, 'adios');
      expect(sheet.remapPoint(0, 0).to.none, contains('avePos'));
      expect(
        sheet.remapCam([30, 0, 196, 216]).to.view,
        'wide@donde-esta-el-pajaro',
      );
      expect(sheet.remapCam([30, 0, 196, 216]).x0, 8);
      expect(sheet.remapCam([135, 46, 94, 50]).crop, [44, 49, 196, 104]);
      expect(sheet.remapCrop([89.36, 46, 45.28, 50]).crop, [4, 20, 196, 104]);
      expect(sheet.remapX(160), 134);
    });

    test(
      'a position the table does not have stops with an error that names it',
      () {
        for (final bad in <(String, List<num>)>[
          ('point', [1, 2]),
          ('point', [146, 87]),
          ('cam', [1, 2, 3, 4]),
          ('crop', [89.36, 46, 45.28, 51]),
          ('x', [111]),
          ('point', [146]),
          ('nope', [146, 86]),
        ]) {
          expect(
            () => sheet.remap(bad.$1, bad.$2),
            throwsA(
              isA<SheetError>().having(
                (x) => x.message,
                'message',
                allOf(
                  contains(bad.$1),
                  contains('${bad.$2}'),
                  contains('frente'),
                ),
              ),
            ),
            reason: '$bad',
          );
        }
        expect(() => sheet.remapPoint(3, 4), throwsA(isA<SheetError>()));
        expect(() => sheet.remapCam([0, 0, 0, 0]), throwsA(isA<SheetError>()));
        expect(() => sheet.remapCrop([0, 0, 0, 0]), throwsA(isA<SheetError>()));
        expect(() => sheet.remapX(1), throwsA(isA<SheetError>()));
      },
    );
  });

  group('the set\'s key, the shadows, the old code', () {
    test('setKey: the parameters, their values and how W gives them; 25 baked states', () {
      final k = sheet.setKey;
      expect(k.params.keys, [
        'door',
        'win',
        'lights',
        'sky',
        'hide',
        'rustle',
        'side',
      ]);
      expect(k.params['door']!.values, ['shut', 'half', 'open']);
      expect(k.params['win']!.values, ['shut', 'open']);
      expect(k.params['sky']!.values, [
        'day',
        'storm',
        'storm2',
        'rain',
        'dusk',
        'sunset',
      ]);
      expect(k.params['rustle']!.values, ['none', 'palma', 'casa', 'todo']);
      expect(k.params['side']!.values, ['-1', '1']);
      expect(k.params['door']!.fromW, contains('W.door'));
      expect(k.params['sky']!.fromW, contains('W.dusk'));
      for (final p in k.params.values) {
        expect(p.values, isNotEmpty);
        expect(p.fromW, isNotEmpty);
      }
      expect(k.key, contains('door + win + lights + sky + hide + rustle'));
      expect(k.baked, hasLength(25));
      expect(
        k.baked.first.ref,
        'coqui/ref/pp/frente/door-half-win-shut-lights-0-sky-day',
      );
      expect(
        k.baked.first.query,
        '?door=half&win=shut&lights=0&sky=day&hide=0&rustle=none&side=1',
      );
      expect(k.baked.map((b) => b.ref).toSet(), hasLength(25));
      expect(k.bakedWhy, isNotNull);
      expect(k.notRead, contains('W.abierto'));
    });

    test('every baked state names a value of each parameter it sets', () {
      for (final b in sheet.setKey.baked) {
        final q = Uri.parse('x${b.query}').queryParameters;
        for (final e in q.entries) {
          final p = sheet.setKey.params[e.key];
          expect(p, isNotNull, reason: '${b.ref}: ${e.key}');
          expect(
            p!.values,
            contains(e.value),
            reason: '${b.ref}: ${e.key}=${e.value}',
          );
        }
      }
    });

    test('shadows: who casts, the radius as a number, the rest in the sheet\'s words', () {
      expect(sheet.shadows['coqui']!.radius, .45);
      expect(sheet.shadows['abuela']!.radius, .35);
      expect(sheet.shadows['coqui']!.cast, 'castShadow(x, y, .3, .45)');
      expect(sheet.shadows['abuela']!.cast, contains('z <= 2'));
      expect(sheet.shadows['abuela']!.when, contains('W.ab'));
      expect(sheet.shadowsNote, contains('juego.js frog()'));
      expect(sheet.frontWhy, contains('nothing in the set covers a character'));
    });

    test('code: every old line with what replaces it, as the sheet has it', () {
      expect(sheet.code, hasLength(186));
      final strings = sheet.code.where((c) => c.to is String).toList();
      final maps = sheet.code
          .where((c) => c.to is Map<String, dynamic>)
          .toList();
      expect(strings.length + maps.length, 186);
      expect(strings, hasLength(62));
      expect(strings.first.to, 'sky: unchanged');
      expect(strings.first.line, 48);
      final fresh = sheet.code.firstWhere((c) => c.line == 'juego.js:16');
      expect((fresh.to as Map)['spot'], 'inicio');
      expect(fresh.note, contains('default frog'));
      expect(sheet.code.where((c) => c.line is String), hasLength(2));
      for (final c in sheet.code) {
        expect(c.old, isNotEmpty);
        expect(c.raw['line'], c.line);
      }
      // the names it uses are names of the sheet
      for (final c in sheet.code) {
        final to = c.to;
        if (to is! Map<String, dynamic>) continue;
        for (final (key, table) in <(String, Map<String, Object?>)>[
          ('spot', sheet.spots),
          ('point', sheet.points),
          ('clip', sheet.clips),
          ('thing', sheet.things),
          ('view', sheet.views),
          ('frame', sheet.frames),
        ]) {
          if (to[key] != null) {
            expect(
              table.containsKey(to[key]),
              isTrue,
              reason: '${c.line} ${c.old}: $key ${to[key]}',
            );
          }
        }
      }
    });

    test('the numbers a code entry gives agree with the part it names', () {
      for (final c in sheet.code) {
        final to = c.to;
        if (to is! Map<String, dynamic>) continue;
        if (to['thing'] != null && to['box'] != null && to['clip'] == null) {
          expect(
            to['box'],
            sheet.things[to['thing']]!.box,
            reason: '${c.line} ${c.old}',
          );
        }
        if (to['thing'] != null && to['hit'] != null) {
          expect(
            to['hit'],
            sheet.things[to['thing']]!.hit!.box,
            reason: '${c.line} ${c.old}',
          );
        }
        if (to['view'] != null) {
          final v = sheet.views[to['view']]!;
          expect(to['x0'], v.x0);
          expect(to['zoom'], v.zoom);
        }
        if (to['point'] != null && to['new'] != null) {
          final p = sheet.points[to['point']]!;
          // the sheet's `new` is the point's screen, or the screen rounded
          final nw = (to['new'] as List).cast<num>();
          expect(nw[0], closeTo(p.screen[0], .5), reason: '${c.line} ${c.old}');
          expect(nw[1], closeTo(p.screen[1], .5), reason: '${c.line} ${c.old}');
        }
        if (to['frame'] != null) {
          expect(
            to['offset'],
            sheet.frames[to['frame']]!.offset,
            reason: '${c.line} ${c.old}',
          );
        }
      }
    });
  });

  group('a sheet that is not quite this one', () {
    Map<String, dynamic> doc() => jsonDecode(text) as Map<String, dynamic>;
    String json(Map<String, dynamic> m) => jsonEncode(m);

    test(
      'fields it does not know are kept and ignored, at the top and in a part',
      () {
        final m = doc()
          ..['future'] = {'a': 1}
          ..['bigNote'] = 'x';
        (m['things'] as Map<String, dynamic>)['puerta'] = {
          ...(m['things'] as Map<String, dynamic>)['puerta']
              as Map<String, dynamic>,
          'extra': [1, 2],
        };
        (m['spots'] as Map<String, dynamic>)['patio'] = {
          ...(m['spots'] as Map<String, dynamic>)['patio']
              as Map<String, dynamic>,
          'mood': 'sunny',
        };
        final s = Sheet.parse(json(m));
        expect(s.unknown.keys, ['future', 'bigNote']);
        expect(s.unknown['future'], {'a': 1});
        expect(s.things['puerta']!.raw['extra'], [1, 2]);
        expect(s.spots['patio']!.raw['mood'], 'sunny');
        expect(s.raw['bigNote'], 'x');
        // and what it knows still reads
        expect(s.boxOf('puerta', e), sheet.boxOf('puerta', e));
        expect(s.spots['patio']!.scale, .86);
      },
    );

    test('what is missing or wrong stops with a path', () {
      void bad(void Function(Map<String, dynamic> m) edit, String path) {
        final m = doc();
        edit(m);
        expect(
          () => Sheet.parse(json(m)),
          throwsA(
            isA<SheetError>().having(
              (x) => x.message,
              'message',
              contains(path),
            ),
          ),
          reason: path,
        );
      }

      bad((m) => m.remove('origin'), r'$.origin');
      bad((m) => (m['origin'] as Map).remove('originY'), r'$.origin.originY');
      bad((m) => m['S'] = 'big', r'$.S');
      bad((m) => m['picture'] = [240], r'$.picture');
      bad(
        (m) => (m['views'] as Map<String, dynamic>)['wide']['zoom'] = 3,
        r'$.views.wide.zoom',
      );
      bad(
        (m) => ((m['views'] as Map<String, dynamic>)['puerta'] as Map).remove(
          'region',
        ),
        r'$.views.puerta',
      );
      bad(
        (m) => ((m['spots'] as Map<String, dynamic>)['patio'] as Map)['world'] =
            [1, 2],
        r'$.spots.patio.world',
      );
      bad(
        (m) => ((m['lugar'] as Map<String, dynamic>)['patio'] as Map)['spot'] =
            'nada',
        'lugar "patio"',
      );
      bad(
        (m) => ((m['remap'] as List)[0] as Map)['kind'] = 'edge',
        r'$.remap[0].kind',
      );
      bad(
        (m) => ((m['remap'] as List)[0] as Map)['old'] = [1, 2],
        r'$.remap[0].old',
      );
      bad(
        (m) =>
            ((m['things'] as Map<String, dynamic>)['sol'] as Map)['screen'] = 5,
        r'$.things.sol.screen',
      );
      bad(
        (m) =>
            ((m['clips'] as Map<String, dynamic>)['ventana.hueco']
                    as Map)['thing'] =
                'nada',
        'clip "ventana.hueco"',
      );
      bad(
        (m) => ((m['level'] as List)[0] as Map)['picture'] = 'nada.nada',
        'level abuela[0]',
      );
      bad((m) => (m['code'] as List)[0] = 5, r'$.code[0]');
      bad(
        (m) => ((m['code'] as List)[0] as Map)['line'] = null,
        r'$.code[0].line',
      );
    });

    test('text that is not JSON, or not a sheet, is an error too', () {
      expect(() => Sheet.parse('{'), throwsA(isA<SheetError>()));
      expect(() => Sheet.parse('[]'), throwsA(isA<SheetError>()));
      expect(() => Sheet.parse('{}'), throwsA(isA<SheetError>()));
    });
  });
}
