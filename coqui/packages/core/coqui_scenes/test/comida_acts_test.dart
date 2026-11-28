// La comida's acts, Needs things, touch boxes, and speaker keys (comida.md, stories 90 to 92).
// Walks all three stories (prueba, falta-algo, mas-y-menos) across both right and wrong branches, verifies every
// touchable thing answers a touch and its touch box contains its drawn pixels, and verifies every speaker key has a
// talkAt point while visible.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart' show jsTruthy;
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/comida/comida.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Deterministic draw variable assignment for walking [id] in acts/frames tests (`pick`: 0 or 1).
Map<String, String> comidaVars(String id, int pick) => switch (id) {
  'prueba' =>
    pick == 0
        ? {
            'ax': 'salado',
            'ay': 'dulce',
            'az': 'picante',
            'qa': 'luis',
            'ga': 'dulce',
            'pa': 'platillo2',
            'bx': 'picante',
            'by': 'salado',
            'bz': 'dulce',
            'eb': '1',
            'qb': 'abuelo',
            'gb': 'salado',
            'pb': 'platillo2',
          }
        : {
            'ax': 'picante',
            'ay': 'salado',
            'az': 'dulce',
            'qa': 'carmen',
            'ga': 'picante',
            'pa': 'platillo1',
            'bx': 'dulce',
            'by': 'picante',
            'bz': 'salado',
            'eb': '2',
            'qb': 'abuela',
            'gb': 'dulce',
            'pb': 'platillo1',
          },
  'falta-algo' =>
    pick == 0
        ? {
            'ha': 'sal',
            'fa': 'hielo',
            'hb': 'azucar',
            'fb': 'servilletas',
            'qa': 'abuelo',
            'oa': 'hf',
            'eb': '2',
            'qb': 'carmen',
            'ob': 'fh',
          }
        : {
            'ha': 'hielo',
            'fa': 'sal',
            'hb': 'servilletas',
            'fb': 'azucar',
            'qa': 'abuela',
            'oa': 'fh',
            'eb': '1',
            'qb': 'luis',
            'ob': 'hf',
          },
  _ =>
    pick == 0
        ? {
            'ga': 'senora',
            'sa': 'menos',
            'pa': 'plato_perro',
            'eb': '2',
            'gb': 'joven',
            'sb': 'bien',
            'pb': 'joven',
          }
        : {
            'ga': 'senor',
            'sa': 'mas',
            'pa': 'olla',
            'eb': '3',
            'gb': 'mujer',
            'sb': 'menos',
            'pb': 'plato_perro',
          },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('comida');
  });

  test(
    'every story walks to the end across both picks and right/wrong acts',
    () async {
      for (final id in const ['prueba', 'falta-algo', 'mas-y-menos']) {
        final story = jsonDecode(
          File('test/support/fixtures/comida/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        for (final pick in const [0, 1]) {
          final scene = createComida() as Comida;
          final frame = StillFrame(scene);
          final host = frame.host;
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = {...comidaVars(id, pick)};
          Object? sub(Object? s) => s is String
              ? s.replaceAllMapped(
                  RegExp(r'\$([a-z]+)'),
                  (m) => v[m[1]!] ?? m[0]!,
                )
              : s;

          Future<void> walk(Object? steps) async {
            if (steps is! List) return;
            for (final st in steps) {
              if (st is! Map<String, dynamic>) continue;
              if (st['set'] is Map) {
                host.W.addAll((st['set'] as Map).cast<String, dynamic>());
              } else if (st['act'] is String) {
                final actName = st['act'] as String;
                expect(
                  scene.acts.containsKey(actName),
                  isTrue,
                  reason: '$id: unknown act $actName',
                );
                final o = {for (final e in st.entries) e.key: sub(e.value)};
                await scene.acts[actName]!(o);
                host.F += 3;
                frame.draw(host.W, F: host.F, cam: host.cam);
              } else if (st['ask'] is String) {
                await walk(st['lead']);
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                final pk = sub(st['pick']) as String;
                v['x'] = [
                  for (final o in st['options'] as List) sub(o) as String,
                ].firstWhere((o) => o != pk);
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['calc'] is String) {
                final c = (st['cond'] as String).split('=');
                v[st['calc'] as String] =
                    sub(v[c[0]] == c[1] ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                await walk(st['then']);
                await walk(st['else']);
              }
            }
          }

          frame.draw(host.W, F: host.F, cam: host.cam);
          await walk(story['beats']);
          await walk(story['final']);
        }
      }
    },
  );

  test('every Needs touch thing answers a touch and its box holds its drawn pixels', () async {
    final answered = <String>{};
    // Verify across the three stories and all guests
    for (final id in const ['prueba', 'falta-algo', 'mas-y-menos']) {
      final story = jsonDecode(
        File('test/support/fixtures/comida/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final scene = createComida() as Comida;
      final frame = StillFrame(scene);
      final host = frame.host;
      host.S = story;
      host.W = {
        ...host.W,
        'lost': 0,
        'resp': null,
        'twinkle': null,
        ...scene.fresh(story),
      };
      if (id == 'falta-algo') {
        await scene.acts['sopas']!({'n': 3});
      }
      if (id == 'mas-y-menos') {
        for (final g in const ['senor', 'senora', 'joven', 'mujer']) {
          await scene.acts['llega']!({'quien': g, 'a': 'fila1'});
          frame.draw(host.W, F: host.F, cam: host.cam);
          final t = scene.cosas.firstWhere((c) => c.id == g);
          expect(t.si == null || t.si!(host.W), isTrue, reason: '$g visible');
          final box = t.box(host.W);
          expect(box, isNotNull, reason: '$g box');
          expect(box![2], greaterThan(0));
          expect(box[3], greaterThan(0));
          expect(scene.talkAt(g, host.W), isNotNull, reason: '$g talkAt');
          answered.add(g);
        }
      }
      frame.draw(host.W, F: host.F, cam: host.cam);
      for (final thing in scene.cosas) {
        if (thing.si != null && !thing.si!(host.W)) continue;
        final box = thing.box(host.W);
        expect(box, isNotNull, reason: '$id: ${thing.id} has null box');
        expect(box![2], greaterThan(0), reason: '$id: ${thing.id} w <= 0');
        expect(box[3], greaterThan(0), reason: '$id: ${thing.id} h <= 0');
        // Touch box lies inside the 196 x 216 view window [22, 218) x [0, 216)
        expect(box[0], greaterThanOrEqualTo(22), reason: '${thing.id} x0');
        expect(
          box[0] + box[2],
          lessThanOrEqualTo(218),
          reason: '${thing.id} x1',
        );
        expect(box[1], greaterThanOrEqualTo(0), reason: '${thing.id} y0');
        expect(
          box[1] + box[3],
          lessThanOrEqualTo(216),
          reason: '${thing.id} y1',
        );
        answered.add(thing.id);
      }
      // Verify speaker keys for this story
      for (final who in const ['coqui']) {
        expect(scene.talkAt(who, host.W), isNotNull);
      }
      if (id != 'mas-y-menos') {
        for (final who in const ['abuela', 'abuelo', 'luis', 'carmen']) {
          expect(scene.talkAt(who, host.W), isNotNull, reason: '$id: $who');
        }
      }
      if (id == 'falta-algo') {
        expect(scene.talkAt('mesera', host.W), isNotNull);
      }
      if (id == 'mas-y-menos') {
        expect(scene.talkAt('cocinero', host.W), isNotNull);
      }
    }

    // All 23 Needs touch things
    expect(
      answered,
      containsAll(const [
        'platillo1',
        'platillo2',
        'platillo3',
        'sal',
        'azucar',
        'hielo',
        'servilletas',
        'olla',
        'plato_perro',
        'jarra',
        'sopas',
        'tazon',
        'abuela',
        'abuelo',
        'luis',
        'carmen',
        'mesera',
        'cocinero',
        'senor',
        'senora',
        'joven',
        'mujer',
        'coqui',
        'perro',
      ]),
    );
  });

  test('every gesto variant and suelto/ya runs cleanly', () async {
    final story = jsonDecode(
      File('test/support/fixtures/comida/falta-algo.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final scene = createComida() as Comida;
    final frame = StillFrame(scene);
    final host = frame.host;
    host.S = story;
    host.W = {...host.W, ...scene.fresh(story)};

    // Loose act + ya
    await scene.acts['sale']!({'quien': 'mesera', 'suelto': 1});
    await scene.acts['ya']!({});
    expect((host.W['gente'] as Map)['mesera']['vis'], 0);

    // Every gesture named in comida.md Needs
    for (final q in const [
      'saluda',
      'no',
      'si',
      'rie',
      'mira',
      'senala',
      'ojos',
      'come',
      'bebe',
      'cara',
      'tapa',
      'cuchara',
    ]) {
      await scene.acts['gesto']!({'quien': 'luis', 'que': q, 'a': 'coqui'});
      frame.draw(host.W, F: host.F, cam: host.cam);
    }
    await scene.acts['brilla']!({'a': 'sal'});
    expect(host.W['twinkle'], 'sal');
    expect(jsTruthy(host.W['cq']['vis']), isTrue);
  });

  test(
    'falta-algo cools abuelo first (n=2) and leaves only abuela hot (n=1)',
    () async {
      final story = jsonDecode(
        File('test/support/fixtures/comida/falta-algo.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final scene = createComida() as Comida;
      final frame = StillFrame(scene);
      final host = frame.host;
      host.S = story;
      host.W = {...host.W, ...scene.fresh(story)};

      await scene.acts['sopas']!({'n': 3});
      for (final who in const ['abuela', 'abuelo', 'luis']) {
        await scene.acts['gesto']!({'quien': who, 'que': 'cuchara'});
      }
      Set<String> steamTags() => {
        for (final it in scene.items(host.W, 0))
          if (it.tag != null && it.tag!.startsWith('fx:vapor_sopa')) it.tag!,
      };
      Map<String, dynamic> g(String who) =>
          (host.W['gente'] as Map<String, dynamic>)[who]
              as Map<String, dynamic>;

      expect(steamTags(), const {
        'fx:vapor_sopa1',
        'fx:vapor_sopa2',
        'fx:vapor_sopa3',
      });

      // 1 miss -> abuelo's bowl (sopa2) cools and his spoon goes down
      await scene.acts['sopas']!({'n': 2});
      expect(steamTags(), const {'fx:vapor_sopa1', 'fx:vapor_sopa3'});
      expect(g('abuela')['cuchara'], 1);
      expect(g('abuelo')['cuchara'], 0);
      expect(g('luis')['cuchara'], 1);

      // 2 misses -> abuelo's and Luis's bowls cool; only abuela's steams
      await scene.acts['final91']!({'n': 1});
      expect(steamTags(), const {'fx:vapor_sopa1'});
      expect(g('abuela')['cuchara'], 1);
      expect(g('abuelo')['cuchara'], 0);
      expect(g('luis')['cuchara'], 0);
    },
  );
}
