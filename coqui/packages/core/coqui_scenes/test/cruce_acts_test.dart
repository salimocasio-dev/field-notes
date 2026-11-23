// El cruce's acts on a host whose waits return at once (StillHost): each story's steps walked in order, every act the
// stories call run with the values they give it (a story variable takes one value of its draw: two sets of values, each
// walked), both branches of each decision (the wrong one before the right one, as the runner plays a miss), and the
// acts of every `lead`. After every act:
// - every touch box contains its thing (a sprite thing's box is its drawn pixels' box; a set thing's is the sheet's);
// - every thing the Needs list says he can touch that is shown answers a touch: some point of its box hits it;
// - the frame draws (the sprite layer and the cards) and the shadows are cast without an error.
// And: each thing the Needs list names answered a touch at least once over the three stories.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/cruce/cruce.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// What the Needs list says he can touch: the three streets, each person, perro, the frog's places of story 59.
const List<String> needs = [
  'calle_izq',
  'calle_der',
  'calle_recta',
  'abuela',
  'abuelo',
  'mama',
  'papa',
  'luis',
  'carmen',
  'bebe',
  'senora',
  'senor',
  'pepe',
  'obrero',
  'piraguero',
  'perro',
  'delante_canelo',
  'detras_canelo',
  'lado_abuela',
  'delante_abuela',
  'coqui',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/cruce/$id.json').readAsStringSync())
        as Map<String, dynamic>;

/// One value for each story variable a draw gives, by the walk ([pick] 0 or 1).
Map<String, String> cruceVars(String id, int pick) => switch (id) {
  'izquierda-o-derecha' =>
    pick == 0
        ? {
            'la': 'tienda',
            'lb': 'colmado',
            'da': 'der',
            'oa': 'izq',
            'db': 'izq',
            'ob': 'der',
          }
        : {
            'la': 'colmado',
            'lb': 'tienda',
            'da': 'izq',
            'oa': 'der',
            'db': 'der',
            'ob': 'izq',
          },
  'sigue-derecho' =>
    pick == 0
        ? {'da': 'recta', 'oa': 'izq', 'db': 'izq', 'ob': 'recta'}
        : {'da': 'izq', 'oa': 'recta', 'db': 'recta', 'ob': 'izq'},
  _ =>
    pick == 0
        ? {'da': 'detras', 'db': 'lado'}
        : {'da': 'delante', 'db': 'delante'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('cruce');
  });
  final answered = <String>{};

  for (final id in const [
    'izquierda-o-derecha',
    'sigue-derecho',
    'al-frente-y-detras',
  ]) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createCruce() as Cruce;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = {...cruceVars(id, pick)};
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
              // a thing on its way in, still out of the picture
              if (b[0] + b[2] <= 0 || b[0] >= 240 || b[1] >= 216) continue;
              // a thing of the set whose every point is under a person, a vehicle or the frog (the button behind the
              // obrero's box in story 50) answers nothing
              final isSet = t.world != null;
              final sets = {
                for (final c in scene.cosas)
                  if (c.world != null) c.id,
              };
              var open = !isSet;
              var hits = false;
              for (var y = b[1].toInt(); y < b[1] + b[3] && !hits; y++) {
                for (var x = b[0].toInt(); x < b[0] + b[2] && !hits; x++) {
                  if (x < 0 || y < 0 || x >= 240 || y >= 216) continue;
                  final h = scene.hit(x, y, W);
                  if (isSet && (h == null || sets.contains(h))) open = true;
                  if (h == k) hits = true;
                }
              }
              if (!open) continue;
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
            // a sprite thing's box holds its drawn pixels
            for (final it in scene.items(W, 0)) {
              final tag = it.tag;
              if (tag == null) continue;
              final k = tag.startsWith('persona:') ? tag.substring(8) : null;
              if (k == null || !needs.contains(k)) continue;
              final b = scene.box(k, W);
              if (b == null) continue;
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
                await walk(st['lead']);
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                final pk = sub(st['pick']) as String;
                v['x'] = [
                  for (final o in st['options'] as List) sub(o),
                ].firstWhere((o) => o != pk) as String;
                host.W['ok'] = false;
                await walk(st['wrong']);
                await walk(st['right']);
                host.W['ok'] = true;
              } else if (st['calc'] is String) {
                final c = (st['cond'] as String).split('=');
                v[st['calc'] as String] =
                    (v[c[0]] == c[1] ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                await walk(st['then']);
                await walk(st['else']);
              }
            }
          }

          await walk(story['beats']);
          await walk(story['final']);
          await scene.acts['ya']!({});
          expect(acts, greaterThan(20));
        },
      );
    }
  }

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
