// El reloj's acts on a host whose waits return at once (StillHost): each story's steps walked in order, every act the
// stories call run with the values they give it (each story walked twice with different draw values), both branches of
// each decision (wrong then right). After every act:
// - every touch box contains its thing (a sprite thing's box is its drawn pixels' box; a set thing's is the sheet's);
// - every thing the Needs list says he can touch that is shown answers a touch: some point of its box hits it;
// - the frame draws (the sprite layer and the signs) and the shadows are cast without an error.
// And: each thing the Needs list names answered a touch at least once over the three stories, and the time cards'
// boxes are those of the sheet (things.carta_a, _b) when the frog is at pie2.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/reloj/reloj.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// What the Needs list says he can touch (reloj.md, "Needs": things he can touch).
const List<String> needs = [
  'reloj',
  'arriba',
  'abajo',
  'carta_a',
  'carta_b',
  'n40',
  'n60',
  'n80',
  'n90',
  'n100',
  'tito',
  'vendedor',
  'luis',
  'carmen',
  'abuela',
  'senor',
  'senora',
  'coqui',
  'pastelillos',
  'puertita',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/reloj/$id.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('reloj');
  });
  final answered = <String>{};

  Map<String, String> vars(String id, int pick) => switch (id) {
    'que-hora-es' =>
      pick == 0
          ? {
              'ha': '5',
              'da': 'l',
              'oa': '8',
              'ka': 'carta_a',
              'ja': 'carta_b',
              'ua': '5',
              'va': '8',
              'hb': '9',
              'db': 'e',
              'ob': '4',
              'kb': 'carta_b',
              'jb': 'carta_a',
              'ub': '4',
              'vb': '9',
            }
          : {
              'ha': '4',
              'da': 'e',
              'oa': '1',
              'ka': 'carta_b',
              'ja': 'carta_a',
              'ua': '1',
              'va': '4',
              'hb': '12',
              'db': 'e',
              'ob': '7',
              'kb': 'carta_a',
              'jb': 'carta_b',
              'ub': '12',
              'vb': '7',
            },
    'y-media' =>
      pick == 0
          ? {
              'ha': '5',
              'da': 'media',
              'oa': 'punto',
              'pa': 'abajo',
              'ma': '1',
              'hb': '8',
              'db': 'punto',
              'ob': 'media',
              'pb': 'arriba',
              'mb': '0',
            }
          : {
              'ha': '4',
              'da': 'punto',
              'oa': 'media',
              'pa': 'arriba',
              'ma': '0',
              'hb': '11',
              'db': 'media',
              'ob': 'punto',
              'pb': 'abajo',
              'mb': '1',
            },
    _ =>
      pick == 0
          ? {'na': '100', 'nb': '60', 'nc': '80', 'xn': '60'}
          : {'na': '80', 'nb': '100', 'nc': '60', 'xn': '100'},
  };

  for (final id in const ['que-hora-es', 'y-media', 'bingo']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createReloj() as Reloj;
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
              final k = tag == 'cosa:plato'
                  ? 'pastelillos'
                  : tag.startsWith('persona:')
                  ? tag.substring(8)
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
          expect(acts, greaterThan(15));
          // time cards' boxes match the sheet's for the frog at pie2
          host.W['cartas'] = {'a': 5, 'b': 8};
          final L = scene.lugar['pie2']!,
              q = host.W['cq'] as Map<String, dynamic>;
          q
            ..['x'] = L[0]
            ..['y'] = L[1]
            ..['vis'] = 1;
          expect(scene.box('carta_a', host.W), scene.places.box('carta_a'));
          expect(scene.box('carta_b', host.W), scene.places.box('carta_b'));
        },
      );
    }
  }

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
