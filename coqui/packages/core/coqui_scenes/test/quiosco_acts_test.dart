// El quiosco's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every touch box holds its thing's drawn pixels;
// - every visible thing in quiosco.md's Needs list answers a touch;
// - draw, hud, and shadows run without error.
// Over the three stories, every single thing in the Needs list answers a touch at least once.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/quiosco/quiosco.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing quiosco.md's Needs list says he can touch.
const List<String> needs = [
  'vendedor',
  'maestra',
  'doctor',
  'cocinero',
  'policia',
  'senor',
  'senora',
  'hombre',
  'mujer',
  'joven',
  'la_joven',
  'nino',
  'nina',
  'beto',
  'ana',
  'carmen',
  'luis',
  'abuela',
  'mama_ana',
  'coqui',
  'caja',
  'vela_a',
  'vela_b',
  'vela_c',
  'quesitos',
  'limbers',
  'torre',
];

Map<String, dynamic> _story(String id) => jsonDecode(
  File('test/support/fixtures/quiosco/$id.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('quiosco');
  });
  final answered = <String>{};

  Map<String, String> vars(String id, int pick) => switch (id) {
    'un-cafe-para-la-maestra' =>
      pick == 0
          ? {
              'pa': 'maestra',
              'qa': 'cafe',
              'pb': 'doctor',
              'qb': 'leche',
              'x': 'cocinero',
            }
          : {
              'pa': 'cocinero',
              'qa': 'jugo',
              'pb': 'policia',
              'qb': 'cafe',
              'x': 'maestra',
            },
    'en-que-trabajas' =>
      pick == 0
          ? {
              'ta': 'estetoscopio',
              'oa': 'senora',
              'na': 'hombre',
              'tb': 'bulto',
              'ob': 'la_joven',
              'nb': 'mujer',
              'x': 'hombre',
            }
          : {
              'ta': 'gorra',
              'oa': 'hombre',
              'na': 'senora',
              'tb': 'delantal',
              'ob': 'mujer',
              'nb': 'la_joven',
              'x': 'senora',
            },
    _ =>
      pick == 0
          ? {
              'ea': '9',
              'ha': '2',
              'ta': '11',
              'ua': '9',
              'va': '2',
              'wa': '11',
              'na': '2',
              'eb': '7',
              'hb': '3',
              'tb': '12',
              'ub': '3',
              'vb': '7',
              'wb': '12',
              'nb': '12',
            }
          : {
              'ea': '5',
              'ha': '4',
              'ta': '10',
              'ua': '10',
              'va': '4',
              'wa': '5',
              'na': '10',
              'eb': '12',
              'hb': '2',
              'tb': '6',
              'ub': '12',
              'vb': '6',
              'wb': '2',
              'nb': '6',
            },
  };

  for (final id in const [
    'un-cafe-para-la-maestra',
    'en-que-trabajas',
    'cuantos-anos-tienes',
  ]) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createQuiosco() as Quiosco;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = vars(id, pick);
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
              for (var y = b[1].toInt(); y < b[1] + b[3] && !hits; y++) {
                for (var x = b[0].toInt(); x < b[0] + b[2] && !hits; x++) {
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
            // every sprite thing's box holds its drawn pixels
            for (final it in scene.items(W, 0)) {
              final tag = it.tag;
              if (tag == null) continue;
              final k = tag.startsWith('persona:')
                  ? tag.substring(8)
                  : tag.startsWith('cosa:limber_')
                  ? 'limbers'
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

          Future<void> walk(Object? steps) async {
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
                await check('${st['act']} #$acts');
              } else if (st['ask'] is String) {
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['if'] is String) {
                await walk(st['then']);
                await walk(st['else']);
              }
            }
          }

          await walk(story['beats']);
          await walk(story['final']);
          expect(acts, greaterThan(10));
        },
      );
    }
  }

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
