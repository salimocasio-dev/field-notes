// La ropa's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in ropa.md's Needs list answers a touch;
// - draw, hud, and shadows run without error.
// Over the three stories, every single one of the 21 things in the Needs list answers a touch at least once.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/ropa/ropa.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing ropa.md's Needs list says he can touch (21 things).
const List<String> needs = [
  'camisa',
  'pantalon',
  'vestido',
  'zapatos',
  'sombrero',
  'toalla',
  'chancletas',
  'gafas',
  'traje',
  'abuela',
  'luis',
  'carmen',
  'coqui',
  'perro',
  'chico_a',
  'chico_b',
  'chica_a',
  'chica_b',
  'plato',
  'bolsa',
  'guagua',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/ropa/$id.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> ropaVars(String id, int pick) => switch (id) {
  'la-ropa-seca' =>
    pick == 0
        ? {'qa': 'pantalon', 'qb': 'zapatos'}
        : {'qa': 'vestido', 'qb': 'camisa'},
  'mi-sombrero' =>
    pick == 0
        ? {
            'oa': 'sombrero',
            'ob': 'chancletas',
            'oc': 'gafas',
            'od': 'traje',
            'qa': 'chancletas',
            'qb': 'gafas',
          }
        : {
            'oa': 'traje',
            'ob': 'gafas',
            'oc': 'sombrero',
            'od': 'chancletas',
            'qa': 'sombrero',
            'qb': 'traje',
          },
  _ =>
    pick == 0
        ? {
            'ha': 'quita',
            'ka': 'sombrero',
            'ca': 'a',
            'hb': 'pone',
            'kb': 'vestido',
            'cb': 'b',
          }
        : {
            'ha': 'pone',
            'ka': 'camisa',
            'ca': 'b',
            'hb': 'quita',
            'kb': 'sombrero',
            'cb': 'a',
          },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('ropa');
  });
  final answered = <String>{};

  for (final id in const [
    'la-ropa-seca',
    'mi-sombrero',
    'se-pone-y-se-quita',
  ]) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createRopa() as Ropa;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = {...ropaVars(id, pick)};
          Object? sub(Object? s) => s is String
              ? s.replaceAllMapped(
                  RegExp(r'\$([a-z]+)'),
                  (m) => v[m[1]!] ?? m[0]!,
                )
              : s;
          final pix = Uint32List(240 * 216), disp = Uint32List(196 * 216);
          var acts = 0;

          Future<void> check(String at) async {
            final W = host.W;
            scene.draw(Ctx(pix, 240, 216), W, host.F);
            scene.hud(Ctx(disp, 196, 216), W, host.F);
            scene.shadows(W);
            for (final k in needs) {
              if (k == 'coqui') continue;
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere(
                (t) => t.id == k,
                orElse: () => Thing(id: ''),
              );
              if (t.id.isEmpty || (t.si != null && !t.si!(W)) || b == null) {
                continue;
              }
              var hits = false;
              final xStart = b[0].toInt().clamp(22, 217);
              final xEnd = (b[0] + b[2]).toInt().clamp(22, 218);
              for (var y = b[1].toInt(); y < b[1] + b[3] && !hits; y++) {
                for (var x = xStart; x < xEnd && !hits; x++) {
                  if (scene.hit(x, y, W) == k) hits = true;
                }
              }
              expect(
                hits,
                isTrue,
                reason: '$id $at: $k shown, its box $b answers no touch',
              );
              answered.add(k);
            }
            final q = W['cq'] as Map<String, dynamic>;
            if (jsTruthy(q['vis'])) {
              final fb = host.frogBox(q);
              var frogHits = false;
              for (var y = fb.y.toInt(); y < fb.y + fb.h && !frogHits; y++) {
                for (var x = fb.x.toInt(); x < fb.x + fb.w && !frogHits; x++) {
                  if (scene.hit(x, y, W) == 'coqui') frogHits = true;
                }
              }
              if (frogHits) answered.add('coqui');
            }
            // Every sprite thing's box holds its drawn pixels.
            for (final it in scene.items(W, 0)) {
              final tag = it.tag;
              if (tag == null) continue;
              final k = tag.startsWith('persona:')
                  ? tag.substring(8)
                  : tag.startsWith('cosa:')
                  ? tag.substring(5)
                  : tag;
              if (!needs.contains(k)) continue;
              final b = scene.box(k, W)!;
              for (var y = 0; y < it.s.h; y++) {
                for (var x = 0; x < it.s.w; x++) {
                  if (it.s.px[y * it.s.w + x] >>> 24 == 0) continue;
                  final X = it.left + x, Y = it.top + y;
                  expect(
                    X >= b[0] &&
                        X < b[0] + b[2] &&
                        Y >= b[1] &&
                        Y < b[1] + b[3],
                    isTrue,
                    reason: '$id $at: $k\'s pixel ($X, $Y) out of its box $b',
                  );
                }
              }
            }
          }

          Future<void> walk(Object? steps, {bool wrong = false}) async {
            if (steps is! List) return;
            for (final st in steps) {
              if (st is! Map<String, dynamic>) continue;
              if (st['set'] is Map) {
                host.W.addAll((st['set'] as Map).cast<String, dynamic>());
              } else if (st['act'] is String) {
                final o = {for (final e in st.entries) e.key: sub(e.value)};
                await scene.acts[st['act']]!(o);
                acts++;
                host.F += 3;
                if (!jsTruthy(o['suelto'])) await check('${st['act']} #$acts');
              } else if (st['ask'] is String) {
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                final pk = sub(st['pick']) as String;
                final ops = [
                  for (final o in st['options'] as List) sub(o) as String,
                ];
                v['x'] = ops.firstWhere((o) => o != pk);
                await walk(st['wrong'], wrong: true);
                await walk(st['right'], wrong: false);
              } else if (st['calc'] is String) {
                final c = (st['cond'] as String).split('=');
                v[st['calc'] as String] =
                    sub(v[c[0]] == c[1] ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                final cond = st['if'] as String;
                if (cond == 'ok') {
                  await walk(wrong ? st['else'] : st['then'], wrong: wrong);
                } else {
                  final parts = cond.split('=');
                  if (parts.length == 2 && v.containsKey(parts[0])) {
                    await walk(
                      v[parts[0]] == parts[1] ? st['then'] : st['else'],
                      wrong: wrong,
                    );
                  } else {
                    await walk(st['then'], wrong: wrong);
                    await walk(st['else'], wrong: wrong);
                  }
                }
              }
            }
          }

          await check('start');
          await walk(story['beats']);
          await walk(story['final']);
          expect(acts, greaterThan(10));
        },
      );
    }
  }

  test('adjacent clothes on line, things afloat, and look-alike children resolve exact boundaries', () {
    // Story 78: camisa [93..108], pantalon [111..126], vestido [129..144].
    final s78 = _story('la-ropa-seca');
    final scene78 = createRopa() as Ropa;
    final host78 = StillHost(scene78);
    host78.S = s78;
    host78.W = {
      ...host78.W,
      ...scene78.fresh(s78),
      'cuerda': {
        'cuerda2': 'camisa',
        'cuerda3': 'pantalon',
        'cuerda4': 'vestido',
      },
      'zapatosVis': 1,
    };
    final w78 = host78.W;
    expect(scene78.hit(100, 62, w78), 'camisa');
    expect(scene78.hit(118, 62, w78), 'pantalon');
    expect(scene78.hit(136, 62, w78), 'vestido');
    expect(scene78.hit(134, 113, w78), 'zapatos');
    expect(scene78.hit(146, 113, w78), 'zapatos');

    // Story 79: agua1 [74..87], agua2 [92..105], agua3 [110..123], agua4 [129..142], agua5 [174..187].
    final s79 = _story('mi-sombrero');
    final scene79 = createRopa() as Ropa;
    final host79 = StillHost(scene79);
    host79.S = s79;
    host79.W = {
      ...host79.W,
      ...scene79.fresh(s79),
      'agua': {
        'agua1': 'sombrero',
        'agua2': 'chancletas',
        'agua3': 'gafas',
        'agua4': 'traje',
        'agua5': 'toalla',
      },
    };
    final w79 = host79.W;
    expect(scene79.hit(81, 49, w79), 'sombrero');
    expect(scene79.hit(99, 49, w79), 'chancletas');
    expect(scene79.hit(117, 49, w79), 'gafas');
    expect(scene79.hit(136, 49, w79), 'traje');
    expect(scene79.hit(181, 49, w79), 'toalla');

    // Story 80: ninos1 (45, 125), ninos2 (71, 125), ninos3 (104, 125), ninos4 (130, 125), guagua (143..217, 148..197).
    final s80 = _story('se-pone-y-se-quita');
    final scene80 = createRopa() as Ropa;
    final host80 = StillHost(scene80);
    host80.S = s80;
    host80.W = {
      ...host80.W,
      ...scene80.fresh(s80),
      'ninos': {
        'chico_a': 'ninos1',
        'chico_b': 'ninos2',
        'chica_a': 'ninos3',
        'chica_b': 'ninos4',
      },
    };
    final w80 = host80.W;
    expect(scene80.hit(45, 108, w80), 'chico_a');
    expect(scene80.hit(71, 108, w80), 'chico_b');
    expect(scene80.hit(104, 108, w80), 'chica_a');
    expect(scene80.hit(130, 108, w80), 'chica_b');
    expect(scene80.hit(180, 170, w80), 'guagua');
  });

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
