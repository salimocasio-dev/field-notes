// El baño's acts, Needs things, touch boxes, and speaker keys (bano.md, stories 99 to 101).
// Walks all three stories (limpio-y-sucio, se-bana, los-dientes) across both right and wrong branches, verifies
// every touchable thing answers a touch and its touch box holds its thing inside the view, and verifies every speaker
// key has a talkAt point.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart' show jsTruthy;
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/bano/bano.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Deterministic draw variable assignment for walking [id] in acts/frames tests (`pick`: 0 or 1).
Map<String, String> banoVars(String id, int pick) => switch (id) {
  'limpio-y-sucio' =>
    pick == 0
        ? {
            'ka': 'luis',
            'kb': 'carmen',
            'la': 'rojo',
            'ra': 'azul',
            'ea': '1',
            'qa': 'a',
            'oa': 'lt',
            'ca': 'rojo',
            'da': 'azul',
            'pa': 'toalla_a',
            'eb': '2',
            'lb': 'blanco',
            'rb': 'rojo',
            'qb': 'b',
            'ob': 'tl',
            'cb': 'rojo',
            'db': 'blanco',
            'pb': 'toalla_b',
          }
        : {
            'ka': 'carmen',
            'kb': 'luis',
            'la': 'azul',
            'ra': 'blanco',
            'ea': '2',
            'qa': 'b',
            'oa': 'tl',
            'ca': 'blanco',
            'da': 'azul',
            'pa': 'toalla_b',
            'eb': '1',
            'lb': 'rojo',
            'rb': 'azul',
            'qb': 'a',
            'ob': 'lt',
            'cb': 'rojo',
            'db': 'azul',
            'pb': 'toalla_a',
          },
  'se-bana' =>
    pick == 0
        ? {
            'ka': 'luis',
            'kb': 'carmen',
            'wa': 'bana',
            'pa': 'llave_ducha',
            'wb': 'lava',
            'pb': 'llave_lavamanos',
          }
        : {
            'ka': 'carmen',
            'kb': 'luis',
            'wa': 'lava',
            'pa': 'llave_lavamanos',
            'wb': 'bana',
            'pb': 'llave_ducha',
          },
  _ =>
    pick == 0
        ? {
            'ga': 'luis',
            'gb': 'carmen',
            'ia': 'cepillo',
            'ta': 'peinilla',
            'ka': 'cosa_a',
            'za': 'cosa_b',
            'pa': 'cosa_b',
            'ib': 'peinilla',
            'tb': 'cepillo',
            'kb': 'cosa_b',
            'zb': 'cosa_a',
            'pb': 'cosa_b',
          }
        : {
            'ga': 'carmen',
            'gb': 'luis',
            'ia': 'peinilla',
            'ta': 'cepillo',
            'ka': 'cosa_b',
            'za': 'cosa_a',
            'pa': 'cosa_b',
            'ib': 'cepillo',
            'tb': 'peinilla',
            'kb': 'cosa_a',
            'zb': 'cosa_b',
            'pb': 'cosa_b',
          },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('bano');
  });

  test(
    'every story walks to the end across both picks and right/wrong acts',
    () async {
      for (final id in const ['limpio-y-sucio', 'se-bana', 'los-dientes']) {
        final story = jsonDecode(
          File('test/support/fixtures/bano/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        for (final pick in const [0, 1]) {
          final scene = createBano() as Bano;
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
          final v = {...banoVars(id, pick)};
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

  test(
    'every Needs touch thing answers a touch and its box lies inside wide view',
    () async {
      final answered = <String>{};
      for (final id in const ['limpio-y-sucio', 'se-bana', 'los-dientes']) {
        final story = jsonDecode(
          File('test/support/fixtures/bano/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final scene = createBano() as Bano;
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
        if (id == 'limpio-y-sucio') {
          await scene.acts['llega']!({'quien': 'luis', 'a': 'lavamanos1'});
          await scene.acts['gesto']!({'quien': 'luis', 'que': 'manos'});
          await scene.acts['llega']!({'quien': 'carmen', 'a': 'lavamanos2'});
          await scene.acts['toallas99']!({'a': 'rojo', 'b': 'azul'});
        }
        if (id == 'se-bana') {
          await scene.acts['llega']!({'quien': 'abuelo', 'a': 'puerta1'});
        }
        if (id == 'los-dientes') {
          await scene.acts['llega']!({'quien': 'carmen', 'a': 'lavamanos1'});
          await scene.acts['llega']!({'quien': 'luis', 'a': 'lavamanos2'});
        }
        frame.draw(host.W, F: host.F, cam: host.cam);
        for (final thing in scene.cosas) {
          if (thing.si != null && !thing.si!(host.W)) continue;
          final box = thing.box(host.W);
          expect(box, isNotNull, reason: '$id: ${thing.id} has null box');
          expect(box![2], greaterThan(0), reason: '$id: ${thing.id} w <= 0');
          expect(box[3], greaterThan(0), reason: '$id: ${thing.id} h <= 0');
          // Wide view [20, 0, 196, 216]
          expect(box[0], greaterThanOrEqualTo(20), reason: '${thing.id} x0');
          expect(
            box[0] + box[2],
            lessThanOrEqualTo(216),
            reason: '${thing.id} x1',
          );
          expect(box[1], greaterThanOrEqualTo(0), reason: '${thing.id} y0');
          expect(
            box[1] + box[3],
            lessThanOrEqualTo(216),
            reason: '${thing.id} y1',
          );
          final hit = scene.hit(
            box[0] + box[2] / 2,
            box[1] + box[3] / 2,
            host.W,
          );
          expect(hit, isNotNull, reason: '$id: ${thing.id} center hit');
          answered.add(thing.id);
        }
        for (final who in const ['abuela', 'luis', 'carmen', 'coqui']) {
          expect(scene.talkAt(who, host.W), isNotNull, reason: '$id: $who');
        }
        if (id == 'se-bana') {
          expect(scene.talkAt('abuelo', host.W), isNotNull);
        }
      }

      expect(
        answered,
        containsAll(const [
          'jabon',
          'toalla_a',
          'toalla_b',
          'ducha',
          'llave_ducha',
          'llave_lavamanos',
          'espejo',
          'cosa_a',
          'cosa_b',
          'tubo',
          'cepillito',
          'calentador',
          'canasta',
          'luis',
          'carmen',
          'abuela',
          'abuelo',
          'perro',
          'coqui',
          'manos_luis',
        ]),
      );
    },
  );

  test('every gesto variant and suelto/ya runs cleanly', () async {
    final story = jsonDecode(
      File('test/support/fixtures/bano/limpio-y-sucio.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final scene = createBano() as Bano;
    final frame = StillFrame(scene);
    final host = frame.host;
    host.S = story;
    host.W = {...host.W, ...scene.fresh(story)};

    await scene.acts['sale']!({'quien': 'abuela', 'suelto': 1});
    await scene.acts['ya']!({});
    expect((host.W['gente'] as Map)['abuela']['vis'], 0);

    for (final q in const [
      'saluda',
      'no',
      'si',
      'rie',
      'mira',
      'senala',
      'huele',
      'dientes',
      'toca',
      'manos',
    ]) {
      await scene.acts['gesto']!({'quien': 'luis', 'que': q, 'a': 'jabon'});
      frame.draw(host.W, F: host.F, cam: host.cam);
    }
    await scene.acts['brilla']!({'a': 'jabon'});
    expect(host.W['twinkle'], 'jabon');
    expect(jsTruthy(host.W['cq']['vis']), isTrue);
  });
}
