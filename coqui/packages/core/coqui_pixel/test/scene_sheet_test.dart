// The reader of the content lane's sheets (SceneSheet, order 50b) against the 28 real sheets of places 4 to 10
// (docs/proyecto/pixel/<id>-sheet.json, every one without the old sheets' `pairPicture`): each parses; what every new
// sheet has is typed, the rest is kept as plain data; every spot's world point projects, by the sheet's own scale and
// origin, onto the screen point the sheet writes; El mostrador's state `calle` reads as a part with its own origin; the
// old sheet a new scene hands on (`legacy`) parses. The files are read from the repository: the vm only.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

Directory _pixel() {
  for (final base in const ['../../../../docs', '../../../docs', 'docs']) {
    final d = Directory('$base/proyecto/pixel');
    if (d.existsSync()) return d;
  }
  throw StateError('docs/proyecto/pixel not found');
}

void main() {
  final dir = _pixel();
  final news = <String, String>{};
  for (final f
      in dir.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path))) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('-sheet.json')) continue;
    final text = f.readAsStringSync();
    // an old scene's sheet: Sheet reads it
    if ((jsonDecode(text) as Map).containsKey('pairPicture')) {
      continue;
    }
    news[name.substring(0, name.length - '-sheet.json'.length)] = text;
  }

  test('there are 28 new sheets (places 4 to 10)', () {
    expect(news, hasLength(28));
    expect(news.keys, containsAll(['mostrador', 'estantes', 'frutas', 'caja']));
  });

  for (final en in news.entries) {
    test('${en.key}: parses; its spots project onto their screen points', () {
      final s = SceneSheet.parse(en.value);
      expect(s.scene, en.key);
      expect(s.S, 26);
      expect([s.pictureW, s.pictureH], [240, 216]);
      expect(s.setKey.baked, isNotEmpty);
      expect(s.spots, isNotEmpty);
      expect(s.views, isNotEmpty);
      expect(s.front.bias, greaterThanOrEqualTo(0));
      expect(s.checks.every((c) => c.ok), isTrue, reason: 'its maker exits 0');
      final e = s.engine();
      for (final sp in s.spots.values) {
        if (sp.world == null || sp.screen == null) continue;
        final p = e.project(sp.world![0], sp.world![1], sp.world![2]);
        expect(
          (p.sx - sp.screen![0]).abs() <= .51 &&
              (p.sy - sp.screen![1]).abs() <= .51,
          isTrue,
          reason:
              '${en.key} ${sp.name}: ${sp.world} projects to (${p.sx}, ${p.sy}), the sheet says ${sp.screen}',
        );
      }
      expect(s.legacy().scene, en.key);
    });
  }

  test('mostrador: the typed parts, the part calle, the plain rest', () {
    final s = SceneSheet.parse(news['mostrador']!);
    expect([s.originX, s.originY], [-7, -32]);
    expect(s.setKey.params.keys, [
      'donde',
      'hora',
      'atras',
      'nevera',
      'puerta',
      'props',
    ]);
    expect(s.setKey.params['atras']!.only, 'dentro');
    expect(s.setKey.baked, hasLength(8));
    expect(s.spot('coqui.mostrador').at, (sx: 133, sy: 107));
    expect(s.spot('pepe.fuera').drawn, isFalse);
    expect(s.spot('pepe.fuera').world, isNull);
    expect(s.spot('monedas').raw['step'], .22);
    expect(s.thing('nevera').box, [157, 107, 27, 27]);
    expect(s.thing('nevera').when, 'nevera = 1');
    expect(s.thing('leche').sprite, isTrue);
    expect(s.view('dentro').cam, [21, 0, 196, 216]);
    expect(s.group('ninos_puerta').map((p) => p.name), [
      'ninos_puerta.1',
      'ninos_puerta.2',
      'ninos_puerta.3',
    ]);
    expect(s.front.bias, .3);
    expect(s.radiusOf('pepe'), .35);
    expect(s.shadows.none, ['pepe.fuera', 'fuera', 'gallo']);
    expect(s.extras.keys, containsAll(['alternatives', 'moved', 'calle']));
    expect(() => s.spot('mostrador_izq'), throwsA(isA<SheetError>()));
    final c = s.part('calle');
    expect([c.originX, c.originY], [-46, -6]);
    expect(c.setKey.baked, hasLength(4));
    expect(c.spot('abuela.acera').at, (sx: 46, sy: 138));
    expect(c.view('calle').cam, [22, 0, 196, 216]);
    expect(c.thing('colmado').box, [83, 30, 43, 98]);
    expect(c.front.bias, .3, reason: 'the depth rule is the sheet\'s');
    expect(c.extras['constants'], isA<Map>());
    expect(() => s.part('nada'), throwsA(isA<SheetError>()));
    // the things of the set: the screen box of their world box (rules.project)
    for (final t in s.things.values) {
      if (!t.set) continue;
      expect(SceneSheet.boxOfWorld(s.engine(), t.world!), t.box, reason: t.id);
    }
    final e = c.engine();
    for (final sp in c.spots.values) {
      final p = e.project(sp.world![0], sp.world![1], sp.world![2]);
      expect([p.sx.round(), p.sy.round()], sp.screen, reason: sp.name);
    }
  });
}
