// La caja's acts on a host whose waits return at once (StillHost), as El mostrador's acts test: each story's steps
// walked in order, every act the stories call run with the values they give it (a story variable takes one value of
// its draw, the first or the second, and `calc` is worked out from them), both branches of each decision (the wrong one,
// then the right one) and of each `if`. After every act:
// - every touch box contains its thing (a sprite thing's box is its drawn pixels' box; a key card's and the register's
//   are the sheet's);
// - every thing the Needs list says he can touch that is shown answers a touch: some point of its box hits it;
// - the frame draws (the sprite layer, the keys and the board) and the shadows are cast without an error.
// And: each thing the Needs list names answered a touch at least once over the three stories.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/caja/caja.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// What the Needs list says he can touch (caja.md, "Needs": things he can touch).
const List<String> needs = [
  'tecla_a',
  'tecla_b',
  'cosa_a',
  'cosa_b',
  'caja',
  'frasco',
  'papel',
  'bola',
  'pepe',
  'luis',
  'carmen',
  'senora',
  'senor',
  'ninos',
  'coqui',
];

const List<String> cajaStories = ['cuanto-es', 'caro-y-barato', 'el-cambio'];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/caja/$id.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('caja');
  });
  final answered = <String>{};

  for (final id in cajaStories) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createCaja() as Caja;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = <String, String>{};
          String sub(String s) => s.replaceAllMapped(
            RegExp(r'\$([a-z]+)'),
            (m) => v[m[1]!] ?? m[0]!,
          );
          Object? subV(Object? s) => s is String ? sub(s) : s;
          bool cond(String c) {
            if (c.startsWith('!')) return (v[c.substring(1)] ?? '').isEmpty;
            final i = c.indexOf('=');
            if (i < 0) return (v[c] ?? '').isNotEmpty;
            return (v[c.substring(0, i)] ?? '') == sub(c.substring(i + 1));
          }

          final pix = Uint32List(240 * 216), disp = Uint32List(196 * 216);
          var acts = 0;
          Future<void> check(String at) async {
            final W = host.W;
            scene.forgetBoxes();
            scene.draw(Ctx(pix, 240, 216), W, host.F);
            scene.hud(Ctx(disp, 196, 216), W, host.F);
            scene.shadows(W);
            for (final k in needs) {
              if (k == 'coqui') continue;
              final t = scene.cosas.firstWhere((t) => t.id == k);
              final b = scene.box(k, W);
              if ((t.si != null && !t.si!(W)) || b == null) continue;
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
              if (tag == null) continue;
              final k = tag.startsWith('cosa:')
                  ? tag.substring(5)
                  : tag.startsWith('persona:')
                  ? tag.substring(8)
                  : null;
              if (k == null || !needs.contains(k)) continue;
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
              } else if (st['draw'] is String) {
                final ops = [for (final o in st['options'] as List) '$o'];
                final got = ops[pick % ops.length];
                v[st['draw'] as String] = got;
                if (st['other'] is String) {
                  v[st['other'] as String] = ops.firstWhere((o) => o != got);
                }
              } else if (st['calc'] is String) {
                v[st['calc'] as String] = sub(
                  '${cond(st['cond'] as String) ? st['then'] : st['else']}',
                );
              } else if (st['act'] is String) {
                final o = {for (final e in st.entries) e.key: subV(e.value)};
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
                final ops = [for (final o in st['options'] as List) '$o'];
                final right = sub(st['pick'] as String);
                v['x'] = ops.firstWhere((o) => o != right);
                v['ok'] = '';
                await walk(st['wrong']);
                await walk(st['right']);
                v['x'] = right;
                v['ok'] = '1';
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
        },
      );
    }
  }

  tearDownAll(() {
    expect(answered, containsAll(needs), reason: 'answered: $answered');
  });
}
