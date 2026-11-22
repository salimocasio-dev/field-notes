// Los estantes' acts on a host whose waits return at once (StillHost): each story's steps walked in order, every act
// the stories call run with the values they give it (a story variable takes one value of its draw: each value is walked
// once), both branches of each decision (the right one, and the wrong one before it). After every act:
// - every touch box contains its thing (a sprite thing's box is its drawn pixels' box; a set thing's is the sheet's);
// - every thing the Needs list says he can touch that is shown answers a touch: some point of its box hits it;
// - the frame draws (the sprite layer and the board) and the shadows are cast without an error.
// And: each thing the Needs list names answered a touch at least once over the three stories.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/estantes/estantes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// What the Needs list says he can touch (the number bubbles are the runner's answer bubbles, not the scene's), and the
/// two boxes the story twinkles (caja_senora, caja_senor).
const List<String> needs = [
  'lata',
  'botella',
  'caja',
  'red_a',
  'red_b',
  'caja_senora',
  'caja_senor',
  'pepe',
  'luis',
  'senora',
  'senor',
  'perro',
  'estante',
  'mesa',
  'coqui',
];

Map<String, dynamic> _story(String id) => jsonDecode(
  File('test/support/fixtures/estantes/$id.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('estantes');
  });
  final answered = <String>{};

  // one value for each story variable a draw or a calc gives, by the walk ([pick] 0 or 1: the first values, or others)
  Map<String, String> vars(String id, int pick) => switch (id) {
    'latas-y-botellas' => {
      'ka': pick == 0 ? 'lata' : 'botella',
      'kb': pick == 0 ? 'botella' : 'lata',
      'x': pick == 0 ? 'botella' : 'lata',
      'ca': '2',
      'bo': '2',
      'pb': pick == 0 ? '3' : '2',
      'pl': pick == 0 ? '2' : '3',
    },
    'siete-latas' => {
      'ra': pick == 0 ? 'red_a' : 'red_b',
      'rb': pick == 0 ? 'red_b' : 'red_a',
      'pra': pick == 0 ? '6' : '4',
      'qra': pick == 0 ? '4' : '6',
      'prb': pick == 0 ? '7' : '5',
      'qrb': pick == 0 ? '5' : '7',
      'rn': pick == 0 ? '4' : '2',
      'x': pick == 0 ? 'red_b' : 'red_a',
    },
    _ => {
      'na': pick == 0 ? '8' : '9',
      'wa': pick == 0 ? 'ocho' : 'nueve',
      'oa': pick == 0 ? 'ocho' : 'diez',
      'pa': pick == 0 ? 'nueve' : 'diez',
      'ma': pick == 0 ? '2' : '1',
      'nb': pick == 0 ? '9' : '8',
      'wb': pick == 0 ? 'nueve' : 'ocho',
      'ob': pick == 0 ? 'ocho' : 'diez',
      'pb': pick == 0 ? 'ocho' : 'nueve',
      'mb': pick == 0 ? '1' : '2',
      'x': 'di_diez',
    },
  };

  for (final id in const ['latas-y-botellas', 'siete-latas', 'diez-botellas']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createEstantes() as Estantes;
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
              final b = scene.box(k, W) ?? (k == 'coqui' ? null : null);
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
            // a sprite thing's box is its drawn pixels' box
            for (final it in scene.items(W, 0)) {
              final tag = it.tag;
              if (tag == null || !tag.startsWith('cosa:')) continue;
              final k = tag.substring(5);
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
          expect(acts, greaterThan(15));
        },
      );
    }
  }

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
