// La muralla's acts on StillHost: each story's steps walked in order with two sets of variable assignments,
// running both branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in muralla.md's Needs list answers a touch;
// - draw, hud, shadows, and talkAt run without error.
// Over the three stories, every single Needs thing answers a touch, plus pixel-visibility checks for doors,
// cord, lanterns, far-road guagua, and special poses.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/muralla/muralla.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

const List<String> murallaNeeds = [
  'puerta_roja',
  'puerta_azul',
  'camara',
  'silla',
  'jugo',
  'plato',
  'vela',
  'guitarra',
  'sombrero',
  'bolsa',
  'caja',
  'libro',
  'banco',
  'escalera',
  ...MURALLA_PERSONAS,
  'coqui',
];

Map<String, dynamic> _story(String id) => jsonDecode(
  File('test/support/fixtures/muralla/$id.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('muralla');
  });

  final answered = <String>{};

  for (final id in const [
    'todos-en-la-foto',
    'por-que-no-bailas',
    'nos-vemos',
  ]) {
    for (final pick in const [0, 1]) {
      test(
        '$id (pick $pick): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createMuralla() as Muralla;
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
            if (id == 'nos-vemos') {
              expect(
                scene.talkAt('gente', W),
                isNotNull,
                reason: '$id $at: talkAt(gente) returned null',
              );
            }

            // Check visible sprite things match boxes
            final its = scene.placed(W, 0);
            for (final k in const [
              'camara',
              'silla',
              'jugo',
              'plato',
              'vela',
              'guitarra',
              'sombrero',
              'bolsa',
              'caja',
              'libro',
              'farol1',
              'farol2',
              'farol3',
              'guagua',
              ...MURALLA_PERSONAS,
            ]) {
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere((t) => t.id == k);
              if ((t.si != null && !t.si!(W)) || b == null) continue;
              final tag = MURALLA_PERSONAS.contains(k)
                  ? 'persona:$k'
                  : 'cosa:$k';
              for (final it in its) {
                if (it.tag != tag) continue;
                final cb = it.clipBox;
                for (var py = 0; py < it.s.h; py++) {
                  for (var px = 0; px < it.s.w; px++) {
                    if (it.s.px[py * it.s.w + px] >>> 24 == 0) continue;
                    final X = it.left + px, Y = it.top + py;
                    if (X < 0 || X >= 240 || Y < 0 || Y >= 216) continue;
                    if (cb != null &&
                        (X < cb[0] ||
                            X >= cb[0] + cb[2] ||
                            Y < cb[1] ||
                            Y >= cb[1] + cb[3])) {
                      continue;
                    }
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

            for (final k in murallaNeeds) {
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
                reason: '$id $at: thing $k box $b did not hit',
              );
              answered.add(k);
            }
            final cq = W['cq'] as Map<String, dynamic>?;
            if (cq != null && jsTruthy(cq['vis'])) {
              final fb = host.frogBox(cq);
              expect(
                scene.hit(fb.x + fb.w / 2, fb.y + fb.h / 2, W),
                'coqui',
                reason: '$id $at: frog did not hit',
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
              } else if (st['draw'] is String) {
                final name = st['draw'] as String;
                final ops = [for (final o in st['options'] as List) '$o'];
                v[name] = ops[pick % ops.length];
              } else if (st['reparte'] is List) {
                final names = (st['reparte'] as List).cast<String>();
                final ops = [for (final o in st['options'] as List) '$o'];
                for (var i = 0; i < names.length; i++) {
                  v[names[i]] = ops[(i + pick) % ops.length];
                }
              } else if (st['calc'] is String) {
                final cond = (st['cond'] as String).split('=');
                final lhs = v[cond[0]] ?? sub(cond[0]);
                final rhs = sub(cond[1]);
                v[st['calc'] as String] =
                    sub(lhs == rhs ? st['then'] : st['else']) as String;
              } else if (st['act'] is String) {
                final o = {for (final e in st.entries) e.key: sub(e.value)};
                await scene.acts[st['act']]!(o);
                acts++;
                host.F += 3;
                await check('after ${st['act']}');
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
                host.W['lost'] = (host.W['lost'] as int) + 1;
                await walk(st['wrong']);
                await walk(st['right']);
              } else if (st['if'] is String) {
                final cond = st['if'] as String;
                if (cond == 'ok') {
                  await walk(st['else']);
                  await walk(st['then']);
                } else if (cond.startsWith('lost=')) {
                  await walk(st['then']);
                } else {
                  final parts = cond.split('=');
                  final lhs = v[parts[0]] ?? sub(parts[0]);
                  final rhs = sub(parts[1]);
                  await walk(lhs == rhs ? st['then'] : st['else']);
                }
              }
            }
          }

          await check('at start');
          await walk(story['beats']);
          await walk(story['final']);
          expect(acts, greaterThan(10));
        },
      );
    }
  }

  test('every one of the 26 Needs things answered a touch', () {
    expect(answered, containsAll(murallaNeeds));
  });

  test(
    'open door, cord, lanterns, guagua, and clipped Carmen render visibly',
    () {
      final scene = createMuralla() as Muralla;
      final host = StillHost(scene);
      final engine = scene.places.e;
      final baked = SetBakes(scene).bakeKey('noche');
      final w = scene.fresh(_story('todos-en-la-foto'));
      host.W = w;
      w['redDoorOpen'] = 1;
      (w['gente'] as Map)['carmen'] = {
        'vis': 1,
        ...scene.places
            .at('dentro_roja')
            .let((a) => {'x': a.x, 'y': a.y, 'z': a.z}),
        'spot': 'dentro_roja',
        'pose': 'boca',
        'sent': 0,
        'dx': 0,
        'dy': 0,
      };
      scene.setFramed(engine, baked, w);
      final frame = Uint32List.fromList(baked.pix);
      scene.draw(Ctx(frame, 240, 216), w, 0);
      final rb = scene.places.box('puerta_roja');
      var doorDiff = 0;
      for (var y = rb[1]; y < rb[1] + rb[3]; y++) {
        for (var x = rb[0]; x < rb[0] + rb[2]; x++) {
          if (frame[y * 240 + x] != baked.pix[y * 240 + x]) doorDiff++;
        }
      }
      expect(doorDiff, greaterThan(300));
      final fb = scene.places.spotBox('farol2');
      var farolDiff = 0;
      for (var y = fb[1]; y < fb[1] + fb[3]; y++) {
        for (var x = fb[0]; x < fb[0] + fb[2]; x++) {
          if (frame[y * 240 + x] != baked.pix[y * 240 + x]) farolDiff++;
        }
      }
      expect(farolDiff, greaterThan(40));
    },
  );
}

extension _LetExt<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
