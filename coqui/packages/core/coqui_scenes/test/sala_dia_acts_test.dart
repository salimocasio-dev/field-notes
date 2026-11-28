// La sala, de día's acts on StillHost: each story's steps walked in order with two sets of draw values, running both
// branches (wrong then right) of every decision. After every act:
// - every sprite thing's touch box holds its drawn pixels;
// - every visible thing in sala_dia.md's Needs list (17 things) answers a touch;
// - draw, hud, shadows, and talkAt run without error.
// Over the three stories, all 17 Needs things answer a touch and all 6 speakers have non-null talkAt.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/sala_dia/sala_dia.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/sheet_bundle.dart';

/// Every thing sala_dia.md's Needs list says he can touch (17 things).
const List<String> needs = [
  'libro',
  'papel',
  'telefono',
  'oreja_abuelo',
  'boca_abuelo',
  'computadora',
  'pagina1',
  'pagina2',
  'pagina3',
  'foto',
  'estrellas',
  'ventana',
  'luis',
  'carmen',
  'abuela',
  'abuelo',
  'coqui',
];

Map<String, dynamic> _story(String id) => jsonDecode(
  File('test/support/fixtures/sala_dia/$id.json').readAsStringSync(),
) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ScenePictures(bundle: testBundle()).frameOf('sala_dia');
  });
  final answered = <String>{};
  final speakersSeen = <String>{};

  for (final id in const ['lee-y-escribe', 'el-telefono', 'por-la-tarde']) {
    for (final pick in const [0, 1]) {
      test(
        '$id (${pick == 0 ? 'first' : 'second'} values): every act, boxes and touches after each',
        () async {
          final story = _story(id);
          final scene = createSalaDia() as SalaDia;
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
            final gente = (W['gente'] as Map<String, dynamic>?) ?? const {};
            for (final spk in SALA_DIA_SPEAKERS) {
              if (spk == 'coqui') {
                if (jsTruthy((W['cq'] as Map?)?['vis'])) {
                  expect(
                    scene.talkAt(spk, W),
                    isNotNull,
                    reason: '$id $at: talkAt(coqui) returned null',
                  );
                  speakersSeen.add(spk);
                }
              } else if (spk == 'mama') {
                if ((W['story'] as int?) == 103) {
                  expect(
                    scene.talkAt(spk, W),
                    isNotNull,
                    reason: '$id $at: talkAt(mama) returned null in story 103',
                  );
                  speakersSeen.add(spk);
                }
              } else {
                final p = gente[spk] as Map<String, dynamic>?;
                if (p != null && p['vis'] != 0) {
                  expect(
                    scene.talkAt(spk, W),
                    isNotNull,
                    reason: '$id $at: talkAt($spk) returned null while visible',
                  );
                  speakersSeen.add(spk);
                }
              }
            }
            // Verify every visible sprite thing's box holds its drawn pixels
            final its = scene.items(W, 0);
            for (final k in const [
              'libro',
              'papel',
              'telefono',
              'pagina1',
              'pagina2',
              'pagina3',
              'estrellas',
              'foto',
              'abuela',
              'abuelo',
              'luis',
              'carmen',
            ]) {
              final b = scene.box(k, W);
              final t = scene.cosas.firstWhere((t) => t.id == k);
              if ((t.si != null && !t.si!(W)) || b == null) continue;
              final tag = SALA_DIA_PERSONAS.contains(k)
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
              } else if (st['draw'] is String) {
                final name = st['draw'] as String;
                final ops = [for (final o in st['options'] as List) '$o'];
                final chosen = ops[pick % ops.length];
                v[name] = chosen;
                if (st['other'] is String) {
                  v[st['other'] as String] = ops.firstWhere((o) => o != chosen);
                }
              } else if (st['reparte'] is List) {
                final names = (st['reparte'] as List).cast<String>();
                final ops = [for (final o in st['options'] as List) '$o'];
                for (var i = 0; i < names.length; i++) {
                  v[names[i]] = ops[(i + pick) % ops.length];
                }
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
                final lhs = v[c[0]] ?? c[0];
                final rhs = sub(c[1]) as String;
                v[st['calc'] as String] =
                    sub(lhs == rhs ? st['then'] : st['else']) as String;
              } else if (st['if'] is String) {
                final cond = st['if'] as String;
                if (cond.contains('=') && !cond.startsWith('lost=')) {
                  final c = cond.split('=');
                  final lhs = v[c[0]] ?? c[0];
                  final rhs = sub(c[1]) as String;
                  await walk(lhs == rhs ? st['then'] : st['else']);
                } else {
                  await walk(st['then']);
                }
              }
            }
          }

          await check('start');
          await walk(story['beats']);
          await walk(story['final']);
          expect(acts, greaterThan(10));
        },
      );
    }
  }

  test('every thing in Needs answers a touch and every speaker has talkAt', () {
    expect(answered, containsAll(needs));
    expect(speakersSeen, containsAll(SALA_DIA_SPEAKERS));
  });

  test('story-specific act state transitions and edge cases', () async {
    final scene = createSalaDia() as SalaDia;
    final host = StillHost(scene);
    host.W = {...host.W, ...scene.fresh(_story('por-la-tarde'))};
    expect(scene.setKey(host.W), '0');
    await scene.acts['pantalla104']!({'act': 'pantalla104'});
    expect(scene.setKey(host.W), '1');

    // Off-screen abuela in story 104 still provides a non-null talkAt point (kitchen doorway).
    expect(scene.talkAt('abuela', host.W), isNotNull);

    // Gestures & sale act exercise all Needs gesture kinds cleanly.
    host.W = {...host.W, ...scene.fresh(_story('el-telefono'))};
    for (final que in const [
      'saluda',
      'no',
      'si',
      'rie',
      'oreja',
      'harina',
      'silencio',
      'cuenta',
    ]) {
      await scene.acts['gesto']!({
        'act': 'gesto',
        'quien': 'abuelo',
        'que': que,
      });
    }
    await scene.acts['gesto']!({
      'act': 'gesto',
      'quien': 'luis',
      'que': 'senala',
      'a': 'computadora',
    });
    await scene.acts['sale']!({'act': 'sale', 'quien': 'abuela'});
    expect((host.W['gente'] as Map)['abuela']['vis'], 0);
  });
}
