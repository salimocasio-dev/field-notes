// La cuenta's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in cuenta-sheet.json's things / cuenta.md's Needs list answers a touch;
// - draw, hud, shadows, and talkAt run without error.
// Over the three stories, every single one of the 23 Needs things answers a touch.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/cuenta/cuenta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing cuenta-sheet.json / cuenta.md's Needs list says he can touch (23 things).
const List<String> needs = [
  'gaveta',
  'mentas',
  'ventana',
  'puerta',
  'flanes',
  'mantecado',
  'tapa',
  'copa',
  'cuenta',
  'maquina',
  'frasco',
  'mesera',
  'mesero',
  'cocinero',
  'abuela',
  'abuelo',
  'luis',
  'carmen',
  'senor',
  'senora',
  'joven',
  'mujer',
  'coqui',
];

Map<String, dynamic> _story(String id) =>
    jsonDecode(File('test/support/fixtures/cuenta/$id.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> cuentaVars(String id, int pick) => switch (id) {
  'el-postre' =>
    pick == 0
        ? {'ga': 'senor', 'gb': 'mujer', 'da': 'mantecado', 'db': 'nada'}
        : {'ga': 'senora', 'gb': 'joven', 'da': 'flan', 'db': 'mantecado'},
  'la-cuenta-por-favor' =>
    pick == 0
        ? {
            'ga': 'senora',
            'gb': 'joven',
            'ta': '60',
            'tb': '20',
            'ca': 'efectivo',
            'cb': 'tarjeta',
          }
        : {
            'ga': 'mujer',
            'gb': 'senora',
            'ta': '40',
            'tb': '80',
            'ca': 'tarjeta',
            'cb': 'efectivo',
          },
  _ =>
    pick == 0
        ? {'ga': 'senor', 'gb': 'mujer', 'pa': 'propina', 'pb': 'cuenta'}
        : {'ga': 'joven', 'gb': 'senora', 'pa': 'cuenta', 'pb': 'propina'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('cuenta');
  });
  final answered = <String>{};

  for (final id in const [
    'el-postre',
    'la-cuenta-por-favor',
    'buenas-noches',
  ]) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createCuenta() as Cuenta;
          final host = StillHost(scene);
          host.S = story;
          host.W = {
            ...host.W,
            'lost': 0,
            'resp': null,
            'twinkle': null,
            ...scene.fresh(story),
          };
          final v = {...cuentaVars(id, pick)};
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
            // Verify talkAt for coqui and every currently visible person
            expect(
              scene.talkAt('coqui', W),
              isNotNull,
              reason: '$id $at: talkAt(coqui) returned null',
            );
            final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
            for (final en in gente.entries) {
              final p = en.value as Map<String, dynamic>;
              if (p['vis'] == 0) continue;
              expect(
                scene.talkAt(en.key, W),
                isNotNull,
                reason: '$id $at: talkAt(${en.key}) returned null',
              );
            }
            // Verify every visible sprite thing's box holds its drawn pixels
            final its = scene.items(W, 0);
            for (final k in const [
              'copa',
              'flanes',
              'mantecado',
              'tapa',
              'cuenta',
              'maquina',
              'frasco',
              ...CUENTA_PERSONAS,
            ]) {
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere((t) => t.id == k);
              if ((t.si != null && !t.si!(W)) || b == null) continue;
              final tag = CUENTA_PERSONAS.contains(k)
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
                final c = (st['cond'] as String).split('=');
                v[st['calc'] as String] =
                    sub(v[c[0]] == c[1] ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                await walk(st['then']);
                await walk(st['else']);
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

  test('every thing in cuenta.md Needs list answered a touch (23 of 23)', () {
    expect(answered, containsAll(needs));
  });

  test('story 93 seats drawn guests (ga/gb) at otra_mesa before their request plays', () async {
    final story = _story('el-postre');
    final scene = createCuenta() as Cuenta;
    final host = StillHost(scene);
    host.S = story;
    host.W = {
      ...host.W,
      'lost': 0,
      'resp': null,
      'twinkle': null,
      ...scene.fresh(story),
    };
    await scene.acts['carrito93']!({'a': 'otra_mesa'});
    // Simulate `reparte` dealing senora and joven before round A's request plays
    host.V['ga'] = 'senora';
    host.V['gb'] = 'joven';
    host.TALK = 'senora';

    final talkPt = scene.talkAt('senora', host.W);
    expect(talkPt, isNotNull);
    final silentItems = scene.items(host.W, 0);
    final speakingItems = scene.items(host.W, 1);

    final senoraSilent = silentItems.firstWhere(
      (it) => it.tag == 'persona:senora',
    );
    final senoraSpeaking = speakingItems.firstWhere(
      (it) => it.tag == 'persona:senora',
    );
    expect(
      speakingItems.any((it) => it.tag == 'persona:joven'),
      isTrue,
      reason: 'both drawn guests must be visibly seated at otra_mesa',
    );
    expect(
      speakingItems.any((it) => it.tag == 'persona:senor'),
      isFalse,
      reason: 'default placeholder senor must be replaced before request',
    );
    expect(
      identical(senoraSilent.s, senoraSpeaking.s),
      isFalse,
      reason: 'speaking drawn guest must animate mouth on odd frame',
    );
    final gente = host.W['gente'] as Map<String, dynamic>;
    expect((gente['senora'] as Map)['spot'], 'otra_mesa1');
    expect((gente['joven'] as Map)['spot'], 'otra_mesa2');
  });
}
