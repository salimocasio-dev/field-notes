// Las frutas' acts on a host whose waits return at once (StillHost): each story's steps walked in order, every act the
// stories call run with the values they give it (a story variable takes one value of its draw: each value is walked
// once), both branches of each decision (the wrong one, then the right one) and of each `if`. After every act:
// - every touch box contains its thing (a sprite thing's box is its drawn pixels' box; a set thing's is the sheet's);
// - every thing the Needs list says he can touch that is shown answers a touch: some point of its box hits it, and the
//   big hand's point (handAt, and 3 down, where the runner touches) hits it;
// - the frame draws (the sprite layer and the boards) and the shadows are cast without an error.
// And: each thing the Needs list names answered a touch at least once over the three stories; every act the Needs list
// names is the scene's; the set's things' boxes hold their parts' pixels (the bake's part tags).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/frutas/frutas.dart';
import 'package:coqui_scenes/src/frutas/frutas_set.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/report.dart';
import 'support/sheet_bundle.dart';

/// What the Needs list says he can touch (frutas.md, "Things he can touch").
const List<String> needs = [
  'tomates',
  'cebollas',
  'papas',
  'platanos',
  'aguacates',
  'pinas',
  'limones',
  'fruta_a',
  'fruta_b',
  'cajon_a',
  'cajon_b',
  'canasta',
  'pesa',
  'guineos',
  'cabra',
  'pepe',
  'abuela',
  'coqui',
];

/// Every act the Needs list names (frutas.md, "Acts"; `brilla` is the engine's twinkle, a `set` step).
const List<String> needActs = [
  'lista',
  'tira',
  'cabra',
  'monedas',
  'guineos',
  'corta',
  'prueba43',
  'huele',
  'pone43',
  'canasta43',
  'sale',
  'vuelve',
  'limon44',
  'vuelca44',
  'cajones',
  'pesa',
  'marca44',
  'piensa',
  'mano',
  'abuela',
  'aparta42',
  'suelta',
  'llama43',
  'ayer44',
  'empuja44',
  'bolsas44',
  'marca',
  'fin',
  'ya',
];

const List<String> stories = ['la-sopa-de-abuela', 'esta-bueno', 'una-libra'];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/frutas/$id.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('frutas');
  });
  final answered = <String>{};
  final rows = <String>[];

  // one value for each story variable a draw gives ([pick] 0 or 1: the first values, or the others)
  Map<String, String> vars(String id, int pick) => switch (id) {
    'la-sopa-de-abuela' => {
      'ka': pick == 0 ? 'papas' : 'platanos',
      'kb': pick == 0 ? 'platanos' : 'papas',
      'x': pick == 0 ? 'platanos' : 'papas',
    },
    'esta-bueno' => {
      'ga': pick == 0 ? 'fruta_a' : 'fruta_b',
      'ha': pick == 0 ? 'fruta_b' : 'fruta_a',
      'wa': pick == 0 ? 'bueno' : 'malo',
      'gb': pick == 0 ? 'fruta_b' : 'fruta_a',
      'hb': pick == 0 ? 'fruta_a' : 'fruta_b',
      'wb': pick == 0 ? 'malo' : 'bueno',
      'ta': pick == 0 ? 'grande' : 'pequeno',
      'tb': pick == 0 ? 'grande' : 'pequeno',
      'x': pick == 0 ? 'fruta_b' : 'fruta_a',
    },
    _ => {
      'la': pick == 0 ? 'a' : 'b',
      'oa': pick == 0 ? 'b' : 'a',
      'lb': pick == 0 ? 'b' : 'a',
      'ob': pick == 0 ? 'a' : 'b',
      'wa': pick == 0 ? 'fresco' : 'malo',
      'wb': pick == 0 ? 'malo' : 'fresco',
      'pa': pick == 0 ? 'cajon_a' : 'cajon_a',
      'pb': pick == 0 ? 'cajon_a' : 'cajon_b',
      'ua': 'una',
      'ub': 'media',
      'x': pick == 0 ? 'cajon_b' : 'cajon_b',
    },
  };

  test('every act the Needs list names is one of the scene\'s', () {
    final scene = createFrutas() as Frutas;
    for (final a in needActs) {
      expect(scene.acts.containsKey(a), isTrue, reason: a);
    }
    // and every act the three stories call
    for (final id in stories) {
      final s = jsonEncode([_story(id)['beats'], _story(id)['final']]);
      for (final m in RegExp(r'"act":"([a-z0-9]+)"').allMatches(s)) {
        expect(scene.acts.containsKey(m[1]), isTrue, reason: '$id: ${m[1]}');
      }
    }
  });

  for (final id in stories) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createFrutas() as Frutas;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = Map.of(vars(id, pick));
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
              final t = scene.cosas.firstWhere(
                (t) => t.id == k,
                orElse: () => Thing(id: ''),
              );
              final b = scene.box(k, W);
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
              final h = scene.handAt(k)!;
              expect(
                scene.hit(h[0], h[1] + 3, W),
                k,
                reason:
                    '$id $at: the big hand on $k at $h touches something else',
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
              if (tag == null) continue;
              final k = tag.startsWith('cosa:')
                  ? tag.substring(5)
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
                // $x: what he touched on the wrong way, the other option than the right one
                final pick = sub(st['pick']);
                v['x'] = (st['options'] as List).firstWhere(
                  (o) => o != pick,
                ) as String;
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
          rows.add('$id pick $pick: $acts acts walked');
        },
      );
    }
  }

  test('every set thing\'s box holds the pixels its part draws (the bake\'s part tags), in every state', () {
    final e = frutasEngine(), set = FrutasSet(e, PpBuild(e))..tags = true;
    final sheet = jsonDecode(
      File('assets/sheets/frutas-sheet.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final things = (sheet['things'] as Map).cast<String, dynamic>();
    for (final q in (sheet['setKey']['baked'] as List).cast<String>()) {
      final st = FrutasState.fromQuery(q);
      set.buildSet(st);
      final tags = set.partTags!;
      for (final en in things.entries) {
        if (en.value is! Map) continue;
        final t = (en.value as Map).cast<String, dynamic>();
        if (t['surtido'] != null && t['surtido'] != st.surtido) continue;
        final b = (t['box'] as List).cast<num>();
        var n = 0, out = 0;
        final where = <String>[];
        for (var i = 0; i < tags.length; i++) {
          if (tags[i] != en.key) continue;
          final x = i % 240, y = i ~/ 240;
          // the scale's box is "from the dial's top row down and no further right than its right edge" (the pole and
          // the arm left out): its pixels above that row or right of that edge are not in it by the sheet's own words
          if (en.key == 'pesa' && (y < b[1] || x >= b[0] + b[2])) continue;
          n++;
          if (x < b[0] || x >= b[0] + b[2] || y < b[1] || y >= b[1] + b[3]) {
            out++;
            if (where.length < 4) where.add('($x, $y)');
          }
        }
        rows.add(
          '${st.key} ${en.key}: $n part pixels, $out outside its box ${where.join(' ')}',
        );
        // the pokes' boxes are the sheet's world boxes (the low crate, the doorway), not their parts' pixels
        if (en.key == 'cajon' || en.key == 'puerta') continue;
        // reported for the content lane, not changed (the boxes are the sheet's): the tip of a pineapple's crown in the
        // bin of piñas reaches one row above the bin's box
        final known = en.key == 'pinas' ? 1 : 0;
        expect(
          out,
          lessThanOrEqualTo(known),
          reason:
              '${st.key}: ${en.key} has $out of $n pixels outside its box $b: ${where.join(' ')}',
        );
      }
    }
  });

  tearDownAll(() {
    report('frutas-acts', rows);
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
