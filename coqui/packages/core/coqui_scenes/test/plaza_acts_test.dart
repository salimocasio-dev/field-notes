// El banco de la plaza's acts on a host whose waits return at once (StillHost): each story's steps walked in order, every act
// the stories call run with the values they give it (a story variable takes one value of its draw: each value is walked
// once), both branches of each decision (the right one, and the wrong one before it). After every act:
// - every touch box contains its thing (a sprite thing's box is its drawn pixels' box; a set thing's is the sheet's);
// - every thing the Needs list says he can touch that is shown answers a touch: some point of its box hits it;
// - the frame draws (the sprite layer and the boards) and the shadows are cast without an error.
// And: each thing the Needs list names answered a touch at least once over the three stories, and the answer bubbles'
// boxes are those of the sheet (things.burbuja_a, _b) when the frog is at asiento4.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/plaza/plaza.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// What the Needs list says he can touch (plaza.md, "Needs": things he can touch).
const List<String> needs = [
  'ana',
  'mama_ana',
  'beto',
  'abuela_ana',
  'luis',
  'carmen',
  'senor',
  'senora',
  'hombre',
  'mujer',
  'joven',
  'piraguero',
  'turista',
  'coqui',
  'perro',
  'palomas',
  'burbuja_a',
  'burbuja_b',
  'fila_isla',
  'fila_ciudad',
  'tarjetas',
  'carrito',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/plaza/$id.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('plaza');
  });
  final answered = <String>{};

  // one value for each story variable a draw gives, by the walk ([pick] 0 or 1: the first values, or others)
  Map<String, String> vars(String id, int pick) => switch (id) {
    'mucho-gusto' =>
      pick == 0
          ? {
              'la': 'llamas',
              'ia': 'insignia',
              'ra': 'insignia',
              'pa': 'burbuja_a',
              'lb': 'gusto',
              'ib': 'insignia',
              'rb': 'manos',
              'pb': 'burbuja_b',
            }
          : {
              'la': 'gusto',
              'ia': 'manos',
              'ra': 'manos',
              'pa': 'burbuja_a',
              'lb': 'llamas',
              'ib': 'manos',
              'rb': 'insignia',
              'pb': 'burbuja_b',
            },
    'de-donde-eres' => {
      'da': pick == 0 ? 'isla' : 'ciudad',
      'na': pick == 0 ? 'ciudad' : 'isla',
      'qa': pick == 0 ? 'soy' : 'vivo',
      'db': pick == 0 ? 'ciudad' : 'isla',
      'nb': pick == 0 ? 'isla' : 'ciudad',
      'qb': 'vivo',
    },
    _ =>
      pick == 0
          ? {
              'pa': 'mujer',
              'pb': 'hombre',
              'pc': 'joven',
              'pd': 'senora',
              'ha': 'u',
              'qa': 'h',
              'ea': 'mujer',
              'na': 'hombre',
              'hb': 'v',
              'qb': 'n',
              'eb': 'senora',
              'nb': 'joven',
            }
          : {
              'pa': 'senor',
              'pb': 'joven',
              'pc': 'hombre',
              'pd': 'mujer',
              'ha': 'v',
              'qa': 'n',
              'ea': 'joven',
              'na': 'senor',
              'hb': 'u',
              'qb': 'h',
              'eb': 'hombre',
              'nb': 'mujer',
            },
  };

  for (final id in const ['mucho-gusto', 'de-donde-eres', 'hablo-espanol']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createPlaza() as Plaza;
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
              final b = scene.box(k, W);
              if (k == 'coqui') continue;
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
              if (scene.hit(fb.x + fb.w / 2, fb.y + fb.h / 2, W) == 'coqui') {
                answered.add('coqui');
              }
            }
            // a sprite thing's box holds its drawn pixels (a person, Canelo, a pigeon, the cards)
            for (final it in scene.items(W, 0)) {
              final tag = it.tag;
              if (tag == null) continue;
              final k = tag.startsWith('cosa:')
                  ? tag.substring(5)
                  : tag.startsWith('persona:')
                  ? tag.substring(8)
                  : tag.startsWith('paloma:')
                  ? 'palomas'
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
          expect(acts, greaterThan(20));
          // the bubbles' boxes are the sheet's for the frog at asiento4 (things.burbuja_a, _b)
          host.W['burbujas'] = {'izq': 'insignia', 'dice': null};
          final L = scene.lugar['asiento4']!,
              q = host.W['cq'] as Map<String, dynamic>;
          q
            ..['x'] = L[0]
            ..['y'] = L[1]
            ..['vis'] = 1;
          expect(scene.box('burbuja_a', host.W), scene.places.box('burbuja_a'));
          expect(scene.box('burbuja_b', host.W), scene.places.box('burbuja_b'));
        },
      );
    }
  }

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
