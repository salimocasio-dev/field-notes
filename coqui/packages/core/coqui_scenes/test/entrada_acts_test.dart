// La entrada's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in entrada.md's Needs list answers a touch;
// - draw, hud, shadows, and talkAt run without error.
// Over the three stories, every single thing (22 + coqui) and every speaker key (12) is verified.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/entrada/entrada.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing entrada.md's Needs list says he can touch (22 things + coqui).
const List<String> needs = [
  'mesera',
  'banco',
  'mesa1',
  'mesa2',
  'mesa3',
  'menu',
  'cosa_a',
  'cosa_b',
  'velas',
  'dulces',
  'mesero',
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'senor',
  'senora',
  'hombre',
  'mujer',
  'joven',
  'coqui',
  'puerta',
  'vellonera',
];

Map<String, dynamic> _story(String id) => jsonDecode(
  File('test/support/fixtures/entrada/$id.json').readAsStringSync(),
) as Map<String, dynamic>;

Map<String, String> entradaVars(String id, int pick) => switch (id) {
  'bienvenidos' =>
    pick == 0
        ? {'da': 'adelante', 'db': 'momento'}
        : {'da': 'momento', 'db': 'adelante'},
  'esta-libre' =>
    pick == 0
        ? {
            'fa': 'verde',
            'ea': '3',
            'la': 'mesa2',
            'oa': 'tl',
            'qa': 'mujer',
            'eb': '1',
            'gb': '4',
            'lb': 'mesa3',
            'ob': 'lt',
          }
        : {
            'fa': 'amarillo',
            'ea': '1',
            'la': 'mesa3',
            'oa': 'lt',
            'qa': 'hombre',
            'eb': '4',
            'gb': '2',
            'lb': 'mesa2',
            'ob': 'tl',
          },
  _ =>
    pick == 0
        ? {
            'qa': 'carmen',
            'ca': 'sin',
            'ia': 'con',
            'gb': '2',
            'cb': 'con',
            'ib': 'sin',
          }
        : {
            'qa': 'abuela',
            'ca': 'con',
            'ia': 'sin',
            'gb': '3',
            'cb': 'sin',
            'ib': 'con',
          },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('entrada');
  });
  final answered = <String>{};
  final talked = <String>{};

  for (final id in const ['bienvenidos', 'esta-libre', 'con-y-sin']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createEntrada() as Entrada;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = {...entradaVars(id, pick)};
          Object? sub(Object? s) => s is String
              ? s.replaceAllMapped(
                  RegExp(r'\$([a-z0-9]+)'),
                  (m) => v[m[1]!] ?? m[0]!,
                )
              : s;
          bool evalCond(String cond) {
            if (cond == 'ok') return true;
            final eq = cond.indexOf('=');
            if (eq < 0) return false;
            final lhs = cond.substring(0, eq);
            final rhs = cond.substring(eq + 1);
            if (lhs == 'lost') return '${host.W['lost']}' == rhs;
            return v[lhs] == rhs;
          }

          final pix = Uint32List(240 * 216), disp = Uint32List(196 * 216);
          var acts = 0;

          Future<void> check(String at) async {
            final W = host.W;
            scene.draw(Ctx(pix, 240, 216), W, host.F);
            scene.hud(Ctx(disp, 196, 216), W, host.F);
            scene.shadows(W);
            // Verify talkAt for every visible speaker
            final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
            for (final spk in ENTRADA_SPEAKERS) {
              if (spk == 'coqui') {
                expect(
                  scene.talkAt(spk, W),
                  isNotNull,
                  reason: '$id $at: talkAt(coqui) returned null',
                );
                talked.add(spk);
              } else if ((gente[spk] as Map?)?['vis'] == 1) {
                expect(
                  scene.talkAt(spk, W),
                  isNotNull,
                  reason: '$id $at: talkAt($spk) returned null when visible',
                );
                talked.add(spk);
              }
            }
            // Verify every visible sprite thing's box holds its drawn pixels
            final its = scene.items(W, 0);
            for (final k in const [
              'cosa_a',
              'cosa_b',
              'menu',
              'dulces',
              'mesera',
              'mesero',
              'abuela',
              'abuelo',
              'luis',
              'carmen',
              'senor',
              'senora',
              'hombre',
              'mujer',
              'joven',
            ]) {
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere((t) => t.id == k);
              if ((t.si != null && !t.si!(W)) || b == null) continue;
              final tag = ENTRADA_TOUCH_PEOPLE.contains(k)
                  ? 'persona:$k'
                  : 'cosa:$k';
              for (final it in its) {
                if (it.tag != tag) continue;
                for (var py = 0; py < it.s.h; py++) {
                  for (var px = 0; px < it.s.w; px++) {
                    if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
                    final X = it.left + px, Y = it.top + py;
                    if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
                    expect(
                      X >= b[0] &&
                          X < b[0] + b[2] &&
                          Y >= b[1] &&
                          Y < b[1] + b[3],
                      isTrue,
                      reason: '$id $at: $k pixel ($X,$Y) outside box $b',
                    );
                  }
                }
              }
            }
            // Verify every visible thing in Needs answers a touch
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
              expect(
                frogHits,
                isTrue,
                reason: '$id $at: coqui answers no touch',
              );
              answered.add('coqui');
            }
          }

          Future<void> walk(Object? steps) async {
            if (steps is! List) return;
            for (final st in steps) {
              if (st is! Map<String, dynamic>) continue;
              if (st['set'] is Map) {
                host.W.addAll((st['set'] as Map).cast<String, dynamic>());
              } else if (st['cost'] is num) {
                host.W['lost'] =
                    (host.W['lost'] as int) + (st['cost'] as num).toInt();
              } else if (st['act'] is String) {
                final name = st['act'] as String;
                expect(
                  scene.acts.containsKey(name),
                  isTrue,
                  reason: '$id: unknown act $name',
                );
                final o = {for (final e in st.entries) e.key: sub(e.value)};
                await scene.acts[name]!(o);
                host.F += 3;
                acts++;
                if (!jsTruthy(o['suelto'])) await check('after $name (#$acts)');
              } else if (st['ask'] is String) {
                await walk(st['lead']);
                final k = sub(st['ask']) as String;
                final b = scene.box(k, host.W);
                expect(b, isNotNull, reason: '$id: asked thing $k has no box');
                await walk(st['after']);
                await walk(st['then']);
              } else if (st['decide'] is String) {
                await walk(st['lead']);
                final pk = sub(st['pick']) as String;
                final ops = [
                  for (final o in st['options'] as List) sub(o) as String,
                ];
                for (final op in ops) {
                  expect(
                    scene.box(op, host.W),
                    isNotNull,
                    reason: '$id: decide option $op has no box',
                  );
                }
                v['x'] = ops.firstWhere((o) => o != pk);
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['calc'] is String) {
                final ok = evalCond(st['cond'] as String);
                v[st['calc'] as String] =
                    sub(ok ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                if (evalCond(st['if'] as String)) {
                  await walk(st['then']);
                } else {
                  await walk(st['else']);
                }
              }
            }
          }

          await check('start');
          await walk(story['beats']);
          await walk(story['final']);
          expect(acts, greaterThan(5));
        },
      );
    }
  }

  test('every thing in entrada.md Needs list answered a touch', () {
    expect(answered, containsAll(needs));
  });

  test('talkAt returned non-null for all 12 speaker keys', () {
    expect(talked, containsAll(ENTRADA_SPEAKERS));
  });
}
